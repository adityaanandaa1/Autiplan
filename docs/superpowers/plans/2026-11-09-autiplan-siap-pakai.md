# AutiPlan Siap Pakai: Rencana dan Implementasi

> **Untuk agen pelaksana:** WAJIB memakai superpowers:executing-plans. Langkah memakai checkbox (`- [ ]`). Kerjakan **satu tahap**, lalu berhenti dan laporkan.

**Tujuan:** menghapus semua sifat demo dari AutiPlan tanpa mengubah fungsinya, lalu menghubungkan HP orang tua dan HP anak secara sungguhan, seluruhnya tanpa biaya dan tanpa kartu pembayaran.

**Arsitektur:** kode yang ada dipakai lagi. `AutiPlanRepository` diganti menjadi aliran data dari Firestore. Layar tetap memanggil `updateState(AppState)`, lalu fungsi murni `diffAppState` mengubahnya menjadi penulisan per field. Cloudflare Worker hanya menangani dua hal yang butuh server: kode pasangan dan pengiriman push.

**Teknologi:** Flutter/Dart, Riverpod 2 (`StateNotifier`), go_router, Firestore + Firebase Auth (paket Spark), FCM, Cloudflare Workers + KV (TypeScript).

**Spesifikasi:** `docs/HANDOFF.md` ditambah keputusan di file ini. Tahap 7 menulis perubahan spesifikasinya ke HANDOFF.

## Keputusan yang sudah disetujui pengguna
- Kode dibersihkan, bukan ditulis ulang.
- Firestore Spark + Firebase Auth. Tanpa OTP SMS.
- Kode pasangan 6 digit, berlaku 10 menit, sekali pakai, diperiksa di Worker.
- Push lewat Worker + FCM, arahnya hanya ke HP orang tua.
- Pengingat memakai notifikasi lokal, tanpa server.
- Target: Android, APK dibagikan langsung.

## Keputusan perencana (boleh dikoreksi saat meninjau)
1. Login orang tua hanya email + kata sandi, tanpa Google Sign-In.
2. Hanya kode 6 digit, tanpa QR, supaya tidak perlu izin kamera.
3. `familyId` sama dengan `uid` orang tua, jadi tidak perlu pencarian keluarga saat login.
4. HP anak boleh membaca seluruh data keluarga. Aturan keamanan membatasi **penulisan**. Alasannya, `Completion` tidak punya `childId` dan HP dimiliki keluarga yang sama.
5. Push hanya untuk `emergencyPressed` dan `changeSeen`. `activityDone` tetap hanya di dalam aplikasi.
6. Pengingat hanya berbunyi di HP orang tua, karena HANDOFF melarang suara dan getar di sisi anak.
7. Kegiatan berulang dibuat sebagai salinan per tanggal sampai 28 hari ke depan, sama seperti bentuk data seed, sehingga aturan streak tidak perlu berubah.
8. Mengubah nama atau jam satu kemunculan hanya berlaku untuk tanggal itu. Mengubah hari ulang berlaku untuk semua tanggal setelahnya.

## Di luar rencana ini
Akun orang tua kedua, Google Sign-In, QR, layar anak untuk beberapa anak di satu HP, hapus akun, terbit ke Play Store, iOS, pemilih bulan penuh. Sebelum terbit ke Play Store, fitur hapus akun wajib dibuat.

## Yang harus dikerjakan pengguna (agen berhenti dan meminta ini)
| Kapan | Tugas |
|---|---|
| Sebelum Tahap 9 | Buat proyek Firebase paket Spark; aktifkan Firestore, Authentication (Email/Password dan Anonymous), Cloud Messaging; jalankan `firebase login` |
| Sebelum Tahap 11 | Buat akun Cloudflare gratis; jalankan `wrangler login`; unduh kunci service account Firebase ke **luar repo** |
| Tahap 13 | Sediakan dua HP Android untuk uji akhir |

Periksa ulang kuota paket gratis saat penyiapan, karena angkanya bisa berubah.

---

## Global Constraints
- Semua aturan `CLAUDE.md` tetap berlaku. Satu commit per tahap dengan pesan `Tahap N: ...`, setelah `docs/PROGRESS.md` diperbarui.
- Setiap akhir tahap: `dart format .`, `flutter analyze` 0 issue, `flutter test` semua lulus.
- Tanpa kartu pembayaran. Dilarang memakai Cloud Functions atau mengaktifkan Blaze.
- Paket baru yang diizinkan hanya: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `http`; dev: `fake_cloud_firestore`.
- Kunci service account dan rahasia Worker tidak boleh masuk git atau APK.
- Sisi anak tetap tanpa merah, hitam pekat, gradien, animasi berulang, suara, getar, pop-up, atau tombol ubah. Tidak ada spinner berputar.
- Teks baru harus persis seperti tabel "Teks baru" di bawah.

