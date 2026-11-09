import '../data/models/models.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _stamp(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

/// Membuat salinan per tanggal untuk setiap seri berulang sampai
/// [today] + [horizonDays] (bentuk data sama dengan data lama, jadi aturan
/// streak tidak berubah).
///
/// - Hanya tanggal setelah kemunculan terakhir seri yang dibuat, sehingga
///   kemunculan tengah yang dihapus tidak muncul lagi.
/// - Tanggal sebelum [today] tidak diisi mundur: HP yang lama tidak dibuka
///   tidak boleh punya hari lampau yang dianggap terlewat.
/// - Hari ulang mengikuti kemunculan terakhir (aturan seri terbaru);
///   isi salinan (judul, jam, langkah) mengikuti kemunculan terbaru yang
///   tidak diganti per tanggal (`replacedTitle == null`).
/// - ID `'${seriesId}_yyyyMMdd'` membuat fungsi ini aman dijalankan berulang.
///
/// Kegiatan tanpa `seriesId` tidak disentuh. Bila tidak ada yang perlu
/// ditambah, daftar yang sama dikembalikan.
List<Activity> materializeRecurring(
  List<Activity> all,
  DateTime today, {
  int horizonDays = 28,
}) {
  final bySeries = <String, List<Activity>>{};
  for (final a in all) {
    final id = a.seriesId;
    if (id != null) bySeries.putIfAbsent(id, () => []).add(a);
  }

  final todayOnly = _dateOnly(today);
  final horizon = DateTime(
    todayOnly.year,
    todayOnly.month,
    todayOnly.day + horizonDays,
  );

  final added = <Activity>[];
  for (final entry in bySeries.entries) {
    final occurrences = [...entry.value]
      ..sort((a, b) => a.date.compareTo(b.date));
    final last = occurrences.last;
    final weekdays = last.repeatWeekdays;
    if (weekdays.isEmpty) continue;

    final template = occurrences.lastWhere(
      (a) => a.replacedTitle == null,
      orElse: () => last,
    );

    final lastDate = _dateOnly(last.date);
    final firstNew = DateTime(lastDate.year, lastDate.month, lastDate.day + 1);
    var day = firstNew.isBefore(todayOnly) ? todayOnly : firstNew;
    while (!day.isAfter(horizon)) {
      if (weekdays.contains(day.weekday)) {
        added.add(
          template.copyWith(
            id: '${entry.key}_${_stamp(day)}',
            date: day,
            repeatWeekdays: weekdays,
            clearReplacedTitle: true,
          ),
        );
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
  }

  return added.isEmpty ? all : [...all, ...added];
}

/// Menerapkan perubahan hari ulang pada [edited] (§ keputusan 8): kemunculan
/// itu disimpan apa adanya, dan semua kemunculan lain dari seri yang sama
/// pada tanggal setelahnya dibuang supaya dibuat ulang dengan hari baru.
/// Kemunculan sebelum tanggal itu tidak disentuh.
///
/// Kegiatan yang belum punya seri dan kini diberi hari ulang memulai seri
/// baru dengan `seriesId` sama dengan ID-nya.
List<Activity> applyRepeatChange(List<Activity> all, Activity edited) {
  final seriesId =
      edited.seriesId ?? (edited.repeatWeekdays.isEmpty ? null : edited.id);
  final stored = seriesId == null
      ? edited
      : edited.copyWith(seriesId: seriesId);
  final cutoff = _dateOnly(edited.date);

  return [
    for (final a in all)
      if (a.id == edited.id)
        stored
      else if (seriesId != null &&
          a.seriesId == seriesId &&
          _dateOnly(a.date).isAfter(cutoff))
        ...const <Activity>[]
      else
        a,
  ];
}
