import 'package:intl/intl.dart';

import '../../../data/models/models.dart';

String formatTimeLite(TimeOfDayLite time) => time.toString();

String formatDateLong(DateTime date) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);

String formatDateShort(DateTime date) =>
    DateFormat('EEEE, d MMM', 'id_ID').format(date);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String generateId(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';

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
    shortTitle: (shortTitle == null || shortTitle.trim().isEmpty)
        ? shortTitleFromTitle(title)
        : shortTitle.trim(),
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
