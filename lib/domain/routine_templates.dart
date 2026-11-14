import '../data/models/models.dart';

enum RoutineCategory {
  pagi('Pagi', 'Rutinitas awal hari yang segar & teratur'),
  sekolah('Sekolah & Siang', 'Aktivitas belajar formal dan istirahat siang'),
  sore('Sore & Olahraga', 'Aktivitas fisik, hobi kreatif, dan kebersihan'),
  malam('Malam & Spiritual', 'Ibadah, waktu tenang tanpa gawai, dan tidur nyenyak');

  const RoutineCategory(this.label, this.description);
  final String label;
  final String description;
}

class RoutineTemplateItem {
  const RoutineTemplateItem({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.start,
    this.end,
    this.steps = const [],
    required this.category,
    required this.description,
  });

  final String id;
  final String title;
  final String shortTitle;
  final ActivityIcon icon;
  final TimeOfDayLite start;
  final TimeOfDayLite? end;
  final List<String> steps;
  final RoutineCategory category;
  final String description;

  Activity toActivity({
    required String childId,
    required DateTime date,
    String? customId,
  }) {
    return Activity(
      id: customId ?? 'tpl_${id}_${date.millisecondsSinceEpoch}_${start.hour}${start.minute}',
      childId: childId,
      title: title,
      shortTitle: shortTitle,
      icon: icon,
      date: DateTime(date.year, date.month, date.day),
      start: start,
      end: end,
      steps: List.from(steps),
      independentMode: false,
    );
  }
}

class RoutinePack {
  const RoutinePack({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.items,
  });

  final String id;
  final String name;
  final String description;
  final RoutineCategory category;
  final ActivityIcon icon;
  final List<RoutineTemplateItem> items;
}

