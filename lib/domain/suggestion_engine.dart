import '../data/models/models.dart';
import 'schedule_rules.dart';

/// Menghasilkan semua saran aktif untuk anak tertentu (§9)
List<Suggestion> generateSuggestions(
  AppState state,
  DateTime now,
  String childId,
) {
  final suggestions = <Suggestion>[];

  // Tanpa anak, tidak ada saran (akun baru belum mengisi profil).
  Child? child;
  for (final c in state.children) {
    if (c.id == childId) {
      child = c;
      break;
    }
  }
  if (child == null) return const [];

  suggestions.addAll(_generateIndependenceSuggestions(state, now, child));
  suggestions.addAll(_generateQuietTimeSuggestions(state, now, child));
  suggestions.addAll(_generateTransitionGapSuggestions(state, now, child));
  suggestions.addAll(_generateEmptyDaySuggestions(state, now, child));

  return suggestions
      .where(
        (s) =>
            (state.suggestionStatus[s.id] ?? SuggestionStatus.active) ==
            SuggestionStatus.active,
      )
      .toList();
}

/// Saran `emptyDay` yang berlaku untuk [date] saja (§9.4, §11 OT-07).
/// Mengembalikan null bila tidak ada saran untuk tanggal itu.
Suggestion? emptyDaySuggestionForDate(
  List<Suggestion> suggestions,
  DateTime date,
) {
  final key = _dateKey(date);
  for (final s in suggestions) {
    if (s.type == SuggestionType.emptyDay && s.payload['date'] == key) {
      return s;
    }
  }
  return null;
}

/// Benar bila "Cek otomatis · Jeda transisi aman" berlaku (§9.2): tidak ada
/// pemicu `transitionGap` dalam 7 hari ke depan (status saran diabaikan,
/// supaya saran yang di-dismiss tidak dianggap aman) dan hari ini punya
/// minimal dua kegiatan.
bool transitionGapAllClear(AppState state, DateTime now, String childId) {
  final today = DateTime(now.year, now.month, now.day);
  var todayCount = 0;
  for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
    final date = today.add(Duration(days: dayOffset));
    final sorted = sortActivitiesByStartTime(
      state.activities
          .where(
            (a) =>
                a.childId == childId &&
                a.date.year == date.year &&
                a.date.month == date.month &&
                a.date.day == date.day,
          )
          .toList(),
    );
    if (dayOffset == 0) todayCount = sorted.length;
    for (int i = 0; i < sorted.length - 1; i++) {
      final gap = calculateGapMinutes(sorted[i], sorted[i + 1]);
      if (gap != null && gap < state.settings.minGapMinutes) return false;
    }
  }
  return todayCount >= 2;
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// §9.3 Independence
List<Suggestion> _generateIndependenceSuggestions(
  AppState state,
  DateTime now,
  Child child,
) {
  final today = DateTime(now.year, now.month, now.day);
  final suggestions = <Suggestion>[];

  final candidateActivities = state.activities.where(
    (a) =>
        a.childId == child.id &&
        a.steps.length >= 2 &&
        !a.independentMode &&
        a.date.year == today.year &&
        a.date.month == today.month &&
        a.date.day == today.day,
  );

  for (final activity in candidateActivities) {
    final streakDates = consecutiveOnTimeDates(
      activity: activity,
      referenceDate: now,
      allActivities: state.activities,
      completions: state.completions,
    );
    final streak = streakDates.length;

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
                '${activity.title} selesai tepat waktu ${formatDateRange(streakDates.last, streakDates.first)} minggu ini.',
            reasonBasis:
                'Anak autis dapat berpindah kegiatan secara mandiri bila bantuan dikurangi bertahap (MacDuff dkk., 1993).',
            actionLabel: 'Kurangi langkah',
            payload: {
              'activityId': activity.id,
              'originalSteps': activity.steps.length,
              // Teks detail (§9.3, OT-17); daftar memakai [body].
              'detailBody':
                  '${child.name} menyelesaikan ${activity.title} tepat waktu $streak hari berturut-turut. Coba kurangi langkah instruksi dari ${activity.steps.length} menjadi 1 supaya ${child.name} berlatih mandiri.',
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
      .where(
        (a) =>
            a.childId == child.id &&
            a.date.year == today.year &&
            a.date.month == today.month &&
            a.date.day == today.day,
      )
      .toList();

  final sleepIndex = todayActivities.indexWhere(
    (a) => a.icon == ActivityIcon.tidur,
  );
  if (sleepIndex == -1) return suggestions;
  final sleepActivity = todayActivities[sleepIndex];

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
        final hasNoticeToday = state.notices.any(
          (n) =>
              n.activityId == activity.id &&
              n.sentAt.year == today.year &&
              n.sentAt.month == today.month &&
              n.sentAt.day == today.day,
        );

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
    final checkDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: dayOffset));

    final dayActivities = state.activities
        .where(
          (a) =>
              a.childId == child.id &&
              a.date.year == checkDate.year &&
              a.date.month == checkDate.month &&
              a.date.day == checkDate.day,
        )
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

  // Hanya hari ini sampai Minggu pada minggu yang ditampilkan (§9.4)
  final daysUntilSunday = DateTime.sunday - now.weekday;
  for (int dayOffset = 0; dayOffset <= daysUntilSunday; dayOffset++) {
    final checkDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: dayOffset));

    final dayActivities = state.activities.where(
      (a) =>
          a.childId == child.id &&
          a.date.year == checkDate.year &&
          a.date.month == checkDate.month &&
          a.date.day == checkDate.day,
    );

    if (dayActivities.isEmpty) {
      final suggestionId =
          'emptyDay:${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
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
          final avoidText = child.avoids.isNotEmpty
              ? child.avoids.first.toLowerCase()
              : '';

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
