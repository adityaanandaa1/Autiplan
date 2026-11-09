import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/schedule_rules.dart';
import '../../features/caregiver/forms/form_utils.dart';

/// A-01/A-03/A-11: Jadwal anak (HANDOFF §12 A-01, A-03, A-11).
/// Tema dari Child.theme, banner perubahan bila ada, daftar kegiatan hari ini.
class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;

    final child = ref.watch(currentChildProvider);
    if (child == null) return const CalmEmptyScreen(isChild: true);

    final palette = Theme.of(context).extension<ChildPalette>()!;
    final today = DateTime(now.year, now.month, now.day);

    // Sapaan berdasarkan jam (HANDOFF §11 OT-01)
    final hour = now.hour;
    final greeting = hour >= 4 && hour < 11
        ? 'Selamat pagi'
        : hour >= 11 && hour < 15
        ? 'Selamat siang'
        : hour >= 15 && hour < 18
        ? 'Selamat sore'
        : 'Selamat malam';

    // Banner: ada ChangeNotice hari ini dengan seenAt == null
    final hasUnseenNotice = state.notices.any(
      (n) =>
          n.childId == child.id &&
          n.sentAt.year == today.year &&
          n.sentAt.month == today.month &&
          n.sentAt.day == today.day &&
          n.seenAt == null,
    );

    // Kegiatan hari ini, filter yang tidak dihapus
    final todayActivities = state.activities
        .where(
          (a) =>
              a.childId == child.id &&
              a.date.year == today.year &&
              a.date.month == today.month &&
              a.date.day == today.day,
        )
        .toList();

    final visibleActivities = todayActivities.where((a) {
      final notice = state.notices.firstWhere(
        (n) => n.activityId == a.id && _isSameDay(n.sentAt, today),
        orElse: () => ChangeNotice(
          id: '',
          childId: '',
          activityId: '',
          before: ActivitySnapshot(
            title: '',
            icon: ActivityIcon.sepeda,
            start: const TimeOfDayLite(0, 0),
            shortTitle: '',
          ),
          message: '',
          sentAt: DateTime(1970),
        ),
      );
      return notice.id.isEmpty || notice.after != null;
    }).toList();

    final sorted = sortActivitiesByStartTime(visibleActivities);

    final current = findCurrentActivity(
      childId: child.id,
      now: now,
      activities: state.activities,
      completions: state.completions,
    );

    return Scaffold(
      backgroundColor: palette.anakLatar,
      body: _buildBody(
        context,
        child,
        palette,
        today,
        now,
        greeting,
        hasUnseenNotice,
        sorted,
        current,
        state,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  ChildActivityStatus _cardStatus(
    Activity activity,
    DateTime today,
    DateTime now,
    Activity? current,
    List<Completion> completions,
    List<ChangeNotice> notices,
  ) {
    if (completions.any(
      (c) =>
          c.activityId == activity.id &&
          c.date.year == today.year &&
          c.date.month == today.month &&
          c.date.day == today.day,
    )) {
      return ChildActivityStatus.completed;
    }

    if (current != null && current.id == activity.id) {
      return ChildActivityStatus.now;
    }

    if (notices.any(
      (n) =>
          n.activityId == activity.id &&
          n.sentAt.year == today.year &&
          n.sentAt.month == today.month &&
          n.sentAt.day == today.day,
    )) {
      return ChildActivityStatus.changed;
    }

    return ChildActivityStatus.normal;
  }

  Widget _buildBody(
    BuildContext context,
    Child child,
    ChildPalette palette,
    DateTime today,
    DateTime now,
    String greeting,
    bool hasUnseenNotice,
    List<Activity> sorted,
    Activity? current,
    AppState state,
  ) {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.emergencyClearance,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: GestureDetector(
                    onLongPress: () => context.go('/'),
                    child: ChildHeader(
                      greeting: greeting,
                      childName: 'Halo, ${child.name}!',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingChild,
                      0,
                      AppSpacing.screenPaddingChild,
                      AppSpacing.grid16,
                    ),
                    child: Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(today),
                      style: AppTypography.sekunderAnak,
                    ),
                  ),
                ),
                if (hasUnseenNotice) _buildBanner(context, palette),
                _buildActivityList(sorted, today, now, current, state),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.grid20),
                ),
              ],
            ),
          ),
        ),
        _buildOverlays(context, palette),
      ],
    );
  }

  Widget _buildBanner(BuildContext context, ChildPalette palette) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingChild,
          0,
          AppSpacing.screenPaddingChild,
          AppSpacing.sectionGapChild,
        ),
        child: Material(
          color: palette.anakAksenLembut,
          borderRadius: AppRadius.kartuAnak,
          child: InkWell(
            onTap: () => context.push('/anak/perubahan'),
            borderRadius: AppRadius.kartuAnak,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.grid16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ada perubahan jadwal hari ini',
                      style: AppTypography.isiAnak.copyWith(
                        color: palette.anakAksenKuat,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.grid8),
                  Text(
                    'Lihat',
                    style: AppTypography.tombolAnakTeks.copyWith(
                      color: palette.anakAksenKuat,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityList(
    List<Activity> sorted,
    DateTime today,
    DateTime now,
    Activity? current,
    AppState state,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingChild,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= sorted.length) return null;
          final activity = sorted[index];
          final status = _cardStatus(
            activity,
            today,
            now,
            current,
            state.completions,
            state.notices,
          );
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == sorted.length - 1
                  ? 0
                  : AppSpacing.sectionGapChild,
            ),
            child: ChildActivityCard(
              icon: activity.icon,
              title: activity.shortTitle,
              time: formatTimeLite(activity.start),
              status: status,
              onTap: () => context.push('/anak/aktivitas/${activity.id}'),
            ),
          );
        }, childCount: sorted.length),
      ),
    );
  }

  Widget _buildOverlays(BuildContext context, ChildPalette palette) {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.grid8,
          right: AppSpacing.grid16,
          child: const RoleSwitchButton(isChild: true),
        ),
        Positioned(
          right: AppSpacing.grid16,
          bottom: AppSpacing.grid16,
          child: EmergencyButton(
            onPressed: () => context.push('/anak/darurat'),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.grid20,
          left: AppSpacing.screenPaddingChild,
          child: Semantics(
            button: true,
            label: 'Pilih tema',
            child: InkWell(
              onTap: () => context.push('/anak/tema'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.grid8),
                child: Text(
                  'Tema',
                  style: AppTypography.sekunderAnak.copyWith(
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
