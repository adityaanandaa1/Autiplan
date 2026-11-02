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

/// A-04/A-05/A-10: Detail aktivitas anak (HANDOFF §12 A-04, A-05, A-10).
class ChildActivityScreen extends ConsumerStatefulWidget {
  const ChildActivityScreen({super.key, required this.activityId});
  final String activityId;

  @override
  ConsumerState<ChildActivityScreen> createState() =>
      _ChildActivityScreenState();
}

class _ChildActivityScreenState extends ConsumerState<ChildActivityScreen> {
  late List<bool> _stepsChecked;
  bool _showFullSteps = false;

  @override
  void initState() {
    super.initState();
    _stepsChecked = [];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;
    final palette = Theme.of(context).extension<ChildPalette>()!;

    final activity = state.activities.firstWhere(
      (a) => a.id == widget.activityId,
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

    if (activity.id.isEmpty) {
      context.go('/anak');
      return const SizedBox.shrink();
    }

    final completion = state.completions.firstWhere(
      (c) =>
          c.activityId == activity.id &&
          c.date.year == activity.date.year &&
          c.date.month == activity.date.month &&
          c.date.day == activity.date.day,
      orElse: () => Completion(
        activityId: '',
        date: DateTime(1970),
        completedAt: DateTime(1970),
        onTime: false,
        stepsChecked: const [],
      ),
    );

    final isCompleted = completion.activityId.isNotEmpty;

    if (_stepsChecked.isEmpty && !isCompleted) {
      _stepsChecked = List.filled(activity.steps.length, false);
    }
    if (isCompleted && _stepsChecked.length != completion.stepsChecked.length) {
      _stepsChecked = List.from(completion.stepsChecked);
    }

    final checkedCount = _stepsChecked.where((c) => c).length;
    final canCompleteNow = canComplete(activity, checkedCount);

    return Scaffold(
      backgroundColor: palette.anakLatar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
              child: ChildBackHeader(
                title: activity.shortTitle,
                onBack: () => context.go('/anak'),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingChild,
                  0,
                  AppSpacing.screenPaddingChild,
                  AppSpacing.grid20,
                ),
                child: _buildContent(
                  activity,
                  isCompleted,
                  palette,
                ),
              ),
            ),
            if (!isCompleted)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
                child: ChildButton(
                  label: 'Aku sudah selesai',
                  enabled: canCompleteNow,
                  onPressed: () => _complete(activity, now),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    Activity activity,
    bool isCompleted,
    ChildPalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(activity.title, style: AppTypography.judulAnak),
        const SizedBox(height: AppSpacing.grid8),
        Text(
          '${formatTimeLite(activity.start)}${activity.end == null ? '' : ' – ${formatTimeLite(activity.end!)}'}',
          style: AppTypography.sekunderAnak,
        ),
        const SizedBox(height: AppSpacing.grid24),
        if (isCompleted)
          _buildCompletedMessage()
        else if (activity.independentMode && !_showFullSteps)
          _buildIndependentCard(activity, palette)
        else if (activity.steps.isEmpty)
          _buildNoSteps()
        else
          _buildSteps(activity),
      ],
    );
  }

  Widget _buildCompletedMessage() => Text(
        'Kegiatan ini sudah selesai.',
        style: AppTypography.isiAnak.copyWith(color: AppColors.teksSekunder),
      );

  Widget _buildNoSteps() => Text(
        'Tidak ada langkah khusus.',
        style: AppTypography.isiAnak.copyWith(color: AppColors.teksSekunder),
      );

  Widget _buildIndependentCard(Activity activity, ChildPalette palette) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid16),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.kartuAnak,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: AppSpacing.iconSize24,
                color: palette.anakAksenKuat,
              ),
              const SizedBox(width: AppSpacing.grid12),
              Expanded(
                child: Text(
                  'Kamu sudah hafal langkahnya. ${activity.shortTitle} seperti biasa, ya.',
                  style: AppTypography.isiAnak,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid12),
          InkWell(
            onTap: () => setState(() => _showFullSteps = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid8),
              child: Text(
                'Lihat langkah lengkap',
                style: AppTypography.tombolAnakTeks.copyWith(
                  color: palette.anakAksenKuat,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(Activity activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Langkah-langkah', style: AppTypography.kegiatanAnak),
        const SizedBox(height: AppSpacing.grid12),
        ...List.generate(activity.steps.length, (i) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: i == activity.steps.length - 1 ? 0 : AppSpacing.sectionGapChild,
            ),
            child: _buildStepRow(i, activity.steps[i]),
          );
        }),
      ],
    );
  }

  Widget _buildStepRow(int index, String step) {
    return Material(
      color: AppColors.permukaan,
      borderRadius: AppRadius.barisLangkahAnak,
      child: InkWell(
        onTap: () => setState(() => _stepsChecked[index] = !_stepsChecked[index]),
        borderRadius: AppRadius.barisLangkahAnak,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.grid16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _stepsChecked[index] ? AppColors.sukses : AppColors.garis,
                    width: 2,
                  ),
                  color: _stepsChecked[index] ? AppColors.sukses : AppColors.transparan,
                ),
                child: _stepsChecked[index]
                    ? const Icon(LucideIcons.check, size: 16, color: AppColors.teksDiAtasUtama)
                    : null,
              ),
              const SizedBox(width: AppSpacing.grid12),
              Expanded(child: Text(step, style: AppTypography.isiAnak)),
            ],
          ),
        ),
      ),
    );
  }

  void _complete(Activity activity, DateTime now) {
    final state = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final result = completeActivity(
      state: state,
      activity: activity,
      stepsChecked: _stepsChecked,
      now: now,
      completionId: const Uuid().v4(),
      notificationId: const Uuid().v4(),
    );
    notifier.updateState(result.state);
    context.go('/anak/berhasil/${activity.id}');
  }
}
