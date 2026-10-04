# Blameless Postmortem — Insiden Kegagalan Deployment Manual

> **Aturan postmortem blameless:** tidak boleh menyebut nama individu.
> Yang dicari adalah cacat pada **sistem kerja**, bukan siapa yang lupa.
> Isi setiap bagian dengan hasil JOB 2–4 kalian sendiri.

**Tanggal insiden** : 21 September 2026 · **Durasi** : 29 menit
**Layanan** : sentra-digital-batam (Flask) · **Status akhir** : Berhasil (dengan catatan: keberhasilan bersifat kebetulan / package drift, tidak reproducible)

---

## 1. Ringkasan Insiden

_Proses serah-terima aplikasi Flask "sentra-digital-batam" dari Development ke Operations gagal berjalan pada lingkungan Ops (JOB 2, simulasi silo / wall of confusion). Penyebab langsungnya adalah paket serah-terima tidak menyertakan `requirements.txt`, sehingga aplikasi tidak dapat dijalankan (galat `ModuleNotFoundError: No module named 'flask'`). Total waktu terbuang **29 menit** dengan **1 kali percobaan gagal** sebelum aplikasi akhirnya merespons. Insiden teratasi setelah terungkap bahwa paket `flask` sebenarnya sudah terpasang di environment Ops secara kebetulan (package drift dari setup CLI sebelumnya) — namun keberhasilan tersebut **tidak reproducible** di mesin Ops yang bersih._

---

## 2. Kronologi (timeline)

Gunakan waktu sebenarnya dari Lembar Kerja JOB 2.

| Waktu | Peristiwa | Aktor (peran, bukan nama) |
|---|---|---|
| 20:09 | Dev menyerahkan paket berisi `src/` + `HANDOVER.md` | Developer |
| 20:09 | Ops mencoba menjalankan aplikasi (`python3 src/app.py`) | Operations |
| 20:09 | Galat pertama muncul: `ModuleNotFoundError: No module named 'flask'` | Operations |
| 20:10 | Percobaan ke-2: `pip3 install flask` → `Requirement already satisfied` (kebetulan sudah ada) | Operations |
| 20:38 | Aplikasi berhasil merespons `GET /health` → `{"status":"ok"}` | Operations |

---

## 3. Dampak

| Jenis dampak | Nilai (dari pengukuran kalian) |
|---|---|
| Waktu terbuang (Lead Time manual) | 29 menit |
| Jumlah kegagalan | 1 kali |
| Percobaan komunikasi Dev ↔ Ops yang terblokir | 2–3 kali |
| Estimasi biaya waktu (Lead Time × tarif/jam × 20 rilis/bulan) | 29 mnt × tarif × 20 = 580 mnt/bulan ≈ 9,7 jam/bulan |

---

## 4. Akar Masalah pada SISTEM (bukan pada orang)

_Tulis minimal 3 akar masalah sistemik. Setiap poin wajib menjawab: "mekanisme apa yang seharusnya mencegah ini tanpa mengganti orangnya?"_

| # | Akar masalah sistemik | Mengapa bukan salah individu | Mekanisme pencegahan |
|---|---|---|---|
| 1 | Dependensi tidak pernah dikunci dan tidak dikirim | Dev wajar menganggap environment-nya merepresentasikan produksi; tidak ada sistem yang memaksa dependensi ikut di paket | `requirements.txt` terkunci + ikut dalam serah-terima (`setup.sh` membacanya) |
| 2 | Tidak ada verifikasi otomatis bahwa artefak bisa dijalankan | Manusia baru tahu gagal setelah mencoba manual; galat baru muncul di tangan Ops | Smoke test `GET /health` otomatis + exit code 0/1 di dalam `setup.sh` |
| 3 | Pengetahuan konfigurasi berada di kepala orang, bukan di repo | Informasi hilang saat orangnya tidak ada/tidak boleh ditanya (aturan silo) | Semua konfigurasi jadi kode: `setup.sh`, `teardown.sh`, `requirements.txt`, `.gitignore` |
| 4 | Tidak ada definisi "selesai" yang bisa diuji | Dev rasa selesai (jalan di laptop sendiri), Ops rasa belum mulai | Definition of Done = `./setup.sh` lulus di mesin bersih |

_Petunjuk arah jawaban (kembangkan dengan kata-kata sendiri):_
- Dependensi tidak pernah dikunci dan tidak dikirim → tidak ada jaminan apa pun bahwa mesin Ops sama dengan mesin Dev.
- Tidak ada verifikasi otomatis bahwa artefak bisa dijalankan → kegagalan baru ketahuan setelah manusia mencoba.
- Pengetahuan konfigurasi berada di kepala orang, bukan di repository → informasi hilang saat orangnya tidak ada.
- Tidak ada definisi "selesai" yang bisa diuji → Dev menganggap selesai, Ops menganggap belum mulai.

---

## 5. Tindakan Perbaikan (action items)

| # | Tindakan | Peran penanggung jawab | Bukti selesai | Status |
|---|---|---|---|---|
| 1 | Seluruh dependensi dikunci di `requirements.txt` | Developer | berkas ada di repo, `flask==3.0.3` | Selesai |
| 2 | Prosedur manual diganti skrip `setup.sh` | Developer | `./setup.sh` lulus di mesin pasangan | Selesai |
| 3 | Validasi prasyarat otomatis (`--check`) | Developer | exit code 0/1 sesuai kondisi | Selesai |
| 4 | Smoke test otomatis `/health` + retry | Developer | log percobaan health check (5×2s) | Selesai |
| 5 | `.gitignore` dibuat sebelum commit pertama | Developer | `git status` tidak memuat `.venv` | Selesai |
| 6 | Deteksi port bentrok otomatis | Developer | `./setup.sh` pindah ke 5001 saat 5000 terpakai | Selesai |

---

## 6. Pelajaran yang Diambil

1. Apa yang berubah pada sistem kerja kalian setelah JOB 4?
   > _Sistem kerja berubah dari prosedur manual rentan (HANDOVER.md 3 baris) menjadi artefak yang mereproduksi dirinya sendiri: `requirements.txt` + `setup.sh` + `teardown.sh`. Lead Time turun dari 29 menit ke ~2 menit, dan keberhasilan tidak lagi bergantung pada kebetulan package sudah terpasang di mesin Ops._

2. Metrik mana yang paling mengejutkan kalian, dan mengapa?
   > _Flow Efficiency JOB 2 yang rendah dan Lead Time 29 menit untuk satu aplikasi Flask sederhana — hanya gara-gara `requirements.txt` tidak ikut. Satu file teks kecil menyebabkan puluhan menit antrean (Wait Time) dan komunikasi terblokir._

3. Jika besok ada anggota tim baru, apa yang membuat dia tidak akan mengulangi insiden ini?
   > _Ia cukup menjalankan `./setup.sh`; tidak perlu tahu konfigurasi manual, tidak perlu bertanya ke Dev. Environment terdefinisi sebagai kode, sehingga onboarding cukup satu perintah._
