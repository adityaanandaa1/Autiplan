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

- **Status:** sebagian. Fungsi dasar dan tes ada, tapi hasil inspeksi (2 November 2026) menemukan bug dan tes yang belum menguji kode asli.
- **File utama:** `lib/domain/schedule_rules.dart`, `lib/domain/suggestion_engine.dart`, tes di `test/` (`schedule_rules_*`, `suggestion_engine_test`, `change_notice_test`, `completion_logic_test`).
- **Hasil:** `flutter analyze` bersih, 55 tes lulus.

### Utang yang diketahui (belum diperbaiki)
1. **emptyDay terlalu banyak:** `_generateEmptyDaySuggestions` memeriksa 7 hari ke depan, padahal HANDOFF §9.4 hanya minggu yang ditampilkan (Jum 1 – Min 3 Mei). Kegiatan berulang juga tidak diperluas ke tanggal depan.
2. **Bisa crash:** `_generateQuietTimeSuggestions` memakai `todayActivities.first` di `orElse`; melempar `StateError` bila anak tidak punya kegiatan hari itu.
3. **Teks "Kenapa (data)" independence** tidak sama dengan §9.3 ("{judul} selesai tepat waktu {rentang hari} minggu ini").
4. **Tes 5, 7, 8 tidak menguji kode asli:** hanya memakai `copyWith` dan objek manual. Belum ada fungsi murni untuk ubah kegiatan (dengan/tanpa ChangeNotice), hapus + urungkan, dan acknowledge.
5. **Tes 12 tidak menguji kode asli:** memakai `List<bool>.every` lokal. Belum ada fungsi seperti `canComplete(activity, checkedSteps)` (§8.10).
6. **Tes saran terlalu longgar:** Tes 9 dan 11 memakai `orElse: () => ...first`; Tes 9c memakai `activityId.contains('sepeda')`.
7. Kecil: `findNearestFreeSlot` memakai `+ 10` tetap (seharusnya `Settings.minGapMinutes`); "Sekarang" tanpa `end` memakai durasi 30 jam (spesifikasi: `start ≤ now`).
8. Isi detail saran independence dan catatan "Bisa dikembalikan ke N langkah" belum ada di model `Suggestion` (mungkin urusan Tahap 4–5).

### Langkah berikutnya
Perbaiki butir 1–3 dan 7, buat fungsi murni untuk butir 4–5 di `schedule_rules.dart`, tulis ulang tesnya agar memanggil fungsi itu, lalu perbarui bagian ini.

## Tahap 3 — Komponen

- **Status:** selesai.
- **Isi:** 14 widget di `lib/core/widgets/`:
  - **Orang tua:** `CaregiverHeader`, `CaregiverNavBar`, `ChildSegmented`, `WeekStrip`, `DaySummary`, `ActivityRow`, `CardSurface`, `SuggestionCard`, `ChangeNoticeCard`, `PrimaryButton`, `SecondaryButton`, `DangerButton`, `DangerOutlineButton`, `AppTextButton`, `AddFab`, `CalmSnackbar`.
  - **Anak:** `ChildHeader`, `ChildActivityCard`.
  - Galeri komponen di `/dev/komponen` (debug only) menampilkan semua widget dengan data contoh.
- **File utama:** `lib/core/widgets/*.dart`, `lib/features/dev/component_gallery_screen.dart`, `lib/core/router.dart`.
- **Hasil:** `flutter analyze` bersih, `flutter test` 55 tes lulus (komponen UI tidak dites unit, hanya tampil di galeri).
- **Catatan:**
  - Ikon `mandi` memakai `LucideIcons.bath` (bukan `shower` yang tidak ada di lucide_icons_flutter v4).
  - Deprecated `withOpacity` diganti `withValues(alpha:)` untuk kompatibilitas Flutter 3.44.
  - Rute `/dev/komponen` hanya ada di `kDebugMode`.

### Langkah berikutnya
Tahap 4: buat layar Beranda, Jadwal, Akun, Notifikasi, Saran, Detail saran (tanpa form). Pakai komponen yang sudah ada.

## Tahap 4 — Orang tua: lihat
- **Status:** belum dimulai.

## Tahap 5 — Orang tua: form
- **Status:** belum dimulai.

## Tahap 6 — Anak
- **Status:** belum dimulai. Ingat catatan di DECISIONS.md: pasang `RoleSwitchButton` di Jadwal anak yang asli.

## Tahap 7 — Rapikan
- **Status:** belum dimulai.

