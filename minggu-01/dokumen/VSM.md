# Value Stream Map — Alur Serah-Terima Manual (JOB 3)

**Tim** : PT Sentra Digital Batam (simulasi) · **Tanggal** : 20 September 2026

## Definisi singkat

| Istilah | Arti |
|---|---|
| **Process Time (PT)** | Waktu kerja aktif yang benar-benar dihabiskan seseorang pada aktivitas itu. |
| **Wait Time (WT)** | Waktu tunggu/antrean sebelum pekerjaan diambil atau diproses ke tahap berikutnya. |
| **%C/A** | Persentase keluaran yang bisa langsung dipakai tahap berikutnya **tanpa revisi/klarifikasi**. |

## Tabel VSM — isi dengan data JOB 2 kalian

| No | Aktivitas | Pelaku | Process Time (PT) | Wait Time (WT) | %C/A |
|---|---|---|---|---|---|
| 1 | Menulis kode | Dev | 15 menit | 0,5 menit | 100 % |
| 2 | Menulis dokumen serah-terima | Dev | 10 menit | 1,5 menit | 80 % |
| 3 | Serah-terima artefak | Dev → Ops | 3 menit | 1,5 menit | 33 % |
| 4 | Instalasi dependensi | Ops | 10 menit | 1,5 menit | 50 % |
| 5 | Perbaikan galat / klarifikasi | Ops | 12 menit | 3,0 menit | 0 % |
| 6 | Verifikasi aplikasi berjalan | Ops | 3 menit | 1,5 menit | 100 % |
| | **TOTAL** | | **ΣPT = 53** | **ΣWT = 9,5** | |

## Perhitungan

```
Flow Efficiency = Σ PT / (Σ PT + Σ WT) × 100%
                = 53 / (53 + 9,5) × 100%
                = 53 / 62,5 × 100%
                = 84,8 % ≈ 85 %
```

**Bottleneck** : aktivitas no. **5** (**Perbaikan galat / klarifikasi**) — %C/A = **0 %**
**Alasan dipilih sebagai sasaran otomasi** :
> Aktivitas ini punya WT tertinggi (3,0 menit ≈ 32% dari total WT) DAN %C/A terendah (0%) sekaligus PT terbesar (12 menit). Artinya ia memakan waktu tunggu paling lama sekaligus paling sering gagal langsung dipakai tahap berikutnya. Mengotomasinya lewat `requirements.txt` + `setup.sh` + health check menghilangkan perbaikan galat sama sekali (0 menit) — penurunan Lead Time absolut terbesar.

---

## Cara mengisi %C/A agar tidak asal menebak

Hitung dari kejadian nyata, bukan perasaan:

```
%C/A = (jumlah serah-terima yang langsung bisa dipakai) / (total serah-terima) × 100%
```

Contoh pemakaian rumus (data kami):
- Aktivitas No.3 (Serah-terima artefak): dari 3 kali Ops menerima artefak, hanya 1 yang langsung bisa dipakai (karena `requirements.txt` tidak ikut) → %C/A = 1/3 × 100% = **33%**
- Aktivitas No.5 (Perbaikan galat): 0 dari 1 serah-terima yang lolos tanpa revisi → %C/A = **0%**

---

## Catatan analisis (wajib ada di laporan)

1. Aktivitas mana yang menyumbang WT terbesar, dan apa yang menyebabkan antrean itu?
   > Aktivitas **No.5 (Perbaikan galat / klarifikasi)** menyumbang WT terbesar: **3,0 menit** dari total 9,5 menit (~32%). Penyebab antrean: Ops hanya boleh bertanya lewat `HANDOVER.md` tertulis (larangan komunikasi lisan), sehingga tiap kejelasan dependensi memicu putaran tunggu bolak-balik Dev↔Ops. Aktivitas 2, 3, 4, dan 6 menambah masing-masing 1,0–1,5 menit karena serah-terima antar pihak berjalan searah tanpa umpan balik cepat.

2. Jika hanya satu aktivitas yang boleh diotomasi, mana yang memberi penurunan Lead Time terbesar?
   > Aktivitas **No.5 (Perbaikan galat / klarifikasi)**: PT 12 + WT 3,0 = **15,0 menit** = 24% dari total Lead Time (ΣPT+ΣWT = 62,5 menit). Mengotomasi instalasi dependensi lewat `setup.sh` + `requirements.txt` membuat perbaikan galat **hilang sama sekali (0 menit)**, sehingga ini penurunan absolut terbesar. Bandingkan No.1 (PT 15 menit tapi WT hanya 0,5 — sudah efisien, otomasi cuma mengurangi sedikit).

3. Setelah JOB 4, aktivitas nomor berapa yang hilang atau menyusut? Berapa Flow Efficiency yang baru?
   > Aktivitas **No.4 (Instalasi dependensi)** menyusut drastis (PT ~10→1 menit, WT 1,5→0) dan **No.5 (Perbaikan galat) hilang sama sekali (0 menit)** karena `requirements.txt` + health check mencegah galat sebelum artefak sampai ke Ops. Flow Efficiency naik dari **85% (manual) ke ~94%** (estimasi: ΣWT ditekan ke ~3,5 menit sehingga 53 / (53 + 3,5) ≈ 94%) — otomasi menekan waktu tunggu mendekati nol sementara ΣPT (waktu kerja nyata) tetap ~53 menit.
