import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/add_fab.dart';
import '../../core/widgets/calm_empty_screen.dart';
import '../../core/widgets/card_surface.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../core/widgets/change_notice_card.dart';
import '../../core/widgets/child_segmented.dart';
import '../../core/widgets/suggestion_card.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/schedule_rules.dart';
import '../../domain/suggestion_engine.dart';
import 'widgets/add_activity_sheet.dart';
import 'widgets/current_activity_card.dart';
import 'widgets/live_tutor_dialog.dart';

/// Sapaan Beranda (OT-01): pagi 04–10.59, siang 11–14.59, sore 15–17.59,
/// malam 18–03.59.
String caregiverGreeting(DateTime now, String caregiverName) {
  final h = now.hour;
  final String part;
  if (h >= 4 && h < 11) {
    part = 'pagi';
  } else if (h >= 11 && h < 15) {
    part = 'siang';
  } else if (h >= 15 && h < 18) {
    part = 'sore';
  } else {
    part = 'malam';
  }
  final name = caregiverName.isEmpty ? 'Pengasuh' : caregiverName;
  return 'Selamat $part, $name';
}

class CaregiverHomeScreen extends ConsumerStatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  ConsumerState<CaregiverHomeScreen> createState() =>
      _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends ConsumerState<CaregiverHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showCaregiverLiveTutorIfNeeded(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final child = ref.watch(currentChildProvider);
    if (child == null) return const CalmEmptyScreen();
    final clock = ref.watch(clockProvider);
    final now = clock.now;

    final childIndex = state.children.indexWhere((c) => c.id == child.id);

    final todayActivities = state.activities
        .where(
          (a) =>
              a.childId == child.id &&
              a.date.year == now.year &&
              a.date.month == now.month &&
              a.date.day == now.day,
        )
        .toList();

    final sortedActivities = sortActivitiesByStartTime(todayActivities);
    final suggestions = generateSuggestions(state, now, child.id);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Beranda',
              showBell: true,
              onBellTap: () => context.push('/ortu/notifikasi'),
              bellHasBadge: state.notifications.any((n) => !n.read),
              trailing: IconButton(
                icon: const Icon(
                  LucideIcons.helpCircle,
                  size: AppSpacing.iconSize22,
                  color: AppColors.teksSekunder,
                ),
                onPressed: () => showCaregiverLiveTutor(context, ref),
                tooltip: 'Panduan aplikasi (Live Tutor)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.minTouchTarget,
                  minHeight: AppSpacing.minTouchTarget,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
                children: [
                  Text(
                    caregiverGreeting(now, state.settings.caregiverName),
                    style: AppTypography.sapaan,
                  ),
                  const SizedBox(height: AppSpacing.grid4),
                  Text(
                    DateFormat('EEEE, d MMMM y', 'id_ID').format(now),
                    style: AppTypography.isi.copyWith(
                      color: AppColors.teksSekunder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid20),
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
                      label:
                          'Saran untuk ${child.name} · 1 dari ${suggestions.length}',
                      content: suggestions.first.body,
                      actionLabel: 'Lihat semua saran',
                      onTap: () => context.push('/ortu/saran'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.grid20),
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
            builder: (ctx) =>
                AddActivitySheet(childId: child.id, initialDate: now),
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
    // Maksimal satu "Sekarang": start paling akhir (§8.1).
    final currentActivity = findCurrentActivity(
      childId: child.id,
      now: now,
      activities: activities,
      completions: completions,
    );

    Activity? nextActivity;
    if (currentActivity == null) {
      final nowMinutes = now.hour * 60 + now.minute;
      for (final activity in activities) {
        if (activity.start.toMinutes() > nowMinutes) {
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
        .where(
          (n) =>
              n.childId == child.id &&
              n.sentAt.year == now.year &&
              n.sentAt.month == now.month &&
              n.sentAt.day == now.day,
        )
        .toList();

    final summary = summarizeNotices(todayNotices);
    final latestNotice = summary?.latest;

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
            hasUnread: latestNotice!.seenAt == null,
            seenAt: latestNotice.seenAt,
            changeLine: noticeChangeLine(latestNotice),
            otherCount: summary!.otherCount,
            onTap: () => context.go('/ortu/jadwal'),
          ),
      ],
    );
  }
}
