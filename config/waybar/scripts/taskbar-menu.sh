#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  任务栏应用图标的右键菜单（由 niri-taskbar 插件调用）
#  参数：该图标对应的窗口 id 列表（可能多个）
#
#  菜单项：
#    · 切换到某个窗口（● 标记当前聚焦的窗口）
#    · 关闭某个窗口
#    · 关闭该应用的全部窗口
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

[[ $# -gt 0 ]] || exit 0

ids_json=$(printf '%s\n' "$@" | jq -Rsc 'split("\n") | map(select(. != "")) | map(tonumber)')
wins=$(niri msg --json windows 2>/dev/null) || exit 0

# 生成 "显示文本<TAB>动作" 列表：
# --with-nth=1 只显示第一列，--accept-nth=2 返回第二列（动作）
mapfile -t entries < <(jq -r --argjson ids "$ids_json" '
  def win_name: (.title // "") as $t
    | (if $t == "" then (.app_id // "窗口") else $t end)
    | gsub("[\t\n]"; " ");

  . as $all
  | [$ids[] as $id | $all[] | select(.id == $id)] as $mine
  | (
      ($mine[] | "\(if .is_focused then "● " else "  " end)\(win_name)\tfocus:\(.id)"),
      ($mine[] | "关闭窗口：\(win_name)\tclose:\(.id)"),
      (if ($mine | length) > 1
       then "关闭全部（\($mine | length) 个窗口）\tcloseall"
       else empty end)
    )
' <<<"$wins")

[[ "${#entries[@]}" -gt 0 ]] || exit 0

choice=$(fuzzel --dmenu --prompt " 窗口操作 " \
  --with-nth=1 --accept-nth=2 \
  --lines "${#entries[@]}" --width 50 \
  --anchor top-right --x-margin 8 --y-margin 8 \
  <<<"$(printf '%s\n' "${entries[@]}")") || exit 0

case "$choice" in
  focus:*)
    niri msg action focus-window --id "${choice#focus:}"
    ;;
  close:*)
    niri msg action close-window --id "${choice#close:}"
    ;;
  closeall)
    while read -r id; do
      [[ -n "$id" ]] || continue
      niri msg action close-window --id "$id" || true
    done < <(jq -r '.[]' <<<"$ids_json")
    ;;
esac
