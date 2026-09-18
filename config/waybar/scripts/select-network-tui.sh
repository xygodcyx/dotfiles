#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  网络管理 TUI（waybar 网络模块左键调用）
#  优先 impala（iwd 后端），否则回退 nmtui（NetworkManager）
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

TERMINAL="${TERMINAL:-kitty}"

if command -v impala >/dev/null 2>&1; then
  exec "$TERMINAL" --class network-tui -e impala
fi

exec "$TERMINAL" --class network-tui -e nmtui
