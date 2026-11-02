import 'package:autiplan/data/models/models.dart';

/// Builds the initial seed state as specified in HANDOFF.md §7.
AppState buildSeedState() {
  // ── 7.2 Children ────────────────────────────────────────────────
  const rafi = Child(
    id: 'child-rafi',
    name: 'Rafi',
    fullName: 'Rafi Ramadhan',
    age: 12,
    theme: ChildTheme.lautTenang,
    likes: ['Bersepeda', 'Film animasi'],
    avoids: ['Suara keras', 'Tempat ramai'],
  );

  const atalia = Child(
    id: 'child-atalia',
    name: 'Atalia',
    fullName: 'Atalia Putri',
    age: 9,
    theme: ChildTheme.padangHijau,
    likes: ['Puzzle'],
    avoids: ['Suara keras'],
  );

  // ── 7.3 Rafi's activities, Friday 1 May 2026 ───────────────────
  final friday = DateTime(2026, 5, 1);

  // Template activities for Rafi on May 1
  final rafiSekolah1Mei = Activity(
    id: 'rafi-sekolah-20260501',
    childId: rafi.id,
    title: 'Sekolah',
    shortTitle: 'Sekolah',
    icon: ActivityIcon.sekolah,
    date: friday,
    start: const TimeOfDayLite(7, 0),
    end: const TimeOfDayLite(8, 0),
    steps: const [
      'Bangun dan rapikan tempat tidur',
      'Sarapan',
      'Pakai seragam',
      'Berangkat sekolah',
    ],
    repeatWeekdays: const {1, 2, 3, 4, 5}, // Mon-Fri
  );

  final rafiSepeda1Mei = Activity(
    id: 'rafi-sepeda-20260501',
    childId: rafi.id,
    title: 'Sepeda Santai',
    shortTitle: 'Sepeda',
    icon: ActivityIcon.sepeda,
    date: friday,
    start: const TimeOfDayLite(16, 0),
    end: const TimeOfDayLite(17, 0),
    steps: const [
      'Pakai helm dan sepatu',
      'Bersepeda santai di dekat rumah',
      'Parkir sepeda, lalu minum air putih',
    ],
    repeatWeekdays: const {1, 2, 3, 4, 5},
  );

  final rafiNgaji1Mei = Activity(
    id: 'rafi-ngaji-20260501',
    childId: rafi.id,
    title: 'Ngaji di Rumah',
    shortTitle: 'Ngaji',
    icon: ActivityIcon.ngaji,
    date: friday,
    start: const TimeOfDayLite(18, 0),
    end: const TimeOfDayLite(19, 0),
    steps: const [
      'Ambil wudu dengan tenang',
      "Siapkan Iqra atau Al-Qur'an",
      'Membaca bersama Ustaz Farhan',
    ],
    repeatWeekdays: const {1, 2, 3, 4, 5},
  );

  final rafiLes1Mei = Activity(
    id: 'rafi-les-20260501',
    childId: rafi.id,
    title: 'Les dengan Pak Lana',
    shortTitle: 'Les',
    icon: ActivityIcon.les,
    date: friday,
    start: const TimeOfDayLite(20, 0),
    end: const TimeOfDayLite(20, 45),
    steps: const [
      'Siapkan buku dan alat tulis',
      'Belajar bersama Pak Lana',
      'Rapikan buku setelah selesai',
    ],
    repeatWeekdays: const {5}, // Friday only
  );

  final rafiTidur1Mei = Activity(
    id: 'rafi-tidur-20260501',
    childId: rafi.id,
    title: 'Istirahat & Tidur Malam',
    shortTitle: 'Tidur',
    icon: ActivityIcon.tidur,
    date: friday,
    start: const TimeOfDayLite(21, 0),
    end: null, // no end — shows "Pagi"
    steps: const ['Sikat gigi dan cuci muka', 'Ganti baju tidur', 'Tidur'],
    repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7}, // Every day
  );

  // ── Rafi's activities for 24 Apr, 27–30 Apr (repeated ones) ─────
  // Repeating activities: Sekolah (Mon-Fri), Sepeda Santai (Mon-Fri),
  // Ngaji di Rumah (Mon-Fri), Tidur (Every day)
  // Apr 24 = Friday, Apr 27 = Monday, Apr 28 = Tuesday,
  // Apr 29 = Wednesday, Apr 30 = Thursday

  final historicalDates = [
    DateTime(2026, 4, 24), // Friday
    DateTime(2026, 4, 27), // Monday
    DateTime(2026, 4, 28), // Tuesday
    DateTime(2026, 4, 29), // Wednesday
    DateTime(2026, 4, 30), // Thursday
  ];

  final List<Activity> historicalActivities = [];
  for (final date in historicalDates) {
    final dateStr = _dateStr(date);
    historicalActivities.addAll([
      rafiSekolah1Mei.copyWith(id: 'rafi-sekolah-$dateStr', date: date),
      rafiSepeda1Mei.copyWith(id: 'rafi-sepeda-$dateStr', date: date),
      rafiNgaji1Mei.copyWith(id: 'rafi-ngaji-$dateStr', date: date),
      rafiTidur1Mei.copyWith(id: 'rafi-tidur-$dateStr', date: date),
    ]);
  }

  // ── 7.4 Atalia's activities, Friday 1 May 2026 ─────────────────
  final ataliaSekolah = Activity(
    id: 'atalia-sekolah-20260501',
    childId: atalia.id,
    title: 'Sekolah TK B',
    shortTitle: 'Sekolah',
    icon: ActivityIcon.sekolah,
    date: friday,
    start: const TimeOfDayLite(8, 0),
    end: const TimeOfDayLite(11, 0),
    steps: const [],
    repeatWeekdays: const {},
  );

  final ataliaMakan = Activity(
    id: 'atalia-makan-20260501',
    childId: atalia.id,
    title: 'Makan Siang Bersama',
    shortTitle: 'Makan',
    icon: ActivityIcon.makan,
    date: friday,
    start: const TimeOfDayLite(12, 0),
    end: const TimeOfDayLite(13, 0),
    steps: const [],
    repeatWeekdays: const {},
  );

  final ataliaPuzzle = Activity(
    id: 'atalia-puzzle-20260501',
    childId: atalia.id,
    title: 'Bermain Puzzle',
    shortTitle: 'Puzzle',
    icon: ActivityIcon.main,
    date: friday,
    start: const TimeOfDayLite(16, 30),
    end: const TimeOfDayLite(17, 30),
    steps: const [],
    repeatWeekdays: const {},
  );

  // ── All activities ──────────────────────────────────────────────
  final allActivities = [
    // Rafi May 1
    rafiSekolah1Mei,
    rafiSepeda1Mei,
    rafiNgaji1Mei,
    rafiLes1Mei,
    rafiTidur1Mei,
    // Rafi historical
    ...historicalActivities,
    // Atalia May 1
    ataliaSekolah,
    ataliaMakan,
    ataliaPuzzle,
  ];

  // ── Completions ─────────────────────────────────────────────────
  // Rafi Sekolah May 1 completed at 07:55 on time (all steps checked)
  final completions = <Completion>[
    Completion(
      activityId: rafiSekolah1Mei.id,
      date: friday,
      completedAt: DateTime(2026, 5, 1, 7, 55),
      onTime: true,
      stepsChecked: const [true, true, true, true],
    ),
    // Atalia's completed activities on May 1
    Completion(
      activityId: ataliaSekolah.id,
      date: friday,
      completedAt: DateTime(2026, 5, 1, 10, 50),
      onTime: true,
      stepsChecked: const [],
    ),
    Completion(
      activityId: ataliaMakan.id,
      date: friday,
      completedAt: DateTime(2026, 5, 1, 12, 50),
      onTime: true,
      stepsChecked: const [],
    ),
    // Sepeda Santai completions for 24, 27, 28, 29, 30 April (on time at 16:50)
    for (final date in historicalDates)
      Completion(
        activityId: 'rafi-sepeda-${_dateStr(date)}',
        date: date,
        completedAt: DateTime(date.year, date.month, date.day, 16, 50),
        onTime: true,
        stepsChecked: const [true, true, true],
      ),
  ];

  // ── 7.5 Initial notifications (today) ───────────────────────────
  final notifications = <CaregiverNotification>[
    CaregiverNotification(
      id: 'notif-1',
      type: NotificationType.activityDone,
      text: 'Rafi menyelesaikan Sekolah',
      at: DateTime(2026, 5, 1, 8, 0),
      read: false,
    ),
    CaregiverNotification(
      id: 'notif-2',
      type: NotificationType.emergencyPressed,
      text: 'Rafi menekan tombol bantuan',
      at: DateTime(2026, 5, 1, 7, 30),
      read: false,
      badge: 'Sudah ditelepon',
    ),
    CaregiverNotification(
      id: 'notif-3',
      type: NotificationType.activityStarted,
      text: 'Rafi mulai Sepeda Santai',
      at: DateTime(2026, 5, 1, 16, 0),
      read: false,
    ),
  ];

  // ── 7.6 No ChangeNotice in seed ─────────────────────────────────

  // ── Settings ────────────────────────────────────────────────────
  const settings = Settings();

  return AppState(
    children: [rafi, atalia],
    activities: allActivities,
    completions: completions,
    notices: const [],
    notifications: notifications,
    suggestionStatus: const {},
    settings: settings,
  );
}

String _dateStr(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
