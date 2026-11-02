import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/activity_icon.dart';
import '../theme/theme.dart';
import 'activity_icon_data.dart';

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
    final isNow = status == ChildActivityStatus.now;
    final isChanged = status == ChildActivityStatus.changed;
    final isCompleted = status == ChildActivityStatus.completed;

    final label = isNow
        ? 'SEKARANG'
        : isChanged
        ? 'BARU BERUBAH'
        : null;

    Widget iconTile = Container(
      width: AppSpacing.iconTileLarge,
      height: AppSpacing.iconTileLarge,
      decoration: BoxDecoration(
        color: palette.anakAksenLembut,
        borderRadius: AppRadius.ubinIkonKartuAnak,
      ),
      child: Icon(
        lucideIconFor(icon),
        size: AppSpacing.iconSize26,
        color: palette.anakAksenKuat,
      ),
    );
    if (isCompleted) {
      iconTile = Opacity(opacity: AppColors.alphaSelesai, child: iconTile);
    }

    return Material(
      color: AppColors.permukaan,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.kartuAnak,
        side: isNow
            ? BorderSide(
                color: palette.anakAksen,
                width: AppSpacing.strokeAccent,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.kartuAnak,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.grid20,
            AppSpacing.grid14,
            AppSpacing.grid16,
            AppSpacing.grid14,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null) ...[
                      Text(
                        label,
                        style: AppTypography.labelAnak.copyWith(
                          color: palette.anakAksenKuat,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.grid4),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCompleted) ...[
                          const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.grid4),
                            child: Icon(
                              LucideIcons.circleCheckBig,
                              size: AppSpacing.iconSize22,
                              color: AppColors.sukses,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.grid8),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.kegiatanAnak.copyWith(
                              color: isCompleted
                                  ? AppColors.teksSekunder
                                  : AppColors.teks,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.grid12),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  iconTile,
                  const SizedBox(height: AppSpacing.grid4),
                  Text(time, style: AppTypography.jamAnak),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
