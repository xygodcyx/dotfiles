#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  蓝牙开关（waybar 蓝牙模块右键调用）
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -a waybar -i bluetooth "$@" || true
}

if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
  rfkill unblock bluetooth
  notify "蓝牙" "已开启蓝牙"
else
  rfkill block bluetooth
  notify "蓝牙" "已关闭蓝牙"
fi
