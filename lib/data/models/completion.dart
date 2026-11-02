import 'equality.dart';

class Completion {
  const Completion({
    required this.activityId,
    required this.date,
    required this.completedAt,
    required this.onTime,
    required this.stepsChecked,
  });

  final String activityId;
  final DateTime date;
  final DateTime completedAt;
  final bool onTime;
  final List<bool> stepsChecked;

  Completion copyWith({
    String? activityId,
    DateTime? date,
    DateTime? completedAt,
    bool? onTime,
    List<bool>? stepsChecked,
  }) {
    return Completion(
      activityId: activityId ?? this.activityId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      onTime: onTime ?? this.onTime,
      stepsChecked: stepsChecked ?? this.stepsChecked,
    );
  }

  Map<String, dynamic> toJson() => {
    'activityId': activityId,
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'completedAt': completedAt.toIso8601String(),
    'onTime': onTime,
    'stepsChecked': stepsChecked,
  };

  factory Completion.fromJson(Map<String, dynamic> json) {
    final rawDate = DateTime.parse(json['date'] as String);
    final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
    return Completion(
      activityId: json['activityId'] as String,
      date: date,
      completedAt: DateTime.parse(json['completedAt'] as String),
      onTime: json['onTime'] as bool,
      stepsChecked: (json['stepsChecked'] as List)
          .map((e) => e as bool)
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Completion &&
          runtimeType == other.runtimeType &&
          activityId == other.activityId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          completedAt == other.completedAt &&
          onTime == other.onTime &&
          listEq(stepsChecked, other.stepsChecked);

  @override
  int get hashCode =>
      activityId.hashCode ^
      date.year.hashCode ^
      date.month.hashCode ^
      date.day.hashCode ^
      completedAt.hashCode ^
      onTime.hashCode;
}
