#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  waybar 系统更新检查 / 全量更新（Arch Linux）
#
#  安全设计（参考社区实践，如 pacman-contrib / arch-update / waybar 社区模块）：
#   · 检查阶段只查询、不升级，不触碰 /var/lib/pacman
#     （官方 checkupdates 在 /tmp 的临时数据库中同步，杜绝部分升级）
#   · 仓库更新用 checkupdates（pacman-contrib 自带的安全工具）
#   · AUR 更新用 paru/yay 的只读查询（-Qua，无 sudo、不编译）
#   · Flatpak 用 flatpak remote-ls --updates
#   · 结果缓存（默认 1 小时），flock 防并发，pacman 运行时跳过检查
#   · 更新前自动创建 snapper 快照，更新后把变更写入日志（grep pacman.log）
#
#  用法：
#    updates.sh            输出 waybar JSON（模块每 5 分钟调用一次）
#    updates.sh --force    忽略缓存，重新检查（右键点击调用）
#    updates.sh --list     在终端里友好地列出全部更新与安全提示
#    updates.sh --open     交互式菜单：回车=检查/全量更新，数字选择其它操作（左键点击调用）
#    updates.sh --update   直接执行全量更新：快照 → yay -Syu → 按需重建 GRUB → 写日志
#    updates.sh --log      查看更新日志（中键点击调用）
#    updates.sh --help
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
CACHE_FILE="$CACHE_DIR/updates.json"
LOCK_FILE="$CACHE_DIR/updates.lock"
CACHE_TTL="${UPDATES_TTL:-3600}"   # 缓存有效期（秒）

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
LOG_FILE="$STATE_DIR/updates.log"  # 更新记录（含 pacman.log 的 grep 结果）
PACMAN_LOG="${PACMAN_LOG:-/var/log/pacman.log}"

SNAPPER_CONFIG="${SNAPPER_CONFIG:-root}"   # snapper 配置名
AUR_HELPER="${AUR_HELPER:-yay}"            # 全量更新用的 AUR helper
# grub-mkconfig 策略：auto=仅在内核增删或 grub 包变化时执行；always/never
GRUB_MKCONFIG="${GRUB_MKCONFIG:-auto}"

# 出现这些包时视为关键更新（红色提醒）
CRITICAL_PKGS=" linux linux-lts linux-zen linux-hardened glibc systemd nvidia nvidia-dkms nvidia-open-dkms mesa pacman "

ICON_UPDATES="󰚰"   # md-update
ICON_OK="󰕥"        # md-shield_check

mkdir -p "$CACHE_DIR"

# ── 终端颜色（仅 --list 且是 TTY 时启用） ───────────────────────────
if [[ -t 1 ]]; then
  BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'
  GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; CYAN=$'\e[36m'; RESET=$'\e[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; RESET=""
fi

usage() {
  sed -n '2,22p' "$0"
}

# ── 数据采集 ────────────────────────────────────────────────────────
check_repo() {
  command -v checkupdates >/dev/null 2>&1 || return 0
  checkupdates 2>/dev/null || true
}

check_aur() {
  local helper
  for helper in paru yay; do
    if command -v "$helper" >/dev/null 2>&1; then
      "$helper" -Qua 2>/dev/null || true
      return 0
    fi
  done
}

check_flatpak() {
  command -v flatpak >/dev/null 2>&1 || return 0
  flatpak remote-ls --updates --columns=application,version 2>/dev/null || true
}

last_upgrade() {
  local line
  line=$(grep -a "starting full system upgrade" /var/log/pacman.log 2>/dev/null | tail -1 || true)
  [[ -z "$line" ]] && return 0
  sed -E 's/^\[([^]]+)\].*/\1/' <<<"$line" | cut -d+ -f1 | tr T ' '
}

