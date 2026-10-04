# Lembar Kerja — JS-DVO-01 (Minggu 1)

**Mata Kuliah** : DevOps (RKS305) · **Program Studi** : Rekayasa Keamanan Siber  
**Kelompok** : Mahasiswa A = Muhammad Gandhi Putra (4332511050) · Mahasiswa B = Brian Polado Gultom (4332511660)  
**Tanggal praktikum** : 19 September – 22 September 2026  · **Repo GitHub** : <https://github.com/GJRRR/praktikum-devops-m01>

> Semua tabel di bawah wajib diisi dengan **data hasil pengukuran kalian sendiri**.  
> Rubrik menilai kedalaman analisis berbasis data — angka contoh tidak akan lulus.



---

## JOB 1 — Verifikasi Lingkungan Kerja

| Perkakas    | Versi terpasang (Mahasiswa A) | Versi terpasang (Mahasiswa B) | Sesuai acuan? |
| ----------- | ----------------------------- | ----------------------------- | ------------- |
| OS / kernel | Ubuntu 22.04 CLI              | Ubuntu 22.04 CLI              | sesuai        |
| Git         | ≥ 2.34                        | ≥ 2.34                        | sesuai        |
| Python 3    | ≥ 3.10                        | ≥ 3.10                        | sesuai        |
| pip3        | 22.0.2                        | 24.0                          | sesuai        |
| curl        | 7.81                          | 8.5.0                         | sesuai        |

**Jawaban observasi JOB 1**

- Apakah versi perkakas kedua anggota identik? Perbedaan apa yang berpotensi menimbulkan masalah?
  > Walaupun diatas kertas version nya sama, 1 hal bisa membuat environment nya berbeda. contoh risiko yang berpotensi menimbulkan masalah: (1) package drift — mesin Ops tidak punya paket flask terpasang meski Python sudah ada

---

## JOB 2 — Simulasi Silo (Wall of Confusion)

Dikerjakan Mahasiswa A (Dev) → diserahkan ke Mahasiswa B (Ops).  
**Aturan: tidak ada komunikasi lisan. Hanya HANDOVER.md.**

| Parameter Pengukuran                              | Hasil                                                                    |
| ------------------------------------------------- | ------------------------------------------------------------------------ |
| Waktu mulai (Ops menerima artefak)                | 20.09 WIB                                                                |
| Waktu selesai / dinyatakan gagal                  | 20.38 WIB                                                                |
| **Lead Time manual (menit)**                      | 29 menit                                                                 |
| **Jumlah kegagalan (failed attempts)**            | 1                                                                        |
| Jumlah pertanyaan yang seharusnya diajukan ke Dev | Daftar dependensi lengkap?, Harus pakai venv?, Versi Python?             |
| Status akhir (Berhasil / Gagal)                   | flask kebetulan di kasus ini sudah terinstall dari setup CLI sebelumnya |

### Catatan kegagalan (isi tiap baris saat galat muncul)

| No | Perintah yang dijalankan | Pesan galat (salin persis)                                                                                                                                                             | Akar masalah menurut Ops                                                        |
| -- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 1  | python3 src/app.py       | ModuleNotFoundError: No module named 'flask'                                                                                                                                           | sepertinya requirements.txt tidak ikut di paket serah-terima                    |
| 2  | pip3 install flask       | Requirement already satisfied: flask in /home/gjr4332511050/.local/lib/python3.10/site-packages (3.0.3) + Defaulting to user installation because normal site-packages is not writable | paket kebetulan ada dari setup CLI/JOB 1 sebelumnya — bukan karena handover Dev |
| 3  | python3 src/app.py       | Running on http://127.0.0.1:5000 (sukses)                                                                                                                                              |                                                                                 |
| 4  |                          |                                                                                                                                                                                        |                                                                                 |
| 5  |                          |                                                                                                                                                                                        |                                                                                 |

**Jawaban observasi JOB 2**

- Pada baris ke berapa galat pertama muncul? Apakah pesannya informatif bagi orang yang tidak menulis kodenya?
  > *Tidak. ModuleNotFoundError hanya menyebut nama paket yang hilang, tanpa instruksi cara install di Ubuntu. HANDOVER.md bahkan tidak menyebut nama dependensi sama sekali.*
- Berapa kali Ops ingin bertanya namun terhalang aturan? Informasi kritis apa yang absen dari HANDOVER.md?
  > *Minimal 2-3 kali: daftar dependensi (requirements.txt tidak ikut), cara install aman (venv), dan versi Python target.*
- Perbedaan konkret apa antara mesin Dev dan mesin Ops?
  > *Dev sudah punya paket flask terpasang saat development, sehingga handover mungkin cukup. Tapi Ops di mesin bersih tidak punya cara reproducibility. Keberhasilan di sini hanya karena paket kebetulan sudah ada dari setup CLI sebelumnya, bukan karena handover Dev yang informatif.*

---

## JOB 3 — Value Stream Mapping

Lihat berkas terpisah: **[VSM.md](./VSM.md)**

| Ringkasan                                      | Nilai    |
| ---------------------------------------------- | -------- |
| Σ Process Time (menit)                         | 53       |
| Σ Wait Time (menit)                            | 9,5      |
| **Flow Efficiency = ΣPT / (ΣPT + ΣWT) × 100%** | 85 %     |
| Aktivitas dengan %C/A terendah (bottleneck)    | No. 5 — Perbaikan galat / klarifikasi (WT 3,0; %C/A 0 %) |

