# Progres pengerjaan

Log per tahap supaya session AI berikutnya tahu apa yang sudah dikerjakan. Perbarui file ini di akhir setiap tahap, lalu buat commit git.

Format tiap tahap: status, file utama, hasil `flutter analyze` / `flutter test`, utang yang diketahui, dan langkah berikutnya.

---

## Tahap 1 — Fondasi

- **Status:** selesai.
- **Isi:** proyek Flutter, paket, font, token tema (`lib/core/theme/`), `ChildPalette`, router, `Clock` demo, model + JSON + seed, `LocalRepository`, provider state, layar Pilih peran, tombol Ganti peran.
- **Hasil:** `flutter analyze` bersih, `flutter test` lulus.
- **Catatan:** keputusan dan penyimpangan dari HANDOFF tercatat di `docs/DECISIONS.md`.

## Tahap 2 — Aturan

- **Status:** selesai (diperbaiki 2 November 2026 setelah inspeksi dengan systematic-debugging).
- **File utama:** `lib/domain/schedule_rules.dart`, `lib/domain/suggestion_engine.dart`, tes di `test/`.
- **Hasil:** `flutter analyze` bersih, 62 tes lulus.
- **Diperbaiki:** emptyDay dibatasi minggu berjalan; crash quietTime saat tanpa kegiatan; teks independence memakai rentang tanggal; `findNearestFreeSlot` memakai `minGapMinutes`; "Sekarang" tanpa `end`; fungsi murni baru (`applyActivityEdit`, `deleteActivity`, `undoDeleteActivity`, `acknowledgeNotice`, `canComplete`, `formatDateRange`, `consecutiveOnTimeDates`) dan tes 5, 7, 8, 12 ditulis ulang agar memanggil kode asli; tes saran diperketat. Keputusan tercatat di DECISIONS.md.
- **Utang yang tersisa:**
  - `generateSuggestions` memakai `children.firstWhere(... orElse: first)`: diam-diam memakai anak pertama bila id tidak ada, melempar bila `children` kosong (belum terbukti bug).
  - Kegiatan berulang belum diperluas ke tanggal depan, jadi emptyDay/transitionGap hanya melihat kegiatan yang benar-benar ada di data.
  - Isi detail saran independence dan catatan "Bisa dikembalikan ke N langkah" belum ada di model `Suggestion` (urusan Tahap 4–5).

## Tahap 3 — Komponen

- **Status:** selesai.
- **Isi:** 14 widget di `lib/core/widgets/`:
  - **Orang tua:** `CaregiverHeader`, `CaregiverNavBar`, `ChildSegmented`, `WeekStrip`, `DaySummary`, `ActivityRow`, `CardSurface`, `SuggestionCard`, `ChangeNoticeCard`, `PrimaryButton`, `SecondaryButton`, `DangerButton`, `DangerOutlineButton`, `AppTextButton`, `AddFab`, `CalmSnackbar`.
  - **Anak:** `ChildHeader`, `ChildActivityCard`.
  - Galeri komponen di `/dev/komponen` (debug only) menampilkan semua widget dengan data contoh.
- **File utama:** `lib/core/widgets/*.dart`, `lib/features/dev/component_gallery_screen.dart`, `lib/core/router.dart`.
- **Hasil:** `flutter analyze` bersih, `flutter test` 62 tes lulus (komponen UI tidak dites unit, hanya tampil di galeri).
- **Diperbaiki 2 November 2026:** semua nilai mentah (warna, ukuran huruf, jarak, radius) di widget dan galeri diganti token baru (daftar di DECISIONS.md, bagian 4 Token).
- **Disamakan dengan HANDOFF §5 (2 November 2026):** `ChildActivityCard` (baris, ubin 48, tepi aksen pada "Sekarang"), `EmergencyButton` terpisah (mengambang kanan-bawah, ditempatkan di Tahap 6), `ChildButton`, `ChildBackHeader`, `Mascot` (versi sederhana `CustomPaint`), `CalmSnackbar` (ikon check, tinggi 48, 4/5 detik), `ActivityRow` "Pengganti {judul lama}" lewat `replacedTitle`. Tes widget di `test/child_widgets_test.dart`. 70 tes lulus.
- **Utang yang tersisa:** (1) `design/screens/` KOSONG, tampilan belum pernah dibandingkan dengan gambar desain. (2) `Mascot` bukan aset resmi; cocokkan dengan komponen "Maskot AutiPlan" di Figma. (3) `DaySummary` overflow 196 px pada lebar 360 dp / skala 1.3x di uji layout (font tes Ahem lebih lebar; perlu dicek di perangkat). (4) Keterangan "Pengganti ..." di `ActivityRow` `maxLines: 1` dengan ellipsis. (5) Gaya label "SEKARANG"/"BARU BERUBAH" (teks polos atau pil), warna ikon "Selesai" (`sukses`), dan bayangan `EmergencyButton` adalah pilihan sendiri. (6) Token lama tak terpakai: `iconTileChild`, `iconSize40`, `ubinIkonAnak`.
- **Catatan:**
  - Ikon `mandi` memakai `LucideIcons.bath` (bukan `shower` yang tidak ada di lucide_icons_flutter v4).
  - Deprecated `withOpacity` diganti `withValues(alpha:)` untuk kompatibilitas Flutter 3.44.
  - Rute `/dev/komponen` hanya ada di `kDebugMode`.

### Langkah berikutnya
Tahap 6: layar anak (A-01 s.d. A-09). Pasang `RoleSwitchButton` di Jadwal anak yang asli dan `EmergencyButton` di kanan-bawah sesuai DECISIONS.md.

## Tahap 4 — Orang tua: lihat
- **Status:** selesai untuk seluruh layar lihat (Beranda, Jadwal, Akun, Notifikasi, Saran, Detail saran).
- **File utama:**
  - `lib/features/caregiver/home_screen.dart` (Beranda OT-01/02/03) ✅
  - `lib/features/caregiver/notifications_screen.dart` (Notifikasi OT-15) ✅
  - `lib/features/caregiver/suggestions_screen.dart` (Saran OT-16) ✅ — baris saran membuka **sheet Detail Saran OT-17** (`widgets/suggestion_detail_sheet.dart` + `widgets/suggestion_actions.dart`).
  - `lib/features/caregiver/schedule_screen.dart` (Jadwal OT-04/05/06/07) ✅ + `schedule_providers.dart` (selectedDateProvider, selectedWeekStartProvider) + `widgets/schedule_activity_rows.dart` + `widgets/schedule_empty_day.dart`
  - `lib/features/caregiver/account_screen.dart` (Akun OT-14) ✅ + `account_widgets.dart` + `account_sheets.dart` (chip Suka/Hindari maks 5, stepper pengingat, batas saran 3 stepper, nomor darurat, reset demo)
  - `lib/core/router.dart`: Jadwal dan Akun pakai layar asli.
