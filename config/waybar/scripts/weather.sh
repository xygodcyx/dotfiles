#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════
#  waybar 天气模块 · 数据源 Open-Meteo（免费、免 API key）
#
#  用法：
#    weather.sh          输出 waybar JSON（模块每 10 分钟调用一次）
#    weather.sh --full   在终端里打印未来 7 天预报
# ════════════════════════════════════════════════════════════════════
set -Eeuo pipefail

# ── 位置：想换城市改这三行即可 ──────────────────────────────────────
CITY="临沂·临沭"
LAT="34.9200"
LON="118.6500"
TZ_NAME="Asia/Shanghai"
# ────────────────────────────────────────────────────────────────────

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
CACHE_FILE="$CACHE_DIR/weather.json"
API="https://api.open-meteo.com/v1/forecast"

# ── WMO 天气代码 → 中文描述 + 图标（白天 / 夜间分开） ───────────────
# 输出格式：描述<TAB>白天图标<TAB>夜间图标
describe() {
  case "$1" in
    0)  printf '晴\t󰖙\t󰖔' ;;
    1)  printf '晴间多云\t󰖕\t󰼱' ;;
    2)  printf '多云\t󰖕\t󰼱' ;;
    3)  printf '阴\t󰖐\t󰖐' ;;
    45) printf '雾\t󰖑\t󰖑' ;;
    48) printf '雾凇\t󰖑\t󰖑' ;;
    51) printf '毛毛雨\t󰖗\t󰖗' ;;
    53) printf '小雨\t󰖗\t󰖗' ;;
    55) printf '强毛毛雨\t󰖖\t󰖖' ;;
    56) printf '冻毛毛雨\t󰙿\t󰙿' ;;
    57) printf '强冻毛毛雨\t󰙿\t󰙿' ;;
    61) printf '小雨\t󰖗\t󰖗' ;;
    63) printf '中雨\t󰖖\t󰖖' ;;
    65) printf '大雨\t󰖖\t󰖖' ;;
    66) printf '冻雨\t󰙿\t󰙿' ;;
    67) printf '强冻雨\t󰙿\t󰙿' ;;
    71) printf '小雪\t󰖘\t󰖘' ;;
    73) printf '中雪\t󰖘\t󰖘' ;;
    75) printf '大雪\t󰼶\t󰼶' ;;
    77) printf '雪粒\t󰖘\t󰖘' ;;
    80) printf '阵雨\t󰼳\t󰼳' ;;
    81) printf '中阵雨\t󰖖\t󰖖' ;;
    82) printf '强阵雨\t󰖖\t󰖖' ;;
    85) printf '小阵雪\t󰼴\t󰼴' ;;
    86) printf '强阵雪\t󰼶\t󰼶' ;;
    95) printf '雷阵雨\t󰖓\t󰖓' ;;
    96) printf '雷阵雨伴冰雹\t󰙾\t󰙾' ;;
    99) printf '强雷雨伴冰雹\t󰙾\t󰙾' ;;
    *)  printf '未知\t󰖐\t󰖐' ;;
  esac
}

fetch() {
  curl -fsS --max-time 15 \
    "$API?latitude=$LAT&longitude=$LON"\
"&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m"\
"&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset"\
"&timezone=$TZ_NAME&forecast_days=7"
}