refresh_cache() {
  # pacman 正在运行（数据库被锁）时不动缓存，等下一轮重试
  if [[ -e /var/lib/pacman/db.lck ]]; then
    return 1
  fi

  local repo aur flatpak
  repo=$(check_repo)
  aur=$(check_aur)
  flatpak=$(check_flatpak)

  jq -n \
    --argjson ts "$(date +%s)" \
    --arg last_upgrade "$(last_upgrade)" \
    --arg repo "$repo" --arg aur "$aur" --arg flatpak "$flatpak" \
    '{ts: $ts, last_upgrade: $last_upgrade, repo: $repo, aur: $aur, flatpak: $flatpak}' \
    >"$CACHE_FILE.tmp" && mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

# 同一时间只允许一个实例联网检查；LOCK_WAIT>0 时最多等待这么多秒
with_lock() {
  exec 9>"$LOCK_FILE"
  flock -w "${LOCK_WAIT:-0}" 9 || return 1
  "$@"
}

# 手动检查完成后的桌面通知（右键点击时用，给个明确反馈）
notify_check_result() {
  command -v notify-send >/dev/null 2>&1 || return 0
  local total
  total=$(cached_total)
  if [[ "$total" -gt 0 ]]; then
    notify-send -a waybar -i system-software-update "系统更新" "检查完成：$total 个可更新"
  else
    notify-send -a waybar -i system-software-update "系统更新" "系统已是最新"
  fi
}

# 强制刷新缓存并通知 waybar 重绘（等锁最多 60 秒，失败自动重试）
refresh_and_signal() {
  local attempt ok=1
  for attempt in 1 2 3; do
    if LOCK_WAIT=60 with_lock refresh_cache; then
      ok=0
      break
    fi
    sleep 2
  done
  pkill -RTMIN+8 waybar 2>/dev/null || true
  return "$ok"
}

cache_age() {
  local ts
  ts=$(jq -r '.ts // 0' "$CACHE_FILE" 2>/dev/null || echo 0)
  echo "$(($(date +%s) - ts))"
}

ensure_cache() {
  local force="${1:-}"
  if [[ "$force" == "--force" ]]; then
    # 手动刷新：等锁，确保真的刷新成功（右键点击走这里）
    LOCK_WAIT=60 with_lock refresh_cache || true
  elif [[ ! -s "$CACHE_FILE" || "$(cache_age)" -gt "$CACHE_TTL" ]]; then
    with_lock refresh_cache || true
  fi
}

count_lines() {
  [[ -z "${1:-}" ]] && echo 0 || grep -c . <<<"$1"
}

# ── 全量更新（snapper 快照 + AUR helper + 日志） ────────────────────
cached_total() {
  [[ -s "$CACHE_FILE" ]] || { echo 0; return; }
  jq -r 'def n(s): (s | split("\n") | map(select(. != "")) | length);
         n(.repo) + n(.aur) + n(.flatpak)' "$CACHE_FILE" 2>/dev/null || echo 0
}

snapper_config() {
  local configs
  command -v snapper >/dev/null 2>&1 || return 0
  configs=$(snapper --csvout --no-headers list-configs --columns config 2>/dev/null || true)
  if grep -qx "$SNAPPER_CONFIG" <<<"$configs"; then
    echo "$SNAPPER_CONFIG"
  else
    head -1 <<<"$configs"
  fi
}

snapper_latest() {
  snapper --csvout --no-headers -c "$1" list --columns number 2>/dev/null | tail -1
}

# 创建快照，成功时输出 "<配置名> <快照号>"
create_snapshot() {
  local desc="$1" config before after
  command -v snapper >/dev/null 2>&1 || return 0
  config=$(snapper_config)
  [[ -z "$config" ]] && return 0

  before=$(snapper_latest "$config")
  if ! sudo snapper --quiet -c "$config" create -d "$desc" >/dev/null 2>&1; then
    return 0
  fi
  after=$(snapper_latest "$config")
  if [[ -n "$after" && "$after" != "$before" ]]; then
    echo "$config $after"
  fi
}

# ── GRUB 配置重建 ───────────────────────────────────────────────────
grub_config_path() {
  local path
  for path in /boot/grub/grub.cfg /boot/grub2/grub.cfg; do
    [[ -f "$path" ]] && { echo "$path"; return; }
  done
}

# 判断是否需要 grub-mkconfig（auto：仅内核增删 / grub 包变化）
grub_mkconfig_needed() {
  local changes="$1"

  case "$GRUB_MKCONFIG" in
    never) return 1 ;;
    always) return 0 ;;
  esac

  command -v grub-mkconfig >/dev/null 2>&1 || return 1
  [[ -n "$(grub_config_path)" ]] || return 1

  # 新增/移除内核（升级内核不需要：vmlinuz-* 文件名不变）
  if grep -qE '\[ALPM\] (installed|removed) (linux|linux-lts|linux-zen|linux-hardened|linux-rt|linux-rt-lts|linux-rt-zen)\b' <<<"$changes"; then
    return 0
  fi
  # grub / grub-btrfs / grub 主题变化
  if grep -qE '\[ALPM\] (installed|upgraded|removed) (grub|grub-btrfs|grub-theme[^ ]*)\b' <<<"$changes"; then
    return 0
  fi
  return 1
}

