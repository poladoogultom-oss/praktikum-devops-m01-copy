#!/usr/bin/env bash
#
# setup.sh - Otomasi penyiapan & verifikasi aplikasi (The First Way: Flow)
# JS-DVO-01 JOB 4, direfaktor menjadi modular (JS-DVO-02 JOB 5)
#
# Pemakaian:
#   ./setup.sh            ; siapkan venv, pasang dependensi, jalankan, smoke test
#   ./setup.sh --check    ; hanya validasi prasyarat lalu keluar (exit 0/1)
#   ./setup.sh --stop     ; hentikan aplikasi yang sedang berjalan
#   PORT=5055 ./setup.sh  ; paksa port tertentu
#
# Kontrak perilaku:
#   - idempotent  : aman dijalankan berulang kali
#   - fail-fast   : set -euo pipefail, berhenti di langkah pertama yang gagal
#   - zero-touch  : tidak ada satu pun langkah yang perlu diketik manual
#   - logging     : seluruh aktivitas tercatat ke $LOG_FILE (default /tmp/sentra-deploy.log)
#
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh disable=SC1091
source "$APP_DIR/lib/common.sh"

VENV_DIR="$APP_DIR/.venv"
PID_FILE="$APP_DIR/.app.pid"
PORT_FILE="$APP_DIR/.port"
PORT="${PORT:-5000}"
MAX_PORT_SCAN="${MAX_PORT_SCAN:-20}"
HEALTH_RETRIES="${HEALTH_RETRIES:-5}"
HEALTH_INTERVAL="${HEALTH_INTERVAL:-2}"

check_prereqs() {
  log_info "[1/5] Memeriksa prasyarat..."
  require_cmd python3
  python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' \
    || die "Python 3.10+ diperlukan."
  log_info "Python: $(python3 --version 2>&1)"
  require_cmd curl
  log_info "curl: $(curl --version 2>&1 | head -n 1)"
  [ -r "$APP_DIR/requirements.txt" ] || die "requirements.txt tidak ditemukan."
  log_info "requirements.txt: ditemukan"
}

prepare_venv() {
  log_info "[3/5] Menyiapkan virtual environment..."
  if [ -d "$VENV_DIR" ]; then
    log_info "venv sudah ada, digunakan kembali (idempotent)."
  else
    python3 -m venv "$VENV_DIR"
    log_info "venv dibuat di $VENV_DIR"
  fi
  if [ -f "$VENV_DIR/bin/activate" ]; then
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
  elif [ -f "$VENV_DIR/Scripts/activate" ]; then
    # shellcheck source=/dev/null
    source "$VENV_DIR/Scripts/activate"
  else
    die "berkas aktivasi venv tidak ditemukan di $VENV_DIR"
  fi
}

install_deps() {
  log_info "[4/5] Memasang dependensi terkunci..."
  if [ -x "$VENV_DIR/bin/python3" ]; then
    PY="$VENV_DIR/bin/python3"
  elif [ -x "$VENV_DIR/Scripts/python.exe" ]; then
    PY="$VENV_DIR/Scripts/python.exe"
  else
    PY="python3"
  fi
  log_info "interpreter: $PY"
  "$PY" -m pip install --quiet --upgrade pip
  "$PY" -m pip install --quiet -r requirements.txt
}

run_app() {
  log_info "[5/5] Menjalankan aplikasi pada port $PORT..."
  : > "$APP_DIR/app.log"
  PORT="$PORT" BUILD_ID="${BUILD_ID:-local-$(date +%Y%m%d%H%M%S)}" \
    "$PY" src/app.py >> "$APP_DIR/app.log" 2>&1 &
  APP_PID=$!
  echo "$APP_PID" > "$PID_FILE"
  echo "$PORT" > "$PORT_FILE"
  trap 'kill "$APP_PID" 2>/dev/null || true; rm -f "$PID_FILE"' EXIT

  log_info "Smoke test /health (maks $HEALTH_RETRIES percobaan, jeda ${HEALTH_INTERVAL}s)..."
  attempt=1
  while [ "$attempt" -le "$HEALTH_RETRIES" ]; do
    if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
      log_info "SUKSES: aplikasi sehat pada percobaan ke-$attempt."
      log_info "  URL      : http://127.0.0.1:$PORT/"
      log_info "  Health   : http://127.0.0.1:$PORT/health"
      log_info "  Log      : $APP_DIR/app.log"
      log_info "  PID      : $APP_PID"
      log_info "Tekan Ctrl+C untuk menghentikan. Atau jalankan: ./setup.sh --stop"
      wait "$APP_PID"
      exit 0
    fi
    log_info "  percobaan $attempt/$HEALTH_RETRIES belum merespons, menunggu..."
    sleep "$HEALTH_INTERVAL"
    attempt=$((attempt + 1))
  done
  log_error "--- 20 baris terakhir $APP_DIR/app.log ---"
  tail -n 20 "$APP_DIR/app.log" >&2 || true
  die "aplikasi tidak lulus health check setelah $HEALTH_RETRIES percobaan."
}

do_check() {
  log_info "Mode --check: hanya memvalidasi prasyarat, aplikasi TIDAK dijalankan."
  check_prereqs
  if port_is_free "$PORT"; then
    log_info "Port $PORT tersedia."
  else
    NEXT="$(find_free_port "$PORT")" \
      || die "tidak ada port bebas dalam rentang $PORT-$((PORT + MAX_PORT_SCAN - 1))."
    log_warn "Port $PORT sudah terpakai; port bebas terdekat: $NEXT"
  fi
  log_info "SUKSES: lingkungan siap."
  exit 0
}

do_stop() {
  stop_app "$PID_FILE"
  exit 0
}

# ---------------------------------------------------------------- mode switch
case "${1:-}" in
  --check) do_check ;;
  --stop)  do_stop ;;
esac

# ---------------------------------------------------------------- alur utama
check_prereqs

log_info "[2/5] Menentukan port..."
if port_is_free "$PORT"; then
  log_info "Port $PORT tersedia."
else
  NEXT_PORT="$(find_free_port "$PORT")" \
    || die "tidak ada port bebas dalam rentang $PORT-$((PORT + MAX_PORT_SCAN - 1))."
  log_info "Port $PORT sudah terpakai -> otomatis pindah ke port $NEXT_PORT"
  PORT="$NEXT_PORT"
fi

prepare_venv
install_deps
run_app