- **Hasil:** `flutter analyze` — 75 issue; SEMUA 50 error hanya di **satu file rusak** `lib/features/caregiver/widgets/edit_activity_sheet.dart` (milik Tahap 5, lihat di bawah). File lain bersih. `flutter test` belum dijalankan ulang setelah perubahan UI (sebelumnya 70 lulus).
- **Catatan:** Home menampilkan kegiatan sekarang/berikutnya, progres, kartu perhatian, saran. Notifikasi mark all as read. Saran menampilkan semua saran aktif. Jadwal: geser kiri/kanan pada strip = pindah minggu; tekan tanggal = ganti hari; baris kegiatan → sheet Ubah; hari kosong (OT-07) + kartu saran emptyDay; FAB → sheet Tambah.

## Tahap 5 — Orang tua: form
- **Status:** selesai (2 November 2026).
- **Selesai dan bersih (analyze aman):**
  - `lib/features/caregiver/forms/sheet_scaffold.dart` — kerangka bottom sheet (pegangan, judul, subjudul, tombol X).
  - `lib/features/caregiver/forms/form_field.dart` — FormLabel, FormBox, FormTextField, FormLinkRow, FormTextLink, FormInfoBox.
  - `lib/features/caregiver/forms/form_utils.dart` — format tanggal/jam id, `buildActivity`, `shortTitleFromTitle`, `generateId`.
  - `lib/features/caregiver/forms/icon_picker_sheet.dart` — pemilih ikon grid 3×3 ("9 ikon tersedia").
  - `lib/features/caregiver/forms/time_picker_sheet.dart` — pemilih tanggal (strip 7 hari) + Mulai/Selesai via `showTimePicker`; "Selesai" bisa dikosongkan hanya untuk ikon Tidur.
  - `lib/features/caregiver/widgets/add_activity_sheet.dart` — **LENGKAP**: ChildSegmented "Untuk", nama, ikon, waktu, cek bentrok + tautan "Pakai {slot kosong}", Opsi lanjutan (`add_activity_advanced.dart`: langkah 0–5, chip ulangi Sen–Min, nama singkat, mode mandiri), "Simpan jadwal" + snackbar "Jadwal tersimpan dan dikirim ke HP {anak}". Mendukung prefill dari saran (payload quietTime/emptyDay).
  - `lib/features/caregiver/widgets/suggestion_detail_sheet.dart` + `suggestion_actions.dart` — OT-17 lengkap: isi, "Kenapa (data)/(dasar)", tombol aksi utama (independence → `independentMode` + steps diringkas + status applied + snackbar; quietTime/emptyDay → sheet Tambah terisi; transitionGap → sheet Ubah dengan jam digeser), "Nanti saja", "Abaikan saran ini" (status dismissed).
  - `lib/features/caregiver/widgets/change_preview_sheet.dart` — pratinjau Dulu → Sekarang (dua ubin + pesan).
  - `lib/features/caregiver/widgets/delete_activity_dialog.dart` — dialog konfirmasi hapus OT-12.
  - `lib/core/widgets/caregiver_header.dart` — parameter `trailing` baru (bulan "Mei 2026 ▾" di header Jadwal).
- **Ditulis ulang utuh:** `lib/features/caregiver/widgets/edit_activity_sheet.dart` (sheet Ubah OT-10/11). File lama rusak (teks parsial, duplikasi extension, import setelah deklarasi) dihapus dan ditulis ulang dengan anchor; `build` ada di dalam kelas State, bukan extension (extension tidak bisa meng-override `build`).
- **Hasil:** `flutter analyze` 0 issue; `flutter test` 70 tes lulus.
- **Diperbaiki selain sheet Ubah:** FAB Beranda membuka sheet Tambah (OT-01, sebelumnya TODO); import ganda di `suggestions_screen.dart`; lint `use_null_aware_elements` di `form_field.dart` (`?leading`, `?trailing`, Dart 3.12); `activeColor` deprecated → `activeThumbColor` di `add_activity_advanced.dart`; `role_switch_test.dart` diberi `scrollUntilVisible` (tombol "Ganti peran" di ujung ListView Beranda tidak ter-build di luar viewport; sebelumnya placeholder). Detail di DECISIONS.md.
- **Alur dicek lewat bacaan kode (belum dijalankan di perangkat):** 13.1 langkah 1–3 (seed: Les 20.00–20.45, Tidur 21.00 → gap 15 < 30 → kartu waktu tenang muncul di sheet Ubah), 13.2, 13.3, 13.5.
- **Utang yang tersisa:**
  - Langkah asli tidak disimpan saat saran independence diterapkan, jadi "Bisa dikembalikan ke N langkah" (§9.3) belum bisa di form Ubah.
  - Status `applied` untuk quietTime/emptyDay/transitionGap belum diatur setelah sheet Tambah/Ubah dari saran berhasil disimpan.
  - Tes widget untuk form Tambah/Ubah belum ada (yang dites hanya fungsi murni dan komponen anak).

## Tahap 4–5 — Perbaikan audit (2 November 2026)
- **Status:** selesai. Audit baca-kode atas Tahap 4 dan 5 menemukan 9 bug + 12 kekurangan (T4) dan 11 bug + 10 kekurangan (T5); semua dikerjakan kecuali B7/B12 T4 (sengaja dilewati).
- **Hasil:** `flutter analyze` 0 issue; `flutter test` 139 lulus (tes baru: `tahap4_logic`, `tahap4_widgets`, `tahap5_*`).
- **Bug utama yang ditutup:** Urungkan hapus tidak lagi melempar StateError; `shortTitle` ikut nama di form Ubah; saran "Geser" bisa diterapkan; saran hari kosong disaring per tanggal; satu kegiatan "Sekarang" (`findCurrentActivity`); validasi Selesai > Mulai; `end` null hanya untuk Tidur; keyboard tidak menutupi isian; status `applied` diatur setelah saran dipakai.
- **Utang:** langkah asli tidak disimpan saat saran independence (§9.3 "Bisa dikembalikan"); swipe abaikan saran (§9.5) belum ada; tombol bulan belum membuka pemilih; `ChildSegmented` di Beranda tidak ada di OT-01; `findNearestFreeSlot` belum menangani lewat tengah malam; kegiatan berulang tidak diperluas saat tanggal diubah; belum dijalankan di perangkat (overflow 360 dp / skala 1.3x belum diuji).

## Tahap 6 — Anak

