#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  构建 niri-taskbar（waybar 的“打开的应用”任务栏模块）
#
#    · 上游 main + PR #34：支持 niri 26.4 的事件流
#      （发行版包里的版本是按 niri 25.11 编译的，事件流会断开）
#    · 本地补丁 niri-taskbar.patch：
#        1. 支持用 ~/.config/waybar/icons/<app_id>.{png,svg} 覆盖应用图标
#        2. 支持 group_by_app_id（同一应用只显示一个图标，点击在窗口间轮换）
#        3. 支持 max_buttons（限制显示的图标数量，以聚焦窗口为中心动态切换）
#
#  用法：build-niri-taskbar.sh
#  产物：~/.local/lib/waybar/libniri_taskbar.so（构建完重启 waybar）
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # ~/.config/waybar
SRC="${XDG_DATA_HOME:-$HOME/.local/share}/src/niri-taskbar"
DEST="$HOME/.local/lib/waybar/libniri_taskbar.so"
PATCH="$ROOT/niri-taskbar.patch"

command -v cargo >/dev/null || {
  echo "错误：未找到 cargo，请先安装 rust" >&2
  exit 1
}

if [[ -d "$SRC/.git" ]]; then
  git -C "$SRC" fetch -q --all --prune
else
  git clone --quiet https://github.com/LawnGnome/niri-taskbar "$SRC"
fi

# 检查 PR #34 是否存在（合并后 GitHub 仍保留 pull ref）
if ! git -C "$SRC" fetch -qf origin pull/34/head:pr34 2>/dev/null; then
  echo "警告：无法获取 PR #34，改用 main（可能与 niri 26.4 不兼容）" >&2
fi

git -C "$SRC" checkout -qf pr34 2>/dev/null || git -C "$SRC" checkout -qf main
git -C "$SRC" apply "$PATCH"

echo "==> 编译 niri-taskbar ..."
cargo build --release --manifest-path "$SRC/Cargo.toml"

install -Dm755 "$SRC/target/release/libniri_taskbar.so" "$DEST"
echo "==> 已安装：$DEST"
echo "==> 重启 waybar：pkill waybar && waybar &"
