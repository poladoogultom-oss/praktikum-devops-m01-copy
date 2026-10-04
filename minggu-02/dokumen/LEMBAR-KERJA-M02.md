# Lembar Kerja — JS-DVO-02 (Minggu 2)

**Mata Kuliah** : DevOps (RKS305) · **Program Studi** : Rekayasa Keamanan Siber
**Mahasiswa** : Muhammad Gandhi Putra (NIM 4332511050)
**Tanggal praktikum** : 22 September – 28 September 2026 · **Repo GitHub** : <https://github.com/GJRRR/praktikum-devops-m01>
**Topik** : Linux Foundation for DevOps — Shell Scripting, CLI, & Manajemen Sistem

> Semua jawaban observasi di bawah diisi berdasarkan hasil pengamatan nyata di mesin Ubuntu 22.04 (CLI).
> Rubrik menilai kedalaman analisis — jawaban template tanpa bukti tidak akan lulus.

---

## JOB 1 — Struktur Berkas, Kepemilikan, dan Izin Akses

**Observasi 1 — Perbedaan `stat` sebelum & sesudah `chmod`, arti digit 644 & 600**

- `644` = `rw-r--r--` → pemilik (u): r+w = 4+2 = **6**; grup (g): r = **4**; lainnya (o): r = **4**.
- `600` = `rw-------` → pemilik (u): **6**; grup (g): **0**; lainnya (o): **0**.
- Setelah `chmod 600`, **grup dan other kehilangan SELURUH akses** (tadinya bisa membaca lewat 644, sekarang tidak bisa membaca maupun menulis). Hanya pemilik yang tetap bisa membaca & menulis `kredensial-latihan.txt`.
- Ini adalah penerapan *least privilege*: berkas kredensial hanya boleh diakses oleh pemiliknya.

**Observasi 2 — Nilai `umask` & mengapa berkas baru tidak pernah langsung executable**

- `umask` default `022` → berkas baru mendapat `666 − 022 = 644`, direktori `777 − 022 = 755`.
- Bit execute (**x = 1**) tidak pernah muncul pada berkas baru karena mask 666 tidak menyertakan x dan umask 022 juga tidak menambahkannya.
- Dampak ke *least privilege*: berkas yang baru dibuat tidak dapat langsung dieksekusi, sehingga berkas teks/log yang tidak sengaja dibuat tidak bisa dijalankan sebagai program oleh pihak lain — mengurangi vektor eksekusi kode berbahaya.

---

## JOB 2 — Analisis Log Aplikasi dengan Pipeline Teks

**Observasi 1 — Urutan `sort | uniq -c`**

- `uniq -c` hanya meruntuhkan baris **berurutan yang identik**. Tanpa `sort`, baris yang sama tersebar di berbagai posisi tidak akan digabung → hitungan salah (undercount).
- Oleh karena itu data **harus diurutkan dulu** agar semua kemunculan token sama menjadi bertetangga, baru `uniq -c` menghitungnya dengan benar.

**Observasi 2 — Sebaran kode status & endpoint yang gagal**

Berdasarkan `app.log` (500 baris, seed tetap untuk contoh):

| Kode | Jumlah |
|---|---|
| 200 | 200 |
| 404 | 105 |
| 500 | 55 |
| 201 | 52 |
| 301 | 46 |
| 502 | 42 |

Endpoint gagal (≥500): `/static/app.js` 21, `/` 21, `/health` 20, `/api/orders` 20, `/api/users` 15.

- Kegagalan **tersebar merata** di seluruh endpoint (bukan terpusat di satu rute).
- **Implikasi**: penyebabnya bersifat **sistemik** (dependensi bersama, kapasitas, atau satu deploy buruk yang menimpa semua rute), bukan bug pada satu endpoint. Memperbaiki satu rute tidak akan menurunkan CFR — tim harus menelusuri layanan bersama/backend, bukan per-endpoint.

---

## JOB 3 — Proses, Layanan, dan Sumber Daya Sistem

**Observasi 1 — Selisih respons SIGTERM vs SIGKILL**

