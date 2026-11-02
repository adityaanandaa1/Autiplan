# AutiPlan — instruksi untuk Claude Code

AutiPlan adalah aplikasi penjadwalan untuk anak autis (Rafi, 12 tahun) dan pengasuhnya (Bu Sari). Proyek ini adalah prototipe tugas mata kuliah Interaksi Manusia dan Komputer (IMK). Kodenya ditulis dengan Flutter dan Dart.

## Baca dulu, sebelum menulis kode
1. `docs/HANDOFF.md` — spesifikasi lengkap: data, aturan bisnis, setiap layar, alur, dan rencana kerja per tahap. Ini sumber kebenaran utama.
2. `design/README.md` — cara membaca desain. Gambar layar ada di `design/screens/`.
3. `docs/DECISIONS.md` — catatan keputusan. Buat file ini kalau belum ada, dan tulis di sana setiap kali kamu harus memilih sesuatu yang tidak tertulis di HANDOFF.md.

## Aturan kerja
- Kerjakan per tahap sesuai bagian "Rencana kerja" di HANDOFF.md. Selesaikan satu tahap, jalankan `flutter analyze` dan `flutter test`, lalu berhenti dan laporkan sebelum lanjut ke tahap berikutnya.
- Jangan menebak. Kalau desain (gambar/Figma) dan HANDOFF.md berbeda, ikuti HANDOFF.md dan catat perbedaannya di `docs/DECISIONS.md`. Kalau keduanya tidak menjawab, tanyakan ke pengguna.
- Semua teks yang tampil di aplikasi berbahasa Indonesia, persis seperti di HANDOFF.md. Nama kelas, variabel, dan file memakai bahasa Inggris.
- Jangan pernah menaruh warna, ukuran huruf, atau jarak langsung di widget. Semua lewat token di `lib/core/theme/`.
- Sisi anak: tidak boleh ada tombol tambah, edit, hapus, atau saran. Tidak ada warna merah, hitam pekat, gradien, animasi pantul, suara, atau getar.
- Jangan menambah fitur atau paket di luar HANDOFF.md tanpa bertanya.
- Hemat panggilan Figma MCP (kuota akun Figma pengguna sangat terbatas, paket Starter). Pakai gambar di `design/screens/` dan token di HANDOFF.md lebih dulu. Panggil Figma hanya untuk detail yang benar-benar tidak terlihat, dan sebutkan dulu ke pengguna sebelum memanggil.

## Perintah
- Menjalankan: `flutter run`
- Analisis: `flutter analyze`
- Tes: `flutter test`
- Format: `dart format .`