## Aturan menulis kode
Ikuti gaya yang sudah ada. Jangan merapikan kode yang tidak terkait dengan tahap berjalan.

**Struktur**
- Aturan bisnis masuk `lib/domain/` sebagai fungsi murni: tanpa Flutter, tanpa Firebase, tanpa `DateTime.now()`. Waktu dan ID dikirim oleh pemanggil.
- Akses Firebase dan HTTP hanya di `lib/data/`. Layar tidak boleh mengimpor `cloud_firestore`, `firebase_auth`, atau `http`.
- Satu file satu tanggung jawab. Kalau file melewati sekitar 300 baris karena perubahanmu, pecah seperti pola `account_screen.dart` + `account_widgets.dart` + `account_sheets.dart`.

**Model**
- Immutable, konstruktor `const`, dengan `copyWith`, `toJson`, `fromJson`, `==`, `hashCode`. Field baru wajib masuk kelimanya.
- `fromJson` memberi nilai bawaan untuk field baru, supaya dokumen lama tetap terbaca.

**State**
- Riverpod 2 dengan `StateNotifier` dan `Provider`. Jangan bermigrasi ke Notifier/riverpod_generator.
- `ref.watch` di `build`, `ref.read` di callback. Pakai `select` kalau hanya perlu satu field.
- Perubahan data lewat fungsi domain, lalu `appStateProvider.notifier.updateState(...)`.

**UI**
- Warna, ukuran huruf, jarak, radius, dan durasi hanya lewat token `lib/core/theme/`. Tanpa `TextStyle(...)` mentah di widget.
- Setelah `await`, periksa `context.mounted`.
- Elemen yang bisa ditekan minimal 48×48 dan punya `Semantics(label: ...)` berbahasa Indonesia.
- Pesan galat bernada tenang, tanpa kata "error" atau "gagal total", dan tidak menampilkan pesan teknis.

**Waktu dan ID**
- Waktu selalu dari `clockProvider`. `DateTime.now()` hanya boleh ada di `clock.dart`.
- ID baru memakai UUID v4. Dua HP bisa membuat data pada mikrodetik yang sama.

**Bahasa dan penamaan**
- Kelas, variabel, dan file berbahasa Inggris. Teks tampil berbahasa Indonesia.
- Komentar hanya menjelaskan alasan yang tidak terlihat dari kode. Komentar dokumentasi `///` di API publik.
- Dilarang memakai nama orang (`rafi`, `Bu Sari`) atau kata `demo` di `lib/`.

**Penanganan galat dan keamanan**
- Dilarang `catch (_) {}` kosong. Tangkap tipe yang spesifik, lalu tampilkan keadaan tenang atau catat dengan `debugPrint`.
- Hindari `firstWhere` tanpa `orElse` pada data dari server; pakai `firstWhereOrNull`-style atau periksa dulu. Data bisa berubah atau terhapus dari HP lain.
- `WriteBatch.commit()` tidak selesai selama HP offline, jadi **jangan di-`await` di jalur UI**.
- Worker selalu memverifikasi token Firebase dan mengambil isi notifikasi dari Firestore, bukan dari isi permintaan.

**Tes**
- Tes baru diberi nama menurut fitur, bukan `tahapN`.
- Tulis tes yang gagal dulu untuk logika di `domain/`, `state_diff`, dan Worker.
- Tes widget selalu meng-override `clockProvider`, supaya tidak ada timer berjalan.

---

## Review Focus
1. **Akun baru tanpa anak atau kegiatan:** tidak boleh crash di layar mana pun; diarahkan ke isi profil. Tes di Tahap 7.
2. **HP tanpa sinyal:** tombol simpan dan centang langsung berhasil, tanpa menggantung. Tes di Tahap 9.
3. **Aplikasi terbuka melewati pergantian jam atau tengah malam:** status "Sekarang" dan hari ikut bergeser. Tes di Tahap 7.
4. **Tombol darurat tanpa internet:** telepon tetap terbuka, dan kegagalan push tidak terlihat oleh anak. Tes di Tahap 12.
5. **Dua HP menulis bersamaan:** centang anak tidak menimpa perubahan orang tua. Tes di Tahap 9.

