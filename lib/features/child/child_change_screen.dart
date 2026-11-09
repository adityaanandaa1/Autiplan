import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/schedule_rules.dart';
import '../../features/caregiver/forms/form_utils.dart';

/// A-02: Perubahan jadwal (HANDOFF §12 A-02).
class ChildChangeScreen extends ConsumerWidget {
  const ChildChangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;
    final palette = Theme.of(context).extension<ChildPalette>()!;

    final child = ref.watch(currentChildProvider);
    if (child == null) return const CalmEmptyScreen(isChild: true);

    final today = DateTime(now.year, now.month, now.day);

    final unseen =
        state.notices
            .where(
              (n) =>
                  n.childId == child.id &&
                  n.sentAt.year == today.year &&
                  n.sentAt.month == today.month &&
                  n.sentAt.day == today.day &&
                  n.seenAt == null,
            )
            .toList()
          ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    if (unseen.isEmpty) {
      context.go('/anak');
      return const SizedBox.shrink();
    }

    final notice = unseen.first;
    final remainingCount = unseen.length - 1;

    return Scaffold(
      backgroundColor: palette.anakLatar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChildBackHeader(
                title: 'Perubahan Jadwal',
                onBack: () => context.go('/anak'),
              ),
              const SizedBox(height: AppSpacing.grid24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChangeTiles(notice, palette),
                      const SizedBox(height: AppSpacing.grid20),
                      _buildReason(notice),
                      if (notice.after != null)
                        _buildNextActivity(state, notice, now),
                      if (remainingCount > 0) ...[
                        const SizedBox(height: AppSpacing.grid20),
                        Text(
                          'Ada $remainingCount kegiatan yang berubah hari ini.',
                          style: AppTypography.isiAnak,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.grid20),
              ChildButton(
                label: 'Oke, aku mengerti',
                onPressed: () => _acknowledge(context, ref, notice, now),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeTiles(ChangeNotice notice, ChildPalette palette) {
    return Row(
      children: [
        Expanded(
          child: _tile(notice.before, palette, opacity: 0.6, border: false),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.grid12),
          child: Icon(
            LucideIcons.arrowRight,
            size: AppSpacing.iconSize24,
            color: AppColors.teksSekunder,
          ),
        ),
        Expanded(
          child: _tile(
            notice.after ?? notice.before,
            palette,
            opacity: 1.0,
            border: true,
          ),
        ),
      ],
    );
  }

  Widget _tile(
    ActivitySnapshot snap,
    ChildPalette palette, {
    required double opacity,
    required bool border,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.grid16),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          borderRadius: AppRadius.kartuAnak,
          border: border
              ? Border.all(
                  color: palette.anakAksen,
                  width: AppSpacing.strokeAccent,
                )
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: AppSpacing.iconTileLarge,
              height: AppSpacing.iconTileLarge,
              decoration: BoxDecoration(
                color: palette.anakAksenLembut,
                borderRadius: AppRadius.ubinIkonKartuAnak,
              ),
              child: Icon(
                _iconFor(snap.icon),
                size: AppSpacing.iconSize24,
                color: palette.anakAksenKuat,
              ),
            ),
            const SizedBox(height: AppSpacing.grid8),
            Text(
              snap.title,
              style: AppTypography.isiAnak,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.grid4),
            Text(formatTimeLite(snap.start), style: AppTypography.sekunderAnak),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ActivityIcon icon) {
    switch (icon) {
      case ActivityIcon.nonton:
        return LucideIcons.tv;
      case ActivityIcon.tidur:
        return LucideIcons.moon;
      default:
        return LucideIcons.sun;
    }
  }

  Widget _buildReason(ChangeNotice notice) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid16),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.kartuAnak,
      ),
      child: Text(notice.message, style: AppTypography.isiAnak),
    );
  }

  Widget _buildNextActivity(AppState state, ChangeNotice notice, DateTime now) {
    if (notice.after == null) return const SizedBox.shrink();
    final activity = state.activities.firstWhere(
      (a) => a.id == notice.activityId,
      orElse: () => Activity(
        id: '',
        childId: '',
        title: '',
        shortTitle: '',
        icon: ActivityIcon.sepeda,
        date: now,
        start: const TimeOfDayLite(0, 0),
      ),
    );
    if (activity.id.isEmpty) return const SizedBox.shrink();
    final nextActivity = _findNext(state.activities, activity);
    if (nextActivity == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.grid12),
      child: Text(
        'Setelah itu: ${nextActivity.shortTitle}, ${formatTimeLite(nextActivity.start)}',
        style: AppTypography.sekunderAnak,
      ),
    );
  }

  Activity? _findNext(List<Activity> activities, Activity current) {
    final sorted = sortActivitiesByStartTime(
      activities
          .where(
            (a) =>
                a.childId == current.childId &&
                a.date.year == current.date.year &&
                a.date.month == current.date.month &&
                a.date.day == current.date.day &&
                a.start.toMinutes() > current.start.toMinutes(),
          )
          .toList(),
    );
    return sorted.isEmpty ? null : sorted.first;
  }

  void _acknowledge(
    BuildContext context,
    WidgetRef ref,
    ChangeNotice notice,
    DateTime now,
  ) {
    final state = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final updated = acknowledgeNotice(
      state: state,
      noticeId: notice.id,
      now: now,
      notificationId: const Uuid().v4(),
    );
    notifier.updateState(updated);
    context.go('/anak');
  }
}
