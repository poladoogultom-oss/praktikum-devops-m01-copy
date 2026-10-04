#!/usr/bin/env bash
# ubuntu-bootstrap.sh — Bootstrap lengkap M03 di Ubuntu/WSL2
#
# Tujuan: Menyiapkan workstation Ubuntu dari nol untuk praktikum M03:
#   1) Install dependencies (shellcheck, jq, python3-venv, openssh-client)
#   2) Clone atau pull repo praktikum-devops
#   3) Install Challenge hooks (pre-commit, commit-msg) ke parent repo + lab-git
#   4) Jalankan setup SSH (generate key + ssh-agent + ~/.ssh/config + tes koneksi)
#   5) Migrasikan remote repo M01 ke SSH
#
# Usage:
#   bash ubuntu-bootstrap.sh                       # full bootstrap (akan prompt interaktif)
#   bash ubuntu-bootstrap.sh --skip-install        # skip apt install (kalau sudah ada)
#   bash ubuntu-bootstrap.sh --skip-ssh            # skip SSH setup (kalau sudah ada)
#   bash ubuntu-bootstrap.sh --repo-dir <path>     # override path repo (default ~/praktikum-devops)
#
# Prasyarat:
#   - GitHub username (untuk konfigurasi remote SSH)
#   - Akses sudo untuk apt install

set -euo pipefail

red()   { printf '\033[31m%s\033[0m\n' "$*" >&2; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
info()  { printf '    %s\n' "$*"; }

# ---------- Parse args ----------
SKIP_INSTALL=0
SKIP_SSH=0
REPO_DIR="$HOME/praktikum-devops"
GITHUB_REPO="${GITHUB_REPO:-praktikum-devops}"   # nama repo di GitHub
GITHUB_USER="${GITHUB_USERNAME:-}"

while (( $# > 0 )); do
    case "$1" in
        --skip-install)  SKIP_INSTALL=1; shift ;;
        --skip-ssh)      SKIP_SSH=1; shift ;;
        --repo-dir)      REPO_DIR="$2"; shift 2 ;;
        --github-repo)   GITHUB_REPO="$2"; shift 2 ;;
        --github-user)   GITHUB_USER="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,30p' "$0"
            exit 0 ;;
        *)
            red "Argumen tidak dikenal: $1"; exit 2 ;;
    esac
done

bold "=== Bootstrap M03 — Ubuntu/WSL2 ==="
info "OS: $(uname -srm)"
info "Repo target: $REPO_DIR"
info "GitHub repo: $GITHUB_REPO"
echo ""

