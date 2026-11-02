import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/add_fab.dart';
import '../../core/widgets/card_surface.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../core/widgets/change_notice_card.dart';
import '../../core/widgets/child_segmented.dart';
import '../../core/widgets/role_switch_button.dart';
import '../../core/widgets/suggestion_card.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/schedule_rules.dart';
import '../../domain/suggestion_engine.dart';
import 'widgets/add_activity_sheet.dart';
import 'widgets/current_activity_card.dart';

class CaregiverHomeScreen extends ConsumerWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;

    final child = state.children.firstWhere((c) => c.id == selectedChildId);
    final childIndex =
        state.children.indexWhere((c) => c.id == selectedChildId);

    final todayActivities = state.activities
        .where((a) =>
            a.childId == selectedChildId &&
            a.date.year == now.year &&
            a.date.month == now.month &&
            a.date.day == now.day)
        .toList();

    final sortedActivities = sortActivitiesByStartTime(todayActivities);
    final suggestions = generateSuggestions(state, now, selectedChildId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Beranda',
              showBell: true,
              onBellTap: () => context.push('/ortu/notifikasi'),
              bellHasBadge: state.notifications.any((n) => !n.read),
            ),
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
                  const SizedBox(height: AppSpacing.grid20),
                  _buildCurrentActivitySection(
                    context,
                    child,
                    sortedActivities,
                    state.completions,
                    now,
                  ),
                  const SizedBox(height: AppSpacing.grid20),
                  _buildAttentionSection(context, state, child, now),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.grid20),
                    SuggestionCard(
                      content: suggestions.first.body,
                      actionLabel: 'Lihat semua saran',
                      onTap: () => context.push('/ortu/saran'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.grid20),
                  const RoleSwitchButton(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AddFab(
        onPressed: () {
          // OT-01: FAB Tambah → sheet Tambah jadwal (anak terpilih, hari ini).
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => AddActivitySheet(
              childId: selectedChildId,
              initialDate: now,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentActivitySection(
    BuildContext context,
    Child child,
    List<Activity> activities,
    List<Completion> completions,
    DateTime now,
  ) {
    Activity? currentActivity;
    Activity? nextActivity;

    for (final activity in activities) {
      final statusResult = getActivityStatus(
        activity: activity,
        selectedDate: now,
        now: now,
        completions: completions,
        notices: [],
      );
      if (statusResult.isNow) {
        currentActivity = activity;
        break;
      }
    }

    if (currentActivity == null) {
      for (final activity in activities) {
        final startMinutes = activity.start.toMinutes();
        final nowMinutes = now.hour * 60 + now.minute;
        if (startMinutes > nowMinutes) {
          nextActivity = activity;
          break;
        }
      }
    }

    final (completedCount, totalCount) = calculateProgress(
      childId: child.id,
      date: now,
      activities: activities,
      completions: completions,
    );

    return CurrentActivityCard(
      child: child,
      currentActivity: currentActivity,
      nextActivity: nextActivity,
      completedCount: completedCount,
      totalCount: totalCount,
      onTapSchedule: () => context.go('/ortu/jadwal'),
    );
  }

  Widget _buildAttentionSection(
    BuildContext context,
    AppState state,
    Child child,
    DateTime now,
  ) {
    final todayNotices = state.notices
        .where((n) =>
            n.childId == child.id &&
            n.sentAt.year == now.year &&
            n.sentAt.month == now.month &&
            n.sentAt.day == now.day)
        .toList();

    todayNotices.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final hasUnreadNotices = todayNotices.any((n) => n.seenAt == null);
    final latestNotice = todayNotices.isNotEmpty ? todayNotices.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Perlu perhatian', style: AppTypography.judulBagian),
        const SizedBox(height: AppSpacing.grid12),
        if (todayNotices.isEmpty)
          CardSurface(
            child: Row(
              children: [
                Container(
                  width: AppSpacing.iconTile40,
                  height: AppSpacing.iconTile40,
                  decoration: BoxDecoration(
                    color: AppColors.suksesLembut,
                    borderRadius: AppRadius.ubinIkon10,
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    size: AppSpacing.iconSize20,
                    color: AppColors.sukses,
                  ),
                ),
                const SizedBox(width: AppSpacing.grid12),
                const Expanded(
                  child: Text(
                    'Semua jadwal berjalan sesuai rencana.',
                    style: AppTypography.isi,
                  ),
                ),
              ],
            ),
          )
        else
          ChangeNoticeCard(
            childName: child.name,
            hasUnread: hasUnreadNotices,
            seenAt: latestNotice?.seenAt,
            onTap: () => context.go('/ortu/jadwal'),
          ),
      ],
    );
  }
}

