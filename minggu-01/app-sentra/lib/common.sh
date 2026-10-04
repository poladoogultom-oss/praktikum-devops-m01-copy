#!/usr/bin/env bash
# lib/common.sh - pustaka fungsi bersama untuk seluruh skrip proyek app-sentra
# Diambil (sourced) oleh setup.sh, teardown.sh, healthwatch.sh, dsb.
# Berkas ini TIDAK dimaksudkan untuk dijalankan langsung.

# Berkas log terpusat; dapat di-override lewat variabel lingkungan LOG_FILE.
LOG_FILE="${LOG_FILE:-/tmp/sentra-deploy.log}"

_ts() {
  date '+%Y-%m-%dT%H:%M:%S%z'
}

log_info() {
  printf '%s [INFO ] %s\n' "$(_ts)" "$*" | tee -a "$LOG_FILE" >&2
}

log_warn() {
  printf '%s [WARN ] %s\n' "$(_ts)" "$*" | tee -a "$LOG_FILE" >&2
}

log_error() {
  printf '%s [ERROR] %s\n' "$(_ts)" "$*" | tee -a "$LOG_FILE" >&2
}

die() {
  log_error "$*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "perkakas wajib tidak ditemukan: $1"
}

port_is_free() {
  # Mengandalkan 'ss' (utilitas Linux standar). Jika 'ss' tidak tersedia,
  # gunakan fallback /dev/tcp (bash builtin) tanpa dependensi eksternal.
  if command -v ss >/dev/null 2>&1; then
    ! ss -ltn "sport = :$1" 2>/dev/null | grep -q LISTEN
  else
    ( exec 3<>"/dev/tcp/127.0.0.1/$1" ) 2>/dev/null
  fi
}

find_free_port() {
  local start="${1:-5000}" p
  for ((p = start; p < start + 20; p++)); do
    if port_is_free "$p"; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 1
}

stop_app() {
  local pid_file="${1:-${APP_DIR:-.}/.app.pid}"
  if [ -f "$pid_file" ]; then
    local pid
    pid="$(cat "$pid_file")"
    if kill -0 "$pid" 2>/dev/null; then
      kill -TERM "$pid" 2>/dev/null || true
      log_info "Aplikasi dihentikan (PID $pid)."
    fi
    rm -f "$pid_file"
  else
    log_info "Tidak ada aplikasi yang berjalan (pid file tidak ditemukan)."
  fi
}