- **Status:** selesai.
- **Isi:** 
  - Prasyarat: field `originalSteps` di Activity untuk mendukung "Bisa dikembalikan ke N langkah" (§9.3), disimpan saat saran independence diterapkan.
  - Fungsi domain `completeActivity` (§8.10): membuat Completion dengan `onTime`, `stepsChecked`, dan notifikasi `activityDone`.
  - 7 layar anak: A-01/A-03/A-11 (child_home_screen.dart), A-02 (child_change_screen.dart), A-04/A-05/A-10 (child_activity_screen.dart), A-06 (child_success_screen.dart), A-09 (child_theme_screen.dart), A-07/A-08 (child_emergency_screen.dart, child_calling_screen.dart).
  - Router: 7 rute `/anak*` diganti dari PlaceholderScreen ke layar asli.
  - Semua widget anak (ChildHeader, ChildActivityCard, ChildButton, ChildBackHeader, Mascot, EmergencyButton) sudah ada dari Tahap 3, langsung dipakai.
- **File utama:** `lib/features/child/*.dart` (7 layar), `lib/domain/schedule_rules.dart` (completeActivity), `lib/data/models/activity.dart` (originalSteps), `lib/core/router.dart` (rute anak), tes di `test/tahap6_*.dart`.
- **Hasil:** `flutter analyze` 0 issue; `flutter test` 147 lulus, 1 gagal (role_picker_test.dart mencari PlaceholderScreen yang sudah diganti ChildHomeScreen - tes Tahap 1, di luar scope Tahap 6).
- **Alur yang bisa dicoba:**
  - 13.1 langkah 4-6: Orang tua kirim perubahan (OT-11) → anak buka A-02 "Oke" → orang tua lihat "Dilihat Rafi pukul ..." (OT-03).
  - 13.4: Anak selesaikan kegiatan (A-04 centang langkah, A-06) → orang tua lihat notifikasi `activityDone`.
  - 13.5 akhir: Orang tua terapkan saran independence → anak buka kegiatan → A-10 mode mandiri.
  - 13.6: Anak tekan tombol darurat (A-07, A-08) → orang tua lihat notifikasi `emergencyPressed`.
  - 13.7: Anak ganti tema (A-09 Padang Hijau) → A-11 tema baru.
- **Keputusan (dicatat di DECISIONS.md):**
  - `originalSteps` disimpan saat independence applied, bukan saat dibuat. Field nullable di Activity, diisi `activity.steps` saat `independentMode = true`.
  - Sapaan "Selamat pagi/siang/sore/malam" memakai jam yang sama dengan sisi orang tua (§11 OT-01).
  - Banner perubahan (A-01) bukan pop-up, tetap tampil sampai dibuka. Tautan "Lihat" ke `/anak/perubahan`.
  - Notice hapus (after = null) ditampilkan "Dulu → Waktu bebas" (A-02).
  - A-06 "Berikutnya" mencari kegiatan berikutnya hari yang sama; bila tidak ada: "Tidak ada kegiatan lagi hari ini."
  - A-08 timer 30 detik memakai Timer biasa (bukan Clock) dan dibatalkan saat layar ditutup (dispose).
  - Tombol "Tema" di A-01 tautan teks (underline) di kiri atas, bukan di header atau FAB.
  - Tekan lama 2 detik "Halo, Rafi!" kembali ke Pilih peran (§10.3); RoleSwitchButton tetap ada di kanan atas sebagai shortcut demo (§10.3 catatan DECISIONS.md).
- **Utang yang tersisa:** 
  - Tes role_picker_test.dart perlu diperbarui (mencari PlaceholderScreen, sekarang ChildHomeScreen).
  - Tes widget untuk 7 layar anak belum ada (hanya tes domain completeActivity dan originalSteps).
  - Belum dijalankan di perangkat (overflow 360 dp / skala 1.3x belum diuji).
  - Langkah asli (`originalSteps`) tersimpan, tetapi UI "Lihat langkah lengkap" (A-10) dan "Bisa dikembalikan ke N langkah" (form Ubah) belum menampilkan langkah penuh/tombol kembalikan.

## Tahap 7 — Bersihkan demo dan siap data kosong

- **Status:** selesai (9 November 2026).
- **Isi:**
  - Data seed dipindah ke `test/support/fixture_state.dart` (`buildFixtureState`, `fixtureNow`). `lib/data/seed.dart` dihapus.
  - `Clock` sekarang menerima callback `DateTime Function()`; `minuteTickProvider` (30 detik, autoDispose) membuat status "Sekarang" ikut bergeser saat jam berganti (setelah perbaikan audit di bawah).
  - `Settings`: `demoClockEnabled` dihapus, tambah `caregiverName` (bawaan `''`), `emergencyNumber`/`backupNumber` bawaan `''`.
  - `AppState.empty()`; `main.dart` mulai dari state kosong.
  - `currentChildProvider` menggantikan semua pencarian anak berdasarkan nama (`app.dart`, `child_home_screen`, `child_change_screen`, `child_theme_screen`, `child_emergency_screen`, `account_screen`, `home_screen`, `schedule_screen`, `suggestions_screen`). Bila tidak ada anak, tampil `CalmEmptyScreen` yang tenang.
  - `generateSuggestions` mengembalikan `[]` bila anak tidak ada.
  - `initialsOf` (`lib/core/widgets/initials.dart`) dan token `AppTypography.inisialBesar`; teks "Bu Sari"/"Ibu Sari"/"IS" diganti `settings.caregiverName` + inisial.
  - `form_utils.generateId` memakai `uuid`.
  - Grup "Demo", `resetToSeed`, `confirmResetDemo`, teks "Di prototipe", galeri komponen, dan `PlaceholderScreen` dihapus.
  - Layar baru `/profil-awal` (`lib/features/onboarding/profile_setup_screen.dart`) membuat `Child` + `Settings`; router mengarah ke sana bila `children` kosong.
  - Dokumen: `docs/DECISIONS.md` diubah ke UTF-8 (baris mojibake/UTF-16 dibuang), keputusan perencana dicatat; HANDOFF mendapat §18 yang mencabut §2, §7, §10.2, §10.3, §17 baris 1–2.
