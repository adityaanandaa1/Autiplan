class Settings {
  const Settings({
    this.reminderMinutesBefore = 15,
    this.minGapMinutes = 10,
    this.independenceStreakDays = 5,
    this.quietTimeMinutes = 30,
    this.emergencyNumber = '081234567890',
    this.backupNumber = '081298765432',
    this.demoClockEnabled = true,
  });

  final int reminderMinutesBefore;
  final int minGapMinutes;
  final int independenceStreakDays;
  final int quietTimeMinutes;
  final String emergencyNumber;
  final String backupNumber;
  final bool demoClockEnabled;

  Settings copyWith({
    int? reminderMinutesBefore,
    int? minGapMinutes,
    int? independenceStreakDays,
    int? quietTimeMinutes,
    String? emergencyNumber,
    String? backupNumber,
    bool? demoClockEnabled,
  }) {
    return Settings(
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      minGapMinutes: minGapMinutes ?? this.minGapMinutes,
      independenceStreakDays:
          independenceStreakDays ?? this.independenceStreakDays,
      quietTimeMinutes: quietTimeMinutes ?? this.quietTimeMinutes,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      backupNumber: backupNumber ?? this.backupNumber,
      demoClockEnabled: demoClockEnabled ?? this.demoClockEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'reminderMinutesBefore': reminderMinutesBefore,
    'minGapMinutes': minGapMinutes,
    'independenceStreakDays': independenceStreakDays,
    'quietTimeMinutes': quietTimeMinutes,
    'emergencyNumber': emergencyNumber,
    'backupNumber': backupNumber,
    'demoClockEnabled': demoClockEnabled,
  };

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      reminderMinutesBefore: (json['reminderMinutesBefore'] as int?) ?? 15,
      minGapMinutes: (json['minGapMinutes'] as int?) ?? 10,
      independenceStreakDays: (json['independenceStreakDays'] as int?) ?? 5,
      quietTimeMinutes: (json['quietTimeMinutes'] as int?) ?? 30,
      emergencyNumber: (json['emergencyNumber'] as String?) ?? '081234567890',
      backupNumber: (json['backupNumber'] as String?) ?? '081298765432',
      demoClockEnabled: (json['demoClockEnabled'] as bool?) ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          runtimeType == other.runtimeType &&
          reminderMinutesBefore == other.reminderMinutesBefore &&
          minGapMinutes == other.minGapMinutes &&
          independenceStreakDays == other.independenceStreakDays &&
          quietTimeMinutes == other.quietTimeMinutes &&
          emergencyNumber == other.emergencyNumber &&
          backupNumber == other.backupNumber &&
          demoClockEnabled == other.demoClockEnabled;

  @override
  int get hashCode =>
      reminderMinutesBefore.hashCode ^
      minGapMinutes.hashCode ^
      independenceStreakDays.hashCode ^
      quietTimeMinutes.hashCode ^
      emergencyNumber.hashCode ^
      backupNumber.hashCode ^
      demoClockEnabled.hashCode;
}