# 执行 grub-mkconfig，把结果写入 GRUB_NOTE 供日志使用
GRUB_NOTE=""
run_grub_mkconfig() {
  local cfg out rc=0
  cfg=$(grub_config_path)
  [[ -z "$cfg" ]] && { GRUB_NOTE="未找到 grub.cfg，已跳过"; return 1; }

  out=$(sudo grub-mkconfig -o "$cfg" 2>&1) || rc=$?
  if [[ "$rc" -eq 0 ]]; then
    GRUB_NOTE="已重建 $cfg（grub-mkconfig 成功）"
  else
    GRUB_NOTE="重建 $cfg 失败（退出码 $rc）"
  fi
  tail -6 <<<"$out" | sed 's/^/        /'
  return "$rc"
}

# 把本次更新写入日志（含 grep pacman.log 得到的软件包变更）
write_update_log() {
  local start="$1" end="$2" rc="$3" snap_config="$4" snap_num="$5" desc="$6" changes="$7" grub_note="$8"
  mkdir -p "$STATE_DIR"
  {
    echo "──────────────────────────────────────────────────────────────"
    echo "[$start] 开始全量更新（$AUR_HELPER -Syu）"
    if [[ -n "$snap_num" ]]; then
      echo "  快照：#$snap_num（$desc）"
    else
      echo "  快照：未创建（snapper 不可用或创建失败）"
    fi
    echo "[$end] 更新结束 · 退出码 $rc"
    if [[ -n "$changes" ]]; then
      echo "  本次变更（grep $PACMAN_LOG）："
      sed 's/^/    /' <<<"$changes"
    else
      echo "  本次变更：无记录"
    fi
    if [[ -n "$grub_note" ]]; then
      echo "  GRUB：$grub_note"
    fi
    if [[ -n "$snap_num" ]]; then
      echo "  回滚命令：sudo snapper -c $snap_config rollback $snap_num"
    fi
  } >>"$LOG_FILE"
}

