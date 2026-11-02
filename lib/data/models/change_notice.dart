import 'activity_snapshot.dart';

class ChangeNotice {
  const ChangeNotice({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.before,
    this.after,
    required this.message,
    required this.sentAt,
    this.seenAt,
  });

  final String id;
  final String childId;
  final String activityId;
  final ActivitySnapshot before;
  final ActivitySnapshot? after;
  final String message;
  final DateTime sentAt;
  final DateTime? seenAt;

  ChangeNotice copyWith({
    String? id,
    String? childId,
    String? activityId,
    ActivitySnapshot? before,
    ActivitySnapshot? after,
    bool clearAfter = false,
    String? message,
    DateTime? sentAt,
    DateTime? seenAt,
    bool clearSeenAt = false,
  }) {
    return ChangeNotice(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      activityId: activityId ?? this.activityId,
      before: before ?? this.before,
      after: clearAfter ? null : (after ?? this.after),
      message: message ?? this.message,
      sentAt: sentAt ?? this.sentAt,
      seenAt: clearSeenAt ? null : (seenAt ?? this.seenAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'childId': childId,
    'activityId': activityId,
    'before': before.toJson(),
    if (after != null) 'after': after!.toJson(),
    'message': message,
    'sentAt': sentAt.toIso8601String(),
    if (seenAt != null) 'seenAt': seenAt!.toIso8601String(),
  };

  factory ChangeNotice.fromJson(Map<String, dynamic> json) {
    return ChangeNotice(
      id: json['id'] as String,
      childId: json['childId'] as String,
      activityId: json['activityId'] as String,
      before: ActivitySnapshot.fromJson(json['before'] as Map<String, dynamic>),
      after: json['after'] != null
          ? ActivitySnapshot.fromJson(json['after'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      seenAt: json['seenAt'] != null
          ? DateTime.parse(json['seenAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangeNotice &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          childId == other.childId &&
          activityId == other.activityId &&
          before == other.before &&
          after == other.after &&
          message == other.message &&
          sentAt == other.sentAt &&
          seenAt == other.seenAt;

  @override
  int get hashCode =>
      id.hashCode ^
      childId.hashCode ^
      activityId.hashCode ^
      before.hashCode ^
      (after?.hashCode ?? 0) ^
      message.hashCode ^
      sentAt.hashCode ^
      (seenAt?.hashCode ?? 0);
}