## Teks baru
| Tempat | Teks |
|---|---|
| Sambutan `/mulai` | "AutiPlan" · "HP ini dipakai oleh siapa?" · kartu "Orang tua" · kartu "Anak" |
| `/masuk` | Judul "Masuk" · label "Email", "Kata sandi" · tombol "Masuk" · tautan "Lupa kata sandi?" · "Belum punya akun? Daftar" |
| `/daftar` | Judul "Daftar" · tombol "Buat akun" · "Sudah punya akun? Masuk" |
| Galat akun | "Email atau kata sandi belum cocok." · "Email ini sudah terdaftar." · "Kata sandi minimal 8 karakter." · "Tautan untuk mengganti kata sandi sudah dikirim." |
| `/profil-awal` | Judul "Kenalan dulu" · label "Nama panggilan kamu" (contoh "Bu Sari"), "Nama lengkap anak", "Nama panggilan anak", "Umur anak", "Nomor darurat", "Kontak cadangan" · tombol "Mulai pakai AutiPlan" |
| Validasi nomor | "Nomor belum sesuai. Contoh: 081234567890." |
| `/hubungkan` | Judul "Hubungkan HP" · "Minta kode 6 angka dari orang tua." · tombol "Hubungkan" |
| Galat kode | "Kode belum cocok. Coba periksa lagi." · "Kode sudah tidak berlaku. Minta kode baru." · "Terlalu banyak percobaan. Coba lagi nanti." · "Belum ada internet. Coba lagi nanti." |
| Sheet kode (Akun) | Judul "Hubungkan HP {anak}" · "Masukkan kode ini di HP {anak}. Berlaku 10 menit." · tombol "Buat kode baru" |
| Akun | Grup "Akun" menggantikan grup "Demo": "Tambah anak", "Hubungkan HP {anak}", "Putuskan HP {anak}", "Keluar" |
| Profil Akun | "Pengasuh utama · Terhubung ke HP {anak}" atau "Pengasuh utama · Belum terhubung ke HP anak" |
| Dialog putus | Judul "Putuskan HP {anak}?" · "HP {anak} tidak akan menerima jadwal sampai dihubungkan lagi." · tombol "Putuskan", "Batal" |
| Pemuatan | "Memuat jadwal" (teks statis, tanpa animasi) |
| Sisi anak | "Ibu Sari"/"IS" diganti `{nama pengasuh}` dan inisialnya · "{pengasuh} akan segera menjawab." · "Kalau {pengasuh} belum menjawab, HP akan menelepon kontak cadangan." |
| Push | Judul "AutiPlan" · isi dari `CaregiverNotification.text` |
| Pengingat | Judul "AutiPlan" · "{judul} untuk {anak} mulai {n} menit lagi." |

---

## Tahap 7: Bersihkan demo dan siap data kosong

**File:**
- Pindah: `lib/data/seed.dart` → `test/support/fixture_state.dart` (`buildSeedState` → `buildFixtureState`, tambah `final fixtureNow = DateTime(2026, 5, 1, 16, 0)`)
- Ubah: `lib/core/clock.dart`, `lib/data/models/settings.dart`, `lib/data/models/app_state.dart`, `lib/data/providers.dart`, `lib/main.dart`, `lib/app.dart`, `lib/core/router.dart`, `lib/features/caregiver/forms/form_utils.dart`, `lib/features/caregiver/home_screen.dart`, `account_screen.dart`, `account_widgets.dart`, `account_sheets.dart`, `lib/features/child/*` (6 file yang memuat nama), `lib/domain/suggestion_engine.dart`, `docs/HANDOFF.md`, `docs/DECISIONS.md`
- Buat: `lib/core/widgets/initials.dart`, `lib/features/onboarding/profile_setup_screen.dart`
- Hapus: `lib/features/dev/`, `lib/core/widgets/placeholder_screen.dart`, `test/clock_test.dart` lama (ditulis ulang)
- Tes: `test/support/`, `test/clock_test.dart`, `test/empty_state_test.dart`

**Interfaces yang dihasilkan:**
```dart
class Clock { const Clock([DateTime Function() now = DateTime.now]); DateTime get now; }
final minuteTickProvider = StreamProvider<int>(...); // Stream.periodic tiap 30 detik
final clockProvider = Provider<Clock>(...);          // watch minuteTickProvider lalu kembalikan Clock
AppState AppState.empty();                           // semua list kosong, Settings() bawaan
final selectedChildIdProvider = StateProvider<String?>((ref) => null);
final currentChildProvider = Provider<Child?>(...);  // anak terpilih, atau anak pertama, atau null
String initialsOf(String name);                      // "Bu Sari" -> "BS", "" -> "?"
```
`Settings`: hapus `demoClockEnabled`, tambah `caregiverName` (bawaan `''`), bawaan `emergencyNumber` dan `backupNumber` menjadi `''`.

