import 'activity_icon.dart';
import 'time_of_day_lite.dart';

class ActivitySnapshot {
  const ActivitySnapshot({
    required this.shortTitle,
    required this.title,
    required this.icon,
    required this.start,
  });

  final String shortTitle;
  final String title;
  final ActivityIcon icon;
  final TimeOfDayLite start;

  ActivitySnapshot copyWith({
    String? shortTitle,
    String? title,
    ActivityIcon? icon,
    TimeOfDayLite? start,
  }) {
    return ActivitySnapshot(
      shortTitle: shortTitle ?? this.shortTitle,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      start: start ?? this.start,
    );
  }

  Map<String, dynamic> toJson() => {
    'shortTitle': shortTitle,
    'title': title,
    'icon': icon.name,
    'start': start.toJson(),
  };

  factory ActivitySnapshot.fromJson(Map<String, dynamic> json) {
    return ActivitySnapshot(
      shortTitle: json['shortTitle'] as String,
      title: json['title'] as String,
      icon: ActivityIcon.values.byName(json['icon'] as String),
      start: TimeOfDayLite.fromJson(json['start'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivitySnapshot &&
          runtimeType == other.runtimeType &&
          shortTitle == other.shortTitle &&
          title == other.title &&
          icon == other.icon &&
          start == other.start;

  @override
  int get hashCode =>
      shortTitle.hashCode ^ title.hashCode ^ icon.hashCode ^ start.hashCode;
}
