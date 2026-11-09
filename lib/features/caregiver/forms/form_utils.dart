import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/models.dart';
import '../../../domain/schedule_rules.dart';

String formatTimeLite(TimeOfDayLite time) => time.toString();

String formatDateLong(DateTime date) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

String formatDateShort(DateTime date) =>
    DateFormat('EEEE, d MMM', 'id_ID').format(date);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String generateId(String prefix) => '$prefix-${const Uuid().v4()}';

/// Kantuk / layar: ikon nonton otomatis dianggap memakai layar.
Activity buildActivity({
  required String id,
  required String childId,
  required String title,
  required ActivityIcon icon,
  required DateTime date,
  required TimeOfDayLite start,
  TimeOfDayLite? end,
  List<String> steps = const [],
  Set<int> repeatWeekdays = const {},
  String? shortTitle,
  bool independentMode = false,
}) {
  return Activity(
    id: id,
    childId: childId,
    title: title.trim(),
    // Maks 2 kata (§6): masukan manual yang lebih panjang dipotong; UI
    // menolak simpan lewat [isValidShortTitle] sebelum sampai di sini.
    shortTitle: shortTitleFromTitle(
      (shortTitle == null || shortTitle.trim().isEmpty) ? title : shortTitle,
    ),
    icon: icon,
    date: dateOnly(date),
    start: start,
    end: end,
    steps: steps,
    repeatWeekdays: repeatWeekdays,
    independentMode: independentMode,
  );
}

/// Dua kata pertama Nama, sesuai §8.6.
String shortTitleFromTitle(String title) {
  final words = title
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .toList();
  return words.join(' ');
}

/// Nama singkat untuk anak: maksimal 2 kata (§6). Kosong dianggap sah
/// (nanti diisi otomatis dari Nama).
bool isValidShortTitle(String value) =>
    value.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length <= 2;

/// Jam selesai bawaan bila sebelumnya kosong (ikon Tidur diganti ke ikon
/// lain): [preferred] bila masih setelah [start], jika tidak [start] + 30
/// menit (dibatasi 23.59).
TimeOfDayLite defaultEndFor(TimeOfDayLite start, {TimeOfDayLite? preferred}) {
  if (preferred != null && preferred.toMinutes() > start.toMinutes()) {
    return preferred;
  }
  final minutes = (start.toMinutes() + 30).clamp(0, 23 * 60 + 59);
  return TimeOfDayLite(minutes ~/ 60, minutes % 60);
}

/// Pesan tenang untuk masalah rentang waktu (§8.6), bukan merah.
String timeRangeIssueMessage(TimeRangeIssue issue) => switch (issue) {
  TimeRangeIssue.endNotAfterStart => 'Jam selesai harus setelah jam mulai.',
  TimeRangeIssue.endRequired =>
    'Pilih jam selesai. Hanya kegiatan Tidur yang boleh tanpa jam selesai.',
};