- [ ] **Langkah 1: Rapikan dokumen.** Ubah `docs/DECISIONS.md` menjadi UTF-8 yang benar: baris 59 memakai Windows-1252, baris 60 adalah UTF-16 dan isinya duplikat baris 59, jadi hapus baris 60. Tambah bagian baru "18. Perubahan menuju aplikasi sungguhan" di HANDOFF yang merujuk file ini dan mencabut §2 (Tidak termasuk), §7, §10.2, §10.3, §17 baris pertama dan kedua. Catat semua "Keputusan perencana" di DECISIONS.md.
- [ ] **Langkah 2: Tulis tes gagal.**
  - `Clock(() => t).now == t`.
  - `initialsOf`: `"Bu Sari"→"BS"`, `"Rafi"→"R"`, `""→"?"`.
  - `Settings.fromJson({'demoClockEnabled': true})` tidak melempar, dan `toJson` tidak memuat `demoClockEnabled`.
  - `generateSuggestions(AppState.empty(), now, 'x')` mengembalikan `[]`.
  - Widget: pump `CaregiverHomeScreen`, `CaregiverScheduleScreen`, `CaregiverAccountScreen`, dan `ChildHomeScreen` dengan `AppState.empty()` tanpa exception.
  - Widget: override `clockProvider` dengan jam 15.59 lalu 16.00, kartu status berpindah ke kegiatan yang benar.
- [ ] **Langkah 3:** Jalankan `flutter test`. Harus gagal karena simbol belum ada.
- [ ] **Langkah 4: Terapkan.**
  - Pindahkan seed ke fixture, perbarui import di 17 file tes, ganti `Clock.demoTime` dengan `fixtureNow`.
  - Tes widget yang bergantung jam demo meng-override `clockProvider` dengan `Clock(() => fixtureNow)`.
  - Ganti semua pencarian anak berdasar nama (`app.dart:30`, `child_home_screen.dart:26`, `child_change_screen.dart:26`, `child_theme_screen.dart:25`, `child_emergency_screen.dart:94`, `account_screen.dart:20`) dengan `currentChildProvider`; kalau null tampilkan layar kosong yang tenang.
  - `suggestion_engine.dart:12`: kembalikan `[]` kalau anak tidak ada.
  - Ganti `'Bu Sari'`, `'Ibu Sari'`, `'IS'` dengan `settings.caregiverName` dan `initialsOf`, dan `TextStyle` mentah di `child_calling_screen.dart:66` dan `child_emergency_screen.dart:57` dengan token baru `AppTypography.inisialBesar`.
  - `child_success_screen.dart:30`: pakai `clockProvider`. `form_utils.dart:21`: pakai `uuid`.
  - Hapus teks "Di prototipe" (`account_sheets.dart:109`), `resetToSeed`, `reset()`, grup Demo, galeri, dan `PlaceholderScreen`.
  - `main.dart` memulai dari `AppState.empty()`. Layar `/profil-awal` membuat `Child` dan `Settings`; router mengarah ke sana kalau `children` kosong.
- [ ] **Langkah 5: Verifikasi.** `grep -riE "demo|rafi|atalia|bu sari|ibu sari" lib` hanya boleh menyisakan `role_picker_screen.dart` dan `role_switch_button.dart`, yang dihapus di Tahap 10. `flutter analyze` 0 issue, `flutter test` lulus.
- [ ] **Langkah 6:** Perbarui PROGRESS.md, commit `Tahap 7: bersihkan demo dan siap data kosong`, berhenti, laporkan.

## Tahap 8: Kegiatan berulang

**File:** ubah `lib/data/models/activity.dart`, `lib/domain/schedule_rules.dart`, `lib/features/caregiver/widgets/add_activity_sheet.dart`, `edit_activity_sheet.dart`, `lib/data/providers.dart`. Buat `lib/domain/recurrence.dart`, `test/recurrence_test.dart`.

**Interfaces:**
```dart
// Activity: field baru String? seriesId (masuk copyWith/toJson/fromJson/==/hashCode)
List<Activity> materializeRecurring(List<Activity> all, DateTime today, {int horizonDays = 28});
List<Activity> applyRepeatChange(List<Activity> all, Activity edited);
// AppStateNotifier(repository, initial, {AppState Function(AppState)? normalize})
```

Aturan `materializeRecurring`: kelompokkan per `seriesId`. Templat adalah kemunculan terbaru dengan `replacedTitle == null`. Buat kemunculan hanya untuk tanggal **setelah kemunculan terakhir seri** sampai `today + horizonDays`, pada hari yang ada di `repeatWeekdays`. ID baru `'${seriesId}_yyyyMMdd'`, jadi aman dijalankan berkali-kali.

