#!/usr/bin/env bash
set -euo pipefail

INTERVAL=5
URL="http://127.0.0.1:5000/health"
LOG_FILE="healthwatch.log"
VERSION="1.0.0"

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME VERSION

# Variabel state sesi
checks=0
incidents=0
total_downtime=0         
current_state=""          
incident_start=0          

usage() {
  cat <<USAGE
$SCRIPT_NAME v$VERSION - pemantau kesehatan endpoint
Penggunaan: $SCRIPT_NAME [OPSI]
  --interval N   Interval pemeriksaan (detik, default: 5)
  --url URL     URL endpoint yang dipantau (default: http://127.0.0.1:5000/health)
  --log BERKAS  Berkas log hasil (default: healthwatch.log)
  -h            Tampilkan bantuan ini
Exit code: 0 = tanpa insiden, 2 = terjadi minimal satu insiden
USAGE
}

now_epoch() { date +%s; }

log_line() {
  printf '%s %s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$1" "$2" >> "$LOG_FILE"
}

cleanup_and_report() {
  local avail
  if [ "$checks" -gt 0 ]; then
    avail=$(awk -v d="$total_downtime" -v c="$checks" -v i="$INTERVAL" \
      'BEGIN { printf "%.2f", (1 - d / (c * i)) * 100 }')
  else
    avail="100.00"
  fi
  {
    echo "=== Ringkasan Sesi healthwatch ==="
    echo "Jumlah pemeriksaan : $checks"
    echo "Jumlah insiden     : $incidents"
    echo "Total waktu padam  : ${total_downtime} detik"
    echo "Ketersediaan       : ${avail} %"
  } >&2
  if [ "$incidents" -gt 0 ]; then
    exit 2
  fi
  exit 0
}

trap 'cleanup_and_report' INT

poll() {
  local start end ms code status now
  start=$(date +%s.%N)
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time "$INTERVAL" "$URL" 2>/dev/null) || code="000"
  end=$(date +%s.%N)
  ms=$(awk -v s="$start" -v e="$end" 'BEGIN { printf "%d", (e - s) * 1000 }')

  if [[ "$code" =~ ^2[0-9][0-9]$ ]]; then
    status="UP"
  else
    status="DOWN"
  fi

  log_line "$status" "$ms"
  checks=$((checks + 1))
  now=$(now_epoch)

  if [ -z "$current_state" ]; then
    current_state="$status"
  fi

  # Deteksi transisi status
  if [ "$current_state" = "UP" ] && [ "$status" = "DOWN" ]; then
    incident_start="$now"
    current_state="DOWN"
    echo "[$(date '+%H:%M:%S')] TRANSISI: UP -> DOWN (insiden #$((incidents + 1)) mulai)" >&2
  elif [ "$current_state" = "DOWN" ] && [ "$status" = "UP" ]; then
    local mttr=$((now - incident_start))
    total_downtime=$((total_downtime + mttr))
    incidents=$((incidents + 1))
    current_state="UP"
    echo "[$(date '+%H:%M:%S')] TRANSISI: DOWN -> UP | MTTR insiden #$incidents = ${mttr} detik" >&2
  fi
}

main_loop() {
  echo "healthwatch dimulai: URL=$URL interval=${INTERVAL}s log=$LOG_FILE (Ctrl+C untuk berhenti)" >&2
  while true; do
    poll
    sleep "$INTERVAL"
  done
}

# ---------------------------------------------------------------- parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --interval)
      [ $# -ge 2 ] || { echo "GALAT: --interval membutuhkan nilai" >&2; exit 1; }
      INTERVAL="$2"; shift 2 ;;
    --url)
      [ $# -ge 2 ] || { echo "GALAT: --url membutuhkan nilai" >&2; exit 1; }
      URL="$2"; shift 2 ;;
    --log)
      [ $# -ge 2 ] || { echo "GALAT: --log membutuhkan nilai" >&2; exit 1; }
      LOG_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; echo "GALAT: argumen tidak dikenal: $1" >&2; exit 1 ;;
  esac
done

# ---------------------------------------------------------------- validasi
[[ "$INTERVAL" =~ ^[0-9]+$ ]] || { echo "GALAT: --interval harus bilangan bulat positif" >&2; exit 1; }
[ "$INTERVAL" -ge 1 ] || { echo "GALAT: --interval minimal 1 detik" >&2; exit 1; }
[[ "$URL" =~ ^https?:// ]] || { echo "GALAT: --url harus diawali http:// atau https://" >&2; exit 1; }

# Mulai pemantauan (loop ini hanya berhenti via trap SIGINT)
: > "$LOG_FILE"
main_loop
