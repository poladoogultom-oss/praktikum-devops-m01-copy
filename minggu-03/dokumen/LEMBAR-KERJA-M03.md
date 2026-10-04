# Lembar Kerja Praktikum Modul 3 (JS-DVO-03)

> **Mahasiswa**: Gandhi · **NIM**: 4332511050 · **Kelas**: RKS305
>
> **Topik**: Version Control (Basic) — Git Fundamental, Workflow, & Konfigurasi Repository
>
> **Tanggal praktikum**: ../../2026

Lembar kerja ini dipakai untuk **menyalin keluaran terminal** saat menjalankan perintah
pada tiap JOB. Tempelkan keluaran asli (bukan ringkasan) — ini akan menjadi bukti pada
laporan dan lampiran PDF.

---

## JOB 1 — Konfigurasi Git & Autentikasi SSH (20')

### 1.1 Tinjau konfigurasi Git global

```bash
git --version
git config --global --list | sort
git config --global core.editor "nano"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global alias.lg "log --oneline --graph --decorate --all"
```

**Keluaran** (tempel di sini):

```
$ git --version
git version 2.34.1

$ git config --global --list | sort
alias.lg=log --oneline --graph --decorate --all
core.editor=nano
init.defaultbranch=main
pull.rebase=false
user.email=...
user.name=...
```

### 1.2 Bangkitkan kunci SSH Ed25519

```bash
ssh-keygen -t ed25519 -C "nim@students.polibatam.ac.id" \
  -f ~/.ssh/id_ed25519_polibatam
ls -l ~/.ssh/
```

> ⚠️ Masukkan passphrase (disarankan). Untuk komputer lab, **wajib** passphrase.

**Keluaran**:

```
$ ls -l ~/.ssh/
-rw------- ... id_ed25519_polibatam
-rw-r--r-- ... id_ed25519_polibatam.pub
```

### 1.3 Amankan izin (least privilege)

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519_polibatam
chmod 644 ~/.ssh/id_ed25519_polibatam.pub
stat -c '%a  %n' ~/.ssh/id_ed25519_polibatam*
```

**Keluaran**:

```
700  /home/<user>/.ssh/
600  /home/<user>/.ssh/id_ed25519_polibatam
644  /home/<user>/.ssh/id_ed25519_polibatam.pub
```

### 1.4 Daftarkan ke akun GitHub

```bash
cat ~/.ssh/id_ed25519_polibatam.pub
```

> Salin ke **Settings → SSH and GPG keys → New SSH key** di GitHub.

### 1.5 ssh-agent + ~/.ssh/config

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_polibatam

cat >> ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_polibatam
  IdentitiesOnly yes
EOF
chmod 600 ~/.ssh/config
```

### 1.6 Uji koneksi SSH

```bash
ssh -T git@github.com
```

**Keluaran yang benar** memuat sapaan berisi username GitHub kamu, mis.:

```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

### 1.7 Alihkan remote repo M01 ke SSH

```bash
cd ~/praktikum-devops/minggu-01/app-sentra
git remote -v
git remote set-url origin git@github.com:<username>/praktikum-devops-m01.git
git remote -v
git fetch origin && echo "Autentikasi SSH berhasil."
```

**Keluaran `git fetch`** — pastikan **tidak** meminta username/token:

```
From github.com:<username>/praktikum-devops-m01
 * branch            main       -> FETCH_HEAD
Autentikasi SSH berhasil.
```

---

## JOB 2 — Tiga Area Kerja & Siklus Commit (20')

> Eksperimen dilakukan pada repo latihan `minggu-03/lab-git` (repo terpisah dari induk).

### 2.1 Siapkan repo latihan

```bash
cd ~/praktikum-devops
mkdir -p minggu-03/lab-git && cd minggu-03/lab-git
git init
git status
ls -a    # muncul direktori .git
```

### 2.2 Commit pertama

```bash
echo "# Lab Git" > README.md
git status --short        # ?? = untracked
git add README.md
git status --short        # A  = ditambahkan ke staging
git commit -m "docs: tambahkan README awal"
git log --oneline
```

**Keluaran**:

```
$ git status --short
?? README.md

$ git status --short   # setelah add
A  README.md

$ git log --oneline
<hash> (HEAD -> main) docs: tambahkan README awal
```

### 2.3 Bedakan isi ketiga area

```bash
printf 'baris pertama\n' > catatan.txt
git add catatan.txt
printf 'baris kedua\n' >> catatan.txt
git status --short        # AM = versi staging BERBEDA dari working dir
git diff                  # working dir vs staging
git diff --staged         # staging vs repository
```

**Kode `git status --short` yang muncul**: `AM catatan.txt`

### 2.4 Commit + .gitignore

```bash
git add catatan.txt
git commit -m "feat: tambahkan catatan awal"

mkdir -p build && echo "artefak" > build/hasil.bin
printf 'build/\n*.log\n.env\n' > .gitignore
git status --short        # hanya .gitignore muncul
git add .gitignore
git commit -m "chore: abaikan artefak build dan berkas rahasia"
git check-ignore -v build/hasil.bin
```

**Keluaran `git check-ignore -v`**:

```
.gitignore:1:build/    build/hasil.bin
```

---

## JOB 3 — Anatomi Objek & Penelusuran Riwayat (15')

### 3.1 Log & alias

```bash
git log --oneline --graph --decorate
git lg
git log --pretty=format:'%h  %ad  %an  %s' --date=short
git show --stat HEAD
git show HEAD:README.md
```

### 3.2 Bongkar objek internal

```bash
git cat-file -t HEAD          # commit
git cat-file -p HEAD          # tree, parent, author, message
git cat-file -p 'HEAD^{tree}'
echo "halo" | git hash-object --stdin
```

**Bukti snapshot — hash blob identik untuk file tak berubah**:

```
$ git cat-file -p 'HEAD^{tree}'         # commit A
100644 blob def456    README.md