do_update() {
  # 选择可用的 AUR helper（默认 yay）
  if ! command -v "$AUR_HELPER" >/dev/null 2>&1; then
    if command -v paru >/dev/null 2>&1; then
      AUR_HELPER=paru
    else
      echo "错误：未找到 yay/paru，无法执行全量更新。" >&2
      return 1
    fi
  fi

  local total start_t desc snap_info snap_config="" snap_num=""
  local log_lines_before changes end_t rc=0 remain=0

  printf '\n%s全量更新%s · %s\n' "$BOLD$CYAN" "$RESET" "$AUR_HELPER -Syu"

  # 1. 更新前重新检查最新状态（避免旧缓存导致漏更 / 误判）
  echo "  [1/6] 更新前重新检查最新状态 ..."
  if refresh_and_signal; then
    total=$(cached_total)
    printf '        待更新 %s 个（仓库 %s · AUR %s · Flatpak %s）\n' \
      "$total" \
      "$(jq -r 'def n(s): (s|split("\n")|map(select(.!=""))|length); n(.repo)' "$CACHE_FILE")" \
      "$(jq -r 'def n(s): (s|split("\n")|map(select(.!=""))|length); n(.aur)' "$CACHE_FILE")" \
      "$(jq -r 'def n(s): (s|split("\n")|map(select(.!=""))|length); n(.flatpak)' "$CACHE_FILE")"
  else
    printf '        %s警告：刷新检查失败（pacman 正在运行？），使用上次的检查结果%s\n' "$YELLOW" "$RESET"
    total=$(cached_total)
  fi
  if [[ "$total" -eq 0 ]]; then
    echo "        系统已是最新，无需更新。"
    return 0
  fi

  start_t=$(date '+%Y-%m-%d %H:%M:%S')
  desc="Befor Update -- $start_t"

  # 2. snapper 快照
  echo "  [2/6] 创建 snapper 快照：$desc"
  snap_info=$(create_snapshot "$desc") || true
  if [[ -n "$snap_info" ]]; then
    snap_config="${snap_info%% *}"
    snap_num="${snap_info##* }"
    printf '        快照 %s#%s%s 已创建（配置：%s）\n' "$GREEN" "$snap_num" "$RESET" "$snap_config"
  else
    printf '        %s警告：快照创建失败（snapper 未配置或认证取消），继续更新%s\n' "$YELLOW" "$RESET"
  fi

  log_lines_before=$(wc -l <"$PACMAN_LOG" 2>/dev/null || echo 0)

  # 3. 全量更新（官方仓库 + AUR）
  echo "  [3/6] $AUR_HELPER -Syu ..."
  "$AUR_HELPER" -Syu || rc=$?

  # 4. Flatpak
  if [[ "$rc" -eq 0 ]] && command -v flatpak >/dev/null 2>&1; then
    echo "  [4/6] flatpak update ..."
    flatpak update -y || rc=$?
  else
    echo "  [4/6] 跳过 Flatpak"
  fi

  # 用 grep 提取本次事务在 pacman.log 中的变更
  changes=$(tail -n "+$((log_lines_before + 1))" "$PACMAN_LOG" 2>/dev/null |
    grep -E '\[ALPM\] (upgraded|installed|removed|downgraded|reinstalled)' || true)

  # 5. 按需重建 GRUB 配置（内核增删 / grub 包变化时；GRUB_MKCONFIG=always 可强制）
  GRUB_NOTE=""
  if [[ "$rc" -ne 0 ]]; then
    echo "  [5/6] 更新未成功，跳过 grub-mkconfig"
    GRUB_NOTE="跳过（更新未成功）"
  elif grub_mkconfig_needed "$changes"; then
    echo "  [5/6] 检测到内核/GRUB 变更，重建 GRUB 配置 ..."
    run_grub_mkconfig || true
    [[ -z "$GRUB_NOTE" ]] && GRUB_NOTE="grub-mkconfig 未执行"
  else
    echo "  [5/6] 跳过 grub-mkconfig（本次没有内核增删 / GRUB 变更）"
    GRUB_NOTE="跳过（无内核/GRUB 变更）"
  fi

  end_t=$(date '+%Y-%m-%d %H:%M:%S')

  # 6. 写日志，并自动复查更新状态（避免更新过程中仓库又推了新版本）
  write_update_log "$start_t" "$end_t" "$rc" "$snap_config" "$snap_num" "$desc" "$changes" "$GRUB_NOTE"

  echo "  [6/6] 记录已写入：$LOG_FILE"
  if [[ -n "$snap_num" ]]; then
    echo "        回滚命令：sudo snapper -c $snap_config rollback $snap_num"
  fi
  if [[ "$rc" -eq 0 ]]; then
    printf '  %s更新完成%s · %s\n' "$GREEN" "$RESET" "$end_t"
  else
    printf '  %s更新中断/失败（退出码 %s）%s · %s\n' "$RED" "$rc" "$RESET" "$end_t"
  fi

  # 更新后复查：重新联网检查并立刻刷状态栏
  echo "  更新后复查最新状态 ..."
  rm -f "$CACHE_FILE"
  if refresh_and_signal; then
    remain=$(cached_total)
    if [[ "$remain" -gt 0 ]]; then
      printf '  %s更新后仍有 %s 个可更新%s（仓库刚推送的新版本，可再次更新）\n' \
        "$YELLOW" "$remain" "$RESET"
    else
      printf '  %s系统已是最新%s\n' "$GREEN" "$RESET"
    fi
  else
    printf '  %s复查失败，状态栏将在下次自动检查时更新%s\n' "$YELLOW" "$RESET"
  fi

  return "$rc"
}

