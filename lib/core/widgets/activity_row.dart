import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/activity_icon.dart';
import '../theme/theme.dart';

enum ActivityRowStatus { normal, completed, now, changed }

class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.startTime,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.status,
    this.onTap,
  });

  final String startTime;
  final ActivityIcon icon;
  final String title;
  final String? subtitle;
  final ActivityRowStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == ActivityRowStatus.completed;
    final isNow = status == ActivityRowStatus.now;
    final isChanged = status == ActivityRowStatus.changed;

    final timeColor = isNow ? AppColors.utama : AppColors.teks;
    final timeWeight = isNow ? FontWeight.w600 : FontWeight.w400;
    final tileBgColor = isNow
        ? AppColors.utamaLembut
        : AppColors.anakLembut.withValues(
            alpha: isCompleted ? 0.6 : 1.0,
          );
    final iconColor = isNow ? AppColors.utama : AppColors.teks;
    final titleColor = isCompleted ? AppColors.teksSekunder : AppColors.teks;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.garis, width: 1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                startTime,
                style: TextStyle(
                  fontFamily: AppTypography.fontParent,
                  fontSize: 14,
                  fontWeight: timeWeight,
                  color: timeColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tileBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconData(icon),
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusWidget(isNow, isCompleted, isChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusWidget(bool isNow, bool isCompleted, bool isChanged) {
    if (isNow) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.utama,
          borderRadius: AppRadius.pil,
        ),
        child: const Text(
          'Sekarang',
          style: TextStyle(
            fontFamily: AppTypography.fontParent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    if (isCompleted) {
      return const Icon(
        LucideIcons.circleCheckBig,
        size: 22,
        color: AppColors.sukses,
      );
    }

    if (isChanged) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.utamaLembut,
          borderRadius: AppRadius.pil,
        ),
        child: const Text(
          'Diubah',
          style: TextStyle(
            fontFamily: AppTypography.fontParent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.utama,
          ),
        ),
      );
    }

    return const Icon(
      LucideIcons.chevronRight,
      size: 20,
      color: AppColors.teksSekunder,
    );
  }

  IconData _getIconData(ActivityIcon icon) {
    switch (icon) {
      case ActivityIcon.sekolah:
        return LucideIcons.school;
      case ActivityIcon.les:
        return LucideIcons.bookOpen;
      case ActivityIcon.ngaji:
        return LucideIcons.book;
      case ActivityIcon.mandi:
        return LucideIcons.bath;
      case ActivityIcon.makan:
        return LucideIcons.utensils;
      case ActivityIcon.tidur:
        return LucideIcons.moon;
      case ActivityIcon.main:
        return LucideIcons.gamepad2;
      case ActivityIcon.sepeda:
        return LucideIcons.bike;
      case ActivityIcon.nonton:
        return LucideIcons.tv;
    }
  }
}
