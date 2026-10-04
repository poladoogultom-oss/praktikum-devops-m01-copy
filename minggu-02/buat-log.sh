#!/usr/bin/env bash
#
set -euo pipefail

OUT="${1:-app.log}"
LINES="${2:-500}"

IPS=(10.10.0.11 10.10.0.12 10.10.0.13 172.16.4.7 192.168.5.20)
PAGES=(/ /health /api/orders /api/users /static/app.js)
CODES=(200 200 200 200 201 301 404 404 500 502)

: > "$OUT"

for _ in $(seq 1 "$LINES"); do
  ts=$(date -d "-$((RANDOM % 1440)) minutes" '+%d/%b/%Y:%H:%M:%S +0700')
  ip=${IPS[$((RANDOM % ${#IPS[@]}))]}
  page=${PAGES[$((RANDOM % ${#PAGES[@]}))]}
  code=${CODES[$((RANDOM % ${#CODES[@]}))]}
  ms=$((RANDOM % 1200 + 5))
  printf '%s - - [%s] "GET %s HTTP/1.1" %s %s\n' "$ip" "$ts" "$page" "$code" "$ms" >> "$OUT"
done

printf 'Dibuat: %s (%d baris)\n' "$OUT" "$(wc -l < "$OUT")"
