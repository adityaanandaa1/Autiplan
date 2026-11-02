import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

enum CaregiverTab { home, schedule, account }

class CaregiverNavBar extends StatelessWidget {
  const CaregiverNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final CaregiverTab currentTab;
  final ValueChanged<CaregiverTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.navBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.permukaan,
        border: Border(
          top: BorderSide(color: AppColors.garis, width: AppSpacing.strokeThin),
        ),
      ),
      child: Row(
        children: [
          _buildTab(
            context,
            tab: CaregiverTab.home,
            icon: LucideIcons.house,
            label: 'Beranda',
          ),
          _buildTab(
            context,
            tab: CaregiverTab.schedule,
            icon: LucideIcons.calendarDays,
            label: 'Jadwal',
          ),
          _buildTab(
            context,
            tab: CaregiverTab.account,
            icon: LucideIcons.user,
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required CaregiverTab tab,
    required IconData icon,
    required String label,
  }) {
    final isActive = currentTab == tab;
    final color = isActive ? AppColors.utama : AppColors.teksSekunder;
    final fontWeight = isActive ? FontWeight.w600 : FontWeight.w500;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        excludeSemantics: true,
        onTap: () => onTabSelected(tab),
        child: InkWell(
          onTap: () => onTabSelected(tab),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppSpacing.iconSize24, color: color),
              const SizedBox(height: AppSpacing.grid4),
              Text(
                label,
                style: AppTypography.mikro.copyWith(
                  fontWeight: fontWeight,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
