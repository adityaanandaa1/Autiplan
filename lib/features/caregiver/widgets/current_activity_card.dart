import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../core/widgets/card_surface.dart';
import '../../../data/models/models.dart';

class CurrentActivityCard extends StatelessWidget {
  const CurrentActivityCard({
    super.key,
    required this.child,
    this.currentActivity,
    this.nextActivity,
    required this.completedCount,
    required this.totalCount,
    required this.onTapSchedule,
  });

  final Child child;
  final Activity? currentActivity;
  final Activity? nextActivity;
  final int completedCount;
  final int totalCount;
  final VoidCallback onTapSchedule;

  /// Kunci ubin ikon (untuk tes ukuran).
  static const Key iconTileKey = ValueKey('current-activity-icon-tile');

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                key: iconTileKey,
                width: AppSpacing.iconTile44,
                height: AppSpacing.iconTile44,
                decoration: BoxDecoration(
                  color: currentActivity != null
                      ? AppColors.utamaLembut
                      : AppColors.anakLembut,
                  borderRadius: AppRadius.ubinIkon44,
                ),
                child: Icon(
                  currentActivity != null
                      ? lucideIconFor(currentActivity!.icon)
                      : (nextActivity != null
                            ? lucideIconFor(nextActivity!.icon)
                            : LucideIcons.sun),
                  size: AppSpacing.iconSize22,
                  color: currentActivity != null
                      ? AppColors.utama
                      : AppColors.teks,
                ),
              ),
              const SizedBox(width: AppSpacing.grid12),
              Expanded(child: _buildContent()),
            ],
          ),
          if (totalCount > 0) _buildProgress(),
          const SizedBox(height: AppSpacing.grid4),
          _buildScheduleLink(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (currentActivity != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SEKARANG · ${child.name.toUpperCase()}',
            style: AppTypography.mikro.copyWith(color: AppColors.utama),
          ),
          const SizedBox(height: AppSpacing.grid2),
          Text(currentActivity!.title, style: AppTypography.judulKartu),
          const SizedBox(height: AppSpacing.grid2),
          Text(
            _formatTimeRange(currentActivity!.start, currentActivity!.end),
            style: AppTypography.meta,
          ),
        ],
      );
    }

    if (nextActivity != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BERIKUTNYA · ${child.name.toUpperCase()}',
            style: AppTypography.mikro.copyWith(color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.grid2),
          Text(nextActivity!.title, style: AppTypography.judulKartu),
          const SizedBox(height: AppSpacing.grid2),
          Text(
            _formatTimeRange(nextActivity!.start, nextActivity!.end),
            style: AppTypography.meta,
          ),
        ],
      );
    }

    return Text(
      'Semua kegiatan hari ini sudah lewat.',
      style: AppTypography.isi,
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.grid16),
        Text(
          '$completedCount dari $totalCount kegiatan hari ini selesai',
          style: AppTypography.meta,
        ),
        const SizedBox(height: AppSpacing.grid8),
        ClipRRect(
          borderRadius: AppRadius.barProgres,
          child: LinearProgressIndicator(
            value: completedCount / totalCount,
            minHeight: AppSpacing.progressBarHeight,
            backgroundColor: AppColors.garis,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sukses),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleLink() {
    return InkWell(
      onTap: onTapSchedule,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Buka jadwal', style: AppTypography.tautanAksi),
            const SizedBox(width: AppSpacing.grid4),
            const Icon(
              LucideIcons.chevronRight,
              size: AppSpacing.iconSize16,
              color: AppColors.utama,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRange(TimeOfDayLite start, TimeOfDayLite? end) {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}.${start.minute.toString().padLeft(2, '0')}';
    if (end == null) return startStr;
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}.${end.minute.toString().padLeft(2, '0')}';
    return '$startStr – $endStr';
  }
}
