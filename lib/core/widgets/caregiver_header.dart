import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

enum CaregiverHeaderVariant { main, back }

class CaregiverHeader extends StatelessWidget {
  const CaregiverHeader({
    super.key,
    required this.title,
    this.variant = CaregiverHeaderVariant.main,
    this.onBack,
    this.showMonthPicker = false,
    this.onMonthPickerTap,
    this.showBell = false,
    this.onBellTap,
    this.bellHasBadge = false,
  });

  final String title;
  final CaregiverHeaderVariant variant;
  final VoidCallback? onBack;
  final bool showMonthPicker;
  final VoidCallback? onMonthPickerTap;
  final bool showBell;
  final VoidCallback? onBellTap;
  final bool bellHasBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(16, 20, 12, 12),
      child: Row(
        children: [
          if (variant == CaregiverHeaderVariant.back) ...[
            IconButton(
              icon: const Icon(LucideIcons.arrowLeft, size: 24),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              color: AppColors.teks,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.judulHeader,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showMonthPicker) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onMonthPickerTap,
              icon: const Icon(LucideIcons.chevronDown, size: 18),
              label: Text(
                title,
                style: AppTypography.isi.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.utama,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(48, 48),
              ),
            ),
          ],
          if (showBell) ...[
            const SizedBox(width: 4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.bell, size: 24),
                  onPressed: onBellTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  color: AppColors.teks,
                ),
                if (bellHasBadge)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.bahaya,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