- [ ] **Langkah 1: Tulis tes gagal** di `test/recurrence_test.dart`:
  - Seri Sen–Jum dari Senin 2 Nov 2026, `today` = 2 Nov, horizon 7 → tanggal 3, 4, 5, 6, 9 Nov.
  - Dijalankan dua kali → daftar sama persis.
  - `seriesId == null` → tidak menambah apa pun.
  - Kemunculan tengah yang dihapus tidak muncul lagi.
  - Kemunculan terakhir punya `replacedTitle` → salinan baru memakai judul kemunculan sebelumnya.
  - `applyRepeatChange` dengan hari kosong → semua kemunculan setelah tanggal itu hilang, kemunculan itu tetap.
  - `applyRepeatChange` tidak menyentuh kemunculan sebelum tanggal itu.
- [ ] **Langkah 2:** Jalankan tes, harus gagal.
- [ ] **Langkah 3: Terapkan** kedua fungsi. Form Tambah mengisi `seriesId = id` bila ada hari ulang. Form Ubah memanggil `applyRepeatChange` bila hari ulang berubah. `appStateProvider` memberi `normalize` hanya di HP orang tua.
- [ ] **Langkah 4:** `flutter analyze` dan `flutter test` lulus, termasuk tes streak yang lama tanpa diubah.
- [ ] **Langkah 5:** Perbarui PROGRESS.md, commit `Tahap 8: kegiatan berulang`, berhenti, laporkan.

## Tahap 9: Sinkronisasi Firestore

**Perlu pengguna:** proyek Firebase, lalu `flutterfire configure --project=<id> --platforms=android` dan `minSdk` minimal 23.

**File:** ubah `lib/data/repository.dart`, `lib/data/providers.dart`, `lib/main.dart`, `lib/app.dart`. Buat `lib/data/state_diff.dart`, `lib/data/firestore_repository.dart`, `test/support/in_memory_repository.dart`, `test/state_diff_test.dart`, `test/firestore_repository_test.dart`. Hapus `lib/data/local_repository.dart`, `test/local_repository_test.dart`.

**Interfaces:**
```dart
abstract class AutiPlanRepository {
  Stream<AppState> watch();
  Future<void> apply(AppState before, AppState after);
}
enum DocOp { set, update, delete }
class DocWrite { final String? collection; final String? id; final DocOp op; final Map<String, dynamic> fields; }
List<DocWrite> diffAppState(AppState before, AppState after);
String completionDocId(Completion c); // '${activityId}_yyyy-MM-dd'
class FirestoreRepository implements AutiPlanRepository { FirestoreRepository(FirebaseFirestore db, String familyId); }
final repositoryReadyProvider = FutureProvider<void>(...); // selesai setelah emisi pertama watch()
```

Struktur data: `families/{familyId}` berisi `Settings.toJson()`, dengan subkoleksi `children`, `activities`, `completions`, `notices`, `notifications`, `suggestionStatus` (`{status}`), `devices`. `collection == null` berarti dokumen keluarga.

`diffAppState` membandingkan per ID, lalu per kunci `toJson()`: dokumen baru `set`, hilang `delete`, berubah `update` berisi **hanya kunci yang berubah**. Tidak berubah berarti tidak menulis.

- [ ] **Langkah 1: Tulis tes gagal.**
  - `diffAppState(s, s)` → `[]`.
  - Ubah `title` satu kegiatan → satu `update` dengan `fields == {'title': ...}`.
  - Tambah, hapus, lalu Completion memakai `completionDocId`.
  - Ubah `Settings.minGapMinutes` → `collection == null`.
  - **Dua HP** (`fake_cloud_firestore`): repo A mengubah `title`, repo B menambah Completion dan mengubah `steps` dari state lama; kedua perubahan tetap ada.
  - `watch()` hanya beremisi setelah semua koleksi memberi snapshot pertama.
  - `AppState → apply → watch` menghasilkan state setara, dengan urutan aktivitas berdasarkan tanggal lalu jam mulai.
  - `updateState` mengubah `state` seketika walau `apply` belum selesai (`Completer` tidak diselesaikan).