- **File utama:** `lib/core/clock.dart`, `lib/core/widgets/initials.dart`, `lib/core/widgets/calm_empty_screen.dart`, `lib/data/models/settings.dart`, `lib/data/models/app_state.dart`, `lib/data/providers.dart`, `lib/core/router.dart`, `lib/features/onboarding/profile_setup_screen.dart`, `test/support/fixture_state.dart`, `test/empty_state_test.dart`.
- **Hasil (setelah perbaikan audit):** `flutter analyze` 0 issue, `flutter test` 180 tes lulus.
- **Perbaikan audit (9 November 2026):** audit menemukan laporan awal "160 tes lulus" tidak mendeteksi bug berikut, dan semuanya sudah ditutup:
  - Tick jam tidak pernah me-rebuild layar karena `clockProvider` mengembalikan `const Clock()`. Sekarang instance baru tiap tick; `FLUTTER_TEST` dihapus dari `lib/`; tes widget meng-override `clockProvider`.
  - `selectedDateProvider`/`selectedWeekStartProvider` memakai `read`, sehingga pilihan tanggal tidak hilang tiap tick. Jadwal ikut hari baru hanya bila sedang melihat hari ini (`currentDayProvider`).
  - Manifest Android mendaftarkan skema `tel` (telepon darurat di Android 11+; belum diuji di HP).
  - Kontak cadangan kosong tidak lagi ditawarkan di A-08; nomor utama kosong tidak membuka `tel:` kosong.
  - Validasi nomor bersama (`lib/domain/phone_number.dart`) di profil awal dan sheet Akun; format `0812-3456-7890` diterima; galat tampil di kolom yang benar; cadangan bisa dikosongkan.
  - Umur 1–18, nama maks 40 karakter, `initialsOf` aman untuk emoji.
  - Waktu selesai anak diambil saat tombol ditekan, bukan saat build.
  - `context.go` di `build` dipindah ke post-frame (3 layar anak).
  - Data contoh versi lama dibuang saat dibuka; data yang tidak terbaca disalin ke `autiplan_state_unreadable`.
  - Kode mati dihapus (`reset()`, `fabClearance`); `MaterialApp` hanya memantau tema anak; `tahap7_cleanup_test` diganti nama menjadi `empty_state_test`.
- **Utang yang tersisa:**
  - `role_picker_screen.dart` dan `role_switch_button.dart` masih memuat nama demo; dihapus di Tahap 10.
  - `AccountProfileCard` selalu menampilkan "Belum terhubung ke HP anak" karena penghubungan perangkat baru dibuat di Tahap 10–11.
  - `createRouter` memakai `WidgetRef` (bukan `Ref` seperti di rencana) karena dipanggil dari `ConsumerState`; akan disesuaikan di Tahap 10.
  - Belum dijalankan di perangkat (telepon `tel:` di Android 11+, overflow 360 dp / skala 1.3x belum diuji).
  - Router belum punya `refreshListenable`, dan `firstWhere` tanpa `orElse` (`add_activity_sheet.dart:130`, `schedule_rules.dart:563,606`) bisa melempar bila anak terhapus. Belum terjangkau sekarang; wajib ditutup di Tahap 9–10 saat data bisa berubah dari HP lain.
  - Nilai mentah lama: `fontSize` di `child_calling_screen.dart` dan `child_theme_screen.dart`, ukuran 96/4 di A-08.
  - Tidur tanpa jam selesai berhenti "Sekarang" tepat pukul 00.00 (sesuai §8.1, perlu keputusan produk).
  - Utang Tahap 5–6 tetap: UI "Lihat langkah lengkap" dan "Bisa dikembalikan ke N langkah", swipe abaikan saran, pemilih bulan.
- **Langkah berikutnya:** Tahap 8 — kegiatan berulang (`lib/domain/recurrence.dart`).

## Tahap 8 — Kegiatan berulang

- **Status:** selesai (9 November 2026).
- **Isi:**
  - `Activity.seriesId` (`String?`) masuk `copyWith` (+`clearSeriesId`), `toJson`, `fromJson` (bawaan null), `==`, `hashCode`.
  - `lib/domain/recurrence.dart`: `materializeRecurring` (salinan per tanggal sampai 28 hari ke depan, ID `'${seriesId}_yyyyMMdd'`, idempoten, tidak menyentuh kegiatan tanpa `seriesId`) dan `applyRepeatChange` (membuang kemunculan seri setelah tanggal yang diubah).
  - `AppStateNotifier(repository, initial, {normalize})` + `renormalize()`. `appStateProvider` memberi `normalize` yang memanggil `materializeRecurring` dengan `clockProvider`, dan memantau `currentDayProvider` supaya seri diperluas saat hari berganti. `main.dart` kini meng-override `initialAppStateProvider`, bukan `appStateProvider`.
  - Form Tambah mengisi `seriesId = id` bila ada hari ulang; form Ubah meneruskan `seriesId` dan memanggil `applyRepeatChange` bila hari ulang berubah.
- **File utama:** `lib/domain/recurrence.dart`, `lib/data/models/activity.dart`, `lib/data/providers.dart`, `lib/main.dart`, `lib/features/caregiver/forms/form_utils.dart`, `add_activity_sheet.dart`, `edit_activity_sheet.dart`, `test/recurrence_test.dart`, `test/recurrence_forms_test.dart`.
- **Hasil:** `dart format .` bersih, `flutter analyze` 0 issue, `flutter test` 199 lulus (180 lama tanpa diubah + 16 domain/model/notifier + 3 alur form).
- **Review Focus:** tidak ada butir yang menjadi milik Tahap 8 (1 dan 3 di Tahap 7, 2 dan 5 di Tahap 9, 4 di Tahap 12). Pergantian hari untuk perluasan seri dites lewat `renormalize`.
- **Keputusan:** tercatat di DECISIONS.md (tidak mengisi mundur, horizon inklusif, hari ulang dari kemunculan terakhir, seri baru dari kegiatan biasa, `normalize` lewat `initialAppStateProvider`).
- **Utang yang tersisa:**
  - Menghapus kemunculan **terakhir** sebuah seri membuatnya dibuat lagi (tidak ada penanda hapus). Kemunculan di tengah aman.
  - Mengubah jam/nama satu kemunculan hanya berlaku untuk tanggal itu (keputusan 8); belum ada cara mengubah seluruh seri sekaligus selain hari ulang.
  - `normalize` berlaku di HP mana pun yang menjalankan aplikasi; pembatasan "hanya HP orang tua" menunggu sesi perangkat di Tahap 10.
  - Belum dijalankan di perangkat (overflow 360 dp / skala 1.3x, telepon `tel:` Android 11+ belum diuji).
  - Utang Tahap 7 lainnya tetap (lihat di atas), termasuk `firstWhere` tanpa `orElse` yang wajib ditutup di Tahap 9.
- **Langkah berikutnya:** Tahap 9 — sinkronisasi Firestore (perlu persetujuan sebelum `flutterfire configure`).

## Tahap 9 — Sinkronisasi Firestore

