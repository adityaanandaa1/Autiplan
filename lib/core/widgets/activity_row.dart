import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/activity_icon.dart';
import '../theme/theme.dart';
import 'activity_icon_data.dart';

enum ActivityRowStatus { normal, completed, now, changed }

class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.startTime,
    required this.icon,
    required this.title,
    this.subtitle,
    this.replacedTitle,
    required this.status,
    this.onTap,
  });

  final String startTime;
  final ActivityIcon icon;
  final String title;
  final String? subtitle;

  /// Judul kegiatan lama. Status "Diubah" memakainya untuk keterangan
  /// "Pengganti {judul lama}" bila [subtitle] tidak diisi.
  final String? replacedTitle;
  final ActivityRowStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == ActivityRowStatus.completed;
    final isNow = status == ActivityRowStatus.now;
    final isChanged = status == ActivityRowStatus.changed;
    final caption =
        subtitle ??
        (isChanged && replacedTitle != null
            ? 'Pengganti $replacedTitle'
            : null);

    final timeColor = isNow ? AppColors.utama : AppColors.teks;
    final timeWeight = isNow ? FontWeight.w600 : FontWeight.w400;
    final tileBgColor = isNow
        ? AppColors.utamaLembut
        : AppColors.anakLembut.withValues(
            alpha: isCompleted ? AppColors.alphaSelesai : AppColors.alphaPenuh,
          );
    final iconColor = isNow ? AppColors.utama : AppColors.teks;
    final titleColor = isCompleted ? AppColors.teksSekunder : AppColors.teks;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.garis,
              width: AppSpacing.strokeThin,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppSpacing.activityTimeWidth,
              child: Text(
                startTime,
                style: AppTypography.jamBaris.copyWith(
                  fontWeight: timeWeight,
                  color: timeColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.grid12),
            Container(
              width: AppSpacing.iconTile40,
              height: AppSpacing.iconTile40,
              decoration: BoxDecoration(
                color: tileBgColor,
                borderRadius: AppRadius.ubinIkon10,
              ),
              child: Icon(
                lucideIconFor(icon),
                size: AppSpacing.iconSize22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.grid12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.judulBaris.copyWith(color: titleColor),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: AppSpacing.grid2),
                    Text(
                      caption,
                      style: AppTypography.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.grid12),
            _buildStatusWidget(isNow, isCompleted, isChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget(bool isNow, bool isCompleted, bool isChanged) {
    if (isNow) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grid10,
          vertical: AppSpacing.grid4,
        ),
        decoration: BoxDecoration(
          color: AppColors.utama,
          borderRadius: AppRadius.pil,
        ),
        child: Text(
          'Sekarang',
          style: AppTypography.mikro.copyWith(color: AppColors.teksDiAtasUtama),
        ),
      );
    }

    if (isCompleted) {
      return const Icon(
        LucideIcons.circleCheckBig,
        size: AppSpacing.iconSize22,
        color: AppColors.sukses,
      );
    }

    if (isChanged) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grid10,
          vertical: AppSpacing.grid4,
        ),
        decoration: BoxDecoration(
          color: AppColors.utamaLembut,
          borderRadius: AppRadius.pil,
        ),
        child: Text(
          'Diubah',
          style: AppTypography.mikro.copyWith(color: AppColors.utama),
        ),
      );
    }

    return const Icon(
      LucideIcons.chevronRight,
      size: AppSpacing.iconSize20,
      color: AppColors.teksSekunder,
    );
  }
}
