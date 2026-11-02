import '../data/models/models.dart';
import 'schedule_rules.dart';

/// Menghasilkan semua saran aktif untuk anak tertentu (§9)
List<Suggestion> generateSuggestions(
  AppState state,
  DateTime now,
  String childId,
) {
  final suggestions = <Suggestion>[];

  final child = state.children.firstWhere(
    (c) => c.id == childId,
    orElse: () => state.children.first,
  );

  suggestions.addAll(_generateIndependenceSuggestions(state, now, child));
  suggestions.addAll(_generateQuietTimeSuggestions(state, now, child));
  suggestions.addAll(_generateTransitionGapSuggestions(state, now, child));
  suggestions.addAll(_generateEmptyDaySuggestions(state, now, child));

  return suggestions
      .where((s) =>
          (state.suggestionStatus[s.id] ?? SuggestionStatus.active) ==
          SuggestionStatus.active)
      .toList();
}

/// §9.3 Independence
List<Suggestion> _generateIndependenceSuggestions(
  AppState state,
  DateTime now,
  Child child,
) {
  final today = DateTime(now.year, now.month, now.day);
  final suggestions = <Suggestion>[];

  final candidateActivities = state.activities.where((a) =>
      a.childId == child.id &&
      a.steps.length >= 2 &&
      !a.independentMode &&
      a.date.year == today.year &&
      a.date.month == today.month &&
      a.date.day == today.day);

  for (final activity in candidateActivities) {
    final streak = countConsecutiveOnTimeCompletions(
      activity: activity,
      referenceDate: now,
      allActivities: state.activities,
      completions: state.completions,
    );

    if (streak >= state.settings.independenceStreakDays) {
      final suggestionId = 'independence:${activity.id}';
      final status =
          state.suggestionStatus[suggestionId] ?? SuggestionStatus.active;

      if (status == SuggestionStatus.active) {
        suggestions.add(
          Suggestion(
            id: suggestionId,
            type: SuggestionType.independence,
            childId: child.id,
            title: 'Latihan mandiri',
            body:
                '${activity.title} selesai tepat waktu $streak hari berturut-turut. Kurangi langkah instruksi dari ${activity.steps.length} jadi 1?',
            reasonData:
                '${activity.title} selesai tepat waktu dalam $streak kemunculan berturut-turut minggu ini.',
            reasonBasis:
                'Anak autis dapat berpindah kegiatan secara mandiri bila bantuan dikurangi bertahap (MacDuff dkk., 1993).',
            actionLabel: 'Kurangi langkah',
            payload: {
              'activityId': activity.id,
              'originalSteps': activity.steps.length,
            },
            status: status,
          ),
        );
      }
    }
  }

  return suggestions;
}

/// §9.1 Quiet Time
List<Suggestion> _generateQuietTimeSuggestions(
  AppState state,
  DateTime now,
  Child child,
) {
  final today = DateTime(now.year, now.month, now.day);
  final suggestions = <Suggestion>[];

  final todayActivities = state.activities
      .where((a) =>
          a.childId == child.id &&
          a.date.year == today.year &&
          a.date.month == today.month &&
          a.date.day == today.day)
      .toList();

  final sleepActivity = todayActivities.firstWhere(
    (a) => a.icon == ActivityIcon.tidur,
    orElse: () => todayActivities.first,
  );

  if (sleepActivity.icon != ActivityIcon.tidur) return suggestions;

  for (final activity in todayActivities) {
    if (!activity.usesScreen) continue;
    if (activity.end == null) continue;

    final gapMinutes =
        sleepActivity.start.toMinutes() - activity.end!.toMinutes();

    if (gapMinutes < state.settings.quietTimeMinutes && gapMinutes >= 0) {
      final suggestionId = 'quietTime:${activity.id}';
      final status =
          state.suggestionStatus[suggestionId] ?? SuggestionStatus.active;

      if (status == SuggestionStatus.active) {
        final hasNoticeToday = state.notices.any((n) =>
            n.activityId == activity.id &&
            n.sentAt.year == today.year &&
            n.sentAt.month == today.month &&
            n.sentAt.day == today.day);

        final bodyText = hasNoticeToday
            ? 'Jadwal hari ini berubah dan ${activity.title} selesai $gapMinutes menit sebelum tidur. Tambahkan waktu tenang tanpa layar?'
            : '${activity.title} selesai $gapMinutes menit sebelum tidur. Tambahkan waktu tenang tanpa layar?';

        suggestions.add(
          Suggestion(
            id: suggestionId,
            type: SuggestionType.quietTime,
            childId: child.id,
            title: 'Waktu tenang sebelum tidur',
            body: bodyText,
            reasonData:
                '${activity.title} selesai pukul ${activity.end!.hour.toString().padLeft(2, '0')}.${activity.end!.minute.toString().padLeft(2, '0')}, tidur pukul ${sleepActivity.start.hour.toString().padLeft(2, '0')}.${sleepActivity.start.minute.toString().padLeft(2, '0')}.',
            reasonBasis:
                'Anak autis yang memakai layar menjelang tidur rata-rata butuh waktu lebih lama untuk tertidur (Mazurek dkk., 2016).',
            actionLabel: 'Tambahkan waktu tenang',
            payload: {
              'screenActivityId': activity.id,
              'sleepStart': sleepActivity.start.toJson(),
              'suggestedDuration': state.settings.quietTimeMinutes,
            },
            status: status,
          ),
        );
      }
    }
  }

  return suggestions;
}