- [ ] **Langkah 2:** Jalankan tes, harus gagal.
- [ ] **Langkah 3: Terapkan.** Impor `cloud_firestore` dengan `as fs`, karena nama `Settings` bentrok. Aktifkan `persistenceEnabled: true`. Pecah batch per 450 operasi. `updateState` menyetel state dulu, lalu memanggil `apply` tanpa `await`, dan galat dicatat dengan `debugPrint`. `AppStateNotifier` berlangganan `watch()` lewat metode `start()` dan membatalkannya di `dispose`. Selama `repositoryReadyProvider` belum selesai, tampilkan teks "Memuat jadwal", supaya anak tidak melihat jadwal kosong sesaat.
- [ ] **Langkah 4:** Semua tes lulus. Jalankan di satu perangkat: buat kegiatan, tutup aplikasi, matikan internet, buka lagi; data tetap ada.
- [ ] **Langkah 5:** Perbarui PROGRESS.md, commit `Tahap 9: sinkronisasi Firestore`, berhenti, laporkan.

## Tahap 10: Akun, sesi, dan aturan keamanan

**File:** buat `lib/data/session/device_session.dart`, `lib/data/session/session_notifier.dart`, `lib/data/auth_service.dart`, `lib/features/onboarding/welcome_screen.dart`, `sign_in_screen.dart`, `sign_up_screen.dart`, `firebase/firestore.rules`, `firebase/tests/rules.test.ts`, `firebase.json`. Ubah `lib/core/router.dart`, `lib/app.dart`, `lib/data/providers.dart`, `lib/features/caregiver/account_*.dart`, `home_screen.dart`, `lib/features/child/child_home_screen.dart`. Hapus `lib/features/role_picker/`, `lib/core/widgets/role_switch_button.dart`, `test/role_picker_test.dart`, `test/role_switch_test.dart`, `activeRoleProvider`, tekan lama "Halo".

**Interfaces:**
```dart
sealed class DeviceSession {}
class UnlinkedSession extends DeviceSession {}
class CaregiverSession extends DeviceSession { final String familyId; }
class ChildSession extends DeviceSession { final String familyId; final String childId; }
abstract class AuthService {
  String? get uid;
  Future<String?> idToken();
  Future<void> signUp(String email, String password);
  Future<void> signIn(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> signInAnonymously();
  Future<void> signOut();
}
GoRouter createRouter(Ref ref); // redirect dari redirectFor
String? redirectFor(DeviceSession session, {required String path, required bool hasChildren});
```
Sesi disimpan di `shared_preferences` agar HP bisa dibuka tanpa internet. `currentChildProvider` di HP anak memakai `ChildSession.childId`.

Tabel `redirectFor`: `Unlinked` hanya boleh `/mulai`, `/masuk`, `/daftar`, `/hubungkan`, selain itu ke `/mulai`. `Caregiver` tanpa anak ke `/profil-awal`; dengan anak, rute `/mulai*`, `/masuk`, `/daftar`, `/hubungkan`, `/anak*` ke `/ortu/beranda`. `Child` selain `/anak*` ke `/anak`. Rute awal `/` mengikuti tabel yang sama.

