class Settings {
  const Settings({
    this.caregiverName = '',
    this.reminderMinutesBefore = 15,
    this.minGapMinutes = 10,
    this.independenceStreakDays = 5,
    this.quietTimeMinutes = 30,
    this.emergencyNumber = '',
    this.backupNumber = '',
  });

  final String caregiverName;
  final int reminderMinutesBefore;
  final int minGapMinutes;
  final int independenceStreakDays;
  final int quietTimeMinutes;
  final String emergencyNumber;
  final String backupNumber;

  Settings copyWith({
    String? caregiverName,
    int? reminderMinutesBefore,
    int? minGapMinutes,
    int? independenceStreakDays,
    int? quietTimeMinutes,
    String? emergencyNumber,
    String? backupNumber,
  }) {
    return Settings(
      caregiverName: caregiverName ?? this.caregiverName,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      minGapMinutes: minGapMinutes ?? this.minGapMinutes,
      independenceStreakDays:
          independenceStreakDays ?? this.independenceStreakDays,
      quietTimeMinutes: quietTimeMinutes ?? this.quietTimeMinutes,
      emergencyNumber: emergencyNumber ?? this.emergencyNumber,
      backupNumber: backupNumber ?? this.backupNumber,
    );
  }

  Map<String, dynamic> toJson() => {
    'caregiverName': caregiverName,
    'reminderMinutesBefore': reminderMinutesBefore,
    'minGapMinutes': minGapMinutes,
    'independenceStreakDays': independenceStreakDays,
    'quietTimeMinutes': quietTimeMinutes,
    'emergencyNumber': emergencyNumber,
    'backupNumber': backupNumber,
  };

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      caregiverName: (json['caregiverName'] as String?) ?? '',
      reminderMinutesBefore: (json['reminderMinutesBefore'] as int?) ?? 15,
      minGapMinutes: (json['minGapMinutes'] as int?) ?? 10,
      independenceStreakDays: (json['independenceStreakDays'] as int?) ?? 5,
      quietTimeMinutes: (json['quietTimeMinutes'] as int?) ?? 30,
      emergencyNumber: (json['emergencyNumber'] as String?) ?? '',
      backupNumber: (json['backupNumber'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          runtimeType == other.runtimeType &&
          caregiverName == other.caregiverName &&
          reminderMinutesBefore == other.reminderMinutesBefore &&
          minGapMinutes == other.minGapMinutes &&
          independenceStreakDays == other.independenceStreakDays &&
          quietTimeMinutes == other.quietTimeMinutes &&
          emergencyNumber == other.emergencyNumber &&
          backupNumber == other.backupNumber;

  @override
  int get hashCode =>
      caregiverName.hashCode ^
      reminderMinutesBefore.hashCode ^
      minGapMinutes.hashCode ^
      independenceStreakDays.hashCode ^
      quietTimeMinutes.hashCode ^
      emergencyNumber.hashCode ^
      backupNumber.hashCode;
}
