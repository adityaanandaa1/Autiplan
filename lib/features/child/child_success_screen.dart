import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/schedule_rules.dart';
import '../../features/caregiver/forms/form_utils.dart';

/// A-06: Berhasil (HANDOFF §12 A-06).
class ChildSuccessScreen extends ConsumerWidget {
  const ChildSuccessScreen({super.key, required this.activityId});
  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final palette = Theme.of(context).extension<ChildPalette>()!;

    final activity = state.activities.firstWhere(
      (a) => a.id == activityId,
      orElse: () => Activity(
        id: '',
        childId: '',
        title: '',
        shortTitle: '',
        icon: ActivityIcon.sepeda,
        date: DateTime.now(),
        start: const TimeOfDayLite(0, 0),
      ),
    );

    if (activity.id.isEmpty) {
      context.go('/anak');
      return const SizedBox.shrink();
    }

    final nextActivity = _findNext(state.activities, activity);

    return Scaffold(
      backgroundColor: palette.anakLatar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
          child: Column(
            children: [
              ChildBackHeader(onBack: () => context.go('/anak')),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Mascot(size: AppSpacing.mascotSize),
                      const SizedBox(height: AppSpacing.grid24),
                      Text('Kamu berhasil!', style: AppTypography.judulAnak),
                      const SizedBox(height: AppSpacing.grid8),
                      Text(
                        '${activity.shortTitle} sudah selesai.',
                        style: AppTypography.isiAnak,
                      ),
                      const SizedBox(height: AppSpacing.grid24),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.grid16),
                        decoration: BoxDecoration(
                          color: AppColors.permukaan,
                          borderRadius: AppRadius.kartuAnak,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Berikutnya', style: AppTypography.kegiatanAnak),
                            const SizedBox(height: AppSpacing.grid12),
                            if (nextActivity != null) ...[
                              Row(
                                children: [
                                  Container(
                                    width: AppSpacing.iconTileLarge,
                                    height: AppSpacing.iconTileLarge,
                                    decoration: BoxDecoration(
                                      color: palette.anakAksenLembut,
                                      borderRadius: AppRadius.ubinIkonKartuAnak,
                                    ),
                                    child: Icon(
                                      _iconForActivity(nextActivity.icon),
                                      size: AppSpacing.iconSize24,
                                      color: palette.anakAksenKuat,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.grid12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(nextActivity.shortTitle, style: AppTypography.isiAnak),
                                        Text(
                                          formatTimeLite(nextActivity.start),
                                          style: AppTypography.sekunderAnak,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Text(
                                'Tidak ada kegiatan lagi hari ini.',
                                style: AppTypography.isiAnak.copyWith(
                                  color: AppColors.teksSekunder,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ChildButton(
                label: 'Kembali ke jadwal',
                onPressed: () => context.go('/anak'),
              ),
            ],
          ),
        ),
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

  IconData _iconForActivity(ActivityIcon icon) {
    return const IconData(0xe800, fontFamily: 'MaterialIcons');
  }
}
