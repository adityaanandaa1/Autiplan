# AutiPlan — Dokumen Serah Terima (Flutter)

Versi 1 · 31 Oktober 2026
Dokumen ini adalah sumber kebenaran untuk membangun aplikasi AutiPlan dengan Flutter. Kalau ada yang tidak tertulis di sini, tanyakan atau catat keputusannya di `docs/DECISIONS.md`.

---

## Daftar isi
1. Produk dan pengguna
2. Ruang lingkup prototipe
3. Teknologi dan struktur proyek
4. Token desain
5. Komponen yang dipakai ulang
6. Model data
7. Data awal (seed) dan jam demo
8. Aturan bisnis
9. Mesin saran
10. Navigasi dan rute
11. Spesifikasi layar orang tua (OT-01 s.d. OT-17)
12. Spesifikasi layar anak (A-01 s.d. A-11)
13. Alur utama dari ujung ke ujung
14. Aksesibilitas dan aturan perilaku
15. Rencana kerja per tahap
16. Tes yang wajib ada
17. Hal yang sengaja belum dibuat

---

## 1. Produk dan pengguna

**Masalah:** anak autis cenderung cemas ketika jadwal harian berubah mendadak. Orang tua butuh cara mengatur jadwal dan memberi tahu perubahan dengan tenang.

**Dua peran dalam satu sistem data:**

| Peran | Siapa | Bisa apa |
|---|---|---|
| Orang tua (pengasuh) | Bu Sari, 38 tahun, mengurus dua anak | Melihat, menambah, mengubah, menghapus jadwal. Mengirim pesan perubahan ke anak. Melihat status apakah anak sudah membaca perubahan. Menerima saran kegiatan. Mengatur profil anak dan pengaturan. |
| Anak | Rafi, 12 tahun, autisme ringan–sedang | **Hanya melihat** jadwal hari ini. Membaca perubahan dalam format Dulu → Sekarang. Mencentang langkah kegiatan dan menandai selesai. Mengganti tema warna. Menelepon pengasuh dalam keadaan darurat. |

Anak kedua, **Atalia (9 tahun)**, hanya muncul di sisi orang tua untuk menunjukkan fitur ganti anak. Tidak ada layar anak untuk Atalia di prototipe ini.

**Prinsip yang tidak boleh dilanggar:**
1. Anak tidak boleh dikejutkan. Perubahan selalu disampaikan dengan banner tenang di atas daftar, bukan pop-up.
2. Sisi anak hanya-lihat. Tidak ada tombol tambah/ubah/hapus, tidak ada saran.
3. Saran hanya untuk orang tua, tidak pernah otomatis masuk ke jadwal.
4. Satu tombol utama per layar.

---

## 2. Ruang lingkup prototipe

**Termasuk:**
- Satu aplikasi Flutter (target utama Android; iOS boleh jalan tapi tidak wajib dites).
- Layar **Pilih peran** saat aplikasi dibuka (untuk demo), lalu masuk ke sisi orang tua atau anak.
- Data disimpan **lokal di perangkat** (satu perangkat dipakai untuk mendemokan kedua peran). Perubahan yang dikirim orang tua langsung terlihat saat beralih ke peran anak, sehingga mensimulasikan sinkronisasi.
- Tombol demo untuk berganti peran tanpa menutup aplikasi (lihat 10.3).
- Jam aplikasi dikunci ke **Jumat, 1 Mei 2026, 16.00** dalam mode demo (lihat bagian 7), supaya status "Sekarang/Selesai" sama dengan desain.
- Panggilan darurat membuka aplikasi telepon dengan `url_launcher` (`tel:`).

**Tidak termasuk (jangan dibuat):** login, server, sinkronisasi antar-perangkat, notifikasi push sungguhan, pengingat terjadwal sungguhan, AI. Arsitektur harus memungkinkan hal-hal ini ditambahkan nanti (lihat repository di bagian 3).

---

## 3. Teknologi dan struktur proyek

### 3.1 Paket
Pakai Flutter stable terbaru dan Dart 3. Paket yang diizinkan (cek versi terbaru di pub.dev saat memasang):

| Paket | Fungsi |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigasi dan rute |
| `shared_preferences` | Menyimpan seluruh data sebagai JSON |
| `intl` | Format tanggal Bahasa Indonesia (`id_ID`) |
| `url_launcher` | Membuka telepon (`tel:`) |
| `lucide_icons_flutter` | Ikon Lucide sesuai desain. Kalau paket ini bermasalah, pakai paket Lucide lain dan catat di DECISIONS.md. Jangan mengganti ke Material Icons. |
| `uuid` | ID data |
| `flutter_test` (bawaan) | Tes |

Font **Inter** (orang tua) dan **Lexend** (anak) dibundel sebagai aset di `assets/fonts/` (unduh file TTF dari fonts.google.com: Inter Regular/Medium/SemiBold, Lexend Regular/Medium/SemiBold). Jangan mengambil font dari internet saat aplikasi berjalan.

### 3.2 Struktur folder
```
lib/
  main.dart
  app.dart                      # MaterialApp.router, tema, lokal id_ID
  core/
    theme/                      # token warna, tipografi, jarak, ThemeExtension
    clock.dart                  # Clock yang bisa dikunci (mode demo)
    router.dart
    widgets/                    # komponen yang dipakai ulang (bagian 5)
  data/
    models/                     # Child, Activity, ChangeNotice, dst.
    seed.dart                   # data awal (bagian 7)
    repository.dart             # interface AutiPlanRepository
    local_repository.dart       # implementasi shared_preferences
  domain/
    schedule_rules.dart         # status, progres, bentrok, jeda
    suggestion_engine.dart      # mesin saran (bagian 9)
  features/
    role_picker/
    caregiver/                  # beranda, jadwal, form, akun, notifikasi, saran
    child/                      # jadwal anak, perubahan, detail, berhasil, darurat, tema
test/
```
Semua logika aturan ada di `domain/` sebagai fungsi Dart murni (tanpa Flutter) supaya mudah dites.

### 3.3 Repository
Buat interface `AutiPlanRepository` (baca seluruh state, simpan seluruh state). Implementasi pertama: `LocalRepository` yang menyimpan satu JSON di `shared_preferences`. Ada tombol **"Reset data demo"** di Akun (bagian 11) yang mengembalikan data ke seed.

---

## 4. Token desain

Buat semua token ini di `lib/core/theme/`. Jangan ada nilai mentah di widget.

### 4.1 Warna orang tua
| Token | Hex | Dipakai untuk |
|---|---|---|
| `latar` | #F6F7F9 | Latar layar |
| `permukaan` | #FFFFFF | Kartu, sheet, nav bawah |
| `utama` | #3A6EA8 | Tombol utama, tab aktif, tanggal terpilih, tautan |
| `utamaLembut` | #E5EDF7 | Segmen terpilih, ubin ikon kegiatan "sekarang", pil "Diubah" |
| `teks` | #2F3A45 | Teks utama (jangan pernah #000000) |
| `teksSekunder` | #6B7684 | Jam, label, keterangan, ikon biasa |
| `garis` | #E4E8EC | Garis pemisah, tepi kartu/segmen, lintasan progres |
| `sukses` | #4F8F6A | Ikon selesai, isi progres |
| `suksesLembut` | #E3F0E8 | Latar pil/ubin sukses |
| `bahaya` | #B5524D | Hanya untuk tombol dan ikon hapus |
| `bahayaLembut` | #F6E4E3 | Latar ikon hapus |
| `saranLembut` | #FAF3EC | Latar kartu saran |
| `saranTeks` | #8A5A3C | Label dan ikon saran |
| `anakLembut` | #DCEDF0 | Latar ubin ikon kegiatan biasa |
| `anakAksen` | #6FA3B0 | Titik penanda hari yang punya kegiatan |

### 4.2 Warna anak (3 tema)
Tema tersimpan per anak. Bawaan: Laut Tenang.

| Token | Laut Tenang | Padang Hijau | Pagi Hangat |
|---|---|---|---|
| `anakLatar` | #EEF5F6 | #F1F5EC | #FAF3EC |
| `anakAksen` | #6FA3B0 | #89AE78 | #D2A07F |
| `anakAksenLembut` | #DCEDF0 | #E1EDD8 | #F5E4D7 |
| `anakAksenKuat` | #3F6F7A | #4E6E40 | #8A5A3C |

