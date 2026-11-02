import 'activity.dart';
import 'caregiver_notification.dart';
import 'change_notice.dart';
import 'child.dart';
import 'completion.dart';
import 'equality.dart';
import 'settings.dart';
import 'suggestion.dart';

class AppState {
  const AppState({
    required this.children,
    required this.activities,
    required this.completions,
    required this.notices,
    required this.notifications,
    required this.suggestionStatus,
    required this.settings,
  });

  final List<Child> children;
  final List<Activity> activities;
  final List<Completion> completions;
  final List<ChangeNotice> notices;
  final List<CaregiverNotification> notifications;
  final Map<String, SuggestionStatus> suggestionStatus;
  final Settings settings;

  AppState copyWith({
    List<Child>? children,
    List<Activity>? activities,
    List<Completion>? completions,
    List<ChangeNotice>? notices,
    List<CaregiverNotification>? notifications,
    Map<String, SuggestionStatus>? suggestionStatus,
    Settings? settings,
  }) {
    return AppState(
      children: children ?? this.children,
      activities: activities ?? this.activities,
      completions: completions ?? this.completions,
      notices: notices ?? this.notices,
      notifications: notifications ?? this.notifications,
      suggestionStatus: suggestionStatus ?? this.suggestionStatus,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() => {
    'children': children.map((c) => c.toJson()).toList(),
    'activities': activities.map((a) => a.toJson()).toList(),
    'completions': completions.map((c) => c.toJson()).toList(),
    'notices': notices.map((n) => n.toJson()).toList(),
    'notifications': notifications.map((n) => n.toJson()).toList(),
    'suggestionStatus': suggestionStatus.map(
      (key, value) => MapEntry(key, value.name),
    ),
    'settings': settings.toJson(),
  };

  factory AppState.fromJson(Map<String, dynamic> json) {
    return AppState(
      children: (json['children'] as List)
          .map((c) => Child.fromJson(c as Map<String, dynamic>))
          .toList(),
      activities: (json['activities'] as List)
          .map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList(),
      completions: (json['completions'] as List)
          .map((c) => Completion.fromJson(c as Map<String, dynamic>))
          .toList(),
      notices: (json['notices'] as List)
          .map((n) => ChangeNotice.fromJson(n as Map<String, dynamic>))
          .toList(),
      notifications: (json['notifications'] as List)
          .map((n) => CaregiverNotification.fromJson(n as Map<String, dynamic>))
          .toList(),
      suggestionStatus: (json['suggestionStatus'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, SuggestionStatus.values.byName(value as String)),
      ),
      settings: Settings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppState &&
          listEq(children, other.children) &&
          listEq(activities, other.activities) &&
          listEq(completions, other.completions) &&
          listEq(notices, other.notices) &&
          listEq(notifications, other.notifications) &&
          mapEq(suggestionStatus, other.suggestionStatus) &&
          settings == other.settings;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(children),
    Object.hashAll(activities),
    Object.hashAll(completions),
    Object.hashAll(notices),
    Object.hashAll(notifications),
    Object.hashAll(
      suggestionStatus.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    settings,
  );
}