- `SIGTERM` (kill tanpa opsi) dikirim, aplikasi Flask menutup koneksi & menyimpan state lalu keluar dalam **~1–2 detik**.
- `SIGKILL` (kill -9) **langsung mematikan tanpa kesempatan cleanup** → risiko socket tertinggal, PID file basi, dan (pada tulis berkas) data korup.
- Aturan: selalu coba SIGTERM dulu; hanya gunakan SIGKILL jika setelah beberapa detik tidak respon.

**Observasi 2 — Keluaran `ss -ltn` saat hidup vs mati**

- Saat hidup: ada baris `LISTEN ... 127.0.0.1:5000`.
- Saat dihentikan: **baris tersebut hilang**.
- Diagnosis konflik port: jika port "dianggap kosong" padahal ada proses lain, `ss -ltnp` (dengan `-p`) menampilkan **PID & nama proses** pemilik LISTEN → kita tahu proses mana yang harus dihentikan, bukan menebak.

---

## JOB 4 — Skrip Bash Modular: `sysreport.sh`

### Tabel exit code hasil pengujian

| Perintah | Exit code | Arti |
|---|---|---|
| `./sysreport.sh` | 0 | sehat (disk < ambang) |
| `./sysreport.sh -j` | 0 | sehat, keluaran JSON |
| `./sysreport.sh -d 1` | 2 | melewati ambang (disk ≥ 1%) → status PERINGATAN |
| `./sysreport.sh -d abc` | 1 | galat penggunaan (validasi angka gagal) |
| `./sysreport.sh -z` | 1 | opsi tidak dikenal |
| `./sysreport.sh -h` | 0 | tampilkan bantuan |

**Observasi 1 — Mengapa CI/CD mutlak butuh pembedaan 0 / 1 / 2**

- Runner (GitHub Actions/GitLab CI) hanya membaca *exit code*, bukan tampilan. `0` = hijau/lanjut, non-nol = merah/berhenti.
- Tanpa kode berbeda, pipeline tidak bisa membedakan "sistem tidak sehat tapi skrip jalan" (**2**) dari "pemanggilan salah" (**1**). Jika keduanya 1, insiden sungguhan bisa terlihat sama dengan salah ketik argumen → alert fatigue atau sebaliknya, insiden tertelan.

**Observasi 2 — Peringatan `shellcheck` paling sering muncul**

- Yang sering muncul di skrip mahasiswa: **SC2086** (quote variable), **SC2046** (quote command substitution), **SC2181** (cek `$?` daripada exit status), **SC2155** (declare & assign dipisah).
- Tidak semuanya "berbahaya": SC2086/SC2046 bisa memicu bug nyata bila nilai mengandung spasi/karakter khusus, sedangkan SC2155 lebih ke gaya penulisan. Skrip kita **lolos bersih (0 peringatan)** karena mengikuti Google Shell Style Guide.

---

## JOB 5 — Refaktor `setup.sh` Menjadi Modular

**Observasi — Isi `/tmp/sentra-deploy.log`**

- Versi Minggu 1 hanya memakai `echo`/`printf` ke stderr/stdout → pesan **hilang** begitu terminal ditutup (kecuali di-redirect manual).
- Versi modular (lib `common.sh`) menulis ke `/tmp/sentra-deploy.log` dengan **stempel ISO-8601 + level** (`[INFO]`, `[WARN]`, `[ERROR]`), mis.:
  ```
  2026-09-28T13:00:00+0700 [INFO ] [1/5] Memeriksa prasyarat...
  2026-09-28T13:00:01+0700 [INFO ] [3/5] Menyiapkan virtual environment...
  ```
- Informasi baru: **waktu pasti tiap langkah + tingkat keparahan**. Bila terjadi insiden, kita bisa mengorelasikan kejadian ke menit tertentu dan melihat urutan langkah yang gagal — mempercepat *root-cause analysis* secara drastis. Log juga **di-append** (bukan ditimpa) sehingga beberapa eksekusi terekam berurutan.