/// Seluruh katalog 23 opsi template rutinitas terstruktur untuk AutiPlan v2.
final List<RoutineTemplateItem> allRoutineTemplates = [
  // --- KATEGORI 1: PAGI (6 Opsi) ---
  const RoutineTemplateItem(
    id: 'pagi_bangun',
    title: 'Bangun & Rapikan Tempat Tidur',
    shortTitle: 'Bangun Tidur',
    icon: ActivityIcon.mandi,
    start: TimeOfDayLite(5, 30),
    end: TimeOfDayLite(6, 0),
    category: RoutineCategory.pagi,
    description: 'Melatih anak memulai hari dengan teratur dan mandiri.',
    steps: [
      'Buka selimut perlahan',
      'Rapikan bantal dan guling',
      'Lipat selimut dengan rapi',
    ],
  ),
  const RoutineTemplateItem(
    id: 'pagi_senam',
    title: 'Senam & Peregangan Pagi',
    shortTitle: 'Senam Pagi',
    icon: ActivityIcon.sepeda,
    start: TimeOfDayLite(6, 0),
    end: TimeOfDayLite(6, 20),
    category: RoutineCategory.pagi,
    description: 'Gerakan motorik ringan untuk menyegarkan fokus anak.',
    steps: [
      'Peregangan tangan ke atas',
      'Memutar bahu dan pinggang pelan-pelan',
      'Jalan di tempat 20 hitungan',
      'Minum segelas air putih hangat',
    ],
  ),
  const RoutineTemplateItem(
    id: 'pagi_mandi',
    title: 'Mandi Pagi & Sikat Gigi',
    shortTitle: 'Mandi Pagi',
    icon: ActivityIcon.mandi,
    start: TimeOfDayLite(6, 20),
    end: TimeOfDayLite(6, 40),
    category: RoutineCategory.pagi,
    description: 'Rutinitas kebersihan sensorik dengan air sejuk/hangat.',
    steps: [
      'Siapkan handuk dan baju bersih',
      'Basahi badan dan pakai sabun',
      'Sikat gigi sampai bersih',
      'Keringkan badan dengan handuk',
    ],
  ),
  const RoutineTemplateItem(
    id: 'pagi_sarapan',
    title: 'Sarapan Pagi Bergizi',
    shortTitle: 'Sarapan Pagi',
    icon: ActivityIcon.makan,
    start: TimeOfDayLite(6, 40),
    end: TimeOfDayLite(7, 10),
    category: RoutineCategory.pagi,
    description: 'Waktu makan tenang bersama keluarga sebelum beraktivitas.',
    steps: [
      'Cuci tangan dengan sabun',
      'Duduk tenang di meja makan',
      'Makan sarapan sampai habis',
      'Bawa piring ke tempat cuci',
    ],
  ),
  const RoutineTemplateItem(
    id: 'pagi_sekolah_siap',
    title: 'Menyiapkan Perlengkapan Sekolah',
    shortTitle: 'Siap Sekolah',
    icon: ActivityIcon.sekolah,
    start: TimeOfDayLite(7, 10),
    end: TimeOfDayLite(7, 30),
    category: RoutineCategory.pagi,
    description: 'Mengecek isi tas dan memakai seragam secara mandiri.',
    steps: [
      'Pakai seragam sekolah dengan rapi',
      'Periksa kembali buku dan kotak pensil',
      'Pakai kaos kaki dan sepatu',
      'Pamit dan salam kepada orang tua',
    ],
  ),
  const RoutineTemplateItem(
    id: 'pagi_pekerjaan_rumah',
    title: 'Membantu Menyiram Tanaman Pagi',
    shortTitle: 'Siram Tanaman',
    icon: ActivityIcon.main,
    start: TimeOfDayLite(6, 30),
    end: TimeOfDayLite(6, 50),
    category: RoutineCategory.pagi,
    description: 'Aktivitas sensorik alam dan tanggung jawab ringan.',
    steps: [
      'Ambil alat penyiram air',
      'Siram tanaman di pot perlahan',
      'Kembalikan alat siram ke tempatnya',
    ],
  ),

  // --- KATEGORI 2: SEKOLAH & SIANG (5 Opsi) ---
  const RoutineTemplateItem(
    id: 'siang_sekolah',
    title: 'Belajar di Sekolah',
    shortTitle: 'Sekolah',
    icon: ActivityIcon.sekolah,
    start: TimeOfDayLite(7, 30),
    end: TimeOfDayLite(11, 30),
    category: RoutineCategory.sekolah,
    description: 'Kegiatan belajar formal terstruktur bersama guru dan teman.',
    steps: [
      'Duduk tenang di bangku kelas',
      'Mendengarkan penjelasan bapak/ibu guru',
      'Mengerjakan lembar kerja mandiri',
      'Merapikan alat tulis setelah belajar',
    ],
  ),
  const RoutineTemplateItem(
    id: 'siang_makan_bekal',
    title: 'Makan Bekal & Istirahat Sekolah',
    shortTitle: 'Makan Bekal',
    icon: ActivityIcon.makan,
    start: TimeOfDayLite(9, 30),
    end: TimeOfDayLite(10, 0),
    category: RoutineCategory.sekolah,
    description: 'Transisi istirahat makan bekal sehat di lingkungan sekolah.',
    steps: [
      'Cuci tangan sebelum makan',
      'Buka kotak bekal dan makan perlahan',
      'Minum air putih',
      'Tutup kembali kotak bekal dengan rapat',
    ],
  ),
  const RoutineTemplateItem(
    id: 'siang_pulang_sekolah',
    title: 'Pulang Sekolah & Ganti Pakaian',
    shortTitle: 'Pulang Sekolah',
    icon: ActivityIcon.mandi,
    start: TimeOfDayLite(12, 0),
    end: TimeOfDayLite(12, 30),
    category: RoutineCategory.sekolah,
    description: 'Membiasakan transisi tenang saat kembali ke rumah.',
    steps: [
      'Lepas sepatu dan letakkan di rak',
      'Cuci tangan dan basuh kaki',
      'Ganti seragam dengan pakaian rumah yang nyaman',
      'Taruh tas di atas meja belajar',
    ],
  ),
  const RoutineTemplateItem(
    id: 'siang_makan_siang',
    title: 'Makan Siang & Istirahat Santai',
    shortTitle: 'Makan Siang',
    icon: ActivityIcon.makan,
    start: TimeOfDayLite(12, 30),
    end: TimeOfDayLite(13, 0),
    category: RoutineCategory.sekolah,
    description: 'Asupan nutrisi siang dan istirahat dari suara bising luar.',
    steps: [
      'Ambil porsi makan yang pas',
      'Makan dengan tertib tanpa tergesa-gesa',
      'Minum air putih secukupnya',
      'Rapikan sendok dan piring ke dapur',
    ],
  ),
  const RoutineTemplateItem(
    id: 'siang_tidur_siang',
    title: 'Istirahat Siang / Waktu Tenang',
    shortTitle: 'Tidur Siang',
    icon: ActivityIcon.tidur,
    start: TimeOfDayLite(13, 30),
    end: TimeOfDayLite(14, 30),
    category: RoutineCategory.sekolah,
    description: 'Pemulihan energi dan penurunan stimulasi sensori otak.',
    steps: [
      'Redupkan tirai atau lampu kamar',
      'Berbaring posisi rileks',
      'Tidur siang atau istirahat tenang',
    ],
  ),

  // --- KATEGORI 3: SORE & OLAHRAGA (5 Opsi) ---
  const RoutineTemplateItem(
    id: 'sore_sepeda',
    title: 'Bersepeda Santai di Taman',
    shortTitle: 'Sepeda Santai',
    icon: ActivityIcon.sepeda,
    start: TimeOfDayLite(16, 0),
    end: TimeOfDayLite(17, 0),
    category: RoutineCategory.sore,
    description: 'Stimulasi sensori proprioseptif dan vestibular yang menyenangkan.',
    steps: [
      'Pakai helm pengaman dan sepatu',
      'Bersepeda di jalur aman',
      'Parkir sepeda di tempat semula',
      'Minum segelas air putih',
    ],
  ),
  const RoutineTemplateItem(
    id: 'sore_jalan_santai',
    title: 'Jalan Santai & Olahraga Ringan',
    shortTitle: 'Jalan Santai',
    icon: ActivityIcon.sepeda,
    start: TimeOfDayLite(16, 15),
    end: TimeOfDayLite(17, 0),
    category: RoutineCategory.sore,
    description: 'Aktivitas luar ruangan untuk melatih regulasi emosi anak.',
    steps: [
      'Pakai sepatu olahraga',
      'Jalan santai mengelilingi komplek',
      'Latihan pernapasan dalam',
    ],
  ),
  const RoutineTemplateItem(
    id: 'sore_main_lego',
    title: 'Bermain Kreatif Balok / Lego',
    shortTitle: 'Bermain Lego',
    icon: ActivityIcon.main,
    start: TimeOfDayLite(16, 30),
    end: TimeOfDayLite(17, 15),
    category: RoutineCategory.sore,
    description: 'Melatih fokus visual spasial dan kreativitas anak.',
    steps: [
      'Buka wadah balok mainan',
      'Susun bentuk atau pola yang disukai',
      'Kumpulkan kembali semua balok ke wadah',
    ],
  ),
  const RoutineTemplateItem(
    id: 'sore_menggambar',
    title: 'Menggambar & Mewarnai Tenang',
    shortTitle: 'Menggambar',
    icon: ActivityIcon.main,
    start: TimeOfDayLite(16, 30),
    end: TimeOfDayLite(17, 15),
    category: RoutineCategory.sore,
    description: 'Aktivitas motorik halus yang menenangkan suasana hati.',
    steps: [
      'Siapkan kertas gambar dan krayon',
      'Mewarnai gambar dengan hati-hati',
      'Simpan krayon kembali ke kotaknya',
    ],
  ),
  const RoutineTemplateItem(
    id: 'sore_mandi',
    title: 'Mandi Sore & Cuci Rambut',
    shortTitle: 'Mandi Sore',
    icon: ActivityIcon.mandi,
    start: TimeOfDayLite(17, 30),
    end: TimeOfDayLite(18, 0),
    category: RoutineCategory.sore,
    description: 'Membersihkan keringat setelah beraktivitas sore.',
    steps: [
      'Buka pakaian kotor dan taruh di keranjang',
      'Mandi bersih dengan air segar dan sabun',
      'Keringkan badan dengan handuk',
      'Pakai pakaian rumah yang bersih',
    ],
  ),

  // --- KATEGORI 4: MALAM & SPIRITUAL (7 Opsi) ---
  const RoutineTemplateItem(
    id: 'malam_sholat_maghrib',
    title: 'Sholat Maghrib & Doa Bersama',
    shortTitle: 'Sholat Maghrib',
    icon: ActivityIcon.ngaji,
    start: TimeOfDayLite(18, 0),
    end: TimeOfDayLite(18, 30),
    category: RoutineCategory.malam,
    description: 'Ibadah awal malam untuk ketenangan jiwa dan spiritual.',
    steps: [
      'Berwudhu dengan tertib dan hemat air',
      'Pakai pakaian sholat yang bersih dan suci',
      'Sholat berjamaah bersama keluarga',
      'Berdoa dengan khusyuk dan tenang',
    ],
  ),
  const RoutineTemplateItem(
    id: 'malam_mengaji',
    title: 'Mengaji Al-Qur\'an & Hafalan Doa',
    shortTitle: 'Mengaji',
    icon: ActivityIcon.ngaji,
    start: TimeOfDayLite(18, 30),
    end: TimeOfDayLite(19, 15),
    category: RoutineCategory.malam,
    description: 'Belajar membaca ayat suci dan doa harian dengan pembimbing.',
    steps: [
      'Buka kitab suci atau buku Iqra',
      'Membaca ayat dengan bimbingan',
      'Mengulang hafalan doa harian',
      'Merapikan kembali kitab suci ke tempat yang tinggi',
    ],
  ),
  const RoutineTemplateItem(
    id: 'malam_makan_malam',
    title: 'Makan Malam Bersama Keluarga',
    shortTitle: 'Makan Malam',
    icon: ActivityIcon.makan,
    start: TimeOfDayLite(19, 15),
    end: TimeOfDayLite(19, 45),
    category: RoutineCategory.malam,
    description: 'Kebersamaan keluarga yang hangat dan santai.',
    steps: [
      'Cuci tangan sebelum makan',
      'Membaca doa sebelum makan bersama',
      'Makan dengan tenang tanpa melihat layar gawai',
      'Membantu merapikan meja makan',
    ],
  ),
  const RoutineTemplateItem(
    id: 'malam_sholat_isya',
    title: 'Sholat Isya & Dzikir Penenang',
    shortTitle: 'Sholat Isya',
    icon: ActivityIcon.ngaji,
    start: TimeOfDayLite(19, 45),
    end: TimeOfDayLite(20, 15),
    category: RoutineCategory.malam,
    description: 'Menyempurnakan ibadah harian dengan dzikir penyejuk hati.',
    steps: [
      'Berwudhu kembali jika batal',
      'Melaksanakan sholat Isya dengan tertib',
      'Membaca dzikir dan shalawat pelan',
      'Melipat sajadah dengan rapi',
    ],
  ),
  const RoutineTemplateItem(
    id: 'malam_quiet_time',
    title: 'Waktu Santai Tanpa Gawai (Quiet Time)',
    shortTitle: 'Waktu Tenang',
    icon: ActivityIcon.les,
    start: TimeOfDayLite(20, 15),
    end: TimeOfDayLite(20, 45),
    category: RoutineCategory.malam,
    description: 'Meredakan stimulasi layar minimal 30 menit sebelum tidur.',
    steps: [
      'Pastikan TV, HP, dan tablet sudah dimatikan',
      'Membaca buku cerita bergambar yang tenang',
      'Mendengarkan kisah teladan sebelum tidur',
      'Minum segelas air putih atau susu hangat',
    ],
  ),
  const RoutineTemplateItem(
    id: 'malam_wudhu_tidur',
    title: 'Sikat Gigi, Wudhu & Siap Tidur',
    shortTitle: 'Siap Tidur',
    icon: ActivityIcon.mandi,
    start: TimeOfDayLite(20, 45),
    end: TimeOfDayLite(21, 0),
    category: RoutineCategory.malam,
    description: 'Menjaga kebersihan dan kesucian diri menjelang istirahat.',
    steps: [
      'Sikat gigi hingga bersih',
      'Cuci muka dan kaki dengan air wudhu',
      'Pakai pakaian tidur yang longgar dan nyaman',
    ],
  ),
  const RoutineTemplateItem(
    id: 'malam_tidur_malam',
    title: 'Doa Tidur & Istirahat Malam',
    shortTitle: 'Tidur Malam',
    icon: ActivityIcon.tidur,
    start: TimeOfDayLite(21, 0),
    end: null, // Sesuai aturan AutiPlan: tidur malam tanpa batas selesai
    category: RoutineCategory.malam,
    description: 'Tidur lelap untuk regenerasi fisik dan kestabilan emosi esok hari.',
    steps: [
      'Membaca doa sebelum tidur dan ayat kursi',
      'Berbaring posisi miring ke kanan dengan nyaman',
      'Matikan lampu utama dan nyalakan lampu tidur redup',
    ],
  ),
];

