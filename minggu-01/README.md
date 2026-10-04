# Praktikum DevOps Minggu 1 — JS-DVO-01

Paket artefak siap pakai untuk JOB 1–5 + Challenge "Zero-Touch Verification".  
Skenario: **PT Sentra Digital Batam** — dari serah-terima manual ke aliran otomatis.

## Struktur

```
minggu-01/
├─ README.md                  <- panduan ini
├─ 00-check-env.sh            <- JOB 1: verifikasi lingkungan (menghasilkan .log bukti)
├─ simulasi-serah-terima.sh  <- JOB 2: membuat paket serah-terima yang sengaja buruk
├─ POSTMORTEM.md              <- JOB 5: template blameless postmortem
├─ app-sentra/
│  ├─ src/app.py              <- aplikasi Flask
│  ├─ requirements.txt        <- dependensi TERKUNCI
│  ├─ HANDOVER.md             <- dokumen serah-terima manual (sengaja tidak sempurna)
│  ├─ setup.sh                <- JOB 4 + Challenge: otomasi penyiapan & smoke test
│  ├─ teardown.sh             <- Challenge: pembersihan aman dengan validasi path
│  └─ .gitignore              <- WAJIB ada sebelum git add pertama
├─ dokumen/
│  ├─ LEMBAR-KERJA.md         <- semua tabel pengukuran
│  ├─ VSM.md                  <- JOB 3: value stream map + flow efficiency
│  └─ LAPORAN-PRAKTIKUM.md    <- kerangka 5 soal analisis
└─ .github/workflows/ci.yml   <- bonus: pipeline CI (shellcheck + smoke test)
```

---

---

# Pembagian Peran (GJRRR & poladoogultom-oss)

| Peran JOB | 🟦 Gandhi (kamu, `GJRRR`) | 🟥 Brian (teman, `poladoogultom-oss`) |
|---|---|---|
| **JOB 2 — Silo** | Operations (Ops) | Developer (Dev) |
| **JOB 3 — VSM** | Kerjakan berdua | Kerjakan berdua |
| **JOB 4 — Otomasi** | **Developer (Dev)** | **Operations (Ops)** |
| **JOB 5 — SDLC & Postmortem** | Berdua | Berdua |

> Aturan: di JOB 4 peran **ditukar**. Identitas git masing-masing:
> - Gandhi: `user.name "Gandhi"`, `user.email "4332511050.Muhammad@students.polibatam.ac.id"`
> - Brian: `user.name "Brian Polido Gultom"`, `user.email "4332511660@students.polibatam.ac.id"`

---

# Setup Repository & Kolaborasi

File paket ini saat ini ada di laptop Gandhi (Windows host). Alur ke Ubuntu:

**1. Gandhi buat repo private di GitHub**
- Login `GJRRR` → New repository → nama `praktikum-devops-m01` → ✅ Private → jangan centang README.

**2. Gandhi push dari Windows host (Git Bash)**
```bash
cd "E:/devops/w1/drive-download-20260920T050145Z-1-001/praktikum-devops/minggu-01"
git init
git config user.name "Gandhi"
git config user.email "4332511050.Muhammad@students.polibatam.ac.id"
git add .
git commit -m "feat: otomasi deployment manual -> setup.sh (Minggu 1)"
git branch -M main
git remote add origin https://github.com/GJRRR/praktikum-devops-m01.git
git push -u origin main
```
> Password biasa tidak dipakai → pakai **Personal Access Token** (GitHub → Settings → Developer settings → PAT, scope `repo`).

**3. Tambah collaborator**
Repo → Settings → Collaborators → invite `poladoogultom-oss` + dosen `antoni@polibatam.ac.id` (harus punya akun GitHub).

**4. Keduanya clone di Ubuntu**
```bash
git clone https://github.com/GJRRR/praktikum-devops-m01.git
cd praktikum-devops-m01
chmod +x 00-check-env.sh simulasi-serah-terima.sh app-sentra/setup.sh app-sentra/teardown.sh
```

---

# Alur Lengkap Berdua: JOB 1 → 5 + Challenge

## Fase 0 — Clone & persiapan (keduanya, di mesin masing-masing)
```bash
git clone https://github.com/GJRRR/praktikum-devops-m01.git
cd praktikum-devops-m01
chmod +x 00-check-env.sh simulasi-serah-terima.sh app-sentra/setup.sh app-sentra/teardown.sh
```
Isi `dokumen/LEMBAR-KERJA.md` bagian identitas kelompok (nama/NIM GitHub masing-masing).