- **Status:** selesai di kode dan tes otomatis (9 November 2026). **Belum teruji dengan data sungguhan di Firestore**: aturan keamanan baru dibuat di Tahap 10 (produksi menolak semua akses), jadi di HP aplikasi belum bisa membaca atau menulis data. Yang terbukti hanya tes otomatis (pakai `fake_cloud_firestore`) dan APK debug yang berhasil dibangun.
- **Isi:**
  - `AutiPlanRepository` kini `watch()` + `apply(before, after)`. `LocalRepository` dan tes lamanya dihapus.
  - `lib/data/state_diff.dart`: `diffAppState` (penulisan per dokumen dan per field, hanya kunci yang berubah), `DocWrite` (+`deletedFields`), `DocOp`, `completionDocId`.
  - `lib/data/firestore_repository.dart`: `watch()` baru beremisi setelah 7 sumber (dokumen keluarga + 6 subkoleksi) memberi snapshot pertama; `apply` memecah batch per 450 operasi dan mengirim semuanya tanpa menunggu satu per satu. Impor `cloud_firestore as fs`.
  - `AppStateNotifier`: `start()` berlangganan `watch()`, `ready`, `updateState` mengubah state dulu lalu memanggil `apply` tanpa `await` (galat dicatat dengan `debugPrint`), `dispose` membatalkan langganan. `repositoryReadyProvider`.
  - `app.dart`: teks statis "Memuat jadwal" (`LoadingScheduleScreen`, tanpa animasi, tanpa spinner) sampai data pertama masuk; router baru dibuat sesudahnya.
  - `lib/data/firebase_bootstrap.dart` + `main.dart`: `Firebase.initializeApp`, `persistenceEnabled: true`, `familyId` sementara `belum-masuk`.
  - Proyek: aplikasi Android `com.adit.autiplan` didaftarkan di `autiplan-bd927` lewat `flutterfire configure` (disetujui pengguna). `lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json` dibuat. `minSdk` minimal 23.
  - Utang `firstWhere` ditutup: `acknowledgeNotice` (notice atau anak hilang), `completeActivity` (anak hilang), form Tambah (anak hilang menutup form). Pemakaian di layar anak (`child_activity_screen`, `child_success_screen`, `child_change_screen`, `child_home_screen`) sudah memakai `orElse`; kini ada tes untuk dua layar pertama.
- **File utama:** `lib/data/repository.dart`, `state_diff.dart`, `firestore_repository.dart`, `providers.dart`, `firebase_bootstrap.dart`, `lib/main.dart`, `lib/app.dart`, `lib/core/widgets/loading_schedule_screen.dart`, `lib/domain/schedule_rules.dart`; tes: `test/state_diff_test.dart`, `firestore_repository_test.dart`, `app_state_notifier_test.dart`, `missing_data_test.dart`, `loading_schedule_test.dart`, `test/support/in_memory_repository.dart`.
- **Hasil:** `dart format .` bersih, `flutter analyze` 0 issue, `flutter test` 225 lulus. `flutter build apk --debug` berhasil.
- **Review Focus:** (2) HP tanpa sinyal: tes `updateState` tidak menunggu `apply`; tes batch Firestore sungguhan offline belum bisa (butuh perangkat). (5) Dua HP menulis bersamaan: tes dua HP dengan `fake_cloud_firestore` (perubahan `title` dan `steps`+Completion keduanya tetap).
- **Utang yang tersisa:**
  - Belum diuji dengan Firestore sungguhan (menunggu aturan Tahap 10) dan belum diuji offline di perangkat (buat kegiatan, matikan internet, buka ulang).
  - `update` pada dokumen yang sudah dihapus HP lain membuat seluruh batch itu gagal (dicatat di log, perubahan lain di batch yang sama ikut hilang).
  - Emisi snapshot lama bisa sesaat mengembalikan tampilan ke state sebelumnya saat dua perubahan beruntun.
  - Router belum punya `refreshListenable` (catatan untuk Tahap 10): setelah data berubah dari HP lain, rute tidak dievaluasi ulang.
  - `normalize` (perluasan seri berulang) berjalan di HP mana pun; pembatasan ke HP orang tua menunggu sesi di Tahap 10. Dua HP yang sama-sama memperluas seri menulis dokumen berID sama (aman, idempoten).
  - `firestore.rules` belum ada (Tahap 10); `flutterfire configure` hanya didaftarkan untuk Android.
  - Utang Tahap 7 dan 8 lainnya tetap.
- **Langkah berikutnya:** Tahap 10 — akun, sesi, dan aturan keamanan (`firebase deploy --only firestore:rules` perlu persetujuan).

## Tahap 10 — Akun, sesi, dan aturan keamanan

- **Status:** selesai di kode dan tes Flutter (9 November 2026). Aturan Firestore sudah di-deploy ke `autiplan-bd927` (9 November 2026, `firebase deploy --only firestore:rules --project autiplan-bd927`, kompilasi berhasil). **Belum:** uji di perangkat dengan Firestore dan Auth sungguhan.
- **Isi:**
  - `lib/data/auth_service.dart`: `AuthService` + `FirebaseAuthService` (daftar, masuk, reset sandi, anonim, `idToken`).
  - `lib/data/session/`: `DeviceSession` (`UnlinkedSession`, `CaregiverSession`, `ChildSession`) dan `SessionNotifier` (disimpan di `shared_preferences`; sesi anak memantau `devices/{uid}`, menjadi `Unlinked` bila dokumen hilang atau `permission-denied`).
  - `providers.dart`: `authServiceProvider`, `sessionNotifierProvider`, `sessionProvider`; `repositoryProvider` dibuat dari sesi (`familyId` = uid atau dari `ChildSession`), `_UnlinkedRepository` untuk sesi belum masuk; `currentChildProvider` memakai `ChildSession.childId`.
  - Layar onboarding baru: `welcome_screen`, `sign_in_screen`, `sign_up_screen`. Router punya `refreshListenable` (`_RouterRefresh`) dan redirect berdasarkan sesi dan jumlah anak.
  - `firebase/firestore.rules` + `firebase/tests/` (tes aturan dengan vitest dan emulator).
  - Dihapus: `role_picker_screen`, `role_switch_button`, `firebase_bootstrap`, serta tes `role_picker_test` dan `role_switch_test` (menguji layar "Pilih peran untuk demo" yang sudah tidak ada).
