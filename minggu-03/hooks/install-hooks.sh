#!/usr/bin/env bash
# install-hooks.sh — salin hook dari minggu-03/hooks/ ke .git/hooks/
# Memasang: pre-commit, commit-msg
# Usage:
#   ./minggu-03/hooks/install-hooks.sh                 # repo praktikum (default)
#   ./minggu-03/hooks/install-hooks.sh lab-git         # repo latihan

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"

TARGET="${1:-}"

case "$TARGET" in
    "" )
        DEST="$ROOT/.git/hooks"
        echo "[install-hooks] Target: repo praktikum ($DEST)"
        ;;
    lab-git )
        DEST="$ROOT/minggu-03/lab-git/.git/hooks"
        echo "[install-hooks] Target: repo latihan lab-git ($DEST)"
        ;;
    * )
        echo "Usage: $0 [lab-git]" >&2
        exit 2
        ;;
esac

if [[ ! -d "$DEST" ]]; then
    echo "[install-hooks] ✗ Direktori $DEST tidak ditemukan." >&2
    echo "[install-hooks]   Apakah sudah 'git init'?" >&2
    exit 1
fi

for hook in pre-commit commit-msg; do
    src="$HERE/$hook"
    if [[ ! -f "$src" ]]; then
        echo "[install-hooks] ✗ Sumber $src tidak ditemukan." >&2
        exit 1
    fi
    cp -f "$src" "$DEST/$hook"
    chmod +x "$DEST/$hook"
    echo "[install-hooks] ✓ $hook terpasang di $DEST/$hook"
done

echo ""
echo "[install-hooks] Selesai. Coba:  git commit -m 'test: percobaan'  di repo target."