import 'equality.dart';
import 'activity_icon.dart';
import 'time_of_day_lite.dart';

class Activity {
  const Activity({
    required this.id,
    required this.childId,
    required this.title,
    required this.shortTitle,
    required this.icon,
    required this.date,
    required this.start,
    this.end,
    this.steps = const [],
    this.repeatWeekdays = const {},
    bool? usesScreen,
    this.independentMode = false,
    this.replacedTitle,
    this.originalSteps,
    this.seriesId,
  }) : usesScreen = usesScreen ?? (icon == ActivityIcon.nonton);

  final String id;
  final String childId;
  final String title;
  final String shortTitle;
  final ActivityIcon icon;
  final DateTime date;
  final TimeOfDayLite start;
  final TimeOfDayLite? end;
  final List<String> steps;
  final Set<int> repeatWeekdays;
  final bool usesScreen;
  final bool independentMode;
  final String? replacedTitle;
  final List<String>? originalSteps;

  /// Penanda seri kegiatan berulang; null bila bukan bagian dari seri.
  final String? seriesId;

  Activity copyWith({
    String? id,
    String? childId,
    String? title,
    String? shortTitle,
    ActivityIcon? icon,
    DateTime? date,
    TimeOfDayLite? start,
    TimeOfDayLite? end,
    bool clearEnd = false,
    List<String>? steps,
    Set<int>? repeatWeekdays,
    bool? usesScreen,
    bool? independentMode,
    String? replacedTitle,
    bool clearReplacedTitle = false,
    List<String>? originalSteps,
    bool clearOriginalSteps = false,
    String? seriesId,
    bool clearSeriesId = false,
  }) {
    return Activity(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      shortTitle: shortTitle ?? this.shortTitle,
      icon: icon ?? this.icon,
      date: date ?? this.date,
      start: start ?? this.start,
      end: clearEnd ? null : (end ?? this.end),
      steps: steps ?? this.steps,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      usesScreen: usesScreen ?? this.usesScreen,
      independentMode: independentMode ?? this.independentMode,
      replacedTitle: clearReplacedTitle
          ? null
          : (replacedTitle ?? this.replacedTitle),
      originalSteps: clearOriginalSteps
          ? null
          : (originalSteps ?? this.originalSteps),
      seriesId: clearSeriesId ? null : (seriesId ?? this.seriesId),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'title': title,
    'shortTitle': shortTitle,
    'icon': icon.name,
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'start': start.toJson(),
    if (end != null) 'end': end!.toJson(),
    'steps': steps,
    'repeatWeekdays': repeatWeekdays.toList(),
    'usesScreen': usesScreen,
    'independentMode': independentMode,
    if (replacedTitle != null) 'replacedTitle': replacedTitle,
    if (originalSteps != null) 'originalSteps': originalSteps,
    if (seriesId != null) 'seriesId': seriesId,
  };

  factory Activity.fromJson(Map<String, dynamic> json) {
    final rawDate = DateTime.parse(json['date'] as String);
    final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
    return Activity(
      id: json['id'] as String,
      childId: json['childId'] as String,
      title: json['title'] as String,
      shortTitle: json['shortTitle'] as String,
      icon: ActivityIcon.values.byName(json['icon'] as String),
      date: date,
      start: TimeOfDayLite.fromJson(json['start'] as Map<String, dynamic>),
      end: json['end'] != null
          ? TimeOfDayLite.fromJson(json['end'] as Map<String, dynamic>)
          : null,
      steps:
          (json['steps'] as List?)?.map((e) => e as String).toList() ??
          const [],
      repeatWeekdays:
          (json['repeatWeekdays'] as List?)?.map((e) => e as int).toSet() ??
          const {},
      usesScreen: json['usesScreen'] as bool?,
      independentMode: (json['independentMode'] as bool?) ?? false,
      replacedTitle: json['replacedTitle'] as String?,
      originalSteps: json['originalSteps'] != null
          ? (json['originalSteps'] as List).map((e) => e as String).toList()
          : null,
      seriesId: json['seriesId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Activity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          childId == other.childId &&
          title == other.title &&
          shortTitle == other.shortTitle &&
          icon == other.icon &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          start == other.start &&
          end == other.end &&
          listEq(steps, other.steps) &&
          setEq(repeatWeekdays, other.repeatWeekdays) &&
          usesScreen == other.usesScreen &&
          independentMode == other.independentMode &&
          replacedTitle == other.replacedTitle &&
          seriesId == other.seriesId &&
          (originalSteps == null && other.originalSteps == null ||
              originalSteps != null &&
                  other.originalSteps != null &&
                  listEq(originalSteps!, other.originalSteps!));

  @override
  int get hashCode =>
      id.hashCode ^
      childId.hashCode ^
      title.hashCode ^
      shortTitle.hashCode ^
      icon.hashCode ^
      date.year.hashCode ^
      date.month.hashCode ^
      date.day.hashCode ^
      start.hashCode ^
      end.hashCode ^
      seriesId.hashCode;
}
