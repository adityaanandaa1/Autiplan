import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/activity_icon.dart';
import '../theme/theme.dart';

enum ChildActivityStatus { normal, now, completed, changed }

class ChildActivityCard extends StatelessWidget {
  const ChildActivityCard({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    required this.status,
    this.onTap,
  });

  final ActivityIcon icon;
  final String title;
  final String time;
  final ChildActivityStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ChildPalette>()!;
    final isChanged = status == ChildActivityStatus.changed;
    final isNow = status == ChildActivityStatus.now;
    final isCompleted = status == ChildActivityStatus.completed;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.kartuAnak,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.kartuAnak,
          border: isChanged
              ? Border.all(color: palette.anakAksenKuat, width: 2)
              : null,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: palette.anakAksenLembut,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getIconData(icon),
                size: 40,
                color: palette.anakAksen,
              ),
            ),
            const SizedBox(height: 12),
            if (isChanged) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.anakAksenKuat,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BARU BERUBAH',
                  style: TextStyle(
                    fontFamily: AppTypography.fontChild,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isNow) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: palette.anakAksen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SEKARANG',
                  style: TextStyle(
                    fontFamily: AppTypography.fontChild,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (isCompleted) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.suksesLembut,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SELESAI',
                  style: TextStyle(
                    fontFamily: AppTypography.fontChild,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sukses,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: AppTypography.kegiatanAnak,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: AppTypography.jamAnak,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
