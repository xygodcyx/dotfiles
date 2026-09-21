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
#        4. 支持 empty_icon（没有任何窗口时显示的占位图标）
#        5. 支持 right_click_command（右键窗口按钮打开菜单脚本）
#        6. 内置系统托盘：StatusNotifierItem 宿主 + DBusMenu 右键菜单
#           （托盘图标和任务栏在同一个模块里，不再需要 waybar 的 tray 模块）
#           相关配置：tray_icon_size、show_passive_items
#           依赖：libdbusmenu-gtk3（waybar 本来就依赖它）
#        7. hide_apps_with_tray：有托盘图标的应用（按 PID / 名字匹配）隐藏其窗口按钮
#           tray_window_aliases 可以手动补充名字别名，例如 [["wechat","微信"]]
#        8. tray_left_click_focus：左键托盘图标直接聚焦对应窗口（应用 Activate 失效时的兜底）
#        9. 托盘项生命周期用 D-Bus NameOwnerChanged 事件监听（按名字订阅 arg0）
#       10. 中键托盘图标：插件自己的兜底菜单（聚焦窗口 / 结束进程并移除图标）
#       11. tray_enabled 开关：false = 纯 niri-taskbar（不创建托盘，不占用 SNI watcher）
#           结束进程会清理整棵进程树 + 同一可执行文件的历史残留（解释器类除外）
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

# 清掉上一次补丁留下的未跟踪文件（比如新增的 src/tray.rs），
# 否则 git apply 会因为"文件已存在"失败；target/ 在 .gitignore 里不会被删
git -C "$SRC" clean -fdq

# 先试应用补丁，失败时给出清晰提示（不会影响已安装的 .so）
if ! git -C "$SRC" apply --check "$PATCH" 2>/dev/null; then
  echo "错误：本地补丁无法应用到当前上游代码（上游可能改了相同文件）。" >&2
  echo "      补丁文件：$PATCH" >&2
  echo "      已安装的 .so 保持不变：$DEST" >&2
  exit 1
fi
git -C "$SRC" apply "$PATCH"

echo "==> 编译 niri-taskbar ..."
cargo build --release --manifest-path "$SRC/Cargo.toml"

install -Dm755 "$SRC/target/release/libniri_taskbar.so" "$DEST"
echo "==> 已安装：$DEST"
echo "==> 重启 waybar：pkill waybar && waybar &"