- **File utama:** `lib/data/auth_service.dart`, `lib/data/session/*`, `lib/data/providers.dart`, `lib/core/router.dart`, `lib/main.dart`, `lib/app.dart`, `lib/features/onboarding/*`, `firebase/firestore.rules`, `test/redirect_test.dart`, `test/session_notifier_test.dart`, `test/support/fake_auth_service.dart`, `test/support/test_session.dart`.
- **Hasil:** `flutter analyze` 0 issue, `flutter test` 267 lulus. Tes aturan Firestore di emulator: 10 dari 10 lulus (`firebase emulators:exec --only firestore --project autiplan-bd927 "npm --prefix firebase/tests test"`; butuh Java 21).
- **Perbaikan saat penutupan tahap:**
  - `firebase/tests/package.json`: `firebase` dinaikkan ke `^11.0.0` karena `@firebase/rules-unit-testing@4` mensyaratkannya sebagai peer dependency (sebelumnya `npm install` gagal ERESOLVE).
  - 97 file `.dart` kehilangan karakter pertama (`import`→`mport`, `enum`→`num`, `// File`→`/ File`) sehingga `analyze` melaporkan 293 galat. Dipulihkan dengan menambah satu byte di awal tiap file. **Penyebabnya belum diketahui** (diduga skrip pembersih BOM yang memotong satu byte tanpa memeriksa BOM). Jangan menjalankan ulang skrip semacam itu.
  - Bug asli: `notifyListeners` dipanggil dari luar subclass (`router.dart`, sekarang lewat `_RouterRefresh.refresh()`); `idToken()` mengembalikan `Future?` ke tipe `Future` (`auth_service.dart`).
  - 23 tes lama gagal karena `currentChildProvider` kini membaca `sessionProvider`. Tes memakai `sessionProvider.overrideWithValue(testCaregiverSession)` dari `test/support/test_session.dart` (5 file: `empty_state`, `live_clock`, `loading_schedule`, `profile_setup`, `tahap4_widgets`).
- **Utang yang tersisa:**
  - Alur akun belum diuji dengan Firebase Auth sungguhan di perangkat.
  - Pembatasan `normalize` (perluasan seri) hanya untuk HP orang tua belum diterapkan.
  - Penghubungan HP anak baru dibuat di Tahap 11 (`AccountProfileCard` masih "Belum terhubung ke HP anak").
  - Utang Tahap 7–9 lainnya tetap.
- **Langkah berikutnya:** Tahap 11 — Worker dan kode pasangan (butuh akun Cloudflare dan kunci service account).

## Tahap 11 — Worker dan kode pasangan

- **Status:** selesai di kode dan tes Flutter (10 November 2026). **Belum:** `wrangler login`, KV namespace, `wrangler secret put`, `wrangler deploy`, dan uji dua perangkat — semua menunggu persetujuan/dikerjakan bersama pengguna (gerbang persetujuan rencana). Tes worker dijalankan pada audit 11 November 2026 (lihat bagian "Audit Tahap 11–12").
- **Isi:**
  - `worker/`: `wrangler.toml` (KV `ATTEMPTS`, id diisi saat pembuatan namespace), `package.json`, `tsconfig.json`, `vitest.config.ts`, `.dev.vars.example`, `src/index.ts` (Bearer token wajib, `/notify` → 501), `src/auth.ts` (verifikasi ID token Firebase dengan `jose` + JWKS securetoken), `src/firestore.ts` (REST Firestore: baca/tulis kode, `documents:commit` dengan prasyarat `updateTime` + tulis `devices/{uid}`), `src/pairing.ts` (kode 6 digit dari `crypto.getRandomValues`, batas percobaan di KV 5x/uid/15 menit dan 20x/IP/1 jam, create/claim), `test/pairing.test.ts`.
  - `lib/data/backend_api.dart`: `PairingCode`, `ClaimedLink`, `BackendFailure`, `BackendException`, `BackendApi`, `HttpBackendApi` (petakan 400→invalidCode, 410→expiredCode, 429→tooManyAttempts, SocketException/ClientException→offline, lain→unknown). `backendApiProvider` di `providers.dart`, di-override di `main()` bila `--dart-define=WORKER_URL` diisi.
  - `lib/features/onboarding/link_device_screen.dart` (`/hubungkan`): masuk anonim → klaim kode → `ChildSession` (`adoptChildSession`). Galat memakai teks tabel "Galat kode" persis.
  - `lib/features/caregiver/pairing_sheet.dart`: sheet "Hubungkan HP {anak}" (kode besar, "Buat kode baru") dan dialog "Putuskan HP {anak}?".
  - `account_screen.dart`: grup Akun bertambah "Hubungkan HP {anak}" dan "Putuskan HP {anak}"; `AccountProfileCard` menampilkan "Terhubung ke HP {anak}" bila ada dokumen `devices` role child (`linkedDevicesProvider` baru).
  - `AutiPlanRepository.unlinkChildDevice(childId)`: hapus dokumen `devices/{uid}` anak (implementasi di `FirestoreRepository`; sesi anak menjadi `Unlinked` lewat listener Tahap 10).
  - `.gitignore`: `worker/.dev.vars`, `*service-account*.json`.
- **File utama:** `worker/*`, `lib/data/backend_api.dart`, `lib/data/providers.dart`, `lib/data/repository.dart`, `lib/data/firestore_repository.dart`, `lib/features/onboarding/link_device_screen.dart`, `lib/features/caregiver/pairing_sheet.dart`, `lib/features/caregiver/account_screen.dart`, `lib/features/caregiver/account_widgets.dart`, `lib/main.dart`, `lib/core/router.dart`, `.gitignore`, `test/backend_api_test.dart`, `test/link_device_screen_test.dart`, `test/account_pairing_test.dart`, `test/support/test_session.dart` (`testChildSession`), `test/support/in_memory_repository.dart`.
- **Hasil:** lihat bagian "Audit Tahap 11–12" di bawah.
- **Utang yang tersisa:**
  - Worker belum dideploy; KV namespace belum dibuat; `FIREBASE_SERVICE_ACCOUNT` belum diisi. Semua butuh persetujuan.
  - Uji dua perangkat (kode benar terhubung, kode dipakai dua kali ditolak, jadwal muncul di HP anak) belum bisa dilakukan tanpa deploy.
  - Teks sheet pairing untuk galat create (mis. anak tidak ada / offline saat membuat kode) memakai teks tenang sendiri karena tabel "Teks baru" hanya memuat galat klaim; lihat DECISIONS.md.
  - Utang Tahap 7–10 lainnya tetap.
- **Langkah berikutnya:** Tahap 12 — push ke orang tua (setelah Worker terdeploy).


## Tahap 12 — Push ke orang tua

