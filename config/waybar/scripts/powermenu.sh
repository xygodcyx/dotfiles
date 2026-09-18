#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  waybar 电源按钮 / 电源菜单
#
#  用法：
#    powermenu.sh            弹出电源菜单（fuzzel）
#    powermenu.sh lock       锁屏
#    powermenu.sh suspend    挂起
#    powermenu.sh logout     注销会话
#    powermenu.sh reboot     重启
#    powermenu.sh shutdown   关机
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a waybar "$@" || true
}

# fuzzel 单选：$1=提示文案，$2=窗口宽度（字符数），其余为候选项
# 取消返回 1，出错返回 2（据此给用户反馈）
pick() {
  local prompt="$1" width="$2"; shift 2
  fuzzel --dmenu --prompt " $prompt " --lines "$#" --width "$width" \
    --anchor top-right --x-margin 8 --y-margin 8 <<<"$(printf '%s\n' "$@")"
}

confirm() {  # $1 = 确认提示文案
  # fuzzel 退出码：0=选中，2=取消（Esc / 失焦），其它=出错
  local ans rc=0
  ans="$(pick "$1" 24 "取消" "确定")" || rc=$?

  if [[ "$rc" -eq 0 && "$ans" == "确定" ]]; then
    return 0
  fi
  if [[ "$rc" -ne 0 && "$rc" -ne 2 ]]; then
    notify "电源菜单" "无法打开 fuzzel（退出码 $rc），请检查 fuzzel 配置"
  fi
  return 1
}

lock()     { setsid -f swaylock -f; }
# systemctl 的 reboot/poweroff/suspend 对活动本地会话由 polkit 直接放行，
# 不需要 sudo（从状态栏调用时没有终端，sudo 反而无法输入密码）
suspend()  { notify "挂起" "锁屏后进入睡眠"; setsid -f swaylock -f; sleep 1; systemctl suspend; }
logout()   { niri msg action quit; }
reboot()   { notify "重启" "系统即将重启"; systemctl reboot; }
shutdown() { notify "关机" "系统即将关闭"; systemctl poweroff; }

menu() {
  # fuzzel 退出码：0=选中，2=取消，其它=出错
  local ans rc=0
  ans="$(pick "电源" 12 "锁定" "挂起" "注销" "重启" "关机")" || rc=$?

  if [[ "$rc" -eq 2 ]]; then
    exit 0
  elif [[ "$rc" -ne 0 ]]; then
    notify "电源菜单" "无法打开 fuzzel（退出码 $rc），请检查 fuzzel 配置"
    exit 1
  fi

  case "$ans" in
    "锁定") lock ;;
    "挂起") suspend ;;
    "注销") confirm "确定要注销吗？" && logout ;;
    "重启") confirm "确定要重启吗？" && reboot ;;
    "关机") confirm "确定要关机吗？" && shutdown ;;
  esac
}

case "${1:-menu}" in
  menu)     menu ;;
  lock)     lock ;;
  suspend)  suspend ;;
  logout)   confirm "确定要注销吗？" && logout ;;
  reboot)   confirm "确定要重启吗？" && reboot ;;
  shutdown) confirm "确定要关机吗？" && shutdown ;;
  *) echo "用法: $0 {menu|lock|suspend|logout|reboot|shutdown}" >&2; exit 1 ;;
esac
