#!/usr/bin/env bash
#
# 00-check-env.sh - JOB 1: Verifikasi kesiapan lingkungan kerja.
# Menghasilkan berkas bukti 00-environment-check.log (lampiran wajib laporan).
#
set -uo pipefail

LOG="00-environment-check.log"

{
  echo "=========================================================="
  echo " JOB 1 - VERIFIKASI LINGKUNGAN KERJA DEVOPS"
  echo " JS-DVO-01 · Politeknik Negeri Batam · Rekayasa Keamanan Siber"
  echo "=========================================================="
  echo
  echo "--- Identitas mesin ---"
  uname -srm
  cat /etc/os-release 2>/dev/null | head -n 3
  echo "user        : $(whoami)"
  echo "tanggal     : $(date)"
  echo
  echo "--- Versi perkakas inti ---"
  for tool in git python3 pip3 curl shellcheck; do
    printf "%-12s : " "$tool"
    if command -v "$tool" >/dev/null 2>&1; then
      "$tool" --version 2>&1 | head -n 1
    else
      echo "TIDAK DITEMUKAN"
    fi
  done
  echo
  echo "--- Konfigurasi Git ---"
  git config --global --get user.name  || echo "user.name   : BELUM DIATUR"
  git config --global --get user.email || echo "user.email  : BELUM DIATUR"
  git config --global --get init.defaultBranch || echo "defaultBranch: BELUM DIATUR"
  echo
  echo "--- Status ---"
} | tee "$LOG"

echo
echo "Berkas bukti tersimpan di: $(pwd)/$LOG"
echo
echo "Jika ada 'TIDAK DITEMUKAN' atau 'BELUM DIATUR', jalankan:"
echo "  sudo apt update && sudo apt install -y git python3 python3-pip python3-venv curl"
echo "  git config --global user.name  \"Nama Lengkap\""
echo "  git config --global user.email \"nim@students.polibatam.ac.id\""
echo "  git config --global init.defaultBranch main"