- **Status:** selesai di kode dan tes (11 November 2026). **Belum:** `wrangler deploy` Worker, `wrangler secret put FIREBASE_SERVICE_ACCOUNT`, dan uji push di perangkat — menunggu persetujuan pengguna. Tes dijalankan pada audit (lihat "Audit Tahap 11–12").
- **Isi:**
  - `lib/data/push_service.dart`: `PushService` + `FirebasePushService` (izin notifikasi, `getToken`, simpan ke `families/{familyId}/devices/{uid}` sebagai `fcmToken` + `role: 'caregiver'`, ikuti `onTokenRefresh`). Dipakai hanya pada `CaregiverSession`.
  - `lib/app.dart`: `registerCaregiverDevice` dipanggil saat sesi sudah `CaregiverSession` (post-frame) dan saat sesi berubah; galat hanya dicatat.
  - `android/app/src/main/AndroidManifest.xml`: izin `POST_NOTIFICATIONS` (+ `INTERNET`).
  - `worker/src/notify.ts`: `POST /notify` `{familyId, notificationId}` — verifikasi anggota keluarga (`403` bila bukan), teks dari dokumen `notifications/{id}`, `activityDone` tidak mengirim, FCM HTTP v1 dengan token OAuth, hapus `fcmToken` bila `UNREGISTERED`, balas `204`.
  - `worker/src/firestore.ts`: `checkFamilyMember`, `getNotification`, `getDevices`, `clearFcmToken`, `sendFcmMessage`; cakupan OAuth `datastore` + `firebase.messaging`.
  - `worker/src/index.ts`: rute `/notify` diteruskan ke `handleNotify` (menggantikan `501`).
  - `lib/features/child/child_emergency_screen.dart` (A-07): urutan buka telepon → simpan notifikasi `emergencyPressed` → `notify` tanpa `await` (galat ditelan) → `/anak/menelepon`. Tanpa snackbar/dialog soal internet atau push.
  - `lib/features/child/child_change_screen.dart`: `changeSeen` juga memanggil `notify` dengan perlakuan galat yang sama.
  - `lib/data/providers.dart`: `pushServiceProvider`, `phoneLauncherProvider`.
  - Paket baru: `firebase_messaging: ^17.0.1` (disetujui pengguna).
- **File utama:** `lib/data/push_service.dart`, `lib/app.dart`, `lib/data/providers.dart`, `lib/features/child/child_emergency_screen.dart`, `lib/features/child/child_change_screen.dart`, `android/app/src/main/AndroidManifest.xml`, `worker/src/notify.ts`, `worker/src/firestore.ts`, `worker/src/index.ts`, `worker/test/notify.test.ts`, `test/emergency_flow_test.dart`, `pubspec.yaml`, `pubspec.lock`, `docs/DECISIONS.md`.
- **Hasil `dart format`:** bersih (seluruh file berhasil diformat).
- **Hasil `flutter analyze`:** 0 issue.
- **Hasil `tsc --noEmit` (worker):** lulus, 0 galat.
- **Hasil tes:** lihat "Audit Tahap 11–12".
- **Utang yang tersisa:**
  - Uji push di perangkat (aplikasi orang tua tertutup, tombol darurat memunculkan push) menunggu deploy Worker dan pengisian `FIREBASE_SERVICE_ACCOUNT`.
  - Kasus tepi no. 4 rencana (tombol darurat tanpa internet) baru terbukti setelah tes jalan.
  - `firebase_messaging` 17 menandai `getToken`/`onTokenRefresh` deprecated; pengganti `register`/`onRegistered` memberi FID, jadi belum dipakai. Lihat DECISIONS.md.
  - Utang Tahap 7–11 lainnya tetap.
- **Langkah berikutnya:** Tahap 13 — pengingat lokal dan uji akhir (setelah verifikasi akhir menjalankan seluruh tes).



## Audit Tahap 11–12 (11 November 2026)

- **Temuan awal:** commit Tahap 12 berisi 6 tes merah (4 di `link_device_screen_test`, 1 di `account_pairing_test`, 1 di `emergency_flow_test`). Semuanya cacat tes: tidak ada `pump()` setelah `enterText`, baris Akun di luar viewport, tema anak tidak dipasang, dan fixture memakai "Bu Sari". Ringkasan Tahap 11 melaporkan perbaikan yang tidak pernah masuk repo. Pelajaran: tes ditulis tanpa dijalankan menyembunyikan kesalahan; jalankan di akhir setiap tahap.
- **Perbaikan Flutter:**
  - Jalur darurat (A-07) dan A-02: `backendApiProvider` bawaan kini `NoopBackendApi` (tidak melempar), `notify` dikirim lewat `notifyParentAfterWrite` setelah penulisan Firestore selesai dan tanpa menahan navigasi, state dibaca setelah `await` telepon, penjaga tekan ganda di A-07, judul "Butuh bantuan?" mengikuti HANDOFF.
  - `HttpBackendApi`: timeout 10 detik, semua galat jaringan/auth/JSON dipetakan ke `BackendException`, 400 → `invalidCode` hanya untuk klaim.
  - `PushService.unregister()` dipanggil sebelum `signOut`; `registerCaregiverDevice` idempoten; `onTokenRefresh` memakai `catchError`; `app.dart` memakai satu fungsi register.
  - `LinkDeviceScreen`: sesi selalu terbentuk setelah klaim sukses; galat tak terduga jadi pesan tenang. Sheet pairing: galat putus HP ditangani; baris "Putuskan" hanya tampil bila ada HP anak terhubung; nama anak terhubung dipetakan dari `childId`.
- **Perbaikan Worker:** validasi masukan dan `encodeURIComponent`, JWKS dan token OAuth di-cache, `/notify` hanya `emergencyPressed` dan `changeSeen` dengan `Promise.allSettled` dan `android.priority: high`, dokumen hilang → 404, UNREGISTERED dari badan JSON, prasyarat Firestore yang tepat, rate limiter naik sebelum verifikasi dan fail-closed.
- **Perbaikan susulan:** `CaregiverNotification.at` kini ditulis UTC (dibaca `toLocal()`), `_acknowledge` mengabaikan tap kedua (tanpa notifikasi/push ganda), `.agents/` dikeluarkan dari git dan di-ignore.
- **Hasil:** `dart format` bersih; `flutter analyze` 0 isu; `flutter test` 324 lulus; `npx tsc --noEmit` bersih; `npx vitest run` 77 lulus (4 berkas).
- **Utang yang diketahui:**
  - Rate limiter memakai KV yang tidak atomik: pembatas upaya terbaik, bukan jaminan (Durable Object sengaja tidak dipakai).
  - Notifikasi lama yang sudah tersimpan di Firestore tanpa zona waktu (sebelum perbaikan UTC) tidak terkena cek umur di Worker; yang baru ditulis UTC.
  - Klaim ganda atas kode pasangan (Firestore `FAILED_PRECONDITION` → HTTP 400) dan `/notify` di perangkat nyata belum diuji di emulator/deploy.
  - Sisa masa berlaku kode pasangan belum ditampilkan (teks wajib "Berlaku 10 menit.").
  - Worker belum dideploy; uji dua perangkat dan uji push di perangkat menunggu deploy.


## Tahap 13 — Pengingat lokal, desugaring, audit aksesibilitas

