# Hooks — "Gerbang Mutu Sebelum Commit" (Challenge M03)

Salinan publik hook `pre-commit` dan `commit-msg` untuk dibagikan ke tim pada Minggu 4.
Hook tidak ikut ter-push karena berada di dalam `.git/`, sehingga setiap anggota tim
harus **menginstalnya secara lokal**.

## Yang Diperiksa Hook

### `pre-commit`

1. **Deteksi kredensial** pada `git diff --cached` (bukan seluruh isi file):
   - `ghp_…` (token GitHub personal access)
   - `AKIA[0-9A-Z]{8,}` (AWS access key ID)
   - `BEGIN … PRIVATE KEY` (blok kunci privat)
   - `PASSWORD=`, `SECRET=`, `TOKEN=` (penetapan variabel)
2. **shellcheck** pada setiap `.sh` yang di-stage; tolak bila ada peringatan severity `warning` ke atas.

### `commit-msg`

Pesan commit harus mengikuti **Conventional Commits**:

```
<type>(<scope>): <subject>
```

Type yang diterima: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`, `build`, `ci`.

Bypass otomatis untuk: `Merge …`, `Revert …`, `fixup! …`, `squash! …`.

## Cara Instalasi Otomatis

```bash
# dari root repo praktikum-devops
./minggu-03/hooks/install-hooks.sh
```

Skrip ini akan:

1. Menyalin `pre-commit` ke `.git/hooks/pre-commit`
2. Menyalin `commit-msg` ke `.git/hooks/commit-msg`
3. `chmod +x` keduanya

## Cara Instalasi Manual

```bash
cp minggu-03/hooks/pre-commit  .git/hooks/pre-commit
cp minggu-03/hooks/commit-msg  .git/hooks/commit-msg
chmod +x .git/hooks/pre-commit .git/hooks/commit-msg
```

> Untuk repo latihan `minggu-03/lab-git/`, ulangi instalasi di `.git/`-nya sendiri.

## Skenario Pengujian Wajib (Lampiran Laporan)

| # | Skenario                                              | Hasil yang diharapkan     |
|---|-------------------------------------------------------|---------------------------|
| 1 | Commit normal (mis. tambah baris di README.md)        | **Diterima** (exit 0)     |
| 2 | Commit dengan string `ghp_abcdef0123456789abcdef…`   | **Ditolak** (exit 1)      |
| 3 | Commit skrip `.sh` yang punya peringatan shellcheck   | **Ditolak** (exit 1)      |

Tiga tangkapan layar pengujian ini wajib dilampirkan di laporan untuk klaim +10 Challenge.

## Bypass Darurat

```bash
git commit --no-verify -m "fix(emergency): revert produksi"
```

Gunakan hanya pada keadaan darurat; hook sengaja mengabaikan `--no-verify` agar tidak
menghambat perbaikan insiden.