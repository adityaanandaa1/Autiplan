enum NotificationType {
  changeSeen,
  activityStarted,
  activityDone,
  emergencyPressed,
}

class CaregiverNotification {
  const CaregiverNotification({
    required this.id,
    required this.type,
    required this.text,
    required this.at,
    required this.read,
    this.badge,
  });

  final String id;
  final NotificationType type;
  final String text;
  final DateTime at;
  final bool read;
  final String? badge;

  CaregiverNotification copyWith({
    String? id,
    NotificationType? type,
    String? text,
    DateTime? at,
    bool? read,
    String? badge,
    bool clearBadge = false,
  }) {
    return CaregiverNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      at: at ?? this.at,
      read: read ?? this.read,
      badge: clearBadge ? null : (badge ?? this.badge),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'text': text,
    // UTC (berakhiran Z) agar Worker bisa menghitung umur notifikasi.
    'at': at.toUtc().toIso8601String(),
    'read': read,
    if (badge != null) 'badge': badge,
  };

  factory CaregiverNotification.fromJson(Map<String, dynamic> json) {
    return CaregiverNotification(
      id: json['id'] as String,
      type: NotificationType.values.byName(json['type'] as String),
      text: json['text'] as String,
      at: DateTime.parse(json['at'] as String).toLocal(),
      read: json['read'] as bool,
      badge: json['badge'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaregiverNotification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          text == other.text &&
          at == other.at &&
          read == other.read &&
          badge == other.badge;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      text.hashCode ^
      at.hashCode ^
      read.hashCode ^
      (badge?.hashCode ?? 0);
}
