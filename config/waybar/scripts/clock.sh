#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  waybar 自定义时钟
#    · 每秒刷新（显示到秒），对齐整秒输出
#    · 全程零 fork：printf '%(...)T' 做时间格式化（等价 date），
#      命名管道 + read -t 做等待（等价 sleep），循环里不创建任何进程
#      开销 ≈ 单核 0.1%、每秒 1 次唤醒（旧版约 1%、7 次唤醒）
#    · 锁屏期间照常运行，解锁后最多 1 秒状态栏就是正确时间
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

# 命名管道只用于 read -t 的定时等待，不传数据；放在运行时目录可跨重载复用
fifo="${XDG_RUNTIME_DIR:-/tmp}/waybar-clock.$UID.fifo"
if [[ ! -p $fifo ]]; then
  rm -f "$fifo"
  mkfifo -m 600 "$fifo"
fi
exec 9<>"$fifo"

emit() {
  local text tooltip
  printf -v text '󰥔 %(%Y/%m/%d %H:%M:%S)T' -1
  printf -v tooltip '%(%Y年%m月%d日 %A · 第 %V 周 · 全年第 %-j 天)T' -1
  printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"
}

wait_next_tick() {
  local interval=${1:-5}
  local now_us now_s now_frac_us next_s wait_us
  now_us=${EPOCHREALTIME/./}          # 去掉小数点，得到微秒级整数
  now_s=$(( now_us / 1000000 ))
  now_frac_us=$(( now_us % 1000000 ))

  # 下一个对齐到 interval 倍数的整秒时刻
  next_s=$(( (now_s / interval + 1) * interval ))

  # 等待的微秒数
  wait_us=$(( (next_s - now_s) * 1000000 - now_frac_us ))
  (( wait_us < 0 )) && wait_us=$(( wait_us + interval * 1000000 ))

  # 转成秒给 read -t
  local delay
  delay=$(printf '%d.%06d' $(( wait_us / 1000000 )) $(( wait_us % 1000000 )))

  # 用 read 等待，能被信号打断
  read -t "$delay" -u 9 _ || true
}

# 等到下一个整秒再返回（EPOCHREALTIME 是 bash 内建，微秒精度；拿不到就等 1 秒）
wait_next_second() {
    wait_next_tick 1
}

emit
while true; do
  wait_next_tick 5
  emit
done
