# 🧩 AutiPlan

> **Aplikasi Penjadwalan Visual Ramah Sensorik untuk Anak dengan Autism Spectrum Disorder (ASD) dan Pengasuh (Caregiver)**

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Design Thinking](https://img.shields.io/badge/Design%20Thinking-Prototype%20%26%20Test-orange)](#)
[![License](https://img.shields.io/badge/License-Academic%20Project-green)](#)

---

## 📖 Tentang AutiPlan

Anak dengan spektrum autisme (*Autism Spectrum Disorder* / ASD) memiliki kebutuhan tinggi terhadap prediktabilitas rutinitas harian. Perubahan jadwal yang terjadi secara mendadak sering kali memicu disrupsi kognitif, kebingungan, hingga kecemasan (*anxiety*) dan tantrum. Di sisi lain, orang tua atau pengasuh (*caregiver*) kerap menghadapi tantangan dalam menyusun dan mengomunikasikan perubahan aktivitas tanpa mengejutkan anak.

**AutiPlan** hadir sebagai solusi berbasis *Design Thinking* dan prinsip *Human-Computer Interaction* (HCI/IMK). Aplikasi ini menyediakan sistem penjadwalan visual dua peran (*dual-role*) terintegrasi yang dirancang khusus dengan memperhatikan batasan stimulasi sensorik anak berkebutuhan khusus.

---

## ✨ Fitur Utama

AutiPlan mengintegrasikan dua antarmuka dalam satu ekosistem:

### 1. 👨‍👩‍👧 Sisi Orang Tua / Pengasuh (*Caregiver*)
* **Dashboard & Manajemen Jadwal:** Menyusun, mengubah, dan menghapus jadwal kegiatan harian maupun mingguan dengan navigasi kalender yang intuitif.
* **Jadwal Berulang (*Recurring Activities*):** Mendukung pengaturan kegiatan rutin otomatis berdasarkan hari (Senin–Minggu).
* **Deteksi Bentrok Otomatis (*Conflict Resolution*):** Mendeteksi jadwal yang bertumpukan secara *real-time* dan memberikan rekomendasi slot waktu luang terdekat.
* **Jeda Transisi & Waktu Tenang (*Quiet Time*):** Menganalisis jeda antar-kegiatan (minimal 10 menit) serta menyarankan waktu istirahat tanpa gawai minimal 30 menit sebelum jam tidur.
* **Mesin Saran Cerdas (*Smart Suggestion Engine*):** Merekomendasikan pengisian hari kosong (*empty day*) dan mode mandiri (*independence mode*) saat anak konsisten menyelesaikan kegiatan tepat waktu.
* **Sinkronisasi Multi-Perangkat (Cloud Firestore):** Terhubung langsung dengan HP anak melalui kode pasang (*pairing code*) 6 digit yang aman tanpa perlu login akun yang rumit.
* **Notifikasi Push Instan (FCM):** Menerima notifikasi langsung di ponsel pengasuh ketika anak menekan tombol darurat atau membaca perubahan jadwal.

### 2. 🧒 Sisi Anak (*Child - Rafi, 12 Tahun*)
* **Antarmuka Tenang & Ramah Sensorik (*Calm Palette*):** Dirancang tanpa warna merah tajam, tanpa hitam pekat (*pure black*), tanpa gradien kontras, serta bebas dari animasi pantul atau getaran yang memicu distorsi sensorik.
* **Pemberitahuan Perubahan Lembut ("Dulu ➔ Sekarang"):** Perubahan jadwal disajikan melalui banner komparatif yang menenangkan—bukan berupa *pop-up* mendadak yang mengejutkan.
* **Ceklis Langkah Terurai (*Step-by-Step Checklist*):** Memecah setiap kegiatan menjadi sub-langkah konkret yang dapat dicentang secara mandiri oleh anak.
* **Pengingat Jadwal Lokal (*Local Notifications*):** Menampilkan pengingat otomatis di perangkat sebelum kegiatan dimulai dengan kanal notifikasi tenang tanpa suara yang mengejutkan.
* **Tombol Darurat Satu Sentuhan (*Emergency Button*):** Tombol mengambang (*floating*) di pojok kanan bawah yang langsung menghubungkan anak ke panggilan telepon orang tua saat merasa cemas atau butuh bantuan mendesak.
* **Personalisasi Tema Visual:** Pilihan warna pastel yang menenangkan sesuai preferensi anak.

---

## 📱 Tangkapan Layar Aplikasi

### 👨‍👩‍👧 Mode Demo & Sisi Pengasuh (Caregiver)
| Pilih Peran Demo | Beranda Pengasuh | Manajemen Jadwal | Profil & Akun |
| :---: | :---: | :---: | :---: |
| <img src="screenshots/01_pilih_peran.jpg" width="220" alt="Pilih Peran Demo" /> | <img src="screenshots/02_beranda_orang_tua.jpg" width="220" alt="Beranda Pengasuh" /> | <img src="screenshots/03_jadwal_orang_tua.jpg" width="220" alt="Manajemen Jadwal" /> | <img src="screenshots/04_akun_orang_tua.jpg" width="220" alt="Profil dan Pengaturan" /> |

### 🧒 Sisi Anak (Ramah Sensorik - Rafi)
| Jadwal Hari Ini | Ceklis Langkah Kegiatan | Apresiasi Selesai (Maskot) | Panggilan Darurat Cepat | Personalisasi Tema |
| :---: | :---: | :---: | :---: | :---: |
| <img src="screenshots/05_jadwal_anak.jpg" width="190" alt="Jadwal Hari Ini" /> | <img src="screenshots/06_ceklis_langkah_anak.jpg" width="190" alt="Ceklis Langkah Kegiatan" /> | <img src="screenshots/07_selesai_maskot.jpg" width="190" alt="Apresiasi Maskot" /> | <img src="screenshots/08_panggilan_darurat.jpg" width="190" alt="Panggilan Darurat" /> | <img src="screenshots/09_pilih_tema_anak.jpg" width="190" alt="Pilihan Tema Warna" /> |

---

## 🎨 Prinsip Desain Sensorik (IMK)

Sesuai pedoman desain untuk neurodivergensi:
1. **Prediktabilitas:** Informasi disajikan secara konsisten dengan tata letak horizontal yang mudah dipindai.
2. **Tanpa Distraksi Destruktif:** Sisi anak bersifat *read-only* (tanpa tombol edit/hapus) untuk mencegah salah tekan dan rasa frustrasi.
3. **Satu Aksi Utama per Layar:** Mengurangi beban kognitif (*cognitive load*) anak dalam menentukan tindakan berikutnya.
4. **Tipografi Inklusif:** Menggunakan font **Lexend** (untuk keterbacaan optimal bagi anak) dan **Inter** (antarmuka pengasuh yang bersih).

---

## 🛠️ Arsitektur & Teknologi

* **Aplikasi Mobile (Client):**
  * **Framework:** [Flutter](https://flutter.dev) (Dart 3)
  * **State Management:** [Riverpod](https://riverpod.dev)
  * **Routing & Deep Linking:** [GoRouter](https://pub.dev/packages/go_router) (*StatefulShellRoute* untuk multi-tab & session guard)
  * **Desain & Ikonografi:** [Lucide Icons](https://lucide.dev)
  * **Notifikasi Lokal:** `flutter_local_notifications` dengan dukungan zona waktu (*timezone*) dan Java 8 Desugaring
* **Layanan Cloud & Backend:**
  * **Database & Aturan Akses:** [Firebase Firestore](https://firebase.google.com/docs/firestore) dengan *family-scoped security rules*
  * **Push Notification:** [Firebase Cloud Messaging (FCM HTTP v1)](https://firebase.google.com/docs/cloud-messaging)
  * **Edge API & Rate Limiting:** [Cloudflare Workers](https://workers.cloudflare.com/) (TypeScript) & Cloudflare KV
* **Kualitas Kode & Aksesibilitas:**
  * **433 Tes Otomatis (Flutter):** Meliputi unit test aturan jadwal, suggestion engine, sinkronisasi, dan tes widget.
  * **77 Tes Backend (Vitest):** Pengujian menyeluruh untuk API pairing dan push dispatch.
  * **Audit Aksesibilitas Penuh:** 96+ pengujian aksesibilitas mencakup kontras warna WCAG, target sentuh (min. 48dp), dan dukungan pembaca layar (*Semantics / TalkBack*).

---

## 📂 Struktur Direktori

```text
Autiplan/
├── lib/
│   ├── core/                    # Token desain (warna, tipografi), router, clock, & komponen UI
│   ├── data/                    # Models, repository (lokal & Firestore), sync, push, reminder, & providers
│   ├── domain/                  # Aturan jadwal, deteksi bentrok, & mesin saran otomatis
│   ├── features/
│   │   ├── caregiver/           # Layar orang tua (Beranda, Jadwal mingguan, Notifikasi, Akun)
│   │   ├── child/               # Layar anak (Jadwal visual, Ceklis langkah, Panggilan darurat, Tema)
│   │   ├── pairing/             # Alur penghubung perangkat (Pairing code 6 digit)
│   │   └── role_picker/         # Layar pilih peran & mode demo
│   ├── app.dart                 # Konfigurasi MaterialApp, tema, & session watcher
│   └── main.dart                # Entry point aplikasi Flutter
├── worker/                      # Backend Cloudflare Worker (TypeScript)
│   ├── src/                     # Endpoint /pair, /notify, & integrasi Firestore FCM
│   └── test/                    # Pengujian unit backend (Vitest)
├── test/                        # 433 unit, widget, dan accessibility tests
└── screenshots/                 # Tangkapan layar aplikasi untuk README
```

---

## 🚀 Memulai (Getting Started)

### Prasyarat
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi stable terbaru)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio / VS Code dengan ekstensi Flutter & Dart

### Instalasi & Menjalankan Aplikasi

1. **Clone repositori ini:**
   ```bash
   git clone https://github.com/username/autiplan.git
   cd autiplan
   ```

2. **Pasang dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan analisis kode:**
   ```bash
   flutter analyze
   ```

4. **Jalankan pengujian unit & widget:**
   ```bash
   flutter test
   ```

5. **Jalankan aplikasi di emulator atau perangkat fisik:**
   ```bash
   flutter run
   ```

---

## 📊 Hasil Uji Coba Prototipe

Berdasarkan pengujian lapangan (*Usability Testing*) pada mata kuliah **Manajemen Inovasi Pendidikan / IMK**, aplikasi memperoleh tingkat kelayakan keseluruhan sebesar **78,3% (Kategori Baik)** dengan rincian:
* **Isi / Materi:** `86,7%` (Sangat Baik)
* **Kemanfaatan:** `80,0%` (Baik)
* **Kesesuaian Kebutuhan:** `80,0%` (Baik)
* **Keterbacaan Teks & Ikon:** `80,0%` (Baik)
* **Desain Tampilan Sensorik:** `80,0%` (Baik)
* **Kemenarikan Maskot & Tema:** `80,0%` (Baik)
* **Kemudahan Penggunaan:** `73,3%` (Baik)
* **Kepraktisan:** `66,7%` (Baik)

---

## 👥 Tim Pengembang (Kelompok 8)

Proyek ini disusun untuk memenuhi tugas mata kuliah **Manajemen Inovasi**, Program Studi Pendidikan Teknik Informatika / Ilmu Komputer, Universitas Negeri Malang (Offering G6 2026):

| No | Nama | NIM | Peran Utama |
|:--:|---|:--:|---|
| 1 | **Asyam Sakhi Maulana** | `240535600363` | Ketua Tim & Product Lead |
| 2 | **Aditya Ananda Kasi** | `240535606063` | Lead Developer |
| 3 | **Zainur Rohman** | `250611602556` | Fasilitator Pengujian Pengguna |
| 4 | **Muchammad Zainuddin** | `250771623553` | Koordinator Uji Coba |
| 5 | **Martinoes Cristian Saputra** | `250771602183` | Penyusun Instrumen & Analisis Data |

**Dosen Pengampu:** Dr. M. Luthfi Oktarianto, M.Pd., MCE.

---

<p align="center">
  2026
</p>
