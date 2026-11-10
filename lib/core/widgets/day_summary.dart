import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/theme.dart';

class DaySummary extends StatelessWidget {
  const DaySummary({
    super.key,
    required this.date,
    required this.completedCount,
    required this.totalCount,
  });

  final DateTime date;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date);
    final hasActivities = totalCount > 0;
    final progress = hasActivities ? completedCount / totalCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(dateText, style: AppTypography.judulBaris)),
            const SizedBox(width: AppSpacing.grid8),
            Text(
              hasActivities
                  ? '$completedCount/$totalCount selesai'
                  : 'Belum ada kegiatan',
              style: AppTypography.meta,
            ),
          ],
        ),
        if (hasActivities) ...[
          const SizedBox(height: AppSpacing.grid8),
          ClipRRect(
            borderRadius: AppRadius.barProgres,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: AppSpacing.progressBarHeight,
              backgroundColor: AppColors.garis,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sukses),
            ),
          ),
        ],
      ],
    );
  }
}