Aturan keamanan (`firebase/firestore.rules`):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function owner(f) { return request.auth != null && request.auth.uid == f; }
    function devicePath(f) { return /databases/$(db)/documents/families/$(f)/devices/$(request.auth.uid); }
    function childDevice(f) { return request.auth != null && exists(devicePath(f)) && get(devicePath(f)).data.role == 'child'; }
    function member(f) { return owner(f) || childDevice(f); }
    function changedOnly(k) { return request.resource.data.diff(resource.data).affectedKeys().hasOnly(k); }

    match /families/{f} {
      allow read: if member(f);
      allow create, update: if owner(f);
      match /children/{id} {
        allow read: if member(f);
        allow create, delete: if owner(f);
        allow update: if owner(f) || (childDevice(f) && id == get(devicePath(f)).data.childId && changedOnly(['theme']));
      }
      match /activities/{id} { allow read: if member(f); allow write: if owner(f); }
      match /suggestionStatus/{id} { allow read: if member(f); allow write: if owner(f); }
      match /completions/{id} {
        allow read: if member(f);
        allow create: if member(f);
        allow update, delete: if owner(f);
      }
      match /notices/{id} {
        allow read: if member(f);
        allow create, delete: if owner(f);
        allow update: if owner(f) || (childDevice(f) && changedOnly(['seenAt']));
      }
      match /notifications/{id} {
        allow read: if member(f);
        allow create: if owner(f) || (childDevice(f) && request.resource.data.type in ['changeSeen','activityDone','emergencyPressed']);
        allow update: if owner(f);
      }
      match /devices/{uid} {
        allow read: if owner(f) || request.auth.uid == uid;
        allow create, update: if owner(f) && request.auth.uid == uid;
        allow delete: if owner(f);
      }
    }
    match /pairingCodes/{c} { allow read, write: if false; }
  }
}
```

- [ ] **Langkah 1: Tulis tes gagal.** `test/redirect_test.dart` mencakup setiap baris tabel. Tes aturan (emulator): anak **tidak bisa** menulis `activities`, mengubah `title` notice, mengubah `likes`, atau membaca keluarga lain; anak **bisa** membuat completion, mengisi `seenAt`, dan mengubah `theme`; orang asing tidak bisa membaca apa pun; `pairingCodes` tertutup untuk semua klien.
- [ ] **Langkah 2:** Jalankan `flutter test` dan `firebase emulators:exec --only firestore "npm --prefix firebase/tests test"`, harus gagal.
- [ ] **Langkah 3: Terapkan** sesi, layar, router, grup Akun (`Tambah anak`, `Keluar`). Daftar akun langsung membuat `CaregiverSession(uid)`. Saat dokumen `devices/{uid}` milik HP anak hilang atau listener mendapat `permission-denied`, sesi menjadi `Unlinked`.
- [ ] **Langkah 4:** Terapkan aturan dengan `firebase deploy --only firestore:rules`, setelah pengguna setuju. Semua tes lulus.
- [ ] **Langkah 5:** Verifikasi `grep -riE "demo|rafi|atalia|bu sari" lib` kosong, kecuali contoh placeholder "Bu Sari" di `/profil-awal`. Perbarui PROGRESS.md, commit `Tahap 10: akun, sesi, dan aturan keamanan`, berhenti, laporkan.

## Tahap 11: Worker dan kode pasangan

**Perlu pengguna:** akun Cloudflare dan kunci service account.

**File:** buat `worker/` (`wrangler.toml`, `package.json`, `src/index.ts`, `src/auth.ts`, `src/firestore.ts`, `src/pairing.ts`, `test/pairing.test.ts`), `lib/data/backend_api.dart`, `lib/features/onboarding/link_device_screen.dart`, `lib/features/caregiver/pairing_sheet.dart`. Ubah `account_screen.dart`, `.gitignore` (`worker/.dev.vars`, `*service-account*.json`).

**Endpoint** (semua `Authorization: Bearer <Firebase ID token>`). Token diverifikasi dengan `jose` terhadap JWKS `securetoken@system.gserviceaccount.com`, `iss = https://securetoken.google.com/<projectId>`, `aud = <projectId>`.

| Endpoint | Masukan | Syarat | Hasil |
|---|---|---|---|
| `POST /pairing/create` | `{childId}` | `familyId` = uid, anak ada | `{code, expiresAt}` |
| `POST /pairing/claim` | `{code}` | batas percobaan, kode berlaku | `{familyId, childId}`, membuat `devices/{uid}` role `child` |
| `POST /notify` | `{familyId, notificationId}` | uid anggota keluarga, tipe diizinkan | `204` (Tahap 12) |

Kode ada di `pairingCodes/{code}` berisi `{familyId, childId, expiresAt, usedAt}`. Klaim memakai `documents:commit` dengan prasyarat `updateTime`, sehingga kode benar-benar sekali pakai. Batas percobaan dicatat di KV: gagal 5 kali per uid per 15 menit, 20 kali per IP per jam, karena akun anonim mudah dibuat ulang. Respons galat: `400 invalid_code`, `410 expired_code`, `429 too_many_attempts`.

```dart
class PairingCode { final String code; final DateTime expiresAt; }
class ClaimedLink { final String familyId; final String childId; }
enum BackendFailure { invalidCode, expiredCode, tooManyAttempts, offline, unknown }
class BackendException implements Exception { final BackendFailure failure; }
abstract class BackendApi {
  Future<PairingCode> createPairingCode(String childId);
  Future<ClaimedLink> claimPairingCode(String code);
  Future<void> notify(String familyId, String notificationId);
}
```

- [ ] **Langkah 1: Tulis tes gagal** (vitest): kode selalu 6 digit dan memakai `crypto.getRandomValues`; `checkClaim` menolak kode kedaluwarsa dan yang sudah dipakai; percobaan ke-6 per uid → `too_many_attempts`; token dengan `aud` salah ditolak. Flutter: `BackendApi` memetakan 400/410/429/`SocketException` ke `BackendFailure`, dan layar menampilkan teks yang sesuai dari tabel.
- [ ] **Langkah 2:** Jalankan `npm test` di `worker/` dan `flutter test`, harus gagal.
- [ ] **Langkah 3: Terapkan.** Rahasia lewat `wrangler secret put FIREBASE_SERVICE_ACCOUNT`. HP anak: `signInAnonymously`, klaim, lalu `ChildSession`. URL Worker lewat `--dart-define=WORKER_URL=...`. Tambah "Hubungkan HP {anak}" dan "Putuskan HP {anak}" di Akun.
- [ ] **Langkah 4:** `wrangler deploy` setelah pengguna setuju. Uji dengan dua perangkat atau emulator: kode benar terhubung, kode dipakai dua kali ditolak, jadwal muncul di HP anak.
- [ ] **Langkah 5:** Perbarui PROGRESS.md, commit `Tahap 11: Worker dan kode pasangan`, berhenti, laporkan.

