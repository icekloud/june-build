#!/usr/bin/env bash
# Memory watcher for the june-build workflow (PUB-69).
# Prints one line every INTERVAL seconds (default 30) until it gets TERM/INT:
#   mem HH:MM:SS avail_mb=N swap_used_mb=N load1=N.NN java_rss_mb=N
# Only numbers: no command lines, paths or environment values, so the lines may go to the public log.
# java_rss_mb is the RSS of the largest process named "java" (0 when none).
# MEMWATCH_PROC overrides /proc (tests use a fake tree).
set -u

INTERVAL="${1:-30}"
PROC="${MEMWATCH_PROC:-/proc}"

SLEEP_PID=
trap '[ -n "$SLEEP_PID" ] && kill "$SLEEP_PID" 2>/dev/null; exit 0' TERM INT

sample() {
  local avail swap_total swap_free load best rss name d
  avail=$(awk '/^MemAvailable:/ {print int($2 / 1024)}' "$PROC/meminfo" 2>/dev/null)
  swap_total=$(awk '/^SwapTotal:/ {print int($2 / 1024)}' "$PROC/meminfo" 2>/dev/null)
  swap_free=$(awk '/^SwapFree:/ {print int($2 / 1024)}' "$PROC/meminfo" 2>/dev/null)
  load=$(awk '{printf "%.2f", $1}' "$PROC/loadavg" 2>/dev/null)
  best=0
  for d in "$PROC"/[0-9]*; do
    name=$(cat "$d/comm" 2>/dev/null) || continue
    [ "$name" = "java" ] || continue
    rss=$(awk '/^VmRSS:/ {print int($2 / 1024)}' "$d/status" 2>/dev/null)
    [ -n "$rss" ] && [ "$rss" -gt "$best" ] && best=$rss
  done
  printf 'mem %s avail_mb=%d swap_used_mb=%d load1=%s java_rss_mb=%d\n' \
    "$(date +%H:%M:%S)" "${avail:-0}" "$(( ${swap_total:-0} - ${swap_free:-0} ))" "${load:-0.00}" "$best"
}

while :; do
  sample
  # sleep in the background so TERM is handled at once instead of after the sleep
  sleep "$INTERVAL" &
  SLEEP_PID=$!
  wait "$SLEEP_PID"
done