# ── 交互式菜单 ──────────────────────────────────────────────────────
NEWS_CACHE=""   # "日期：标题" 每行一条，由 fetch_news_items 填充

# 获取最近 5 条 Arch 新闻
fetch_news_items() {
  timeout 10 python3 - <<'PY' 2>/dev/null || true
import html, re, urllib.request
try:
    xml = urllib.request.urlopen("https://archlinux.org/feeds/news/", timeout=8).read().decode()
    items = re.findall(r"<item>.*?<title>(.*?)</title>.*?<pubDate>(.*?)</pubDate>", xml, re.S)
    for title, date in items[:5]:
        m = re.search(r"\d{2} \w{3} \d{4}", date)
        badge = m.group(0) if m else date.strip()
        print(f"{badge}：{html.unescape(title.strip())}")
except Exception:
    pass
PY
}

# 动态生成菜单；可用动作按顺序放进 MENU_ACTIONS
render_menu() {
  local total pacnew_n orphans_n
  total=$(cached_total)
  pacnew_n=$(pacdiff -o 2>/dev/null | grep -c . || true)
  orphans_n=$(pacman -Qtdq 2>/dev/null | grep -c . || true)
  : "${pacnew_n:=0}" "${orphans_n:=0}"

  MENU_ACTIONS=()
  local idx=1

  printf '%s当前状态%s  待更新 %s（仓库 %s · AUR %s · Flatpak %s）' \
    "$BOLD" "$RESET" "$total" \
    "$(jq -r 'def n(s):(s|split("\n")|map(select(.!=""))|length); n(.repo)' "$CACHE_FILE")" \
    "$(jq -r 'def n(s):(s|split("\n")|map(select(.!=""))|length); n(.aur)' "$CACHE_FILE")" \
    "$(jq -r 'def n(s):(s|split("\n")|map(select(.!=""))|length); n(.flatpak)' "$CACHE_FILE")"
  [[ "$pacnew_n" -gt 0 || "$orphans_n" -gt 0 ]] && \
    printf ' · pacnew %s · 孤立包 %s' "$pacnew_n" "$orphans_n"
  printf '\n\n%s请选择操作%s\n' "$BOLD$CYAN" "$RESET"

  # [1] 永远存在：有更新就全量更新，没有就重新检查（回车即选）
  MENU_ACTIONS+=(update)
  if [[ "$total" -gt 0 ]]; then
    printf '  %s[%d]%s 全量更新（%s -Syu，自动建快照）%s  ← 直接回车即选%s\n' \
      "$BOLD$GREEN" "$idx" "$RESET" "$AUR_HELPER" "$DIM" "$RESET"
  else
    printf '  %s[%d]%s 检查更新（当前已是最新）%s  ← 直接回车即选%s\n' \
      "$BOLD$GREEN" "$idx" "$RESET" "$DIM" "$RESET"
  fi
  idx=$((idx + 1))
  if [[ "$pacnew_n" -gt 0 ]]; then
    MENU_ACTIONS+=(pacnew)
    printf '  %s[%d]%s 处理 %s 个 pacnew/pacsave（sudo pacdiff）\n' "$BOLD" "$idx" "$RESET" "$pacnew_n"
    idx=$((idx + 1))
  fi
  if [[ "$orphans_n" -gt 0 ]]; then
    MENU_ACTIONS+=(orphans)
    printf '  %s[%d]%s 清理 %s 个孤立包（sudo pacman -Rns）\n' "$BOLD" "$idx" "$RESET" "$orphans_n"
    idx=$((idx + 1))
  fi

  MENU_ACTIONS+=(news)
  if [[ -n "$NEWS_CACHE" ]]; then
    printf '  %s[%d]%s Arch 新闻（%s）\n' "$BOLD" "$idx" "$RESET" "$(head -1 <<<"$NEWS_CACHE")"
  else
    printf '  %s[%d]%s 查看 Arch 新闻\n' "$BOLD" "$idx" "$RESET"
  fi
  idx=$((idx + 1))

  if [[ -s "$LOG_FILE" ]]; then
    MENU_ACTIONS+=(log)
    printf '  %s[%d]%s 查看更新日志\n' "$BOLD" "$idx" "$RESET"
    idx=$((idx + 1))
  fi

  MENU_ACTIONS+=(quit)
  printf '  %s[%d]%s 退出\n' "$BOLD" "$idx" "$RESET"
}

