import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/add_fab.dart';
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

class CaregiverScheduleScreen extends ConsumerWidget {
  const CaregiverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final weekStart = ref.watch(selectedWeekStartProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;

    final child = state.children.firstWhere((c) => c.id == selectedChildId);
    final childIndex = state.children.indexWhere((c) => c.id == selectedChildId);
    final weekDates = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final selectedDayActivities = state.activities
        .where((a) =>
            a.childId == selectedChildId &&
            a.date.year == selectedDate.year &&
            a.date.month == selectedDate.month &&
            a.date.day == selectedDate.day)
        .toList();

    final sortedActivities = sortActivitiesByStartTime(selectedDayActivities);

    final (completedCount, totalCount) = calculateProgress(
      childId: selectedChildId,
      date: selectedDate,
      activities: selectedDayActivities,
      completions: state.completions,
    );

    final datesWithActivities = <DateTime>{};
    for (final a in state.activities.where((a) => a.childId == selectedChildId)) {
      datesWithActivities.add(DateTime(a.date.year, a.date.month, a.date.day));
    }

    final suggestions = generateSuggestions(state, now, selectedChildId);
    final emptyDayList = suggestions
        .where((s) => s.type == SuggestionType.emptyDay)
        .toList();
    final emptyDaySuggestion = sortedActivities.isEmpty && emptyDayList.isNotEmpty
        ? emptyDayList.first
        : null;

    final monthYear = DateFormat('MMMM yyyy', 'id_ID').format(selectedDate);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, monthYear),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
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
                      if (details.primaryVelocity! < 0) {
                        ref.read(selectedWeekStartProvider.notifier).state =
                            weekStart.add(const Duration(days: 7));
                      } else if (details.primaryVelocity! > 0) {
                        ref.read(selectedWeekStartProvider.notifier).state =
                            weekStart.subtract(const Duration(days: 7));
                      }
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
            builder: (ctx) => AddActivitySheet(
              childId: selectedChildId,
              initialDate: selectedDate,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String monthYear) {
    return CaregiverHeader(
      title: 'Jadwal',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(monthYear, style: AppTypography.judulBaris),
          const SizedBox(width: 4),
          const Icon(LucideIcons.chevronDown, size: AppSpacing.iconSize18, color: AppColors.teks),
          const SizedBox(width: AppSpacing.grid12),
          IconButton(
            icon: const Icon(LucideIcons.bell),
            iconSize: AppSpacing.iconSize22,
            color: AppColors.teks,
            onPressed: () => context.push('/ortu/notifikasi'),
          ),
        ],
      ),
      showBell: false,
    );
  }
}
