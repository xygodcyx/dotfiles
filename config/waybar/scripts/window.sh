#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  waybar 自定义窗口标题（中间模块）
#    · 有聚焦窗口：图标 + 窗口标题（无标题时退回 app_id）
#    · 没有聚焦窗口：显示 Lyorn
#    · 通过 niri 事件流实时刷新
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

ICON="󰖯"
NO_WINDOW_TEXT="Lyorn"

emit() {
  local win title app tooltip
  win=$(niri msg --json windows 2>/dev/null | jq -c '[.[] | select(.is_focused)][0] // empty')

  if [[ -n "$win" ]]; then
    title=$(jq -r '.title // ""' <<<"$win")
    app=$(jq -r '.app_id // ""' <<<"$win")
    [[ -z "$title" ]] && title="$app"
    [[ -z "$title" ]] && title="$NO_WINDOW_TEXT"

    if [[ -n "$app" && "$app" != "$title" ]]; then
      tooltip="$title"$'\n'"$app"
    else
      tooltip="$title"
    fi

    jq -cn --arg text "$ICON  $title" --arg tooltip "$tooltip" \
      '{text: $text, tooltip: $tooltip}'
  else
    jq -cn --arg text "$ICON  $NO_WINDOW_TEXT" '{text: $text}'
  fi
}

emit

# niri 事件流：每行一个 JSON 事件，只在窗口/工作区变化时刷新
niri msg --json event-stream 2>/dev/null | while read -r event; do
  case "$(jq -r 'keys[0]' <<<"$event" 2>/dev/null)" in
    WindowFocusChanged | WindowOpenedOrChanged | WindowClosed | WindowsChanged | \
      WorkspaceActivated | WorkspaceActiveWindowChanged | WorkspacesChanged)
      emit
      ;;
  esac
done