## Tahap 12: Push ke orang tua

**File:** buat `lib/data/push_service.dart`, `worker/src/notify.ts`, `worker/test/notify.test.ts`, `test/emergency_flow_test.dart`. Ubah `worker/src/index.ts`, `lib/features/child/child_emergency_screen.dart`, `child_change_screen.dart`, `android/app/src/main/AndroidManifest.xml` (`POST_NOTIFICATIONS`), `lib/app.dart`.

**Interfaces:**
```dart
abstract class PushService { Future<void> registerCaregiverDevice(String familyId); }
```
`registerCaregiverDevice` meminta izin, lalu menyimpan token ke `devices/{uid}.fcmToken`, dan mengikuti `onTokenRefresh`. Hanya dipanggil pada `CaregiverSession`, sehingga HP anak tidak pernah punya token.

- [ ] **Langkah 1: Tulis tes gagal.**
  - Worker: `/notify` mengambil teks dari dokumen Firestore dan mengabaikan isi permintaan; tipe `activityDone` → tidak mengirim; uid di luar keluarga → `403`; token FCM `UNREGISTERED` dihapus dari dokumen perangkat.
  - Flutter: pada A-07 dengan `BackendApi` palsu yang melempar `offline`, `launchUrl('tel:...')` tetap dipanggil **sebelum** `notify`, layar pindah ke A-08, dan tidak ada snackbar soal internet.
- [ ] **Langkah 2:** Jalankan tes, harus gagal.
- [ ] **Langkah 3: Terapkan.** FCM HTTP v1 dengan token OAuth dari service account, cakupan `firebase.messaging` dan `datastore`. Urutan A-07: buka telepon, simpan notifikasi, panggil `notify` tanpa `await`. `changeSeen` juga memanggil `notify`.
- [ ] **Langkah 4:** Semua tes lulus. Uji di perangkat dengan aplikasi orang tua tertutup: tombol darurat memunculkan push.
- [ ] **Langkah 5:** Perbarui PROGRESS.md, commit `Tahap 12: push ke orang tua`, berhenti, laporkan.

## Tahap 13: Pengingat lokal dan uji akhir

**File:** buat `lib/domain/reminder_plan.dart`, `lib/data/reminder_service.dart`, `test/reminder_plan_test.dart`. Ubah `lib/app.dart`, `account_sheets.dart`, `android/app/build.gradle.kts` (core library desugaring), `docs/HANDOFF.md`, `docs/PROGRESS.md`.

**Interfaces:**
```dart
class PlannedReminder { final String activityId; final DateTime at; final String body; }
List<PlannedReminder> planReminders(AppState state, DateTime now, {int maxCount = 50});
```

- [ ] **Langkah 1: Tulis tes gagal.** `reminderMinutesBefore` 15, kegiatan 16.00 → `at` 15.45 dengan teks persis dari tabel; `at` yang sudah lewat dilewati; kegiatan yang sudah selesai dilewati; hasil urut paling awal dan maksimal 50.
- [ ] **Langkah 2:** Jalankan tes, harus gagal.
- [ ] **Langkah 3: Terapkan.** `ReminderService` menjadwalkan ulang setiap state berubah, hanya pada `CaregiverSession`. Pakai `AndroidScheduleMode.inexactAllowWhileIdle`, sehingga tidak perlu izin alarm persis. Hapus teks "hanya disimpan sebagai angka" kalau masih tersisa.
- [ ] **Langkah 4: Rapikan.** Selesaikan utang Tahap 7 lama: aksesibilitas §14, tata letak 360 dp dan skala teks 1.3 (termasuk overflow `DaySummary`), UI "Lihat langkah lengkap" dan "Bisa dikembalikan ke N langkah".
- [ ] **Langkah 5: Uji dua HP** (bersama pengguna): daftar → isi profil → hubungkan HP anak → alur 13.1 sampai 13.7 HANDOFF dengan jam dan data asli → HP anak tanpa sinyal tetap menampilkan jadwal dan menyinkron saat online → putuskan HP anak.
- [ ] **Langkah 6:** `dart format .`, `flutter analyze`, `flutter test`, `flutter build apk --release --dart-define=WORKER_URL=...`. Perbarui PROGRESS.md, commit `Tahap 13: pengingat lokal dan uji akhir`, berhenti, laporkan.
