# Cara membaca desain AutiPlan

Urutan sumber (pakai yang paling atas dulu):
1. **Token dan spesifikasi di `docs/HANDOFF.md`** (warna, ukuran huruf, jarak, sudut, teks). Ini selalu menang kalau ada perbedaan.
2. **Gambar layar di folder ini** (`design/screens/`). Buka gambarnya untuk melihat tata letak. Ukuran gambar 2× (780×1688 px untuk layar 390×844), jadi bagi semua ukuran piksel di gambar dengan 2.
3. **Figma lewat MCP**, hanya untuk detail yang tidak terlihat di gambar. Kuotanya sangat terbatas, jadi tanya pengguna dulu.

## File Figma
- File key: `yqSO2up8YLcWjsaHFDsAn3`
- Halaman: `Page 1`
- Section **"v2 · Orang Tua (minimal)"** (`34:68`) — layar orang tua yang dipakai.
- Section **"v2 · Komponen"** (`31:18`) — komponen dan variabel warna.
- Section **"Anak v2"** — layar anak yang dipakai (dibuat pengguna dari Stitch; isi node ID di tabel bawah setelah dicek).
- Section lain (frame lama "OT-01 Beranda Pengasuh", section "Anak" lama, dan frame tanpa awalan) adalah versi lama. **Jangan dipakai sebagai acuan.**

## Daftar gambar yang harus ada di `design/screens/`
Pengguna mengekspor setiap frame dari Figma (pilih frame → panel kanan Export → PNG 2x → Export) dan menyimpannya dengan nama persis seperti ini.

### Orang tua
| File | Frame Figma | Node ID |
|---|---|---|
| `OT-01_beranda.png` | OT-01 v2 · Beranda | 34:69 |
| `OT-02_beranda_belum-dibuka.png` | OT-02 v2 · Beranda – perubahan belum dibuka | 34:154 |
| `OT-03_beranda_sudah-dilihat.png` | OT-03 v2 · Beranda – sudah dilihat anak | 34:244 |
| `OT-04_jadwal_rafi.png` | OT-04 v2 · Jadwal Rafi | 34:334 |
| `OT-05_jadwal_perubahan-terkirim.png` | OT-05 v2 · Jadwal – perubahan terkirim | 35:354 |
| `OT-06_jadwal_atalia.png` | OT-06 v2 · Jadwal Atalia | 35:515 |
| `OT-07_jadwal_hari-kosong.png` | OT-07 v2 · Jadwal – hari kosong | 35:648 |
| `OT-08_tambah-jadwal.png` | OT-08 v2 · Tambah jadwal | 35:1092 |
| `OT-09_jadwal_setelah-tambah.png` | OT-09 v2 · Jadwal – setelah tambah | 35:760 |
| `OT-10_ubah-jadwal_awal.png` | OT-10 v2 · Ubah jadwal – awal | 35:1207 |
| `OT-11_ubah-jadwal_pesan.png` | OT-11 v2 · Ubah jadwal – pesan & pratinjau | 35:1324 |
| `OT-12_konfirmasi-hapus.png` | OT-12 v2 · Konfirmasi hapus | 35:1443 |
| `OT-13_jadwal_setelah-hapus.png` | OT-13 v2 · Jadwal – setelah hapus | 35:941 |
| `OT-14_akun.png` | OT-14 v2 · Akun | 36:1580 |
| `OT-15_notifikasi.png` | OT-15 v2 · Notifikasi | 36:1715 |
| `OT-16_saran.png` | OT-16 v2 · Saran untuk Rafi | 36:1774 |
| `OT-17_detail-saran.png` | OT-17 v2 · Detail saran | 36:1851 |

### Anak
| File | Frame Figma | Node ID |
|---|---|---|
| `A-01_jadwal_ada-perubahan.png` | A-01 Jadwal hari ini – ada perubahan | (isi) |
| `A-02_perubahan-jadwal.png` | A-02 Perubahan jadwal | (isi) |
| `A-03_jadwal_sudah-dimengerti.png` | A-03 Jadwal hari ini – sudah dimengerti | (isi) |
| `A-04_detail_belum-dicentang.png` | A-04 Detail aktivitas – belum dicentang | (isi) |
| `A-05_detail_semua-dicentang.png` | A-05 Detail aktivitas – semua dicentang | (isi) |
| `A-06_berhasil.png` | A-06 Layar berhasil | (isi) |
| `A-07_konfirmasi-darurat.png` | A-07 Konfirmasi panggilan darurat | (isi) |
| `A-08_menelepon.png` | A-08 Sedang menelepon | (isi) |
| `A-09_pilih-tema.png` | A-09 Pilih tema | (isi) |
| `A-10_detail_mode-mandiri.png` | A-10 Detail aktivitas – mode mandiri | (isi) |
| `A-11_jadwal_tema-padang-hijau.png` | A-11 Jadwal hari ini – tema Padang Hijau | (isi) |

Node ID terlihat di URL Figma saat frame dipilih (`node-id=34-69` berarti `34:69`).

## Catatan membaca gambar
- Gambar layar orang tua yang berupa sheet (OT-08, OT-10, OT-11, OT-17) dan dialog (OT-12) memperlihatkan layar di belakangnya dalam keadaan redup. Di Flutter, bagian redup itu **bukan** layar baru: pakai `showModalBottomSheet` / `showDialog` di atas layar Jadwal atau Saran.
- OT-02/OT-03, OT-05, OT-09, OT-13, A-03, A-05, A-11 adalah **kondisi (state)** dari layar yang sama, bukan layar terpisah. Satu widget layar, isinya berubah sesuai data.
- Ikon di desain memakai set **Lucide**. Nama ikon tiap elemen tercantum di HANDOFF.md.
- Kalau gambar anak dari Stitch berbeda dari HANDOFF.md (misalnya urutan kegiatan atau teks), ikuti HANDOFF.md.