confirm_run() {
  local what="$1" note="${2:-}" ans=""
  printf '\n  %s确认执行：%s%s\n' "$BOLD$YELLOW" "$what" "$RESET"
  [[ -n "$note" ]] && printf '  %s%s%s\n' "$DIM" "$note" "$RESET"
  printf '  确定吗？[y/N]：'
  read -r ans || return 1
  [[ "$ans" =~ ^[Yy]$ ]]
}

run_pacdiff() {
  local n diffprog="${DIFFPROG:-}"
  n=$(pacdiff -o 2>/dev/null | grep -c . || true)
  if [[ "${n:-0}" -eq 0 ]]; then
    echo "  没有需要处理的 pacnew/pacsave。"
    return 0
  fi
  if [[ -z "$diffprog" ]]; then
    if command -v vimdiff >/dev/null 2>&1; then
      diffprog="vimdiff"
    elif command -v nvim >/dev/null 2>&1; then
      diffprog="nvim -d"
    elif command -v meld >/dev/null 2>&1; then
      diffprog="meld"
    fi
  fi
  echo "  启动 pacdiff（差异工具：${diffprog:-默认}）..."
  if [[ -n "$diffprog" ]]; then
    sudo DIFFPROG="$diffprog" pacdiff || true
  else
    sudo pacdiff || true
  fi
}

run_orphan_cleanup() {
  local -a orphans
  mapfile -t orphans < <(pacman -Qtdq 2>/dev/null)
  if [[ "${#orphans[@]}" -eq 0 ]]; then
    echo "  没有孤立包。"
    return 0
  fi

  printf '  共 %s 个孤立包：\n' "${#orphans[@]}"
  printf '    %s\n' "${orphans[@]}"
  echo
  echo "  提示：如果其中有你还需要的（比如某软件的可选依赖），先标记它们："
  echo "        sudo pacman -D --asexplicit <包名>"
  echo "  pacman 接下来还会显示一次确认，请注意核对要删除的列表。"
  sudo pacman -Rns "${orphans[@]}"
}

show_news() {
  if [[ -z "$NEWS_CACHE" ]]; then
    echo "  正在获取 Arch 新闻 ..."
    NEWS_CACHE=$(fetch_news_items)
  fi
  if [[ -z "$NEWS_CACHE" ]]; then
    echo "  获取失败（网络问题？）可手动访问：https://archlinux.org/news/"
    return 0
  fi
  printf '\n  %s最近 Arch 新闻%s\n' "$BOLD$BLUE" "$RESET"
  while IFS= read -r line; do
    [[ -n "$line" ]] && printf '  · %s\n' "$line"
  done <<<"$NEWS_CACHE"
  printf '\n  完整列表：https://archlinux.org/news/\n'
  printf '  按回车继续 ...'
  read -r _ || true
}

open_flow() {
  ensure_cache
  NEWS_CACHE=$(fetch_news_items)
  list_updates

  # 非交互环境（管道等）只打印列表
  if [[ ! -t 0 || ! -t 1 ]]; then
    return 0
  fi

  while true; do
    render_menu

    local hint="[1]（直接回车 = 检查/全量更新）" answer="" action=""
    printf '\n  %s%s：' "$BOLD" "$hint"
    if ! read -r answer; then
      break
    fi

    # 回车：选 [1]（检查/全量更新）
    if [[ -z "$answer" ]]; then
      answer=1
    fi

    if ! [[ "$answer" =~ ^[0-9]+$ ]] || ((answer < 1 || answer > ${#MENU_ACTIONS[@]})); then
      printf '  无效编号：%s\n\n' "$answer"
      continue
    fi
    action="${MENU_ACTIONS[$((answer - 1))]}"

    case "$action" in
      update)
        do_update || true
        ;;
      pacnew)
        if confirm_run "处理 pacnew/pacsave（sudo pacdiff）" "pacdiff 会逐个打开差异文件，由你决定保留哪个版本"; then
          run_pacdiff
        else
          echo "  已取消。"
        fi
        ;;
      orphans)
        if confirm_run "清理孤立包（sudo pacman -Rns）" "这份列表会先展示，pacman 还会再确认一次"; then
          run_orphan_cleanup
        else
          echo "  已取消。"
        fi
        ;;
      news)
        show_news
        ;;
      log)
        if [[ -s "$LOG_FILE" ]]; then
          less +G "$LOG_FILE"
        else
          echo "  还没有更新记录。"
        fi
        ;;
      quit)
        break
        ;;
    esac
    printf '\n'
  done

  exec "${SHELL:-bash}"
}