/// Paket rutinitas lengkap (Full Routine Packs) yang bisa langsung diaplikasikan
/// sekaligus ke jadwal anak dalam satu klik.
final List<RoutinePack> routinePacks = [
  RoutinePack(
    id: 'pack_pagi_sekolah',
    name: 'Paket Hari Sekolah Lengkap',
    description: 'Jadwal terpadu mulai bangun pagi, sekolah, istirahat siang, hingga pulang.',
    category: RoutineCategory.sekolah,
    icon: ActivityIcon.sekolah,
    items: [
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_bangun'),
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_mandi'),
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_sarapan'),
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_sekolah_siap'),
      allRoutineTemplates.firstWhere((t) => t.id == 'siang_sekolah'),
      allRoutineTemplates.firstWhere((t) => t.id == 'siang_pulang_sekolah'),
      allRoutineTemplates.firstWhere((t) => t.id == 'siang_makan_siang'),
    ],
  ),
  RoutinePack(
    id: 'pack_malam_spiritual',
    name: 'Paket Malam Spiritual & Tidur Tenang',
    description: 'Rangkaian sholat Maghrib, mengaji, makan malam, sholat Isya, hingga istirahat.',
    category: RoutineCategory.malam,
    icon: ActivityIcon.ngaji,
    items: [
      allRoutineTemplates.firstWhere((t) => t.id == 'malam_sholat_maghrib'),
      allRoutineTemplates.firstWhere((t) => t.id == 'malam_mengaji'),
      allRoutineTemplates.firstWhere((t) => t.id == 'malam_makan_malam'),
      allRoutineTemplates.firstWhere((t) => t.id == 'malam_sholat_isya'),
      allRoutineTemplates.firstWhere((t) => t.id == 'malam_quiet_time'),
      allRoutineTemplates.firstWhere((t) => t.id == 'malam_wudhu_tidur'),
      allRoutineTemplates.firstWhere((t) => t.id == 'malam_tidur_malam'),
    ],
  ),
  RoutinePack(
    id: 'pack_sore_aktif',
    name: 'Paket Sore Olahraga & Kreatif',
    description: 'Kombinasi aktivitas fisik di luar dan hobi menenangkan di rumah.',
    category: RoutineCategory.sore,
    icon: ActivityIcon.sepeda,
    items: [
      allRoutineTemplates.firstWhere((t) => t.id == 'sore_sepeda'),
      allRoutineTemplates.firstWhere((t) => t.id == 'sore_main_lego'),
      allRoutineTemplates.firstWhere((t) => t.id == 'sore_mandi'),
    ],
  ),
  RoutinePack(
    id: 'pack_pagi_ceria',
    name: 'Paket Pagi Mandiri & Sehat',
    description: 'Membangun kebiasaan bangun pagi, senam ringan, mandi, dan sarapan.',
    category: RoutineCategory.pagi,
    icon: ActivityIcon.mandi,
    items: [
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_bangun'),
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_senam'),
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_mandi'),
      allRoutineTemplates.firstWhere((t) => t.id == 'pagi_sarapan'),
    ],
  ),
];

/// Mengubah daftar [RoutineTemplateItem] menjadi daftar [Activity] baru untuk anak pada [date].
List<Activity> generateActivitiesFromTemplate({
  required List<RoutineTemplateItem> items,
  required String childId,
  required DateTime date,
}) {
  final targetDate = DateTime(date.year, date.month, date.day);
  final List<Activity> activities = [];
  final nowMs = DateTime.now().millisecondsSinceEpoch;

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final customId = 'act_${nowMs}_${item.id}_$i';
    activities.add(
      item.toActivity(
        childId: childId,
        date: targetDate,
        customId: customId,
      ),
    );
  }

  return activities;
}
