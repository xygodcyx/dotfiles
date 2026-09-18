#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  waybar 自定义时钟
#    · 启动立即输出一次，之后对齐到每分钟的第 0 秒刷新
#    · 用系统 date 格式化，中文星期 / ISO 周数 / 年内第几天都正确
#      （waybar 内置 clock 的 %A 是英文，且 %V、%j 不会替换）
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

emit() {
  local text tooltip
  text="󰥔 $(date '+%Y/%m/%d %H:%M')"
  tooltip="$(date '+%Y年%m月%d日 %A · 第 %V 周 · 全年第 %-j 天')"
  jq -cn --arg text "$text" --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip}'
}

emit
while true; do
  sleep "$((60 - 10#$(date +%S)))"
  emit
done
