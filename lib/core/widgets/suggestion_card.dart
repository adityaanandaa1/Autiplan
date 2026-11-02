import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

class SuggestionCard extends StatelessWidget {
  const SuggestionCard({
    super.key,
    required this.content,
    required this.actionLabel,
    this.onTap,
  });

  final String content;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.kartuSaran,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.saranLembut,
          borderRadius: AppRadius.kartuSaran,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grid16,
          vertical: AppSpacing.grid14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.lightbulb,
                  size: AppSpacing.iconSize18,
                  color: AppColors.saranTeks,
                ),
                const SizedBox(width: AppSpacing.grid6),
                Text(
                  'SARAN',
                  style: AppTypography.mikro.copyWith(
                    color: AppColors.saranTeks,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.grid8),
            Text(content, style: AppTypography.kecil),
            const SizedBox(height: AppSpacing.grid8),
            Row(
              children: [
                Text(actionLabel, style: AppTypography.tautanAksi),
                const SizedBox(width: AppSpacing.grid4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: AppSpacing.iconSize16,
                  color: AppColors.utama,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