$ git cat-file -p 'HEAD~2^{tree}'       # commit lebih awal
100644 blob def456    README.md         # <-- hash sama
```

### 3.3 Diff antar commit

```bash
git diff HEAD~1 HEAD
git diff HEAD~2 HEAD --stat
git log -p -n 1 -- catatan.txt
```

---

## JOB 4 — Koreksi Riwayat (amend, restore, reset, revert, reflog) (30')

### 4.1 Amend

```bash
echo "baris ketiga" >> catatan.txt
git add catatan.txt
git commit -m "feat: tambah baris ketiga"
git commit --amend -m "feat: tambahkan baris ketiga pada catatan"
git log --oneline -n 2      # hash BERUBAH → riwayat ditulis ulang
```

### 4.2 Restore (belum commit)

```bash
echo "kesalahan ketik" >> catatan.txt
git status --short          # ' M' = berubah, belum di-stage
git restore catatan.txt
git status --short          # kosong = bersih

echo "salah lagi" >> catatan.txt && git add catatan.txt
git restore --staged catatan.txt   # keluarkan dari staging
git restore catatan.txt            # baru buang perubahan
```

### 4.3 Tiga commit percobaan untuk reset

```bash
for i in 1 2 3; do
  echo "percobaan $i" >> log-percobaan.txt
  git add log-percobaan.txt
  git commit -m "test: commit percobaan $i"
done
git log --oneline -n 4
```

### 4.4 Tiga mode reset — bandingkan `git status --short`

```bash
# --soft
git reset --soft HEAD~1
git status --short          # 'M ' = perubahan tetap di STAGING
git commit -m "test: commit percobaan 3 (dipulihkan)"

# --mixed (default)
git reset --mixed HEAD~1
git status --short          # ' M' = perubahan turun ke WORKING
git add . && git commit -m "test: commit percobaan 3 (dipulihkan kembali)"
```

> ⚠️ `--hard` HANYA aman karena perubahan sudah di-commit. Pada kerjaan nyata: `git status` + `git stash` dulu.

```bash
# --hard (eksperimen terkontrol)
git log --oneline -n 2
git reset --hard HEAD~1
git log --oneline -n 2      # commit teratas lenyap

# reflog → pulihkan
git reflog -n 6             # HEAD@{1} masih mencatat commit
git reset --hard <hash-dari-reflog>
git log --oneline -n 2      # commit kembali
```

### 4.5 Revert (tidak menulis ulang riwayat)

```bash
git revert --no-edit HEAD
git log --oneline -n 3      # commit lama TETAP ada, + commit pembatal
```

**Tabel ringkasan reset vs revert**:

| Mode            | Working Dir         | Staging Area      | Riwayat                |
|-----------------|---------------------|-------------------|------------------------|
| `reset --soft`  | Tidak berubah       | Dipertahankan     | Penunjuk mundur        |
| `--mixed`        | Tidak berubah       | Dikosongkan       | Penunjuk mundur        |
| `--hard`        | **DIHAPUS**         | Dikosongkan       | Penunjuk mundur        |
| `revert`        | Tidak berubah       | Tidak berubah     | **Ditambah** commit baru |

---

## JOB 5 — Tata Repo Praktikum + Tag v1.0.0 (15')

### 5.1 Audit kredensial di riwayat

```bash
cd ~/praktikum-devops/minggu-01/app-sentra
git log --oneline --graph --decorate -n 10
git log -p --all | grep -nEi '(ghp_|AKIA|BEGIN .*PRIVATE KEY|password *=)' | head
```

> **Keluaran kosong = bersih**. Bila ada: rotasi kredensial dulu, lalu lapor dosen.

### 5.2 Lengkapi `.gitignore` & README

```bash
# di minggu-01/app-sentra
```

Konten `.gitignore` (lihat juga `minggu-02/.gitignore`):

```
.venv/
__pycache__/
*.pyc
.env
*.log
app.log
ringkasan-log.txt
```

Konten README:

```markdown
# Sentra Digital Batam - Layanan Contoh DevOps
…
```

### 5.3 Commit atomik + tag

```bash
git status --short
git add .gitignore
git diff --staged            # WAJIB tinjau
git commit -m "chore: lengkapi daftar berkas yang diabaikan"

git add README.md
git commit -m "docs: tambahkan panduan penggunaan dan daftar skrip"

git tag -a v1.0.0 -m "Rilis pertama: deployment otomatis dan laporan sistem"
git tag -n
git show v1.0.0 --stat | head -n 12
```

### 5.4 Push + verifikasi

```bash
git push origin main
git push origin v1.0.0
git log --oneline --graph --decorate -n 10
```

---

## Observasi kelas (diisi kelas/diskusi)

| Job   | Aspek yang Diamati                               | Catatan / Bukti                              |
|-------|--------------------------------------------------|--------------------------------------------|
| 1     | Izin akses kunci SSH                             |                                            |
| 1     | `git fetch` setelah pindah SSH                   |                                            |
| 2     | Kode dua huruf `git status --short`              |                                            |
| 2     | Selisih `git diff` vs `git diff --staged`        |                                            |
| 2     | `git check-ignore -v`                            |                                            |
| 3     | Hash blob pada dua commit berbeda                |                                            |
| 4     | Hash commit sebelum/sesudah amend                |                                            |
| 4     | Tabel tiga mode reset                            |                                            |
| 4     | Isi `git reflog`                                 |                                            |
| 5     | `git log --graph` — atomik?                      |                                            |