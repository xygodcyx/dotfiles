#!/usr/bin/env bash

FILE="/tmp/brightness"

swayidle -w \
  timeout 300 'swaylock -f' \
  lock 'swaylock -f' \
  timeout 600 "brightnessctl -m | awk -F, '{print \$4}' > $FILE && niri msg action power-off-monitors" \
  resume "niri msg action power-on-monitors && brightnessctl set \"\$(cat $FILE)\"" \
  timeout 1200 'systemctl suspend'
