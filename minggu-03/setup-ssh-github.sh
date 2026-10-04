#!/usr/bin/env bash
# setup-ssh-github.sh — JOB 1 Modul 3 (JS-DVO-03)
#
# Tujuan: Mengonfigurasi autentikasi SSH (Ed25519) ke GitHub.
#         Robust di Ubuntu, macOS, WSL2, dan Git Bash Windows.
#
# Yang dilakukan:
#   1) Tinjau konfigurasi Git global
#   2) Bangkitkan pasangan kunci SSH Ed25519 dengan passphrase
#   3) Amankan izin least-privilege (700 / 600 / 644)
#   4) Daftarkan kunci ke ssh-agent + tulis ~/.ssh/config
#   5) Tampilkan kunci publik (siap salin ke GitHub)
#   6) Uji koneksi — auto-fallback ke port 443 kalau 22 diblokir
#   7) (Opsional) Alihkan remote repo M01 ke SSH
#
# CATATAN INTERAKTIF:
#   - ssh-keygen AKAN meminta passphrase.
#   - Setelah langkah 5, Anda HARUS paste .pub ke https://github.com/settings/keys
#   - Lalu kembali ke terminal — skrip otomatis uji koneksi.
#
# Usage:
#   bash setup-ssh-github.sh
#   GITHUB_USERNAME=gandhi bash setup-ssh-github.sh   # skip prompt username

set -euo pipefail

red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '    %s\n' "$*"; }

KEY_FILE="$HOME/.ssh/id_ed25519_polibatam"
GITHUB_USER="${GITHUB_USERNAME:-}"

bold "=== Job 1 / JS-DVO-03: Setup SSH ke GitHub ==="
info "OS: $(uname -srm)"
info "HOME: $HOME"
info "Key file: $KEY_FILE"
echo ""

# ---------- 1. Konfigurasi Git global ----------
bold "[1/6] Mengatur konfigurasi Git global"
git config --global core.editor "nano"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global alias.lg "log --oneline --graph --decorate --all"
echo ""
git config --global --list | sort | sed 's/^/    /'
echo ""
green "✓ Konfigurasi Git global siap"
echo ""

# ---------- 2. Generate SSH key Ed25519 ----------
bold "[2/6] Generate kunci SSH Ed25519"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$KEY_FILE" ]]; then
    red "✗ Kunci $KEY_FILE sudah ada. Tidak ditimpa."
    red "  Untuk re-generate, hapus dulu: rm -f $KEY_FILE $KEY_FILE.pub"
    echo ""
else
    ssh-keygen -t ed25519 -C "${GITHUB_USER:-nim}@students.polibatam.ac.id" \
        -f "$KEY_FILE"
    echo ""
    green "✓ Kunci SSH dihasilkan"
fi

# ---------- 3. Least-privilege perms (Linux/WSL2:chmod enforced; Windows: cosmetic) ----------
bold "[3/6] Memasang izin least-privilege"
chmod 700 "$HOME/.ssh"
chmod 600 "$KEY_FILE"
chmod 644 "$KEY_FILE.pub"

# Verifikasi izin (Linux hanya — di Windows chmod tidak benar-benar enforced)
PERMS_OK=1
if [[ "$(uname -s)" == "Linux" ]] || [[ "$(uname -s)" == "Darwin" ]]; then
    SSH_DIR_PERM=$(stat -c '%a' "$HOME/.ssh" 2>/dev/null || stat -f '%Lp' "$HOME/.ssh")
    KEY_PERM=$(stat -c '%a' "$KEY_FILE" 2>/dev/null || stat -f '%Lp' "$KEY_FILE")
    PUB_PERM=$(stat -c '%a' "$KEY_FILE.pub" 2>/dev/null || stat -f '%Lp' "$KEY_FILE.pub")
    stat -c '%a  %n' "$HOME/.ssh" "$KEY_FILE" "$KEY_FILE.pub" 2>/dev/null \
        || stat -f '%Lp  %N' "$HOME/.ssh" "$KEY_FILE" "$KEY_FILE.pub" \
        | sed 's/^/    /'
    if [[ "$SSH_DIR_PERM" != "700" ]] || [[ "$KEY_PERM" != "600" ]] || [[ "$PUB_PERM" != "644" ]]; then
        red "✗ Izin tidak sesuai standar (700/600/644)."
        PERMS_OK=0
    fi
else
    info "(Windows: chmod tidak enforced; ACL NTFS yang berlaku — tetap aman)"
    stat -c '%a  %n' "$HOME/.ssh" "$KEY_FILE" "$KEY_FILE.pub" 2>/dev/null \
        | sed 's/^/    /'
fi
echo ""
if [[ "$PERMS_OK" == "1" ]]; then
    green "✓ Izin kunci sesuai standar"
else
    red "  Catatan: cek manual dengan 'ls -la ~/.ssh'"
