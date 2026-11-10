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
            _buildHeader(context, ref, monthYear, selectedDate, state),
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
                  // Panah memberi petunjuk bahwa minggu bisa digeser; geser
                  // jari pada strip tetap berfungsi.
                  Row(
                    children: [
                      _WeekArrow(
                        icon: LucideIcons.chevronLeft,
                        label: 'Minggu sebelumnya',
                        onTap: () => _shift(ref, weekStart, selectedDate, -1),
                      ),
                      Expanded(
                        child: Text(
                          _weekRange(weekDates),
                          textAlign: TextAlign.center,
                          style: AppTypography.meta.copyWith(
                            color: AppColors.teksSekunder,
                          ),
                        ),
                      ),
                      _WeekArrow(
                        icon: LucideIcons.chevronRight,
                        label: 'Minggu berikutnya',
                        onTap: () => _shift(ref, weekStart, selectedDate, 1),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v == 0) return;
                      _shift(ref, weekStart, selectedDate, v < 0 ? 1 : -1);
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

  static void _shift(WidgetRef ref, DateTime weekStart, DateTime date, int w) {
    final shifted = shiftWeek(weekStart, date, w);
    ref.read(selectedWeekStartProvider.notifier).state = shifted.weekStart;
    ref.read(selectedDateProvider.notifier).state = shifted.selectedDate;
  }

  static String _weekRange(List<DateTime> days) {
    final first = days.first;
    final last = days.last;
    final end = DateFormat('d MMM', 'id_ID').format(last);
    final start = first.month == last.month
        ? '${first.day}'
        : DateFormat('d MMM', 'id_ID').format(first);
    return '$start – $end';
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(selectedDate.year - 2),
      lastDate: DateTime(selectedDate.year + 2, 12, 31),
      locale: const Locale('id', 'ID'),
    );
    if (picked == null) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    ref.read(selectedDateProvider.notifier).state = day;
    ref.read(selectedWeekStartProvider.notifier).state = mondayOf(day);
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String monthYear,
    DateTime selectedDate,
    AppState state,
  ) {
    return CaregiverHeader(
      title: 'Jadwal',
      trailing: Semantics(
        button: true,
        label: 'Pilih bulan, $monthYear',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => _pickMonth(context, ref, selectedDate),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTouchTarget,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  monthYear,
                  style: AppTypography.judulBaris.copyWith(
                    color: AppColors.utama,
                  ),
                ),
                const SizedBox(width: AppSpacing.grid4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: AppSpacing.iconSize18,
                  color: AppColors.utama,
                ),
              ],
            ),
          ),
        ),
      ),
      showBell: true,
      onBellTap: () => context.push('/ortu/notifikasi'),
      bellHasBadge: state.notifications.any((n) => !n.read),
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AppSpacing.minTouchTarget,
          height: AppSpacing.minTouchTarget,
          child: Icon(
            icon,
            size: AppSpacing.iconSize24,
            color: AppColors.utama,
          ),
        ),
      ),
    );
  }
}
