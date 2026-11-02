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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.saranLembut,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.lightbulb,
                  size: 18,
                  color: AppColors.saranTeks,
                ),
                const SizedBox(width: 6),
                Text(
                  'SARAN',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontParent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.saranTeks,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: AppTypography.kecil,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontParent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.utama,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
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