# ---------- 1. Install dependencies ----------
if (( SKIP_INSTALL == 0 )); then
    bold "[1/5] Install dependencies"
    if command -v sudo >/dev/null 2>&1; then SUDO=sudo; else SUDO=; fi

    # Check what's missing
    MISSING=()
    command -v git         >/dev/null 2>&1 || MISSING+=("git")
    command -v ssh         >/dev/null 2>&1 || MISSING+=("openssh-client")
    command -v shellcheck  >/dev/null 2>&1 || MISSING+=("shellcheck")
    command -v jq          >/dev/null 2>&1 || MISSING+=("jq")
    command -v python3     >/dev/null 2>&1 || MISSING+=("python3")
    command -v ssh-agent   >/dev/null 2>&1 || MISSING+=("openssh-client")

    if (( ${#MISSING[@]} == 0 )); then
        green "✓ Semua tool sudah terpasang"
    else
        info "Akan menginstall: ${MISSING[*]}"
        $SUDO apt-get update -qq
        $SUDO apt-get install -y "${MISSING[@]}"
    fi
    echo ""
    git --version | sed 's/^/    git:         /'
    shellcheck --version | sed 's/^/    shellcheck: /' | head -1
    jq --version | sed 's/^/    jq:          /'
    python3 --version | sed 's/^/    python3:     /'
    echo ""
else
    bold "[1/5] Install dependencies (SKIPPED per --skip-install)"
    echo ""
fi

# ---------- 2. Clone or pull repo ----------
bold "[2/5] Sinkronkan repo praktikum-devops"
if [[ -d "$REPO_DIR/.git" ]]; then
    info "Repo sudah ada di $REPO_DIR — pull terbaru"
    cd "$REPO_DIR"
    git fetch origin
    # Hanya fast-forward jika lokal tidak punya commit yang akan hilang
    if git status --porcelain | grep -q .; then
        red "✗ Working tree tidak bersih — commit/stash dulu sebelum pull"
        git status --short | sed 's/^/      /'
        exit 1
    fi
    if git rev-parse --verify 'HEAD@{1}' >/dev/null 2>&1; then
        UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
        if [[ -n "$UPSTREAM" ]] && ! git merge-base --is-ancestor HEAD "$UPSTREAM"; then
            red "✗ Lokal punya commit yang tidak ada di remote — merge manual dulu"
            exit 1
        fi
    fi
    git pull --ff-only
elif [[ -d "$REPO_DIR" ]]; then
    red "✗ $REPO_DIR ada tapi bukan repo git. Hapus dulu atau pindahkan."
    exit 1
else
    info "Clone repo dari GitHub"
    if [[ -z "$GITHUB_USER" ]]; then
        read -r -p "    Username GitHub: " GITHUB_USER
    fi
    PARENT_DIR="$(dirname "$REPO_DIR")"
    mkdir -p "$PARENT_DIR"
    git clone "git@github.com:${GITHUB_USER}/${GITHUB_REPO}.git" "$REPO_DIR"
    cd "$REPO_DIR"
fi
echo ""
green "✓ Repo siap di $REPO_DIR"
git log --oneline -3 | sed 's/^/    /'
echo ""

# ---------- 3. Install Challenge hooks ----------
bold "[3/5] Install hook Challenge ke repo"
HOOKS_DIR="$REPO_DIR/minggu-03/hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
    red "✗ Direktori hook tidak ditemukan: $HOOKS_DIR"
    red "  Pastikan kamu sudah pull commit M03 scaffolding (33ae368+)."
    exit 1
fi

# Parent repo
"$HOOKS_DIR/install-hooks.sh"
echo ""

# lab-git (jika sudah ada .git di dalamnya)
LAB_GIT="$REPO_DIR/minggu-03/lab-git"
if [[ -d "$LAB_GIT/.git" ]]; then
    "$HOOKS_DIR/install-hooks.sh" lab-git
else
    info "lab-git belum di-init — hook akan dipasang setelahnya via 'install-hooks.sh lab-git'"
fi
echo ""

# ---------- 4. SSH setup ----------
if (( SKIP_SSH == 0 )); then
    bold "[4/5] Setup SSH (generate key, ssh-agent, config, tes koneksi)"
    bash "$REPO_DIR/minggu-03/setup-ssh-github.sh"
    echo ""
else
    bold "[4/5] Setup SSH (SKIPPED per --skip-ssh)"
    echo ""
fi

# ---------- 5. Summary ----------
bold "[5/5] Ringkasan"
info "Repo praktikum-devops: $REPO_DIR"
info "Shell:                 bash (Bash 5+)"
info "Git:                   $(git --version)"
info "Shellcheck:            $(shellcheck --version | head -1)"
info "Python:                $(python3 --version)"

if [[ -f "$HOME/.ssh/id_ed25519_polibatam.pub" ]]; then
    FINGER=$(ssh-keygen -lf "$HOME/.ssh/id_ed25519_polibatam.pub" 2>/dev/null | awk '{print $2}')
    info "SSH key fingerprint:  $FINGER"
fi

echo ""
bold "Next steps:"
info "1. JOB 1: konfirmasi koneksi: ssh -T git@github.com"
info "2. JOB 2-4: cd $REPO_DIR/minggu-03/lab-git"
info "3. JOB 5:   cd $REPO_DIR/minggu-01/app-sentra"
info "4. Setelah JOB 5 sukses: git tag -a v1.0.0 && git push origin v1.0.0"