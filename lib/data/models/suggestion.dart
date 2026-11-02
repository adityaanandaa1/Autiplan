import 'equality.dart';

enum SuggestionType { quietTime, transitionGap, independence, emptyDay }

enum SuggestionStatus { active, dismissed, applied }

class Suggestion {
  const Suggestion({
    required this.id,
    required this.type,
    required this.childId,
    required this.title,
    required this.body,
    required this.reasonData,
    required this.reasonBasis,
    required this.actionLabel,
    this.payload = const {},
    required this.status,
  });

  final String id;
  final SuggestionType type;
  final String childId;
  final String title;
  final String body;
  final String reasonData;
  final String reasonBasis;
  final String actionLabel;
  final Map<String, dynamic> payload;
  final SuggestionStatus status;

  Suggestion copyWith({
    String? id,
    SuggestionType? type,
    String? childId,
    String? title,
    String? body,
    String? reasonData,
    String? reasonBasis,
    String? actionLabel,
    Map<String, dynamic>? payload,
    SuggestionStatus? status,
  }) {
    return Suggestion(
      id: id ?? this.id,
      type: type ?? this.type,
      childId: childId ?? this.childId,
      title: title ?? this.title,
      body: body ?? this.body,
      reasonData: reasonData ?? this.reasonData,
      reasonBasis: reasonBasis ?? this.reasonBasis,
      actionLabel: actionLabel ?? this.actionLabel,
      payload: payload ?? this.payload,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'childId': childId,
    'title': title,
    'body': body,
    'reasonData': reasonData,
    'reasonBasis': reasonBasis,
    'actionLabel': actionLabel,
    'payload': payload,
    'status': status.name,
  };

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] as String,
      type: SuggestionType.values.byName(json['type'] as String),
      childId: json['childId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      reasonData: json['reasonData'] as String,
      reasonBasis: json['reasonBasis'] as String,
      actionLabel: json['actionLabel'] as String,
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      status: SuggestionStatus.values.byName(json['status'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          childId == other.childId &&
          title == other.title &&
          body == other.body &&
          reasonData == other.reasonData &&
          reasonBasis == other.reasonBasis &&
          actionLabel == other.actionLabel &&
          mapEq(payload, other.payload) &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      childId.hashCode ^
      title.hashCode ^
      status.hashCode;
}