Teks anak memakai `teks` (#2F3A45) dan `teksSekunder` (#6B7684). Kartu anak putih (#FFFFFF). Implementasikan sebagai `ThemeExtension<ChildPalette>` dengan tiga instance.

### 4.3 Tipografi
**Orang tua — Inter**
| Gaya | Ukuran / berat | Dipakai |
|---|---|---|
| judulHeader | 20 / SemiBold | Judul di header |
| sapaan | 22 / SemiBold | "Selamat sore, Bu Sari" |
| judulSheet | 18 / SemiBold | Judul sheet dan dialog |
| judulKartu | 17 / SemiBold | Nama kegiatan di kartu Sekarang |
| isi | 15 / Regular | Isi umum, nilai kolom |
| judulBaris | 15 / SemiBold | Nama kegiatan di daftar |
| kecil | 14 / Regular | Teks pendukung, isi kartu saran (tinggi baris 20) |
| meta | 13 / Medium | Label kolom, label bagian, jam di daftar |
| mikro | 12 / SemiBold | Pil, label "SEKARANG · RAFI", label tab |

**Anak — Lexend**, tinggi baris 140%
| Gaya | Ukuran / berat | Dipakai |
|---|---|---|
| sapaanAnak | 26 / SemiBold | "Halo, Rafi!", "Kamu berhasil!" |
| judulAnak | 22 / SemiBold | Judul header |
| kegiatanAnak | 20 / SemiBold | Nama kegiatan di kartu |
| isiAnak | 17 / Regular | Langkah, alasan perubahan, tombol (SemiBold) |
| sekunderAnak | 15–16 / Regular | Tanggal, teks bantu |
| jamAnak | 14 / Medium | Jam di bawah ikon |
| labelAnak | 12–13 / SemiBold | "SEKARANG", "BARU BERUBAH", "Dulu", "Sekarang" |

Hormati pengaturan ukuran teks sistem (jangan mengunci `textScaler`).

### 4.4 Jarak dan sudut
- Kisi 4/8. Padding sisi layar: orang tua 16, anak 20.
- Jarak antar-bagian: orang tua 12–20, anak 12–16.
- Sudut: kartu orang tua 16, kolom isian 12, pil 12, ubin ikon 10 (ukuran 40) / 25% dari ukuran, sheet atas 24, dialog 20; kartu anak 20, baris langkah anak 16, tombol anak 28 (bulat penuh).
- Tinggi tombol: orang tua 48, anak 56. Target sentuh minimal 48×48.

### 4.5 Gerak
Hanya fade atau slide 150–200 ms, `Curves.easeOut`. Tanpa efek pantul, pegas, confetti, shimmer, atau animasi berulang. Sheet memakai animasi bawaan `showModalBottomSheet`.

---

## 5. Komponen yang dipakai ulang

Buat di `lib/core/widgets/`. Nama di Figma section "v2 · Komponen" disebut dalam kurung.

### Orang tua
| Widget | Spesifikasi |
|---|---|
| `CaregiverHeader` (Header) | Tinggi 64, padding kiri 16 kanan 12 atas 20 bawah 12. Varian: utama (judul) atau kembali (ikon `arrowLeft` + judul). Opsional di kanan: tombol teks "Mei 2026 ▾" (ikon `chevronDown`) dan tombol ikon `bell`. Tanpa latar berwarna. |
| `CaregiverNavBar` (Nav Bawah) | Tinggi 72, latar putih, garis atas `garis`. Tiga tab sama lebar: Beranda (`house`), Jadwal (`calendarDays`), Akun (`user`). Ikon 24 + label 12. Aktif: `utama` SemiBold; tidak aktif: `teksSekunder` Medium. |
| `ChildSegmented` (Segmen Anak) | Lebar penuh, tinggi 44, latar putih, tepi `garis`, sudut 12, padding 4. Dua segmen: "Rafi · 12 th", "Atalia · 9 th". Terpilih: latar `utamaLembut`, teks `utama` SemiBold. |
| `WeekStrip` (Strip Minggu) | Tujuh kolom sama lebar: label hari 12 `teksSekunder`, tanggal 16 SemiBold dalam lingkaran 36. Terpilih: lingkaran `utama`, angka putih. Titik 4 px `anakAksen` di bawah hari yang punya kegiatan. Tanpa kartu/latar. |
| `DaySummary` | Baris: tanggal panjang (15 SemiBold) kiri, "1/5 selesai" (13 Medium sekunder) kanan. Di bawahnya bar progres tinggi 6, sudut 3, lintasan `garis`, isi `sukses`. Kalau tidak ada kegiatan: teks kanan "Belum ada kegiatan", tanpa bar. |
| `ActivityRow` (Baris Kegiatan) | Lebar penuh, padding vertikal 14, garis bawah 1 `garis`, tanpa kartu. Isi: jam mulai (14, lebar tetap 44), ubin ikon 40 (latar `anakLembut`, ikon 22 `teks`), kolom judul (15 SemiBold) + keterangan opsional (13 sekunder), lalu satu elemen status di kanan. Status: **Biasa** → ikon `chevronRight` sekunder; **Selesai** → ikon `circleCheckBig` `sukses`, judul berwarna sekunder, ubin opasitas 60%; **Sekarang** → jam `utama` SemiBold, ubin `utamaLembut` dengan ikon `utama`, pil "Sekarang" (latar `utama`, teks putih); **Diubah** → pil "Diubah" (latar `utamaLembut`, teks `utama`) dan keterangan "Pengganti {judul lama}". Judul maksimal 2 baris, tidak pernah dipotong "…". Seluruh baris bisa ditekan. |
| `CardSurface` | Latar putih, sudut 16, padding 16, tanpa bayangan. |
| `SuggestionCard` (Kartu Saran) | Latar `saranLembut`, sudut 14, padding 16×14. Baris atas: ikon `lightbulb` 18 + label 12 SemiBold `saranTeks`. Isi 14 (tinggi baris 20). Tautan aksi 14 SemiBold `utama` + `chevronRight`. Seluruh kartu bisa ditekan. |
| `PrimaryButton` / `SecondaryButton` / `DangerButton` / `DangerOutlineButton` / `TextButton` (Tombol) | Tinggi 48, sudut 12, label 15 SemiBold. Utama: `utama`/putih. Sekunder: putih, tepi `garis`, teks `teks`. Bahaya: `bahaya`/putih. Bahaya garis: putih, tepi `bahaya`, teks `bahaya`. Teks: tanpa latar, teks `utama`. Nonaktif: opasitas 40%. |
| `AddFab` (FAB Tambah) | Lingkaran 56, `utama`, ikon `plus` putih, bayangan halus. Posisi kanan-bawah, 16 dari tepi, di atas nav bar. Kalau snackbar tampil, FAB naik di atas snackbar. |
| `CalmSnackbar` (Snackbar) | Latar `teks`, sudut 12, tinggi 48, ikon `check` putih, pesan 14 Medium putih, aksi opsional 14 SemiBold warna `anakLembut`. Hilang sendiri setelah 4 detik (5 detik bila ada aksi Urungkan). |
| `FormField` (kolom sheet) | Label 13 Medium sekunder di atas. Kotak isian latar `latar`, sudut 12, padding 14×13. Bisa memuat ubin ikon 32 di kiri, ikon awal 20, teks, dan aksi kanan ("Ganti" `utama` atau ikon `chevronRight`/`pencil`). |
| `ListGroupCard` | Untuk Akun, Notifikasi, Saran: label grup 13 SemiBold sekunder, lalu kartu putih berisi baris dengan garis pemisah (padding vertikal 12, ubin/avatar 36–40). |

### Anak
| Widget | Spesifikasi |
|---|---|
| `ChildActivityCard` (Kartu Aktivitas Anak) | Putih, sudut 20, padding kiri 20 kanan 16 vertikal 14. Kiri: label opsional + nama kegiatan (20 SemiBold). Kanan: blok ikon 48 (sudut 14, latar `anakAksenLembut`, ikon 26 `anakAksenKuat`) dan jam di bawahnya (14 Medium sekunder). Status: **Biasa**; **Selesai** → ikon `circleCheckBig` sebelum nama, nama sekunder, blok ikon opasitas 60%; **Sekarang** → tepi 2 px `anakAksen` + label "SEKARANG"; **Berubah** → label "BARU BERUBAH" tanpa tepi. Hanya satu kartu bertepi di satu layar. |
| `ChildButton` | Tinggi 56, bulat penuh. Utama: latar `anakAksenKuat`, teks putih 17 SemiBold. Garis: putih, tepi 2 `anakAksen`, teks `anakAksenKuat`. Teks: tanpa latar, teks `anakAksenKuat` 17 Medium. |
| `EmergencyButton` (Tombol Darurat) | Lingkaran 56 putih, tepi 2 `anakAksen`, ikon `phone` `anakAksenKuat`, bayangan halus. Kanan-bawah, 16 dari tepi. Ada di semua layar anak kecuali A-07 dan A-08. Konten layar harus memberi ruang bawah ≥ 88 supaya tombol ini tidak menimpa apa pun. |
| `ChildBackHeader` | Ikon `arrowLeft` 26 + judul 22 SemiBold. |
| `Mascot` | Karakter kalender sederhana (lihat komponen "Maskot AutiPlan" di Figma). Buat sebagai widget `CustomPaint` atau SVG aset. Hanya dipakai di A-06. |

---

## 6. Model data

Semua model immutable dengan `copyWith`, `toJson`, `fromJson`.

```dart
enum ActivityIcon { sekolah, les, ngaji, mandi, makan, tidur, main, sepeda, nonton }
// Urutan tetap ini dipakai di pemilih ikon (grid 3x3):
// Baris 1 Belajar: sekolah, les, ngaji | Baris 2 Rutinitas: mandi, makan, tidur | Baris 3 Santai: main, sepeda, nonton
// Ikon Lucide: sekolah=school, les=bookText, ngaji=bookOpen, mandi=bath, makan=utensils,
//              tidur=moon, main=puzzle, sepeda=bike, nonton=clapperboard
// Label: Sekolah, Les, Ngaji, Mandi, Makan, Tidur, Main, Sepeda, Nonton

enum ChildTheme { lautTenang, padangHijau, pagiHangat }

class Child {
  String id; String name; String fullName; int age;
  ChildTheme theme;
  List<String> likes;      // contoh: ['Bersepeda', 'Film animasi']
  List<String> avoids;     // contoh: ['Suara keras', 'Tempat ramai']
}

class Activity {
  String id; String childId;
  String title;            // nama untuk orang tua, contoh "Sepeda Santai"
  String shortTitle;       // nama untuk anak, contoh "Sepeda" (maks 2 kata)
  ActivityIcon icon;
  DateTime date;           // tanggal (tanpa jam)
  TimeOfDayLite start;     // jam:menit
  TimeOfDayLite? end;      // boleh null untuk kegiatan malam (Tidur)
  List<String> steps;      // langkah untuk anak, boleh kosong
  Set<int> repeatWeekdays; // 1=Senin..7=Minggu, boleh kosong
  bool usesScreen;         // true otomatis kalau ikon = nonton
  bool independentMode;    // mode mandiri (langkah diringkas)
  String? replacedTitle;   // judul lama kalau kegiatan ini hasil perubahan
}

class Completion {         // riwayat penyelesaian oleh anak
  String activityId; DateTime date; DateTime completedAt; bool onTime;
  List<bool> stepsChecked;
}

class ChangeNotice {       // perubahan yang dikirim ke anak
  String id; String childId; String activityId;
  ActivitySnapshot before; ActivitySnapshot? after; // after null = kegiatan dihapus
  String message;          // "Pesan untuk Rafi", 1–120 karakter
  DateTime sentAt; DateTime? seenAt;
}
class ActivitySnapshot { String shortTitle; String title; ActivityIcon icon; TimeOfDayLite start; }

enum NotificationType { changeSeen, activityStarted, activityDone, emergencyPressed }
class CaregiverNotification { String id; NotificationType type; String text; DateTime at; bool read; String? badge; }

enum SuggestionType { quietTime, transitionGap, independence, emptyDay }
enum SuggestionStatus { active, dismissed, applied }
class Suggestion {
  String id; SuggestionType type; String childId;
  String title; String body;        // teks tampil (bagian 9)
  String reasonData; String reasonBasis;  // isi "Kenapa saran ini?"
  String actionLabel;               // label tombol utama di detail
  Map<String, dynamic> payload;     // data untuk aksi
  SuggestionStatus status;
}

class Settings {
  int reminderMinutesBefore;   // 15
  int minGapMinutes;           // 10
  int independenceStreakDays;  // 5
  int quietTimeMinutes;        // 30
  String emergencyNumber;      // '081234567890'
  String backupNumber;         // '081298765432' (kontak cadangan)
  bool demoClockEnabled;       // true
}

class AppState { List<Child> children; List<Activity> activities; List<Completion> completions;
  List<ChangeNotice> notices; List<CaregiverNotification> notifications;
  Map<String, SuggestionStatus> suggestionStatus; Settings settings; }
```

Saran (Suggestion) **tidak disimpan**: dihitung ulang dari state setiap kali dibutuhkan; yang disimpan hanya status dismissed/applied per ID saran (ID dibentuk deterministik, misalnya `independence:{activityId}`).

---

## 7. Data awal (seed) dan jam demo

### 7.1 Jam demo
Buat `Clock` (provider Riverpod). Saat `demoClockEnabled = true`, `now()` mengembalikan **Jumat, 1 Mei 2026 pukul 16.00** (waktu lokal) dan **tidak bergerak**. Semua status (Selesai/Sekarang) dan teks "Selamat sore" bergantung pada clock ini. Jangan memakai `DateTime.now()` langsung di mana pun.

Minggu yang ditampilkan: Sen 27 Apr – Min 3 Mei 2026. Default hari terpilih: Jum 1.

### 7.2 Anak
- Rafi Ramadhan ("Rafi"), 12 tahun, tema Laut Tenang, suka: Bersepeda, Film animasi; hindari: Suara keras, Tempat ramai.
- Atalia Putri ("Atalia"), 9 tahun, tema Padang Hijau, suka: Puzzle; hindari: Suara keras.

### 7.3 Kegiatan Rafi, Jumat 1 Mei 2026
| title | shortTitle | ikon | mulai–selesai | langkah | ulangi |
|---|---|---|---|---|---|
| Sekolah | Sekolah | sekolah | 07.00–08.00 | Bangun dan rapikan tempat tidur; Sarapan; Pakai seragam; Berangkat sekolah | Sen–Jum |
| Sepeda Santai | Sepeda | sepeda | 16.00–17.00 | Pakai helm dan sepatu; Bersepeda santai di dekat rumah; Parkir sepeda, lalu minum air putih | Sen–Jum |
| Ngaji di Rumah | Ngaji | ngaji | 18.00–19.00 | Ambil wudu dengan tenang; Siapkan Iqra atau Al-Qur'an; Membaca bersama Ustaz Farhan | Sen–Jum |
| Les dengan Pak Lana | Les | les | 20.00–20.45 | Siapkan buku dan alat tulis; Belajar bersama Pak Lana; Rapikan buku setelah selesai | Jum |
| Istirahat & Tidur Malam | Tidur | tidur | 21.00 (tanpa selesai, tampil "Pagi") | Sikat gigi dan cuci muka; Ganti baju tidur; Tidur | Setiap hari |

Penyelesaian awal: Sekolah 1 Mei selesai pukul 07.55 tepat waktu (semua langkah dicentang).
Kegiatan Rafi tanggal **24 April dan 27–30 April**: salin kegiatan yang berulang (Sekolah, Sepeda Santai, Ngaji di Rumah, Istirahat & Tidur Malam) dengan ID baru per tanggal, supaya titik di strip minggu muncul dan riwayat bisa dihitung. Sabtu 2 dan Minggu 3 Mei **kosong**.

Riwayat Sepeda Santai: ada `Completion` tepat waktu (selesai 16.50) untuk tanggal **24, 27, 28, 29, dan 30 April**. Saat dihitung pada Jumat 1 Mei pukul 16.00 (kemunculan hari ini belum selesai sehingga dilewati), hasilnya 5 kemunculan berturut-turut, sehingga saran "Latihan mandiri" muncul saat demo (lihat 9.3).

### 7.4 Kegiatan Atalia, Jumat 1 Mei 2026
| title | shortTitle | ikon | waktu |
|---|---|---|---|
| Sekolah TK B | Sekolah | sekolah | 08.00–11.00 (selesai) |
| Makan Siang Bersama | Makan | makan | 12.00–13.00 (selesai) |
| Bermain Puzzle | Puzzle | main | 16.30–17.30 |

### 7.5 Notifikasi awal (hari ini)
- 08.00 · `activityDone` · "Rafi menyelesaikan Sekolah"
- 07.30 · `emergencyPressed` · "Rafi menekan tombol bantuan" · badge "Sudah ditelepon"
- 16.00 · `activityStarted` · "Rafi mulai Sepeda Santai"

### 7.6 Tidak ada ChangeNotice di awal
Perubahan "Les → Nonton film" **tidak** ada di seed. Perubahan itu dibuat oleh orang tua saat demo (alur 13.1). Ini disengaja.

---

## 8. Aturan bisnis

Semua di `domain/schedule_rules.dart`, fungsi murni.

### 8.1 Status kegiatan (untuk hari terpilih)
- **Selesai** jika ada `Completion` untuk kegiatan dan tanggal itu.
- **Sekarang** jika tanggal = hari ini, belum selesai, dan `start ≤ now < end` (kalau `end` null: `start ≤ now`). Kalau beberapa memenuhi, pilih yang `start` paling akhir. Maksimal satu kegiatan "Sekarang" per anak.
- **Diubah** jika kegiatan punya `ChangeNotice` hari ini (dipakai di daftar orang tua).
- Selain itu **Biasa**.
- Kegiatan yang sudah lewat tapi belum selesai tetap "Biasa" (jangan diberi label terlambat; tidak menghakimi).

### 8.2 Progres
`selesai / total` kegiatan anak pada tanggal itu. Tampil "1/5 selesai" dan bar `selesai/total`. Di Beranda: "1 dari 5 kegiatan hari ini selesai".

### 8.3 Urutan
Daftar selalu diurutkan berdasarkan jam mulai.

### 8.4 Bentrok (dipakai di form Tambah dan Ubah)
Dua kegiatan anak yang sama di tanggal yang sama bentrok jika rentang `[start, end)` beririsan (kegiatan tanpa `end` dianggap berdurasi 30 menit).
- Saat bentrok: tampilkan kotak peringatan tenang di bawah kolom Waktu (latar `saranLembut`, ikon `info`, teks `teks`, **bukan merah**): "Waktu ini bentrok dengan {judul} ({mulai}–{selesai}). Pilih waktu lain supaya Rafi tidak bingung." dengan tautan "Pakai {slot kosong terdekat}".
- **Slot kosong terdekat**: mulai dari akhir kegiatan yang bentrok + `minGapMinutes`, dengan durasi sama, maju ke depan sampai tidak bentrok, maksimal pukul 21.00.
- Tombol simpan/kirim **nonaktif** selama bentrok.

### 8.5 Jeda transisi
Jeda antara selesainya satu kegiatan dan mulainya kegiatan berikutnya < `minGapMinutes` (10) → bukan blokir, tapi memicu saran jenis `transitionGap` (bagian 9) dan teks bantu kecil di form: "Jeda dengan {kegiatan sebelumnya} hanya {n} menit."

### 8.6 Tambah jadwal
Kolom wajib: Untuk (anak), Nama kegiatan (1–40 karakter), Ikon, Tanggal, Mulai, Selesai (Selesai > Mulai; boleh dikosongkan hanya untuk ikon Tidur). Opsi lanjutan (terlipat): Langkah-langkah (0–5 langkah, tiap langkah 1–60 karakter), Ulangi tiap minggu (pilih hari), Mode mandiri (toggle).
`shortTitle` diisi otomatis dari dua kata pertama Nama, bisa diedit di Opsi lanjutan.
Simpan → kegiatan dibuat, sheet tertutup, snackbar "Jadwal tersimpan dan dikirim ke HP {anak}". **Kegiatan baru tidak membuat ChangeNotice** (bukan perubahan).

### 8.7 Ubah jadwal
- Form berisi data kegiatan. Selama nama, ikon, dan waktu **belum berubah**: tampilkan catatan "Kolom "Pesan untuk Rafi" muncul setelah kamu mengubah nama, ikon, atau jam.", tombol "Kirim perubahan" nonaktif.
- Begitu salah satu dari nama/ikon/jam berubah: tampilkan kolom **Pesan untuk {anak}** (wajib, 1–120 karakter, penghitung "n/120") dan tautan "Lihat tampilan Dulu → Sekarang di HP {anak}" yang membuka pratinjau (bottom sheet kecil berisi dua ubin Dulu/Sekarang seperti A-02).
- Perubahan pada Opsi lanjutan saja (langkah/ulangi/mode mandiri) disimpan dengan tombol yang sama berlabel "Simpan" **tanpa** membuat ChangeNotice dan tanpa kolom pesan.
- Kirim perubahan → kegiatan diperbarui, `replacedTitle` = judul lama, dibuat `ChangeNotice` (before = snapshot lama, after = snapshot baru, message), sheet tertutup, snackbar "Perubahan terkirim ke {anak}".
- Saran kontekstual di dalam form (kartu saran kecil): muncul jika kegiatan hasil ubahan `usesScreen` dan selesai < `quietTimeMinutes` sebelum kegiatan Tidur. Teks: "{Judul} selesai {n} menit sebelum tidur. Layar menjelang tidur bisa membuat {anak} lebih lama tertidur. Tambahkan waktu tenang tanpa layar?" Aksi "Lihat alasannya" → membuka detail saran `quietTime`.

### 8.8 Hapus jadwal
Tombol "Hapus kegiatan" di form Ubah → dialog konfirmasi (OT-12). Hapus → kegiatan dihapus, dibuat `ChangeNotice` dengan `after = null` dan pesan otomatis "{Judul} hari ini tidak jadi. Kamu bisa istirahat dulu.", snackbar "{Judul} dihapus" dengan aksi **Urungkan** (5 detik) yang mengembalikan kegiatan dan menghapus notice-nya.

### 8.9 Perubahan dilihat anak
Saat anak menekan "Oke, aku mengerti" di A-02: `seenAt = now`, tambah notifikasi `changeSeen` "Rafi melihat perubahan jadwal {judul baru}". Di Beranda orang tua, pil berubah dari "Belum dibuka {anak}" menjadi "Dilihat {anak} pukul HH.mm".

### 8.10 Penyelesaian oleh anak
- Di detail aktivitas anak, setiap langkah dicentang satu per satu (bisa dibatalkan). Tombol "Aku sudah selesai" aktif hanya jika semua langkah dicentang, atau jika kegiatan tidak punya langkah, atau jika `independentMode = true`.
- Selesai → `Completion` dibuat (`onTime = completedAt ≤ akhir kegiatan`), notifikasi `activityDone` "{anak} menyelesaikan {judul}", buka A-06.
- Kegiatan yang sudah selesai dibuka lagi → tampil langkah dalam keadaan tercentang dan tombol diganti teks "Kegiatan ini sudah selesai." (tanpa tombol).

### 8.11 Darurat
- A-07 → "Telepon {pengasuh}" membuka `tel:{emergencyNumber}` lewat `url_launcher`, lalu menampilkan A-08, dan menambah notifikasi `emergencyPressed` "{anak} menekan tombol bantuan".
- A-08 menampilkan hitungan 30 detik. Setelah 30 detik, tampilkan tombol garis "Telepon kontak cadangan" (`tel:{backupNumber}`). Aplikasi tidak bisa tahu apakah telepon dijawab; teks di A-08 menjelaskan langkah ini, bukan mendeteksinya.
- Kalau `url_launcher` gagal (emulator tanpa telepon), tetap tampilkan A-08 dan snackbar kecil "Telepon tidak tersedia di perangkat ini".

### 8.12 Tema anak
Dipilih di A-09, disimpan di `Child.theme`, berlaku untuk semua layar anak. Sisi orang tua tidak berubah.

---

## 9. Mesin saran

`domain/suggestion_engine.dart` — fungsi `List<Suggestion> generateSuggestions(AppState s, DateTime now, String childId)`. Hasil diurutkan: independence, quietTime, transitionGap, emptyDay. Saran dengan status dismissed/applied tidak ditampilkan. Semua ambang diambil dari `Settings`.

### 9.1 `quietTime` — Waktu tenang sebelum tidur
- **Pemicu:** di tanggal hari ini ada kegiatan `usesScreen` yang selesai kurang dari `quietTimeMinutes` sebelum kegiatan ikon `tidur`.
- **Judul:** "Waktu tenang sebelum tidur"
- **Isi:** kalau hari ini ada ChangeNotice: "Jadwal hari ini berubah dan {judul} selesai {n} menit sebelum tidur. Tambahkan waktu tenang tanpa layar?"; kalau tidak: "{judul} selesai {n} menit sebelum tidur. Tambahkan waktu tenang tanpa layar?"
- **Kenapa (data):** "{judul} selesai pukul {selesai}, tidur pukul {mulai tidur}."
- **Kenapa (dasar):** "Anak autis yang memakai layar menjelang tidur rata-rata butuh waktu lebih lama untuk tertidur (Mazurek dkk., 2016)."
- **Aksi:** "Tambahkan waktu tenang" → buka form Tambah terisi: Nama "Waktu tenang", ikon tidur, mulai = selesai kegiatan layar, durasi = `quietTimeMinutes`. Pemeriksaan bentrok di form akan menunjukkan bentrok dengan Tidur; orang tua yang memutuskan. Status menjadi `applied` hanya setelah jadwal disimpan.

### 9.2 `transitionGap` — Jeda transisi
- **Pemicu:** di 7 hari ke depan (termasuk hari ini) ada dua kegiatan berurutan dengan jeda < `minGapMinutes`.
- **Judul:** "Jeda transisi"
- **Isi:** "{hari}: {judul B} mulai {n} menit setelah {judul A} selesai. Beri jeda {minGapMinutes} menit?"
- **Kenapa (data):** "{judul A} selesai {jam}, {judul B} mulai {jam}."
- **Kenapa (dasar):** "Pemberitahuan sebelum perpindahan kegiatan dapat mengurangi kesulitan saat transisi (León dkk., 2023)."
- **Aksi:** "Geser {judul B}" → buka form Ubah kegiatan B dengan jam mulai dan selesai sudah digeser sehingga jeda = `minGapMinutes`.
- Kalau tidak ada pemicu: di layar Saran tampil baris "Cek otomatis · Jeda transisi aman — Semua kegiatan hari ini punya jeda minimal {n} menit." (bukan saran, tanpa aksi).

### 9.3 `independence` — Latihan mandiri
- **Pemicu:** kegiatan dengan ≥ 2 langkah dan `independentMode = false` yang `Completion.onTime` di `independenceStreakDays` (5) **kemunculan terakhirnya berturut-turut** (hitung mundur dari hari ini; kemunculan hari ini yang belum selesai dilewati; kemunculan yang tidak selesai memutus hitungan).
- **Judul:** "Latihan mandiri"
- **Isi (daftar):** "{judul} selesai tepat waktu {n} hari berturut-turut. Kurangi langkah instruksi dari {jumlah langkah} jadi 1?"
- **Isi (detail):** "{anak} menyelesaikan {judul} tepat waktu {n} hari berturut-turut. Coba kurangi langkah instruksi dari {jumlah} menjadi 1 supaya {anak} berlatih mandiri."
- **Kenapa (data):** "{judul} selesai tepat waktu {rentang hari} minggu ini."
- **Kenapa (dasar):** "Anak autis dapat berpindah kegiatan secara mandiri bila bantuan dikurangi bertahap (MacDuff dkk., 1993)."
- Catatan: "Bisa dikembalikan ke {jumlah} langkah kapan saja."
- **Aksi:** "Kurangi langkah" → `independentMode = true`, status `applied`, snackbar "Mode mandiri aktif untuk {judul}". Bisa dimatikan di form Ubah → Opsi lanjutan.

### 9.4 `emptyDay` — Isi hari kosong
- **Pemicu:** ada hari dalam minggu yang ditampilkan (mulai hari ini) tanpa kegiatan, dan anak punya minimal satu `likes`.
- **Judul:** "Isi hari kosong"
- **Isi:** "{Hari} masih kosong. {anak} suka {likes[0] huruf kecil} dan tidak suka {avoids[0] huruf kecil}. {usulan}?" — untuk Rafi usulannya "Bersepeda pagi di taman pukul 07.00 saat masih sepi".
- Pemetaan usulan sederhana (tabel tetap): suka "Bersepeda" → "Bersepeda pagi di taman pukul 07.00 saat masih sepi" (ikon sepeda, 07.00–07.45); suka "Puzzle" → "Bermain puzzle di rumah pukul 09.00" (ikon main, 09.00–09.45). Selain itu tidak ada saran.
- **Kenapa (data):** "Hari {hari} belum punya kegiatan. Profil {anak}: suka {likes}, hindari {avoids}."
- **Kenapa (dasar):** "Kegiatan yang memakai minat khusus anak meningkatkan keterlibatan (Gunn & Delafield-Butt, 2016)."
- **Aksi:** "Tambahkan ke jadwal" → form Tambah terisi (tanggal hari kosong, nama, ikon, jam dari tabel).

### 9.5 Aturan tampilan saran
- Saran **hanya** di sisi orang tua: kartu di Beranda (saran teratas, label "Saran untuk {anak} · 1 dari {jumlah}", aksi "Lihat semua saran"), kartu di Jadwal hari kosong, kartu kontekstual di form Ubah, dan layar Saran (OT-16).
- Layar Saran selalu menampilkan catatan: "Saran dibuat dari pola jadwal dan profil {anak}. Bukan saran medis. Diskusikan dengan terapis bila ragu."
- Detail saran (OT-17): tombol utama = aksi saran, tombol teks "Nanti saja" (tutup tanpa mengubah status). Di layar daftar, geser atau tombol "Abaikan" di detail mengubah status menjadi `dismissed` (tambahkan tombol teks "Abaikan saran ini" kecil di bawah "Nanti saja").

---

## 10. Navigasi dan rute

### 10.1 Rute (`go_router`)
| Rute | Layar |
|---|---|
| `/` | Pilih peran |
| `/ortu/beranda` | OT-01/02/03 (Beranda) — dalam ShellRoute dengan nav bawah |
| `/ortu/jadwal` | OT-04/05/06/07/09/13 (Jadwal) — dalam ShellRoute |
| `/ortu/akun` | OT-14 — dalam ShellRoute |
| `/ortu/notifikasi` | OT-15 (tanpa nav bawah) |
| `/ortu/saran` | OT-16 (tanpa nav bawah) |
| `/anak` | A-01/A-03/A-11 (jadwal anak) |
| `/anak/perubahan` | A-02 |
| `/anak/aktivitas/:id` | A-04/A-05/A-10 |
| `/anak/berhasil/:id` | A-06 |
| `/anak/darurat` | A-07 |
| `/anak/menelepon` | A-08 |
| `/anak/tema` | A-09 |

Sheet dan dialog (bukan rute): Tambah jadwal (OT-08), Ubah jadwal (OT-10/11), Konfirmasi hapus (OT-12), Detail saran (OT-17), Pratinjau Dulu → Sekarang, Pemilih ikon, Pemilih tanggal/jam.

### 10.2 Pilih peran
Layar sederhana bergaya orang tua: logo teks "AutiPlan", kalimat "Pilih peran untuk demo", dua kartu besar: "Orang tua · Bu Sari" (ikon `user`) dan "Anak · Rafi" (ikon `smile` atau `user`). Peran terakhir diingat.

### 10.3 Ganti peran saat demo
- Sisi orang tua: di Akun, baris "Ganti ke tampilan anak" (dan "Reset data demo").
- Sisi anak: **tekan lama 2 detik** pada teks "Halo, Rafi!" → kembali ke Pilih peran. Tidak ada tombol yang terlihat, supaya anak tidak keluar tanpa sengaja.

---

## 11. Spesifikasi layar orang tua

Semua layar orang tua: latar `latar`, font Inter, header di atas, nav bawah di layar utama.

### OT-01/02/03 · Beranda (`/ortu/beranda`)
Header utama "Beranda" + lonceng (ke `/ortu/notifikasi`; tampilkan titik kecil `utama` di lonceng jika ada notifikasi belum dibaca). Isi (jarak 20):
1. **Sapaan:** "Selamat {pagi/siang/sore/malam}, Bu Sari" (pagi 04–10.59, siang 11–14.59, sore 15–17.59, malam 18–03.59) dan tanggal panjang "Jumat, 1 Mei 2026".
2. **Kartu Sekarang:** label "SEKARANG · {ANAK}" (anak yang terakhir dipilih di Jadwal, bawaan Rafi), ubin ikon 44 (`utamaLembut`/`utama`), judul kegiatan sekarang + "16.00 – 17.00", teks progres + bar, tautan "Buka jadwal ›". Kalau tidak ada kegiatan sekarang: tampilkan kegiatan berikutnya dengan label "BERIKUTNYA · {ANAK}"; kalau tidak ada lagi: "Semua kegiatan hari ini sudah lewat."
3. **Perlu perhatian:** label bagian + satu kartu:
   - Tidak ada ChangeNotice hari ini: ubin `shieldCheck` (`suksesLembut`/`sukses`) + "Semua jadwal berjalan sesuai rencana." (OT-01)
   - Ada notice belum dilihat: ubin `refreshCw` + "Perubahan terkirim ke Rafi", baris "{judul lama} → {judul baru}, {jam}" dan pil "Belum dibuka Rafi" (`saranLembut`/`saranTeks`). (OT-02) Menekan kartu membuka Jadwal.
   - Sudah dilihat: pil "Dilihat Rafi pukul 16.05" (`suksesLembut`/`sukses`). (OT-03)
   - Beberapa notice: tampilkan yang terbaru dan teks "+{n} perubahan lain".
4. **Kartu saran** (jika ada saran aktif): lihat 9.5. Menekan → `/ortu/saran`.
FAB Tambah → sheet Tambah jadwal (untuk anak terpilih, tanggal hari ini).

### OT-04/05/06/07/09/13 · Jadwal (`/ortu/jadwal`)
Header utama "Jadwal" + "Mei 2026 ▾" (membuka pemilih bulan sederhana; di prototipe cukup menampilkan bulan saat ini, berpindah minggu dengan geser kiri/kanan pada strip) + lonceng. Isi (jarak 12):
1. `ChildSegmented` (Rafi/Atalia).
2. `WeekStrip` (tekan tanggal → ganti hari; geser → minggu sebelumnya/berikutnya).
3. `DaySummary`.
4. Daftar `ActivityRow` (tekan baris → sheet Ubah jadwal). Kegiatan yang punya ChangeNotice hari itu tampil dengan status Diubah dan keterangan "Pengganti {replacedTitle}". (OT-05)
5. **Hari kosong** (OT-07): ubin `calendarDays` 48, "Belum ada jadwal di hari ini", "Tambahkan kegiatan supaya Rafi tahu rencananya lebih awal.", lalu kartu saran `emptyDay` jika ada (label "Saran untuk hari kosong", aksi "Tambahkan ke jadwal").
FAB Tambah → sheet Tambah (anak dan tanggal terpilih). Snackbar setelah simpan (OT-09) dan setelah hapus dengan Urungkan (OT-13).

### OT-08 · Sheet Tambah jadwal
Pegangan, judul "Tambah jadwal", subjudul tanggal panjang, tombol tutup `x`. Kolom (jarak 16):
1. **Untuk:** `ChildSegmented`.
2. **Nama kegiatan:** teks, placeholder "Contoh: Mandi sore".
3. **Ikon:** ubin ikon terpilih + label + "Ganti" → sheet pemilih ikon (grid 3×3 urutan tetap di bagian 6, judul "Pilih ikon", label kecil "9 ikon tersedia"; terpilih: latar `utamaLembut` + tepi 2 `utama`). Bawaan: kosong dengan teks "Pilih ikon"; tombol simpan nonaktif sampai dipilih.
4. **Waktu:** satu kolom "Jumat, 1 Mei · 17.15 – 17.45" (ikon `clock`, `chevronRight`) → sheet pemilih: tanggal (strip 7 hari), Mulai, Selesai (pakai `showTimePicker` 24 jam). Peringatan bentrok/jeda di bawah kolom ini (8.4, 8.5).
5. **Opsi lanjutan:** ikon `slidersHorizontal`, "Langkah & pengulangan", ringkasan kanan "{n} langkah". Menekan → membuka bagian tambahan di dalam sheet: daftar langkah (tambah/hapus/urutkan), pilihan hari ulangi (chip Sen–Min), nama singkat untuk anak, toggle "Mode mandiri".
Tombol utama "Simpan jadwal".

### OT-10/11 · Sheet Ubah jadwal
Judul "Ubah jadwal", subjudul "Untuk {anak} · {tanggal}". Kolom sama seperti Tambah (tanpa "Untuk"; nama dengan ikon `pencil`). Lalu sesuai 8.7: catatan (OT-10) atau kolom **Pesan untuk {anak}** + tautan pratinjau + "n/120" (OT-11), kartu saran kontekstual jika berlaku, tombol "Kirim perubahan", tombol bahaya garis "Hapus kegiatan".

### OT-12 · Dialog Konfirmasi hapus
Ubin `trash2` 48 (`bahayaLembut`/`bahaya`), "Hapus jadwal ini?", "{Judul} ({mulai} – {selesai}) akan hilang dari jadwal {anak}. {anak} akan menerima pemberitahuan dengan tampilan yang tenang.", tombol Bahaya "Hapus jadwal", tombol Sekunder "Batal".

### OT-14 · Akun (`/ortu/akun`)
Header "Akun" (tanpa lonceng). Grup:
1. Profil: avatar "IS", "Bu Sari", "Pengasuh utama · Terhubung ke HP Rafi".
2. **Anak:** Rafi Ramadhan "12 tahun · Tema Laut Tenang"; Atalia Putri "9 tahun · Tema Padang Hijau".
3. **Profil Rafi · dipakai untuk saran:** "Suka" (ikon `heart`) "Bersepeda, film animasi"; "Hindari" (ikon `sun`) "Suara keras, tempat ramai". Menekan → sheet edit berisi chip yang bisa ditambah/dihapus (teks bebas, maks 5).
4. **Pengaturan:** "Pengingat sebelum kegiatan" "15 menit"; "Batas saran" "Jeda 10 mnt · 5 hari" (sheet berisi tiga stepper: jeda minimal 5–30, hari berturut-turut 3–10, waktu tenang 15–60); "Nomor darurat" "0812-3456-7890" (sheet dua kolom: nomor utama, kontak cadangan).
5. **Demo:** "Ganti ke tampilan anak", "Reset data demo" (konfirmasi dialog sekunder).
Pengingat di prototipe hanya disimpan sebagai angka (tidak menjadwalkan notifikasi sungguhan).

### OT-15 · Notifikasi (`/ortu/notifikasi`)
Header kembali "Notifikasi". Grup "Hari ini" (dan "Sebelumnya" jika ada). Baris: ubin ikon sesuai jenis (changeSeen `circleCheckBig` sukses; activityStarted ikon kegiatan `utama`; activityDone ikon kegiatan; emergencyPressed `phone` bahaya), teks, jam di kanan, pil badge opsional. Membuka layar menandai semua dibaca. Urut terbaru di atas.

### OT-16 · Saran (`/ortu/saran`)
Header kembali "Saran untuk {anak}". Catatan (9.5). Grup "{n} saran baru": baris per saran (ubin ikon `saranLembut`/`saranTeks`: independence `sparkles`, quietTime `moon`, emptyDay `sun`, transitionGap `hourglass`; judul; isi 13). Grup "Cek otomatis" bila berlaku. Kosong: "Belum ada saran. Kami akan memberi tahu kalau ada pola yang perlu diperhatikan."

### OT-17 · Sheet Detail saran
Ubin ikon + judul + tutup. Isi detail (15, tinggi baris 22). Kotak "Kenapa saran ini?" (latar `latar`): "Data: …", "Dasar: …", catatan tambahan. Tombol utama = aksi, tombol teks "Nanti saja", tombol teks kecil "Abaikan saran ini".

---

## 12. Spesifikasi layar anak

Semua layar anak: font Lexend, warna dari tema anak, padding sisi 20, `EmergencyButton` kecuali A-07/A-08. Tidak ada nav bawah.

### A-01/A-03/A-11 · Jadwal hari ini (`/anak`)
- Baris atas: "Halo, Rafi!" + "Jumat, 1 Mei" di kiri; tombol pil putih "Tema" (ikon `palette`) di kanan → `/anak/tema`.
- **Banner perubahan** (A-01) jika ada ChangeNotice hari ini yang `seenAt == null`: latar `anakAksenLembut`, sudut 16, ikon `info`, "Ada perubahan jadwal hari ini", teks "Lihat" (`anakAksenKuat` SemiBold) → `/anak/perubahan`. Tidak pernah otomatis hilang; hilang setelah dibaca (A-03).
- Daftar `ChildActivityCard` untuk **hari ini saja**, urut jam, memakai `shortTitle`. Status: Selesai/Sekarang sesuai 8.1; **Berubah** untuk kegiatan dengan notice yang belum dilihat. Kegiatan yang dihapus tidak tampil.
- Menekan kartu → `/anak/aktivitas/:id`.
- A-11 hanyalah A-03 dengan tema Padang Hijau.

### A-02 · Perubahan jadwal (`/anak/perubahan`)
Menampilkan notice terlama yang belum dilihat. Header kembali "Jadwal kamu berubah". Teks "Hanya satu kegiatan malam ini yang berubah." (jika lebih dari satu notice: "Ada {n} kegiatan yang berubah hari ini." dan setelah "Oke" tampilkan notice berikutnya). Dua ubin: **Dulu** (opasitas 60%, tanpa tepi: label, blok ikon 52, `before.shortTitle`, jam) → ikon `arrowRight` → **Sekarang** (tepi 2 `anakAksen`: label `anakAksenKuat`, ikon, `after.shortTitle`, jam). Untuk notice hapus, ubin Sekarang menampilkan ikon `sun` dan teks "Waktu bebas". Kotak alasan (`anakAksenLembut`, 17): `message`. Baris kecil ikon `moon`/ikon kegiatan berikutnya: "Setelah itu: {kegiatan berikutnya}, {jam}". Tombol utama "Oke, aku mengerti" → 8.9 lalu kembali ke `/anak`.

### A-04/A-05/A-10 · Detail aktivitas (`/anak/aktivitas/:id`)
Header kembali `shortTitle`. Kartu kegiatan (status seperti di daftar). Label "Langkah-langkah". Baris langkah: lingkaran nomor 28 (`anakAksenLembut`), teks 17, kotak centang bulat 28 di kanan (belum: tepi 2 `anakAksen`; sudah: isi `anakAksenKuat` + ikon `check` putih). Menekan seluruh baris men-toggle centang. Teks bantu "Centang setiap langkah yang sudah kamu lakukan." sampai semua tercentang. Tombol "Aku sudah selesai" (aturan 8.10), ditempatkan langsung di bawah konten, bukan dipaku di bawah layar.
**Mode mandiri (A-10):** ganti label dan langkah dengan satu kartu putih: ikon `sparkles` + "Kamu sudah hafal langkahnya. {shortTitle} seperti biasa, ya." dan tombol teks "Lihat langkah lengkap" (menampilkan langkah seperti A-04; centang opsional). Tombol selesai langsung aktif.
Kegiatan tanpa langkah: tampilkan "Tidak ada langkah khusus." dan tombol aktif.

### A-06 · Berhasil (`/anak/berhasil/:id`)
Tombol kembali saja (tanpa judul). Maskot 120. "Kamu berhasil!" dan "{shortTitle} sudah selesai.". Kartu putih "Berikutnya" berisi blok ikon + `shortTitle` + jam kegiatan berikutnya hari ini (jika tidak ada: "Tidak ada kegiatan lagi hari ini."). Tombol utama "Kembali ke jadwal" → `/anak`.

### A-07 · Konfirmasi darurat (`/anak/darurat`)
Header kembali "Butuh bantuan?". Lingkaran 140 `anakAksenLembut` dengan ikon `phone` `anakAksenKuat`. Avatar inisial "IS" dan "Ibu Sari". "Tekan tombol di bawah untuk menelepon Ibu Sari." Tombol utama "Telepon Ibu Sari" (8.11), tombol teks "Tidak jadi" (kembali). Tanpa tombol darurat mengambang.

### A-08 · Menelepon (`/anak/menelepon`)
Avatar "IS" 96 dalam cincin `anakAksenLembut`, "Menelepon Ibu Sari…", "Tarik napas pelan-pelan. Ibu akan segera menjawab." Kartu info putih (`info`): "Kalau Ibu belum menjawab, HP akan menelepon kontak cadangan." Setelah 30 detik muncul tombol garis "Telepon kontak cadangan". Tombol garis "Tutup panggilan" → `/anak`. Tanpa warna merah.

### A-09 · Pilih tema (`/anak/tema`)
Header kembali "Pilih tema". Tiga kartu pratinjau (latar tema + satu kartu aktivitas mini dengan blok ikon warna aksen tema, nama tema, lingkaran pilihan). Tema yang sedang dipakai diberi teks kecil "Sedang dipakai". Menekan kartu memilih (tepi 2 aksen + centang) tanpa langsung menerapkan. Tombol utama "Pakai tema ini" (nonaktif jika pilihan = tema sekarang) → simpan, kembali ke `/anak` dengan tema baru (transisi fade 200 ms).

---

## 13. Alur utama dari ujung ke ujung

### 13.1 Ubah jadwal sampai dilihat anak (alur demo utama)
1. Orang tua → Jadwal (Rafi, Jum 1) → tekan "Les dengan Pak Lana".
2. Sheet Ubah (OT-10): ubah nama "Nonton film bersama", ikon Nonton → kolom pesan muncul (OT-11), isi "Pak Lana sedang sakit. Kita nonton film dulu supaya kamu santai sebelum tidur." → kartu saran layar sebelum tidur muncul di form.
3. Kirim perubahan → Jadwal menampilkan baris "Nonton film bersama · Pengganti Les dengan Pak Lana · Diubah" (OT-05); Beranda menampilkan "Belum dibuka Rafi" (OT-02) dan saran waktu tenang.
4. Ganti ke peran anak → A-01 dengan banner dan kartu "Nonton film · BARU BERUBAH".
5. Lihat → A-02 → Oke → A-03.
6. Ganti ke orang tua → Beranda "Dilihat Rafi pukul 16.00" (jam demo tidak bergerak) dan notifikasi baru.

### 13.2 Tambah jadwal dengan pemeriksaan bentrok
Jadwal → FAB → Nama "Mandi Sore", ikon Mandi, waktu 16.30–17.15 → peringatan bentrok dengan Sepeda Santai → tekan "Pakai 17.10 – 17.55" (slot 8.4) atau atur 17.15–17.45 → Simpan → OT-09 + snackbar.

### 13.3 Hapus dan urungkan
Jadwal → baris → Hapus kegiatan → dialog → Hapus jadwal → OT-13 + snackbar Urungkan.

### 13.4 Anak menjalankan kegiatan
A-03 → kartu Sepeda → centang 3 langkah (A-05) → Aku sudah selesai → A-06 → Kembali ke jadwal (Sepeda kini Selesai; progres orang tua 2/5).

### 13.5 Saran latihan mandiri
Orang tua → Beranda → kartu saran → Saran → Latihan mandiri → Kurangi langkah → anak membuka Sepeda → A-10.

### 13.6 Darurat
A-03 → tombol darurat → A-07 → Telepon Ibu Sari → aplikasi telepon terbuka → kembali ke A-08 → (30 detik) tombol kontak cadangan → Tutup panggilan.

### 13.7 Tema
A-03 → Tema → Padang Hijau → Pakai tema ini → A-11.

---

## 14. Aksesibilitas dan aturan perilaku

- Semua elemen yang bisa ditekan minimal 48×48 dan punya `Semantics(label: …)` dalam Bahasa Indonesia.
- Kontras teks minimal 4.5:1 (token sudah memenuhi untuk teks utama).
- Tidak ada teks hitam murni, merah di sisi anak, gradien, animasi berulang, suara, atau getar.
- Tidak ada pop-up/toast perubahan di sisi anak; hanya banner.
- Jangan memotong judul dengan "…" di daftar orang tua (maks 2 baris) dan kartu anak (biarkan membungkus).
- Layar harus tetap rapi pada lebar 360–430 dp dan skala teks 1.3×.
- Bahasa: kalimat pendek, tanpa idiom, tanpa tanda seru berlebihan (maksimal satu di "Halo, Rafi!" dan "Kamu berhasil!").

---

## 15. Rencana kerja per tahap

Selesaikan satu tahap, jalankan `flutter analyze` dan `flutter test`, lalu berhenti dan laporkan.

| Tahap | Isi | Selesai jika |
|---|---|---|
| 1. Fondasi | Proyek Flutter, paket, font, token (bagian 4), tema orang tua dan `ChildPalette`, router kosong, Clock demo, model + JSON + seed, LocalRepository, provider state | `flutter test` lulus untuk serialisasi dan seed; aplikasi membuka layar Pilih peran |
| 2. Aturan | `schedule_rules.dart` dan `suggestion_engine.dart` + semua tes bagian 16 | Semua tes lulus tanpa UI |
| 3. Komponen | Semua widget bagian 5 + halaman galeri komponen sementara (`/dev/komponen`, hanya di mode debug) | Galeri tampil sesuai gambar desain |
| 4. Orang tua: lihat | Beranda, Jadwal, Akun, Notifikasi, Saran, Detail saran (tanpa form) | Tampilan cocok dengan OT-01, 04, 06, 07, 14, 15, 16, 17 |
| 5. Orang tua: form | Sheet Tambah, Ubah, pemilih ikon/waktu, bentrok, pesan, hapus + urungkan, aksi saran | Alur 13.1 langkah 1–3, 13.2, 13.3, 13.5 (sisi orang tua) berjalan |
| 6. Anak | Semua layar A-01 s.d. A-11, ganti peran, darurat, tema | Alur 13.1 langkah 4–6, 13.4, 13.6, 13.7 berjalan |
| 7. Rapikan | Aksesibilitas (bagian 14), uji di 360 dp dan skala teks 1.3, perbaiki selisih dengan desain, isi DECISIONS.md | Semua alur bagian 13 berjalan berurutan dari data seed tanpa error |

---

## 16. Tes yang wajib ada

Di `test/`:
1. **Status:** dengan jam demo, Sekolah = Selesai, Sepeda Santai = Sekarang, sisanya Biasa; progres Rafi 1/5, Atalia 2/3.
2. **Urutan:** kegiatan baru 17.15 masuk di antara Sepeda dan Ngaji.
3. **Bentrok:** 16.30–17.15 bentrok dengan Sepeda; slot terdekat = 17.10–17.55; 17.15–17.45 tidak bentrok.
4. **Jeda:** kegiatan mulai 17.00 setelah Sepeda selesai 17.00 memicu `transitionGap`; 17.15 tidak (jeda 15 ≥ 10).
5. **Ubah tanpa perubahan inti:** mengubah langkah saja tidak membuat ChangeNotice.
6. **Ubah dengan perubahan nama:** membuat ChangeNotice dengan before "Les", after "Nonton film", `seenAt` null.
7. **Hapus + urungkan:** kegiatan dan notice kembali seperti semula.
8. **Dilihat:** acknowledge mengisi `seenAt` dan menambah notifikasi `changeSeen`.
9. **Saran independence:** muncul dari seed; hilang setelah `independentMode = true`; tidak muncul jika satu hari dalam 5 terakhir tidak tepat waktu.
10. **Saran quietTime:** tidak muncul di seed; muncul setelah Les diubah menjadi Nonton film 20.00–20.45 (tidur 21.00, selisih 15 < 30).
11. **Saran emptyDay:** muncul untuk Sabtu 2 Mei dengan usulan bersepeda pagi.
12. **Penyelesaian:** tombol selesai nonaktif sampai semua langkah dicentang; aktif langsung bila `independentMode`.
13. **Serialisasi:** `AppState` → JSON → `AppState` identik.

---

## 17. Hal yang sengaja belum dibuat
- Sinkronisasi antar-perangkat, akun, server.
- Notifikasi pengingat sungguhan (nilai pengingat hanya disimpan).
- Deteksi apakah telepon dijawab.
- Pemilih bulan penuh (cukup geser minggu).
- Layar anak untuk Atalia.
- Pengujian dengan anak autis sungguhan (di luar ruang lingkup kode).

Kalau ada permintaan di luar daftar ini, tanyakan dulu ke pengguna.

## 18. Perubahan menuju aplikasi sungguhan

Bagian ini mencabut beberapa batasan prototipe di atas. Rencana kerja dan
keputusan teknisnya ada di `docs/superpowers/plans/2026-11-09-autiplan-siap-pakai.md`.

**Dicabut:**
- §2 "Tidak termasuk": login, server, sinkronisasi antar-perangkat, notifikasi
  push, dan pengingat terjadwal **sekarang termasuk**. AI tetap tidak termasuk.
- §7 (data seed dan jam demo): data awal tidak lagi diisi otomatis. Aplikasi
  mulai dari data kosong dan pengguna mengisi profil lewat `/profil-awal`.
  Jam demo dihapus; aplikasi memakai jam perangkat.
- §10.2 (layar Pilih peran): diganti alur akun sungguhan (`/mulai`, `/masuk`,
  `/daftar`, `/hubungkan`).
- §10.3 (tombol ganti peran demo): dihapus. Peran ditentukan oleh sesi
  perangkat, bukan tombol.
- §17 baris pertama (sinkronisasi antar-perangkat, akun, server) dan baris
  kedua (notifikasi pengingat sungguhan): keduanya sekarang dibuat.

**Ditambah:**
- Data disimpan di Firestore (paket Spark) dengan `familyId` = `uid` orang tua.
- HP anak dihubungkan lewat kode 6 digit yang diperiksa Cloudflare Worker.
- Push hanya ke HP orang tua, untuk `emergencyPressed` dan `changeSeen`.
- Pengingat memakai notifikasi lokal di HP orang tua.

**Penyesuaian bagian lain:**
- §6: `Settings.demoClockEnabled` dihapus, `caregiverName` ditambah, nomor bawaan kosong.
- §3.3 dan §11 (OT-14): grup "Demo" dan "Reset data demo" dihapus.
- §12 (A-07, A-08) dan §13: "Bu Sari"/"Ibu Sari"/"IS" diganti nama pengasuh dan inisialnya; nama contoh di §7 hanya dipakai sebagai data tes.
- §8.11 (A-08): bila kontak cadangan kosong, kartu info dan tombol cadangan tidak ditampilkan.
- Kegiatan berulang dibuat sebagai salinan per tanggal sampai 28 hari ke depan.

**Tetap berlaku:** seluruh aturan bisnis §8, mesin saran §9, spesifikasi layar
§11 dan §12, alur §13, aksesibilitas §14, dan tes §16.

---

## Lampiran: sumber dasar saran
- Mazurek dkk. (2016). Bedtime Electronic Media Use and Sleep in Children with Autism Spectrum Disorder. https://doi.org/10.1097/DBP.0000000000000314
- León dkk. (2023). Assessment and treatment of problem behavior occasioned by variable-sequence transitions for children with autism. Behavioral Interventions.
- MacDuff, Krantz & McClannahan (1993). Teaching children with autism to use photographic activity schedules. https://doi.org/10.1901/jaba.1993.26-89
- Gunn & Delafield-Butt (2016). Teaching Children With Autism Spectrum Disorder With Restricted Interests. Review of Educational Research.
