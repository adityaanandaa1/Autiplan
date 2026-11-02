class TimeOfDayLite {
  const TimeOfDayLite(this.hour, this.minute);

  final int hour;
  final int minute;

  int toMinutes() => hour * 60 + minute;

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute};

  factory TimeOfDayLite.fromJson(Map<String, dynamic> json) {
    return TimeOfDayLite(json['hour'] as int, json['minute'] as int);
  }

  TimeOfDayLite copyWith({int? hour, int? minute}) {
    return TimeOfDayLite(hour ?? this.hour, minute ?? this.minute);
  }

  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDayLite &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