## Fase 1 — JOB 1: Verifikasi Lingkungan (masing-masing)
```bash
./00-check-env.sh
# bila ada yang kurang:
sudo apt update && sudo apt install -y git python3 python3-pip python3-venv curl
git config --global user.name  "Gandhi"        # Brian: "Brian Polido Gultom"
git config --global user.email "4332511050.Muhammad@students.polibatam.ac.id"  # Brian: 4332511660@students.polibatam.ac.id
git config --global init.defaultBranch main
```
📝 Isi **tabel JOB 1** di `dokumen/LEMBAR-KERJA.md` + jawaban observasi. Lampiran: `00-environment-check.log`.

## Fase 2 — JOB 2: Simulasi Silo (🟥 Brian = Dev, 🟦 Gandhi = Ops)

**🟥 Brian (Dev):** kemas serah-terima yang sengaja buruk, lalu serahkan.
```bash
cd app-sentra
./simulasi-serah-terima.sh          # buat folder ../serah-terima (hanya src/ + HANDOVER.md, TANPA requirements.txt)
# catat WAKTU MULAI penyerahan
git add serah-terima && git commit -m "chore: paket serah-terima (JOB 2)" && git push
```

**🟦 Gandhi (Ops):** terima, jalankan TANPA bikin venv, catat kegagalan (jangan tanya lisan).
```bash
git pull
mkdir -p ~/praktikum-devops-ops && cd ~/praktikum-devops-ops
cp -r praktikum-devops-m01/serah-terima . && cd serah-terima
python3 src/app.py                  # GAGAL: ModuleNotFoundError: No module named 'flask'
```
📝 Isi **tabel JOB 2** (waktu mulai/selesai, Lead Time, jumlah kegagalan, pertanyaan) + screenshot galat.

## Fase 3 — JOB 3: Value Stream Mapping (berdua)
📝 Isi `dokumen/VSM.md`: 6 aktivitas → PT, WT, %C/A → hitung
`Flow Efficiency = ΣPT / (ΣPT+ΣWT) × 100%` → tandai bottleneck (sasaran otomasi JOB 4).
Lampiran: tabel VSM terisi.

## Fase 4 — JOB 4: Otomasi (SWAP → 🟦 Gandhi = Dev, 🟥 Brian = Ops)

**🟦 Gandhi (Dev):** siapkan artefak & jalankan setup.sh sebagai bukti.
```bash
cd app-sentra
printf "flask==3.0.3\n" > requirements.txt     # pastikan terkunci
./setup.sh --check                            # validasi prasyarat, exit 0
./setup.sh                                    # venv + deps + health check SUKSES
# screenshot output "SUKSES: aplikasi sehat"
git add setup.sh teardown.sh .gitignore requirements.txt
git commit -m "feat: otomasi deployment menggantikan prosedur manual (JOB 4)"
git push
```

**🟥 Brian (Ops):** tarik & jalankan di mesinnya, catat waktu.
```bash
git pull
cd app-sentra && ./setup.sh
```
📝 Isi **tabel perbandingan JOB 4** (Lead Time, langkah manual, kegagalan, komunikasi Dev↔Ops).
Screenshot `./setup.sh` sukses dari mesin Brian.

## Fase 5 — JOB 5: SDLC & Blameless Postmortem (berdua)
1. GitHub → **Projects** → 2 board:
   - **Waterfall**: Requirement → Design → Implementation → Testing → Deployment
   - **DevOps Flow**: Backlog → In Progress (WIP 2) → Review → Deployed → Monitored
2. Simulasikan perpindahan kartu, catat kolom tempat kartu tertahan paling lama.
3. 📝 Isi `POSTMORTEM.md` (blameless, **tanpa nama individu**).
```bash
git add POSTMORTEM.md && git commit -m "docs: blameless postmortem insiden deployment manual" && git push
```

## Fase 6 — Challenge: Zero-Touch Verification (bonus +10, berdua)
```bash
sudo apt install -y shellcheck
cd app-sentra
shellcheck setup.sh teardown.sh && echo "SHELLCHECK BERSIH"   # screenshot ini wajib
./setup.sh --check          # exit 0/1 tanpa menjalankan app
./setup.sh                  # uji deteksi port bentrok & retry health check
./teardown.sh --purge       # bersihkan .venv (path divalidasi)
git commit -m "feat(challenge): zero-touch verification" && git push
```