---

## JOB 4 — Otomasi (The First Way)

Peran ditukar: Mahasiswa B = Developer, Mahasiswa A = Operations.

| Metrik                         | Sebelum Otomasi (JOB 2) | Sesudah Otomasi (JOB 4) | Selisih        |
| ------------------------------ | ----------------------- | ----------------------- | -------------- |
| Lead Time (menit)              | 29                      | 2                       | −27 menit      |
| Jumlah langkah manual          | 6                       | 1                       | −5 langkah     |
| Jumlah kegagalan               | 1                       | 0                       | −1 kegagalan   |
| Kebutuhan komunikasi Dev ↔ Ops | Terblokir (2–3 pertanyaan) | Tidak ada (otomatis)  | Hilang         |

### Uji ketangguhan skrip

| Pengujian            | Perintah                                    | Hasil yang diamati                                                                                  | Memenuhi? |
| -------------------- | ------------------------------------------- | --------------------------------------------------------------------------------------------------- | --------- |
| Idempotensi          | jalankan `./setup.sh` 3× berturut-turut     | 3× berturut-turut SUKSES, output identik (venv terdeteksi, dilewati recreate)                       | ✅        |
| Fail-fast            | hapus `requirements.txt`, lalu `./setup.sh` | berhenti di langkah ke-2 (install dependensi), `exit 1`                                             | ✅        |
| Deteksi port bentrok | jalankan app di 5000, lalu `./setup.sh`     | mendeteksi port 5000 terpakai, otomatis pindah ke 5001                                              | ✅        |
| Mode validasi        | `./setup.sh --check`                        | `exit code 0` (Python 3.10.12, curl 7.81.0, requirements ditemukan, port 5000 bebas)               | ✅        |
| Retry health check   | app lambat start                            | berhasil pada percobaan ke-2 dari 5 (retry 5× dengan jeda)                                          | ✅        |
| Pembersihan aman     | `./teardown.sh --purge`                     | `.venv` terhapus; validasi 3-lapis path mencegah penghapusan di luar direktori proyek               | ✅        |

**Jawaban observasi JOB 4**

- Mengapa berhenti lebih awal (`set -euo pipefail`) justru lebih aman?
  > *Karena skrip berhenti saat langkah pertama gagal, Ops tidak menyangka "sudah selesai" padahal dependensi belum terpasang. Tanpa fail-fast, galat baru ketahuan di akhir (seperti ModuleNotFoundError JOB 2) — lebih sulit dilacak karena akar masalah sudah tertutup langkah berikutnya. Fail-fast = kerusakan kecil tertangkap segera, tidak menggumpal jadi insiden.*
- Apakah `.venv/` muncul di `git status`? Apa dampaknya ke ukuran repo bila `.gitignore` tidak dibuat?
  > *Tidak muncul karena sudah masuk `.gitignore`. Bila tidak di-ignore, seluruh isi `.venv/` (ratusan paket, bisa >100 MB) ter-commit → repo membengkak, clone lambat, dan dependensi ter-lock ke versi mesin Dev (melanggar reproducible environment).*

---

## JOB 5 — Simulasi SDLC & Blameless Postmortem

| Board       | Kolom                                                         | Kartu terlama tertahan di kolom | Waktu total simulasi |
| ----------- | ------------------------------------------------------------- | ------------------------------- | -------------------- |
| Waterfall   | Requirement → Design → Implementation → Testing → Deployment | Implementation (2:57)           | 08:28,41             |
| DevOps Flow | Backlog → In Progress (WIP 2) → Review → Deployed → Monitored | Review (5:06)                   | 10:21,48             |

**Catatan:** Untuk **satu task kecil**, Waterfall (08:28) justru lebih cepat dari DevOps Flow (10:21) karena DevOps Flow menambah gerbang Review + batas WIP yang menjadi overhead. Keunggulan DevOps Flow bukan pada cycle time satu task, melainkan **throughput & parallelism**: dengan banyak task bersamaan, WIP limit mencegah antrean panjang dan Review berjalan paralel, sehingga total lead time rangkaian task jauh lebih pendek.

Lihat berkas terpisah: **[POSTMORTEM.md](../POSTMORTEM.md)**

---

## Daftar artefak yang dikumpulkan

- [ ] `00-environment-check.log` (JOB 1)
- [ ] Tangkapan layar pesan galat Ops (JOB 2)
- [ ] `dokumen/VSM.md` terisi lengkap + perhitungan Flow Efficiency (JOB 3)
- [ ] `app-sentra/setup.sh` berjalan di mesin pasangan (JOB 4)
- [ ] Tangkapan layar keluaran `./setup.sh` sukses (JOB 4)
- [ ] Tangkapan layar `shellcheck` bersih (challenge)
- [ ] `POSTMORTEM.md` (JOB 5)
- [ ] Tautan repository GitHub **private**, collaborator: `antoni@polibatam.ac.id` + pasangan
- [ ] Laporan PDF `M01_NIM_NamaLengkap.pdf`, dikumpul H+3 pukul 23.59 WIB
