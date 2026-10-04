# Laporan Praktikum Modul 3 (JS-DVO-03)

**Mata Kuliah**: DevOps · **Kode**: RKS305 · **Semester**: 3 / 2026-2027
**Topik**: Version Control (Basic) — Git Fundamental, Workflow, & Konfigurasi Repository
**Mahasiswa**: Gandhi · **NIM**: 4332511050 · **Program Studi**: Rekayasa Keamanan Siber
**Dosen Pengampu**: Antoni Haikal
**Tanggal Praktikum**: …… / …… / 2026

---

## Ringkasan Pelaksanaan

Modul ini menuntaskan fondasi Version Control untuk kerja kolaboratif:

| Job | Aktivitas                                          | Output / Bukti                                            |
|-----|----------------------------------------------------|-----------------------------------------------------------|
| 1   | Konfigurasi Git global + kunci SSH Ed25519         | `ssh -T git@github.com` berhasil; remote M01 = SSH        |
| 2   | Eksplorasi working dir / staging / repo            | Repo latihan `minggu-03/lab-git/`; status & diff tercatat |
| 3   | Anatomi blob / tree / commit + log decoration       | `git cat-file` & perbandingan hash blob                   |
| 4   | Koreksi riwayat (amend / restore / reset / revert / reflog) | Tabel perbandingan 3 mode reset, reflog rescue        |
| 5   | Tata repo praktikum (README, .gitignore) + tag v1.0.0 | `git tag -n`; tag muncul di GitHub                       |

Seluruh eksperimen penulisan ulang riwayat (JOB 4) dilakukan di repo latihan `lab-git/`
agar repo praktikum tetap aman. Repo induk (`praktikum-devops`) hanya menerima
commit atomic berpola Conventional Commits dan ditandai dengan tag `v1.0.0`.

---

## Pertanyaan Analisis

### 1. Reset versus revert pada branch bersama

**Soal**: Seorang rekan melakukan commit yang merusak layanan pada `main`, sudah di-push,
dan sudah ditarik tiga anggota tim. Ia mengusulkan `git reset --hard` + `git push --force`.
Jelaskan kerusakan konkret pada tiga salinan repo rekan lainnya, dan mengapa `git revert`
adalah satu-satunya pilihan tepat.

**Jawaban**:

[…]

---

### 2. Peta tiga area (working dir / staging / repo) setelah reset

**Soal**: Berdasarkan eksperimen JOB 4, susun tabel kondisi working directory dan staging
area setelah `reset --soft`, `--mixed`, dan `--hard`. Tentukan perubahan apa yang TIDAK
dapat dipulihkan reflog, dan jelaskan alasannya dengan merujuk pada apa yang sebenarnya
dicatat reflog.

**Jawaban**:

| Mode reset | Working Directory     | Staging Area            | HEAD pointer | Reflog recovery? |
|-----------|----------------------|------------------------|--------------|------------------|
| `--soft`  | Tidak berubah         | Perubahan tetap staged | Mundur       | Ya               |
| `--mixed` | Tidak berubah         | Dikosongkan            | Mundur       | Ya               |
| `--hard`  | **DIHAPUS** (sama dgn target commit) | Dikosongkan | Mundur       | Ya, *jika* perubahan sempat di-commit; tidak jika baru ada di working dir |

**Yang tidak dapat dipulihkan reflog**: perubahan yang **belum pernah di-commit** lalu
hilang karena `reset --hard` / `restore`. Reflog hanya mencatat pergerakan HEAD (commit
hash, branch pointer, checkout, reset). Perubahan di working directory yang tidak pernah
menjadi object Git tidak pernah masuk reflog.

[…]

---

### 3. Kredensial yang terlanjur ter-commit

**Soal**: Token akses ter-commit pukul 09.00, dihapus commit baru pukul 09.05. Mengapa
repo tetap dianggap bocor? Susun urutan tindakan yang benar beserta alasan urutannya
tidak boleh dibalik.

**Jawaban**:

[…]

---

### 4. Ukuran commit dan kemampuan pemulihan

**Soal**: Tinjau riwayat commit sendiri, identifikasi satu commit yang memuat >1 perubahan
logis. Jelaskan kesulitan pembatalan sebagian, hubungkan dengan metrik **Mean Time to
Restore** (Minggu 1).

**Jawaban**:

[…]

---

### 5. Snapshot dan biaya branching

**Soal**: Dengan merujuk keluaran `git cat-file` dari JOB 3, jelaskan mengapa Git
menyimpan snapshot (bukan selisih) namun tetap hemat ruang, dan mengapa pembuatan
branch hampir tanpa biaya — sifat dasar strategi branching Minggu 4.

**Jawaban**:

[…]

---

## Lampiran (Wajib)

1. Tangkapan layar `ssh -T git@github.com` (berisi sapaan username GitHub).
2. Tabel perbandingan tiga mode reset (soft / mixed / hard) dari JOB 4.
3. Tangkapan layar `git reflog` saat pemulihan commit (JOB 4 langkah 5).
4. Keluaran `git log --oneline --graph` repo praktikum (JOB 5).
5. Tautan tag `v1.0.0` pada halaman GitHub.
6. **[Challenge, bila dikerjakan]** Tangkapan layar tiga skenario pengujian hook
   (commit normal, commit `ghp_` ditolak, commit skrip cacat ditolak).

---

## Checklist Penilaian Sendiri (Rubrik)

| No | Kriteria                                  | Bobot | Self-Score (0–4) |
|----|-------------------------------------------|-------|------------------|
| 1  | Konfigurasi Git & SSH (JOB 1)             | 15%   |                  |
| 2  | Tiga area & siklus commit (JOB 2)        | 15%   |                  |
| 3  | Anatomi objek (JOB 3)                     | 15%   |                  |
| 4  | Koreksi riwayat & pemulihan (JOB 4)       | 25%   |                  |
| 5  | Tata repo & kualitas commit (JOB 5)      | 20%   |                  |
| 6  | Keamanan, K3, sistematika laporan        | 10%   |                  |
| +  | Challenge "Gerbang Mutu Sebelum Commit"   | +10   |                  |
| +  | Kontribusi diskusi & refleksi kelas       | +5    |                  |
|    | **Total** (dibatasi maks 100)             | 100%  |                  |