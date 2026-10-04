#!/usr/bin/env bash
#
# teardown.sh - Menghentikan aplikasi dan membersihkan lingkungan dengan aman.
# JS-DVO-01 · Challenge "Zero-Touch Verification" butir 4
#
# Pemakaian:
#   ./teardown.sh           ; hentikan aplikasi saja
#   ./teardown.sh --purge   ; hentikan aplikasi + hapus .venv & artefak
#
# ATURAN KESELAMATAN (K3 praktikum):
#   - Tidak ada `rm -rf` dengan variabel yang tidak divalidasi.
#   - Path wajib lolos 3 pemeriksaan sebelum dihapus:
#       1) tidak kosong
#       2) absolut dan berada di dalam APP_DIR
#       3) memiliki basename yang persis diizinkan (.venv)
#
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$APP_DIR/.venv"
PID_FILE="$APP_DIR/.app.pid"
LOG_FILE="$APP_DIR/app.log"

log()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
fail() { printf '[%s] GAGAL: %s\n' "$(date '+%H:%M:%S')" "$*" >&2; exit 1; }

# Pemeriksaan path sebelum penghapusan apa pun.
safe_rm_dir() {
  local target="${1:-}"

  [ -n "$target" ] || fail "target penghapusan kosong."
  case "$target" in
    /*) : ;;
    *)  fail "target penghapusan harus path absolut: '$target'" ;;
  esac
  [ "$target" != "/" ] || fail "menolak menghapus '/'."
  case "$target" in
    "$APP_DIR"/*) : ;;
    *) fail "target di luar direktori proyek: '$target'" ;;
  esac
  case "$(basename "$target")" in
    .venv) : ;;
    *) fail "basename tidak diizinkan untuk dihapus: '$(basename "$target")'" ;;
  esac
  [ -d "$target" ] || { log "Tidak ada direktori $target, dilewati."; return 0; }

  log "Menghapus $target ..."
  rm -rf -- "$target"
  log "Selesai menghapus $target."
}

log "[1/2] Menghentikan aplikasi..."
if [ -f "$PID_FILE" ]; then
  pid="$(cat "$PID_FILE")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    sleep 1
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
    log "Aplikasi dihentikan (PID $pid)."
  else
    log "PID $pid sudah tidak aktif."
  fi
  rm -f "$PID_FILE"
else
  log "Tidak ada pid file, aplikasi kemungkinan sudah berhenti."
fi

if [ "${1:-}" = "--purge" ]; then
  log "[2/2] Mode --purge: membersihkan artefak..."
  safe_rm_dir "$VENV_DIR"
  rm -f -- "$LOG_FILE"
  log "SUKSES: lingkungan bersih. Jalankan ./setup.sh untuk memulai lagi dari nol."
else
  log "[2/2] Mode default: .venv dipertahankan (setup berikutnya lebih cepat)."
  log "SUKSES. Gunakan ./teardown.sh --purge untuk menghapus .venv juga."
fi