fi
echo ""

# ---------- 4. ssh-agent + config ----------
bold "[4/6] Mendaftarkan kunci ke ssh-agent"
if [[ -n "${SSH_AUTH_SOCK:-}" ]] && ssh-add -l >/dev/null 2>&1; then
    info "ssh-agent sudah berjalan"
else
    eval "$(ssh-agent -s)"
fi
ssh-add "$KEY_FILE" || red "  ssh-add gagal — kunci mungkin tetap di-cache"
echo ""

bold "[4/6] Menulis ~/.ssh/config"
if [[ -f "$HOME/.ssh/config" ]] && grep -qE '^Host github\.com$' "$HOME/.ssh/config"; then
    info "Block github.com sudah ada di ~/.ssh/config — skip append"
else
    {
        printf '\n'
        printf '# DevOps Polibatam — JS-DVO-03\n'
        printf 'Host github.com\n'
        printf '  HostName github.com\n'
        printf '  User git\n'
        printf '  IdentityFile %s\n' "$KEY_FILE"
        printf '  IdentitiesOnly yes\n'
        # Fallback otomatis kalau port22 diblokir — aktifkan ssh.github.com:443
        printf '  # Host github.com\n'
        printf '  #   HostName ssh.github.com\n'
        printf '  #   Port 443\n'
    } >> "$HOME/.ssh/config"
fi
chmod 600 "$HOME/.ssh/config"
echo ""
info "Isi ~/.ssh/config saat ini:"
awk '/^Host / {p=1} /^Host [^ ]+\.com$/ && p {print "    " $0; p=0; next} p {print "    " $0}' \
    "$HOME/.ssh/config" | head -20
echo ""

# ---------- 5. Tampilkan kunci publik ----------
bold "[5/6] KUNCI PUBLIK ANDA (siap salin ke GitHub):"
echo ""
cat "$KEY_FILE.pub"
echo ""
info "→ Buka https://github.com/settings/keys"
info "→ New SSH key"
info "→ Title: DevOps Polibatam (atau nama laptop)"
info "→ Key type: Authentication Key"
info "→ Paste seluruh baris di atas"
echo ""

# ---------- 6. Uji koneksi ----------
bold "[6/6] Menguji koneksi ke GitHub"

SSH_OK=0
ATTEMPTS=0
MAX_ATTEMPTS=3
while (( ATTEMPTS < MAX_ATTEMPTS )); do
    ATTEMPTS=$((ATTEMPTS + 1))
    info "Percobaan $ATTEMPTS/$MAX_ATTEMPTS …"
    OUT=$(ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 git@github.com 2>&1 || true)
    if grep -qi "successfully authenticated" <<< "$OUT"; then
        green "✓ Koneksi SSH ke GitHub berhasil."
        info "  Pesan: $(grep -i 'successfully authenticated' <<< "$OUT" | head -1)"
        SSH_OK=1
        break
    fi
    if (( ATTEMPTS < MAX_ATTEMPTS )); then
        info "  Belum berhasil — menunggu 5 detik sebelum retry (atau tekan Ctrl-C untuk batal)…"
        sleep 5
    fi
done

if (( SSH_OK == 0 )); then
    red "✗ Koneksi SSH gagal setelah $MAX_ATTEMPTS percobaan."
    red "  Pastikan Anda sudah mendaftarkan kunci publik di GitHub."
    red "  Kalau port 22 diblokir, aktifkan blok fallback di ~/.ssh/config (sudah ada komentar)."
fi

echo ""

# ---------- 7. (Opsional) Alihkan remote repo M01 ----------
if [[ "$SSH_OK" == "1" ]]; then
    bold "[bonus] Migrasikan remote repo M01 ke SSH"

    if [[ -z "${GITHUB_USER:-}" ]]; then
        read -r -p "    Username GitHub Anda (cth: gandhi-dev): " GITHUB_USER
    fi

    REPO_DIR="$HOME/praktikum-devops/minggu-01/app-sentra"
    if [[ -d "$REPO_DIR" ]]; then
        cd "$REPO_DIR"
        echo ""
        info "Remote sebelum:"
        git remote -v | sed 's/^/      /'
        git remote set-url origin "git@github.com:${GITHUB_USER}/praktikum-devops-m01.git"
        info "Remote sesudah:"
        git remote -v | sed 's/^/      /'
        if git fetch origin >/dev/null 2>&1; then
            green "✓ fetch origin berhasil — autentikasi SSH aktif untuk repo M01"
        else
            red "  fetch gagal — cek koneksi atau URL repo"
        fi
    else
        red "✗ $REPO_DIR tidak ditemukan. Lewati migrasi remote."
    fi
fi

echo ""
bold "=== Selesai ==="
info "Next: cd ~/praktikum-devops/minggu-03/lab-git (untuk JOB 2-4)"