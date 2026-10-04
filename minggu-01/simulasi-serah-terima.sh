#!/usr/bin/env bash
#
# simulasikan-serah-terima.sh - JOB 2: membuat paket serah-terima yang SENGAJA BURUK.
# Hanya berisi src/ + HANDOVER.md, TANPA requirements.txt, tanpa .venv.
#
# Dijalankan oleh Mahasiswa A (peran Developer).
#
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$BASE_DIR/app-sentra"
DEST="$BASE_DIR/serah-terima"

echo "[*] Menyusun paket serah-terima (sengaja tidak lengkap)..."
rm -rf -- "$DEST"
mkdir -p "$DEST"
cp -r "$SRC/src" "$DEST/"
cp "$SRC/HANDOVER.md" "$DEST/"

echo "[*] Isi paket:"
ls -la "$DEST"
echo
echo "[!] Perhatikan: requirements.txt TIDAK disertakan. Ini disengaja."
echo "[!] Mahasiswa B (Ops) cukup menyalin folder 'serah-terima' ini ke direktorinya."
echo
echo "    cp -r serah-terima ~/praktikum-devops-ops/minggu-01/"
