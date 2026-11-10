import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/add_fab.dart';
import '../../core/widgets/calm_empty_screen.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../core/widgets/child_segmented.dart';
import '../../core/widgets/day_summary.dart';
import '../../core/widgets/week_strip.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/schedule_rules.dart';
import '../../domain/suggestion_engine.dart';
import 'schedule_providers.dart';
import 'widgets/add_activity_sheet.dart';
import 'widgets/schedule_activity_rows.dart';
import 'widgets/schedule_empty_day.dart';

/// Berpindah [weeks] minggu pada strip. Tanggal terpilih ikut bergeser
/// (hari yang sama di minggu tujuan) supaya selalu terlihat di strip dan
/// ringkasan hari/daftar kegiatan konsisten dengan strip (OT-04).
({DateTime weekStart, DateTime selectedDate}) shiftWeek(
  DateTime weekStart,
  DateTime selectedDate,
  int weeks,
) {
  final delta = Duration(days: 7 * weeks);
  return (
    weekStart: weekStart.add(delta),
    selectedDate: selectedDate.add(delta),
  );
}

class CaregiverScheduleScreen extends ConsumerWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hari berganti: ikut pindah hanya bila pengguna sedang melihat "hari ini".
    ref.listen<DateTime>(currentDayProvider, (previous, today) {
      if (ref.read(selectedDateProvider) != previous) return;
      ref.read(selectedDateProvider.notifier).state = today;
      ref.read(selectedWeekStartProvider.notifier).state = mondayOf(today);
    });

    final state = ref.watch(appStateProvider);
    final child = ref.watch(currentChildProvider);
    if (child == null) return const CalmEmptyScreen();
    final selectedDate = ref.watch(selectedDateProvider);
    final weekStart = ref.watch(selectedWeekStartProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;

    final childIndex = state.children.indexWhere((c) => c.id == child.id);
    final weekDates = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final selectedDayActivities = state.activities
        .where(
          (a) =>
              a.childId == child.id &&
              a.date.year == selectedDate.year &&
              a.date.month == selectedDate.month &&
              a.date.day == selectedDate.day,
        )
        .toList();

    final sortedActivities = sortActivitiesByStartTime(selectedDayActivities);

    final (completedCount, totalCount) = calculateProgress(
      childId: child.id,
      date: selectedDate,
      activities: selectedDayActivities,
      completions: state.completions,
    );

    final datesWithActivities = <DateTime>{};
    for (final a in state.activities.where((a) => a.childId == child.id)) {
      datesWithActivities.add(DateTime(a.date.year, a.date.month, a.date.day));
    }

    final emptyDaySuggestion = sortedActivities.isEmpty
        ? emptyDaySuggestionForDate(
            generateSuggestions(state, now, child.id),
            selectedDate,
          )
        : null;

    final monthYear = DateFormat('MMMM yyyy', 'id_ID').format(selectedDate);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, monthYear, state.notifications),
            Expanded(
              child: ListView(
                // Samping 12 (bukan 16) supaya tujuh tanggal tiap minimal 48 dp
                // di lebar 360 dp.
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.grid12,
                  vertical: AppSpacing.grid16,
                ),
                children: [
                  ChildSegmented(
                    children: state.children
                        .map((c) => ChildSegmentData(name: c.name, age: c.age))
                        .toList(),
                    selectedIndex: childIndex,
                    onSegmentSelected: (index) {
                      ref.read(selectedChildIdProvider.notifier).state =
                          state.children[index].id;
                    },
                  ),
                  const SizedBox(height: AppSpacing.grid12),
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v == 0) return;
                      final shifted = shiftWeek(
                        weekStart,
                        selectedDate,
                        v < 0 ? 1 : -1,
                      );
                      ref.read(selectedWeekStartProvider.notifier).state =
                          shifted.weekStart;
                      ref.read(selectedDateProvider.notifier).state =
                          shifted.selectedDate;
                    },
                    child: WeekStrip(
                      dates: weekDates,
                      selectedDate: selectedDate,
                      onDateSelected: (date) {
                        ref.read(selectedDateProvider.notifier).state = date;
                      },
                      datesWithActivities: datesWithActivities,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid12),
                  DaySummary(
                    date: selectedDate,
                    completedCount: completedCount,
                    totalCount: totalCount,
                  ),
                  const SizedBox(height: AppSpacing.grid12),
                  if (sortedActivities.isEmpty)
                    ScheduleEmptyDay(
                      childName: child.name,
                      suggestion: emptyDaySuggestion,
                    )
                  else
                    ...buildScheduleActivityRows(
                      context: context,
                      activities: sortedActivities,
                      selectedDate: selectedDate,
                      now: now,
                      state: state,
                      child: child,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AddFab(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) =>
                AddActivitySheet(childId: child.id, initialDate: selectedDate),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String monthYear,
    List<CaregiverNotification> notifications,
  ) {
    return CaregiverHeader(
      title: 'Jadwal',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            monthYear,
            style: AppTypography.judulBaris.copyWith(color: AppColors.utama),
          ),
          const SizedBox(width: AppSpacing.grid4),
          const Icon(
            LucideIcons.chevronDown,
            size: AppSpacing.iconSize18,
            color: AppColors.utama,
          ),
        ],
      ),
      showBell: true,
      onBellTap: () => context.push('/ortu/notifikasi'),
      bellHasBadge: notifications.any((n) => !n.read),
    );
  }
}
