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
    this.trailing,
  });

  /// Kunci titik notifikasi di lonceng (untuk tes).
  static const Key bellBadgeKey = ValueKey('caregiver-bell-badge');

  final String title;
  final CaregiverHeaderVariant variant;
  final VoidCallback? onBack;
  final bool showMonthPicker;
  final VoidCallback? onMonthPickerTap;
  final bool showBell;
  final VoidCallback? onBellTap;
  final bool bellHasBadge;

  /// Widget tambahan di kanan header (mis. tombol bulan di layar Jadwal).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.headerHeight,
      // Tinggi 64 = 8 + 48 (target sentuh minimal) + 8.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.grid16,
        AppSpacing.grid8,
        AppSpacing.grid12,
        AppSpacing.grid8,
      ),
      child: Row(
        children: [
          if (variant == CaregiverHeaderVariant.back) ...[
            IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                size: AppSpacing.iconSize24,
              ),
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              color: AppColors.teks,
            ),
            const SizedBox(width: AppSpacing.grid4),
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
            const SizedBox(width: AppSpacing.grid8),
            TextButton.icon(
              onPressed: onMonthPickerTap,
              icon: const Icon(
                LucideIcons.chevronDown,
                size: AppSpacing.iconSize18,
              ),
              label: Text(
                title,
                style: AppTypography.isi.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.utama,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.grid12,
                  vertical: AppSpacing.grid8,
                ),
                minimumSize: const Size(
                  AppSpacing.minTouchTarget,
                  AppSpacing.minTouchTarget,
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.grid4),
            trailing!,
          ],
          if (showBell) ...[
            const SizedBox(width: AppSpacing.grid4),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    LucideIcons.bell,
                    size: AppSpacing.iconSize24,
                  ),
                  onPressed: onBellTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.minTouchTarget,
                    minHeight: AppSpacing.minTouchTarget,
                  ),
                  color: AppColors.teks,
                ),
                if (bellHasBadge)
                  Positioned(
                    right: AppSpacing.badgeOffset,
                    top: AppSpacing.badgeOffset,
                    child: Container(
                      key: bellBadgeKey,
                      width: AppSpacing.badgeDot,
                      height: AppSpacing.badgeDot,
                      decoration: const BoxDecoration(
                        color: AppColors.utama,
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