# ── waybar JSON ─────────────────────────────────────────────────────
json_output() {
  local text tooltip class
  text="${1:-$ICON_UPDATES …}"
  tooltip="${2:-正在检查更新…}"
  class="${3:-checking}"

  jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

render_waybar() {
  if [[ ! -s "$CACHE_FILE" ]]; then
    json_output && return
  fi

  local repo aur flatpak repo_n aur_n flat_n total
  local tooltip text class critical=false pkg

  repo=$(jq -r '.repo' "$CACHE_FILE")
  aur=$(jq -r '.aur' "$CACHE_FILE")
  flatpak=$(jq -r '.flatpak' "$CACHE_FILE")
  repo_n=$(count_lines "$repo")
  aur_n=$(count_lines "$aur")
  flat_n=$(count_lines "$flatpak")
  total=$((repo_n + aur_n + flat_n))

  while read -r pkg _; do
    [[ -z "$pkg" ]] && continue
    if [[ " $CRITICAL_PKGS " == *" $pkg "* ]]; then
      critical=true
      break
    fi
  done <<<"$repo"

  if [[ "$total" -gt 0 ]]; then
    text="$ICON_UPDATES $total"
    class="has-updates"
    if $critical; then
      class="critical"
    fi
  else
    text="$ICON_OK"
    class="updated"
  fi

  # 提示框：分来源列出包名与版本变化（最多 15 条）
  local lines=""
  if [[ "$repo_n" -gt 0 ]]; then
    lines+=$'官方仓库：\n'"$(head -n 15 <<<"$repo" | sed 's/^/  /')"$'\n'
  fi
  if [[ "$aur_n" -gt 0 ]]; then
    lines+=$'AUR：\n'"$(head -n 15 <<<"$aur" | sed 's/^/  /')"$'\n'
  fi
  if [[ "$flat_n" -gt 0 ]]; then
    lines+=$'Flatpak：\n'"$(head -n 15 <<<"$flatpak" | sed 's/^/  /')"$'\n'
  fi
  [[ -z "$lines" ]] && lines="没有可用更新"$'\n'

  tooltip="$(printf '待更新 %s 个（仓库 %s · AUR %s · Flatpak %s）\n%s\n上次完整升级：%s\n左键：交互式菜单（回车即全量更新）\n中键：查看更新日志 · 右键：立即重新检查' \
    "$total" "$repo_n" "$aur_n" "$flat_n" "$lines" "$(jq -r '.last_upgrade // "未知"' "$CACHE_FILE")")"

  json_output "$text" "$tooltip" "$class"
}

# ── 终端列表（--list） ──────────────────────────────────────────────
list_updates() {
  local repo aur flatpak repo_n aur_n flat_n total critical_list=""
  local pkg line

  repo=$(jq -r '.repo' "$CACHE_FILE" 2>/dev/null || echo "")
  aur=$(jq -r '.aur' "$CACHE_FILE" 2>/dev/null || echo "")
  flatpak=$(jq -r '.flatpak' "$CACHE_FILE" 2>/dev/null || echo "")
  repo_n=$(count_lines "$repo"); aur_n=$(count_lines "$aur"); flat_n=$(count_lines "$flatpak")
  total=$((repo_n + aur_n + flat_n))

  printf '%s系统更新检查%s · %s\n' "$BOLD$CYAN" "$RESET" "$(date '+%Y-%m-%d %H:%M')"
  printf '%s上次完整升级：%s%s\n\n' "$DIM" "$(jq -r '.last_upgrade // "未知"' "$CACHE_FILE" 2>/dev/null || echo 未知)" "$RESET"

  if [[ "$total" -eq 0 ]]; then
    printf '  %s%s 系统已是最新%s\n\n' "$GREEN" "$ICON_OK" "$RESET"
  else
    printf '%s待更新：%s 个%s（仓库 %s · AUR %s · Flatpak %s）\n\n' \
      "$BOLD" "$total" "$RESET" "$repo_n" "$aur_n" "$flat_n"
  fi

  print_section() {
    local title="$1" data="$2" count="$3"
    [[ "$count" -eq 0 ]] && return
    printf '%s%s（%s）%s\n' "$BOLD$BLUE" "$title" "$count" "$RESET"
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if [[ "$line" == *" -> "* ]]; then
        printf '  %-28s %s → %s\n' \
          "${line%% *}" "$(awk '{print $2}' <<<"$line")" "$(awk '{print $4}' <<<"$line")"
      else
        printf '  %s\n' "$line"
      fi
    done <<<"$data"
    printf '\n'
  }

  print_section "官方仓库" "$repo" "$repo_n"
  print_section "AUR" "$aur" "$aur_n"
  print_section "Flatpak" "$flatpak" "$flat_n"

  # 安全提示
  local notes=()
  while read -r pkg _; do
    [[ -z "$pkg" ]] && continue
    [[ " $CRITICAL_PKGS " == *" $pkg "* ]] && critical_list+="$pkg "
  done <<<"$repo"
  [[ -n "$critical_list" ]] && notes+=("包含关键组件更新，建议更新后重启：$critical_list")

  local pacnew_n
  pacnew_n=$(pacdiff -o 2>/dev/null | grep -c . || true)
  [[ "${pacnew_n:-0}" -gt 0 ]] && notes+=("有 $pacnew_n 个 pacnew/pacsave 待处理（运行 sudo pacdiff）")

  local orphans_n
  orphans_n=$(pacman -Qtdq 2>/dev/null | grep -c . || true)
  [[ "${orphans_n:-0}" -gt 0 ]] && notes+=("有 $orphans_n 个孤立包（sudo pacman -Rns \$(pacman -Qtdq)）")

  if [[ -e /var/lib/pacman/db.lck ]]; then
    notes+=("pacman 正在运行，数据库被锁定，稍后再试")
  fi

  # Arch 官方新闻（更新前必看；NEWS_CACHE 由交互菜单预取）
  if [[ -z "$NEWS_CACHE" ]]; then
    NEWS_CACHE=$(fetch_news_items)
  fi
  [[ -n "$NEWS_CACHE" ]] && notes+=("Arch 新闻（$(head -1 <<<"$NEWS_CACHE")）")

  if [[ "${#notes[@]}" -gt 0 ]]; then
    printf '%s安全提示%s\n' "$BOLD$YELLOW" "$RESET"
    for line in "${notes[@]}"; do
      printf '  %s·%s %s\n' "$YELLOW" "$RESET" "$line"
    done
    printf '\n'
  fi

  # 更新命令
  printf '%s更新命令%s\n' "$BOLD$GREEN" "$RESET"
  printf '  sudo pacman -Syu          # 官方仓库（不要用 -Sy 部分升级）\n'
  printf '  paru -Syu                 # 官方仓库 + AUR\n'
  command -v flatpak >/dev/null 2>&1 && [[ "$flat_n" -gt 0 ]] && \
    printf '  flatpak update            # Flatpak\n'
  printf '\n'
}

# ── 入口 ────────────────────────────────────────────────────────────
case "${1:-}" in
  --help | -h)
    usage
    ;;
  --force)
    ensure_cache --force
    notify_check_result
    pkill -RTMIN+8 waybar 2>/dev/null || true
    render_waybar
    ;;
  --list)
    ensure_cache
    list_updates
    ;;
  --open)
    open_flow
    ;;
  --log)
    mkdir -p "$STATE_DIR"
    if [[ ! -s "$LOG_FILE" ]]; then
      echo "（还没有更新记录；在更新组上左键 → 回车执行一次全量更新后会写入这里）" >"$LOG_FILE"
    fi
    exec less +G "$LOG_FILE"
    ;;
  --update)
    ensure_cache
    do_update
    ;;
  *)
    ensure_cache
    render_waybar
    ;;
esac
