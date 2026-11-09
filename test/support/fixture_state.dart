import 'package:autiplan/data/models/models.dart';

/// Jam demo untuk tes: Jumat, 1 Mei 2026, 16.00 WIB
final fixtureNow = DateTime(2026, 5, 1, 16, 0);

/// Builds the fixture state for tests, previously buildSeedState().
AppState buildFixtureState() {
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

  final friday = DateTime(2026, 5, 1);

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
    repeatWeekdays: const {1, 2, 3, 4, 5},
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
    repeatWeekdays: const {5},
  );

  final rafiTidur1Mei = Activity(
    id: 'rafi-tidur-20260501',
    childId: rafi.id,
    title: 'Istirahat & Tidur Malam',
    shortTitle: 'Tidur',
    icon: ActivityIcon.tidur,
    date: friday,
    start: const TimeOfDayLite(21, 0),
    end: null,
    steps: const ['Sikat gigi dan cuci muka', 'Ganti baju tidur', 'Tidur'],
    repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
  );

  final historicalDates = [
    DateTime(2026, 4, 24),
    DateTime(2026, 4, 27),
    DateTime(2026, 4, 28),
    DateTime(2026, 4, 29),
    DateTime(2026, 4, 30),
  ];

  final historicalActivities = <Activity>[
    for (final date in historicalDates) ...[
      Activity(
        id: 'rafi-sekolah-${_dateStr(date)}',
        childId: rafi.id,
        title: 'Sekolah',
        shortTitle: 'Sekolah',
        icon: ActivityIcon.sekolah,
        date: date,
        start: const TimeOfDayLite(7, 0),
        end: const TimeOfDayLite(8, 0),
        steps: const [
          'Bangun dan rapikan tempat tidur',
          'Sarapan',
          'Pakai seragam',
          'Berangkat sekolah',
        ],
        repeatWeekdays: const {1, 2, 3, 4, 5},
      ),
      Activity(
        id: 'rafi-sepeda-${_dateStr(date)}',
        childId: rafi.id,
        title: 'Sepeda Santai',
        shortTitle: 'Sepeda',
        icon: ActivityIcon.sepeda,
        date: date,
        start: const TimeOfDayLite(16, 0),
        end: const TimeOfDayLite(17, 0),
        steps: const [
          'Pakai helm dan sepatu',
          'Bersepeda santai di dekat rumah',
          'Parkir sepeda, lalu minum air putih',
        ],
        repeatWeekdays: const {1, 2, 3, 4, 5},
      ),
      Activity(
        id: 'rafi-ngaji-${_dateStr(date)}',
        childId: rafi.id,
        title: 'Ngaji di Rumah',
        shortTitle: 'Ngaji',
        icon: ActivityIcon.ngaji,
        date: date,
        start: const TimeOfDayLite(18, 0),
        end: const TimeOfDayLite(19, 0),
        steps: const [
          'Ambil wudu dengan tenang',
          "Siapkan Iqra atau Al-Qur'an",
          'Membaca bersama Ustaz Farhan',
        ],
        repeatWeekdays: const {1, 2, 3, 4, 5},
      ),
      Activity(
        id: 'rafi-tidur-${_dateStr(date)}',
        childId: rafi.id,
        title: 'Istirahat & Tidur Malam',
        shortTitle: 'Tidur',
        icon: ActivityIcon.tidur,
        date: date,
        start: const TimeOfDayLite(21, 0),
        end: null,
        steps: const ['Sikat gigi dan cuci muka', 'Ganti baju tidur', 'Tidur'],
        repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
      ),
    ],
  ];

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

  final allActivities = [
    rafiSekolah1Mei,
    rafiSepeda1Mei,
    rafiNgaji1Mei,
    rafiLes1Mei,
    rafiTidur1Mei,
    ...historicalActivities,
    ataliaSekolah,
    ataliaMakan,
    ataliaPuzzle,
  ];

  final completions = <Completion>[
    Completion(
      activityId: rafiSekolah1Mei.id,
      date: friday,
      completedAt: DateTime(2026, 5, 1, 7, 55),
      onTime: true,
      stepsChecked: const [true, true, true, true],
    ),
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
    for (final date in historicalDates)
      Completion(
        activityId: 'rafi-sepeda-${_dateStr(date)}',
        date: date,
        completedAt: DateTime(date.year, date.month, date.day, 16, 50),
        onTime: true,
        stepsChecked: const [true, true, true],
      ),
  ];

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

  return AppState(
    children: [rafi, atalia],
    activities: allActivities,
    completions: completions,
    notices: const [],
    notifications: notifications,
    suggestionStatus: const {},
    settings: const Settings(
      caregiverName: 'Bu Sari',
      emergencyNumber: '081234567890',
      backupNumber: '081298765432',
    ),
  );
}

String _dateStr(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
