#!/bin/bash
# install.sh

ln -sf ~/dotfiles/config/nvim ~/.config/nvim
ln -sf ~/dotfiles/config/waybar ~/.config/waybar
ln -sf ~/dotfiles/config/niri ~/.config/niri
ln -sf ~/dotfiles/config/sunsetr ~/.config/sunsetr
ln -sf ~/dotfiles/config/ghostty ~/.config/ghostty
ln -sf ~/dotfiles/config/zellij ~/.config/zellij
ln -sf ~/dotfiles/config/fuzzel ~/.config/fuzzel
ln -sf ~/dotfiles/config/mako ~/.config/mako
ln -sf ~/dotfiles/config/matugen ~/.config/matugen

ln -sf ~/dotfiles/home/.zshrc ~/.zshrc
ln -sf ~/dotfiles/home/.gitconfig ~/.gitconfig

rm -rf config/niri/niri config/nvim/nvim config/waybar/waybar config/sunsetr/sunsetr config/ghostty/ghostty config/zellig/zellij config/fuzzel/fuzzel
