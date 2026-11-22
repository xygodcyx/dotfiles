#!/bin/bash
# install.sh

set -euo pipefail

DOTFILES="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# 支持 sudo ./install.sh：此时 ~/$HOME 会变成 /root，
# 所以显式回到调用 sudo 的用户来创建用户级软链接。
if [[ "$(id -u)" -eq 0 ]]; then
  if [[ -z "${SUDO_USER:-}" ]]; then
    echo "错误：请不要直接以 root 运行，请用普通用户执行 ./install.sh。" >&2
    exit 1
  fi
  RUN_USER="$SUDO_USER"
else
  RUN_USER="$(id -un)"
fi

RUN_HOME="$(getent passwd "$RUN_USER" | cut -d: -f6)"
if [[ -z "$RUN_HOME" ]]; then
  echo "错误：无法确定用户 $RUN_USER 的家目录。" >&2
  exit 1
fi

as_user() {
  if [[ "$(id -un)" == "$RUN_USER" ]]; then
    "$@"
  else
    sudo -u "$RUN_USER" "$@"
  fi
}

as_user mkdir -p "$RUN_HOME/.config"

# -n 防止目标已是软链接时，把新链接创建到链接指向的目录里
for name in nvim waybar niri sunsetr ghostty zellij fuzzel mako matugen swaylock yay kitty xremap; do
  as_user ln -sfn "$DOTFILES/config/$name" "$RUN_HOME/.config/$name"
done

as_user ln -sfn "$DOTFILES/home/.zshrc" "$RUN_HOME/.zshrc"
as_user ln -sfn "$DOTFILES/home/.gitconfig" "$RUN_HOME/.gitconfig"

sudo cp -r "$DOTFILES/etc/." /etc/
# 镜像源由 etc/cron.daily/update-mirrors 每日更新，停用 reflector 包自带的每周定时器
sudo systemctl enable --now cronie.service
sudo systemctl disable --now reflector.timer 2>/dev/null || true
sudo systemctl daemon-reload

# 清理旧版 ln -sf 产生的嵌套链接
rm -rf "$DOTFILES"/config/{niri/niri,nvim/nvim,waybar/waybar,sunsetr/sunsetr,ghostty/ghostty,zellig/zellij,fuzzel/fuzzel,swaylock/swaylock,yay/yay,kitty/kitty,xremap/xremap}