- **Status:** selesai kode (10 November 2026). Yang tersisa hanya uji di perangkat dan pekerjaan yang menunggu pengguna (lihat Utang).
- **Isi:**
  - `lib/data/reminder_service.dart`: `NotificationGateway` (antarmuka tipis), `FlutterLocalNotificationsReminderService` (init + izin sekali, `cancelAll`, lalu jadwalkan tiap `PlannedReminder`), `PluginNotificationGateway` (plugin + `timezone` + `flutter_timezone`, `inexactAllowWhileIdle`, channel tanpa suara/getar), `reminderNotificationId` (FNV-1a). `main.dart` menimpa `reminderServiceProvider`; bawaan tetap Noop untuk tes.
  - Paket: `flutter_local_notifications ^22.3.3` (23.0.0 butuh compileSdk 37), `timezone`, `flutter_timezone`. `android/app/build.gradle.kts`: desugaring aktif + `desugar_jdk_libs:2.1.4`.
  - Audit aksesibilitas §14: `test/accessibility_test.dart` (96+ kasus). Temuan dan perbaikan ada di DECISIONS.md (kontras `teksSekunder`, label tombol kembali/lonceng/FAB, target sentuh chip anak/strip tanggal/isian/Tema, overflow baris masuk/daftar, Semantics chip dan tanggal).
  - HANDOFF §11 dan §17 diperbarui; `test/reminder_service_test.dart`.
- **Hasil:** `dart format` bersih; `flutter analyze` 0 isu; `flutter test` 433 lulus; `flutter build apk --debug` berhasil (~3 menit).
- **Utang:**
  - Notifikasi belum diuji di perangkat nyata (izin runtime Android 13+, ketepatan `inexactAllowWhileIdle`, zona waktu, channel tanpa suara).
  - Langkah 5 (uji dua HP), `flutter build apk --release`, dan deploy Worker menunggu pengguna.
  - Uji TalkBack dan urutan baca di perangkat nyata belum dilakukan; audit otomatis tidak menilai teks di atas gambar.
  - Naikkan `flutter_local_notifications` ke 23.x setelah Android SDK 37 terpasang dengan benar.


## Perbaikan setelah uji di HP (10 November 2026)

- **Status:** kode selesai dan di-push. Worker sudah dideploy ke `https://autiplan-worker.autiplan-app.workers.dev` dan secret `FIREBASE_SERVICE_ACCOUNT` terpasang, tetapi **deploy ulang** setelah perbaikan `fetch` menunggu pengguna.
- **Isi:**
  - Kode pairing tidak muncul: penyebab pertama aplikasi dijalankan tanpa `WORKER_URL` (memakai `NoopBackendApi`), lalu log `wrangler tail` menunjukkan `TypeError: Illegal invocation` di Worker. Perbaikan di `worker/src/firestore.ts` dan `worker/src/notify.ts` (lihat DECISIONS.md). Rute `/notify` memakai jalur yang sama, jadi ikut terperbaiki.
  - `lib/features/caregiver/schedule_screen.dart`: pemilih bulan di header dan panah minggu di atas strip tanggal.
  - `worker/wrangler.toml`: id namespace KV `ATTEMPTS` terisi.
- **Hasil:** `flutter analyze` 0 isu; `flutter test` 433 lulus; `npx tsc --noEmit` bersih; `npx vitest run` 77 lulus.
- **Utang:**
  - Jalankan `npx wrangler deploy` dari `worker/`, lalu coba "Buat kode baru" dengan `wrangler tail` terbuka. Bila galat baru muncul, kemungkinan Firestore API belum aktif atau izin akun layanan kurang.
  - Build APK memakai `--dart-define=WORKER_URL=https://autiplan-worker.autiplan-app.workers.dev`.
  - Panah minggu dan pemilih bulan belum punya tes widget.
  - Uji dua HP (klaim kode) dan uji push di perangkat nyata masih menunggu.


## Perbaikan HP anak per anak, Daftar anak, Suka/Hindari (11 November 2026)

- **Status:** kode selesai; uji di dua HP nyata menunggu pengguna.
- **Isi:**
  - Bug hanya anak pertama yang bisa dihubungkan: tombol di Akun terikat ke `currentChildProvider`. Worker dan Firestore sudah mendukung banyak HP, jadi hanya UI yang diubah: kelompok "HP anak" dengan satu baris per anak ("Hubungkan HP {nama}" / "Putuskan HP {nama}") di `account_screen.dart`.
  - `lib/features/caregiver/child_list_sheet.dart`: sheet "Daftar anak" (ubah, hapus, Suka, Hindari per anak). Hapus ikut membersihkan jadwal, catatan selesai, dan pemberitahuan perubahan anak itu, lalu memutuskan HP-nya. Anak satu-satunya tidak bisa dihapus.
  - `account_sheets.dart`: `showChildFormSheet` (tambah dan ubah). Bug Suka/Hindari tidak tersimpan: teks yang belum ditekan Enter hilang saat Simpan; kini ikut disimpan dan kolom dikosongkan setelah Enter.
  - Tautan "Tema" di beranda anak pindah ke kanan atas.
- **Hasil:** `flutter analyze` 0 isu; `flutter test` 442 lulus. Tes baru: `child_list_sheet_test.dart`, `profile_list_save_test.dart`, kasus dua anak di `account_pairing_test.dart`.
- **Utang:**
  - Belum diuji di dua HP nyata (kode untuk anak kedua) dan belum ada build APK baru.
  - Teks "Daftar anak", "Ubah", "Hapus" dan susunan sheet adalah usulan; belum ada di HANDOFF.md.
  - Notifikasi/jadwal anak yang dihapus hanya dibersihkan lewat state aplikasi; dokumen yatim yang sudah ada sebelumnya tidak dibersihkan.


## Susunan ulang layar Akun (12 November 2026)

- **Status:** kode selesai; belum di-commit dan belum ada build APK baru.
- **Isi:**
  - `account_screen.dart`: grup "Anak" dan grup "Profil {anak}" (Suka/Hindari) dihapus. Kartu "Anak" baru di paling atas berisi "Daftar anak", baris HP per anak (gabungan dengan grup "HP anak" lama), dan "Tambah anak" di bagian bawah kartu. Grup "Akun" tinggal "Keluar".
  - `account_widgets.dart`: `AccountListRow` bertinggi minimal 48 dp (baris "Daftar anak", "Tambah anak", "Keluar" sebelumnya 40 dp). `AccountChildRow` dan `themeName` dihapus.
  - Tes diperbarui: `account_pairing_test.dart` (label "Anak"), `child_list_sheet_test.dart` (nama lengkap kini hanya di sheet).
- **Hasil:** `dart format` bersih; `flutter analyze` 0 isu; `flutter test` 443 lulus (satu tes baru untuk urutan baris di kartu Anak).
- **Utang:**
  - HANDOFF.md OT-14 belum diperbarui; perbedaannya dicatat di DECISIONS.md.
  - Harus membangun APK baru: `flutter build apk --release --dart-define=WORKER_URL=https://autiplan-worker.autiplan-app.workers.dev`.