# ── waybar 输出 ─────────────────────────────────────────────────────
render() {
  local raw="$1"
  local code is_day temp feels hum wind precip pop
  local tmax tmin sunrise sunset updated desc icon_day icon_night icon cls text tooltip

  IFS=$'\t' read -r code is_day temp feels hum wind precip pop tmax tmin sunrise sunset updated < <(
    jq -r '[.current.weather_code, .current.is_day, .current.temperature_2m,
            .current.apparent_temperature, .current.relative_humidity_2m,
            .current.wind_speed_10m, .current.precipitation,
            .daily.precipitation_probability_max[0],
            .daily.temperature_2m_max[0], .daily.temperature_2m_min[0],
            .daily.sunrise[0], .daily.sunset[0], .current.time] | @tsv' <<<"$raw"
  )

  IFS=$'\t' read -r desc icon_day icon_night <<<"$(describe "$code")"
  if [[ "$is_day" == "1" ]]; then icon="$icon_day"; else icon="$icon_night"; fi

  case "$code" in
    0|1)                 cls="clear" ;;
    2|3)                 cls="cloudy" ;;
    45|48)               cls="fog" ;;
    65|82)               cls="heavy-rain" ;;
    51|53|55|56|57|61|63|66|67|80|81) cls="rain" ;;
    71|73|75|77|85|86)   cls="snow" ;;
    95|96|99)            cls="storm" ;;
    *)                   cls="unknown" ;;
  esac

  text="$icon $desc $(printf '%.0f' "$temp")°C"
  tooltip=$(printf '%s · %s\n气温 %s°C（体感 %s°C）\n湿度 %s%% · 风速 %s km/h · 降水 %s mm\n今日 %s° ~ %s° · 降水概率 %s%%\n日出 %s · 日落 %s\n更新 %s' \
    "$CITY" "$desc" "$temp" "$feels" "$hum" "$wind" "$precip" "$tmin" "$tmax" "$pop" \
    "${sunrise#*T}" "${sunset#*T}" "${updated/T/ }")

  jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$cls" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

# ── 终端 7 天预报（左键点击天气模块时打开） ─────────────────────────
full() {
  local raw
  if ! raw="$(fetch)"; then
    echo "无法获取天气数据，请检查网络连接。" >&2
    exit 1
  fi

  echo "$CITY"
  echo "────────────────────────────────────────────────────────────"
  local code is_day temp feels desc icon_day icon_night icon
  IFS=$'\t' read -r code is_day temp feels < <(
    jq -r '[.current.weather_code, .current.is_day, .current.temperature_2m,
            .current.apparent_temperature] | @tsv' <<<"$raw"
  )
  IFS=$'\t' read -r desc icon_day icon_night <<<"$(describe "$code")"
  if [[ "$is_day" == "1" ]]; then icon="$icon_day"; else icon="$icon_night"; fi
  printf '现在  %s  %s  %s°C（体感 %s°C）\n\n' "$icon" "$desc" "$temp" "$feels"

  local -a days codes tmaxs tmins pops
  mapfile -t days  < <(jq -r '.daily.time[]' <<<"$raw")
  mapfile -t codes < <(jq -r '.daily.weather_code[]' <<<"$raw")
  mapfile -t tmaxs < <(jq -r '.daily.temperature_2m_max[]' <<<"$raw")
  mapfile -t tmins < <(jq -r '.daily.temperature_2m_min[]' <<<"$raw")
  mapfile -t pops  < <(jq -r '.daily.precipitation_probability_max[]' <<<"$raw")

  local i
  for i in "${!days[@]}"; do
    IFS=$'\t' read -r desc icon_day _ <<<"$(describe "${codes[$i]}")"
    printf '%s  %s  %-8s %4.0f° ~ %4.0f°   降水 %s%%\n' \
      "${days[$i]}" "$icon_day" "$desc" "${tmins[$i]}" "${tmaxs[$i]}" "${pops[$i]}"
  done

  printf '\n按回车键退出...'
  read -r _ || true
}

# ── 入口 ────────────────────────────────────────────────────────────
main() {
  case "${1:-}" in
    --full|-f) full; return ;;
    --help|-h) sed -n '2,9p' "$0"; return ;;
  esac

  mkdir -p "$CACHE_DIR"

  local raw
  if ! raw="$(fetch 2>/dev/null)"; then
    # 网络失败时退回上次缓存
    if [[ -s "$CACHE_FILE" ]]; then
      cat "$CACHE_FILE"
    else
      jq -cn --arg t "󰖐 --" --arg tt "天气获取失败，请检查网络" \
        '{text: $t, tooltip: $tt, class: "unknown"}'
    fi
    return
  fi

  render "$raw" | tee "$CACHE_FILE"

}

main "$@"