/// §9.2 Transition Gap
List<Suggestion> _generateTransitionGapSuggestions(
  AppState state,
  DateTime now,
  Child child,
) {
  final suggestions = <Suggestion>[];

  for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
    final checkDate = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));

    final dayActivities = state.activities
        .where((a) =>
            a.childId == child.id &&
            a.date.year == checkDate.year &&
            a.date.month == checkDate.month &&
            a.date.day == checkDate.day)
        .toList();

    final sorted = sortActivitiesByStartTime(dayActivities);

    for (int i = 0; i < sorted.length - 1; i++) {
      final first = sorted[i];
      final second = sorted[i + 1];

      final gap = calculateGapMinutes(first, second);
      if (gap != null && gap < state.settings.minGapMinutes) {
        final suggestionId = 'transitionGap:${first.id}:${second.id}';
        final status =
            state.suggestionStatus[suggestionId] ?? SuggestionStatus.active;

        if (status == SuggestionStatus.active) {
          final dayName = _getDayName(checkDate.weekday);
          suggestions.add(
            Suggestion(
              id: suggestionId,
              type: SuggestionType.transitionGap,
              childId: child.id,
              title: 'Jeda transisi',
              body:
                  '$dayName: ${second.title} mulai $gap menit setelah ${first.title} selesai. Beri jeda ${state.settings.minGapMinutes} menit?',
              reasonData:
                  '${first.title} selesai ${first.end!.hour.toString().padLeft(2, '0')}.${first.end!.minute.toString().padLeft(2, '0')}, ${second.title} mulai ${second.start.hour.toString().padLeft(2, '0')}.${second.start.minute.toString().padLeft(2, '0')}.',
              reasonBasis:
                  'Pemberitahuan sebelum perpindahan kegiatan dapat mengurangi kesulitan saat transisi (León dkk., 2023).',
              actionLabel: 'Geser ${second.title}',
              payload: {
                'firstActivityId': first.id,
                'secondActivityId': second.id,
                'currentGap': gap,
                'requiredGap': state.settings.minGapMinutes,
              },
              status: status,
            ),
          );
        }
      }
    }
  }

  return suggestions;
}

/// §9.4 Empty Day
List<Suggestion> _generateEmptyDaySuggestions(
  AppState state,
  DateTime now,
  Child child,
) {
  final suggestions = <Suggestion>[];

  if (child.likes.isEmpty) return suggestions;

  for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
    final checkDate = DateTime(now.year, now.month, now.day).add(Duration(days: dayOffset));

    final dayActivities = state.activities.where((a) =>
        a.childId == child.id &&
        a.date.year == checkDate.year &&
        a.date.month == checkDate.month &&
        a.date.day == checkDate.day);

    if (dayActivities.isEmpty) {
      final suggestionId = 'emptyDay:${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      final status =
          state.suggestionStatus[suggestionId] ?? SuggestionStatus.active;

      if (status == SuggestionStatus.active) {
        String? proposalText;
        ActivityIcon? proposalIcon;
        TimeOfDayLite? proposalStart;
        TimeOfDayLite? proposalEnd;

        if (child.likes.contains('Bersepeda')) {
          proposalText = 'Bersepeda pagi di taman pukul 07.00 saat masih sepi';
          proposalIcon = ActivityIcon.sepeda;
          proposalStart = const TimeOfDayLite(7, 0);
          proposalEnd = const TimeOfDayLite(7, 45);
        } else if (child.likes.contains('Puzzle')) {
          proposalText = 'Bermain puzzle di rumah pukul 09.00';
          proposalIcon = ActivityIcon.main;
          proposalStart = const TimeOfDayLite(9, 0);
          proposalEnd = const TimeOfDayLite(9, 45);
        }

        if (proposalText != null) {
          final dayName = _getDayName(checkDate.weekday);
          final avoidText =
              child.avoids.isNotEmpty ? child.avoids.first.toLowerCase() : '';

          suggestions.add(
            Suggestion(
              id: suggestionId,
              type: SuggestionType.emptyDay,
              childId: child.id,
              title: 'Isi hari kosong',
              body:
                  '$dayName masih kosong. ${child.name} suka ${child.likes.first.toLowerCase()}${avoidText.isNotEmpty ? ' dan tidak suka $avoidText' : ''}. $proposalText?',
              reasonData:
                  'Hari $dayName belum punya kegiatan. Profil ${child.name}: suka ${child.likes.join(', ')}, hindari ${child.avoids.join(', ')}.',
              reasonBasis:
                  'Kegiatan yang memakai minat khusus anak meningkatkan keterlibatan (Gunn & Delafield-Butt, 2016).',
              actionLabel: 'Tambahkan ke jadwal',
              payload: {
                'date':
                    '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}',
                'icon': proposalIcon!.name,
                'start': proposalStart!.toJson(),
                'end': proposalEnd!.toJson(),
                'title': proposalText.split(' pukul ').first,
              },
              status: status,
            ),
          );
        }
      }
    }
  }

  return suggestions;
}

String _getDayName(int weekday) {
  switch (weekday) {
    case 1:
      return 'Senin';
    case 2:
      return 'Selasa';
    case 3:
      return 'Rabu';
    case 4:
      return 'Kamis';
    case 5:
      return 'Jumat';
    case 6:
      return 'Sabtu';
    case 7:
      return 'Minggu';
    default:
      return '';
  }
}

