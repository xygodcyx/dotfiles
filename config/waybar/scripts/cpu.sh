#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  waybar 自定义 CPU 模块
#    · 所有核心当前频率的平均值（GHz，保留两位小数）
#    · 两次采样之间的使用率（/proc/stat 差值）
#    · 1/5/15 分钟负载
#    · 电源模式（platform_profile）：悬浮框显示，右键循环切换
#
#  用法：
#    cpu.sh                  输出 waybar JSON（模块每 2 秒调用）
#    cpu.sh --cycle-profile  切换平台电源模式：节能 → 平衡 → 性能 → 节能
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
STAT_FILE="$CACHE_DIR/cpu.stat"
PROFILE_FILE="${PLATFORM_PROFILE_FILE:-/sys/firmware/acpi/platform_profile}"
PROFILE_ORDER=(low-power balanced performance)
mkdir -p "$CACHE_DIR"

profile_label() {
  case "$1" in
    low-power)   echo "节能" ;;
    balanced)    echo "平衡" ;;
    performance) echo "性能" ;;
    *)           echo "${1:-未知}" ;;
  esac
}

current_profile() {
  [[ -r "$PROFILE_FILE" ]] && cat "$PROFILE_FILE" 2>/dev/null || true
}

# 右键：循环切换平台电源模式
cycle_profile() {
  if [[ ! -r "$PROFILE_FILE" ]]; then
    notify-send -a waybar "电源模式" "此设备不支持 platform_profile 切换" 2>/dev/null || true
    exit 1
  fi

  local current next="" i idx=0
  current=$(current_profile)
  for i in "${!PROFILE_ORDER[@]}"; do
    if [[ "${PROFILE_ORDER[$i]}" == "$current" ]]; then
      idx=$i
      next="${PROFILE_ORDER[$(((i + 1) % ${#PROFILE_ORDER[@]}))]}"
      break
    fi
  done
  [[ -z "$next" ]] && next="${PROFILE_ORDER[0]}"

  local ok=0
  if [[ -w "$PROFILE_FILE" ]]; then
    # 直接可写（例如配置了 udev/sudoers 免密）
    printf '%s' "$next" >"$PROFILE_FILE" && ok=1
  elif sudo -n true 2>/dev/null; then
    # sudo 免密（或凭据仍在有效期内）
    printf '%s' "$next" | sudo -n tee "$PROFILE_FILE" >/dev/null && ok=1
  elif command -v pkexec >/dev/null 2>&1; then
    # 图形化 polkit 授权（需要认证代理，例如 polkit-gnome）
    pkexec sh -c "printf '%s' '$next' > '$PROFILE_FILE'" && ok=1
  fi

  if [[ "$ok" -eq 1 ]]; then
    notify-send -a waybar "电源模式" "已切换到：$(profile_label "$next")" 2>/dev/null || true
  else
    notify-send -a waybar "电源模式" "切换失败（需要 root 权限）" 2>/dev/null || true
    exit 1
  fi

  # 让状态栏立刻刷新
  pkill -RTMIN+9 waybar 2>/dev/null || true
}

case "${1:-}" in
  --cycle-profile)
    cycle_profile
    exit 0
    ;;
  --help | -h)
    sed -n '2,13p' "$0"
    exit 0
    ;;
esac

# ── 平均频率（GHz，两位小数） ───────────────────────────────────────
sum=0
count=0
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
  [[ -r "$f" ]] || continue
  sum=$((sum + $(<"$f")))
  count=$((count + 1))
done
freq=$(awk -v s="$sum" -v n="$count" 'BEGIN { printf "%.2f", (n ? s / n / 1000000 : 0) }')

# ── 使用率（与上次采样的差值） ──────────────────────────────────────
read -r _ u n s i w q sq st _ < <(grep '^cpu ' /proc/stat)
total=$((u + n + s + i + w + q + sq + st))
idle=$((i + w))

usage=0
if [[ -r "$STAT_FILE" ]]; then
  read -r prev_total prev_idle <"$STAT_FILE" || true
  d_total=$((total - prev_total))
  d_idle=$((idle - prev_idle))
  if ((d_total > 0)); then
    usage=$(((100 * (d_total - d_idle)) / d_total))
  fi
fi
printf '%s %s\n' "$total" "$idle" >"$STAT_FILE"

# ── 负载 ────────────────────────────────────────────────────────────
read -r load1 load5 load15 _ </proc/loadavg

# ── 电源模式 ────────────────────────────────────────────────────────
profile=$(current_profile)
profile_line=""
if [[ -n "$profile" ]]; then
  profile_line=$(printf '\n模式  %s（右键切换）' "$(profile_label "$profile")")
fi

# ── waybar JSON ─────────────────────────────────────────────────────
tooltip=$(printf '频率 %s GHz\n使用率 %s%%\n负载 %s · %s · %s%s' \
  "$freq" "$usage" "$load1" "$load5" "$load15" "$profile_line")

class="normal"
((usage >= 80)) && class="high"

jq -cn --arg text "󰻠 ${freq}GHz" --arg tooltip "$tooltip" --arg class "$class" \
  '{text: $text, tooltip: $tooltip, class: $class}'