## Fase 7 — Laporan & Pengumpulan
1. 📝 Isi `dokumen/LAPORAN-PRAKTIKUM.md` (5 soal analisis) dengan **angka hasil kalian sendiri**.
2. Export ke PDF `M01_4332511050_Gandhi.pdf` (template Polibatam).
3. Lampirkan: link repo (private + collaborator dosen), screenshot `./setup.sh`, tabel JOB 3 & 4, `POSTMORTEM.md`.
4. Kumpulkan **H+3 pukul 23.59 WIB**.

> ⚠️ **Plagiarisme:** riwayat commit identik antar kelompok = nilai 0 untuk berdua. Tulis analisis dengan kalimat kalian sendiri.

---

## Cara pakai (kerjakan berurutan)

### Persiapan sekali — salin ke WSL2/Ubuntu

```bash
mkdir -p ~/praktikum-devops
# salin folder minggu-01 ini ke ~/praktikum-devops/
cd ~/praktikum-devops/minggu-01
chmod +x 00-check-env.sh simulasi-serah-terima.sh app-sentra/setup.sh app-sentra/teardown.sh
```

> **Peringatan K3 (dari modul, wajib dipatuhi):**  
> jangan `curl <url> | sudo bash` · jangan `chmod 777` (pakai `chmod +x`) ·  
> jangan commit kredensial/`.env` · pakai Personal Access Token saat push, bukan password.

---

### JOB 1 — Verifikasi lingkungan (± 15 menit)

```bash
./00-check-env.sh
```

Bila ada yang belum terpasang:

```bash
sudo apt update && sudo apt install -y git python3 python3-pip python3-venv curl
git config --global user.name  "Nama Lengkap"
git config --global user.email "nim@students.polibatam.ac.id"
git config --global init.defaultBranch main
```

Bukti: `00-environment-check.log`. Isi tabel JOB 1 di `dokumen/LEMBAR-KERJA.md`.

---

### JOB 2 — Simulasi silo / Wall of Confusion (± 30 menit)

**Mahasiswa A (Developer):**

```bash
cd ~/praktikum-devops/minggu-01
./simulasi-serah-terima.sh
```

Paket `serah-terima/` hanya berisi `src/` + `HANDOVER.md` — `requirements.txt` sengaja tidak ikut.

**Mahasiswa B (Operations):**

```bash
mkdir -p ~/praktikum-ops && cd ~/praktikum-ops
cp -r ~/praktikum-devops/minggu-01/serah-terima .
cd serah-terima
python3 src/app.py        # catat galat yang muncul
```

> Dilarang bertanya lisan. Jika 15 menit habis, nyatakan gagal.  
> Catat waktu mulai/selesai, jumlah kegagalan, dan pesan galat ke `dokumen/LEMBAR-KERJA.md`.

---

### JOB 3 — Value Stream Mapping (± 15 menit)

Isi `dokumen/VSM.md`: PT, WT, dan %C/A tiap aktivitas, lalu hitung Flow Efficiency.  
Tandai aktivitas dengan %C/A terendah → itulah sasaran otomasi JOB 4.

---

### JOB 4 — Otomasi: The First Way (± 30 menit)

Peran ditukar. Mahasiswa B sekarang Developer.

```bash
cd ~/praktikum-devops/minggu-01/app-sentra
./setup.sh --check        # validasi prasyarat saja, exit 0 = siap
./setup.sh                # pasang dependensi, jalankan, smoke test otomatis
curl -s http://127.0.0.1:5000/ | head -c 200; echo
```

Yang dilakukan skrip secara otomatis, menggantikan seluruh HANDOVER.md:

| Fitur                | Perilaku                                                         |
| -------------------- | ---------------------------------------------------------------- |
| `set -euo pipefail`  | fail-fast: berhenti di langkah pertama yang gagal                |
| Idempoten            | `.venv` dipakai ulang bila sudah ada                             |
| Deteksi port bentrok | port 5000 terpakai → pindah otomatis ke port bebas berikutnya    |
| Retry health check   | 5 percobaan × 2 detik sebelum dinyatakan gagal                   |
| `--check`            | hanya validasi lingkungan (exit 0/1), tidak menjalankan aplikasi |
| `--stop`             | menghentikan aplikasi lewat pid file                             |
| Log                  | semua keluaran aplikasi ke `app.log`                             |

Bersihkan:

```bash
./teardown.sh           # hentikan aplikasi
./teardown.sh --purge   # hentikan + hapus .venv (path divalidasi 3 lapis)
```

Lengkapi `.gitignore` **sebelum** `git add`, lalu:

```bash
cd ~/praktikum-devops/minggu-01
git init
git add .
git status      # pastikan .venv/ dan *.log TIDAK muncul
git commit -m "feat: otomasi deployment menggantikan prosedur manual (Minggu 1)"
git branch -M main
git remote add origin https://github.com/<username>/praktikum-devops-m01.git
git push -u origin main
```

Isi tabel perbandingan JOB 4 di `dokumen/LEMBAR-KERJA.md`.

---

### JOB 5 — Simulasi SDLC & Blameless Postmortem (± 10 menit)

1. GitHub → tab **Projects** → buat dua board:
   - **Waterfall**: Requirement → Design → Implementation → Testing → Deployment  
     (aturan: kartu baru boleh pindah kalau semua kartu di kolom sebelumnya selesai)
   - **DevOps Flow**: Backlog → In Progress (WIP limit 2) → Review → Deployed → Monitored
2. Masukkan 5 aktivitas JOB 1–4 sebagai kartu, jalankan simulasi, catat kolom tempat kartu tertahan paling lama.
3. Lengkapi `POSTMORTEM.md` (tanpa menyebut nama individu), lalu:

```bash
git add POSTMORTEM.md && git commit -m "docs: blameless postmortem insiden deployment manual"
git push
```

---

### Challenge — Zero-Touch Verification (bonus +10)

Semua butir sudah diimplementasikan. Buktikan:

```bash
sudo apt install -y shellcheck
cd app-sentra && shellcheck setup.sh teardown.sh && echo "SHELLCHECK BERSIH"
```

Butir challenge:

| # | Ketentuan                                                                                     | Status                                                                               |
| - | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 1 | `./setup.sh --check` validasi prasyarat, exit 0/1, tanpa menjalankan aplikasi                 | ✅                                                                                    |
| 2 | Deteksi port bentrok → cari port bebas berikutnya & laporkan                                  | ✅                                                                                    |
| 3 | Retry health check maks 5× jeda 2 detik                                                       | ✅                                                                                    |
| 4 | `teardown.sh` hentikan aplikasi + bersihkan `.venv` aman (validasi path, tanpa `rm -rf` buta) | ✅                                                                                    |
| 5 | `shellcheck setup.sh teardown.sh` bersih                                                      | ✅ sudah diuji: **0 peringatan** — tetap jalankan & lampirkan tangkapan layar sendiri |

Kumpulkan sebagai commit terpisah:

```bash
git commit -m "feat(challenge): zero-touch verification"
```

---

## Sudah diuji

Skrip dalam paket ini sudah dijalankan dan diverifikasi:

| Pengujian                                                                  | Hasil                                                         |
| -------------------------------------------------------------------------- | ------------------------------------------------------------- |
| `bash -n` pada keempat skrip                                               | lolos                                                         |
| `./setup.sh --check` saat siap                                             | exit 0                                                        |
| `./setup.sh --check` saat `requirements.txt` dihapus                       | exit 1 (fail-fast berjalan)                                   |
| `./setup.sh` dari nol                                                      | venv + dependensi + health check **SUKSES** di percobaan ke-1 |
| `./setup.sh` kedua saat port 5000 terpakai                                 | otomatis pindah ke **5001**                                   |
| `./teardown.sh --purge`                                                    | `.venv` terhapus, path lolos 3 lapis validasi                 |
| `shellcheck setup.sh teardown.sh 00-check-env.sh simulasi-serah-terima.sh` | **0 peringatan**                                              |

**Catatan lingkungan:** modul mewajibkan Linux/WSL2. Skrip ditulis agar tetap toleran bila  
terpaksa dijalankan di Git Bash Windows (mendeteksi `.venv/bin/` vs `.venv/Scripts/`,  
dan selalu memanggil Python dengan path relatif). Tetap kerjakan praktikum di WSL2  
sesuai ketentuan modul.

## Checklist pengumpulan

- [ ] `00-environment-check.log`
- [ ] Tangkapan layar galat Ops (JOB 2) dan `./setup.sh` sukses (JOB 4)
- [ ] `dokumen/VSM.md` + perhitungan Flow Efficiency
- [ ] `POSTMORTEM.md`
- [ ] Repo GitHub **private**, collaborator `antoni@polibatam.ac.id` + pasangan
- [ ] Laporan PDF `M01_NIM_NamaLengkap.pdf` — batas H+3 pukul 23.59 WIB

> **Ingat aturan plagiarisme modul:** riwayat commit identik antar kelompok = nilai 0 untuk kedua pihak.  
> Isi semua tabel dengan data kalian sendiri, dan tulis analisis dengan kalimat kalian sendiri.
