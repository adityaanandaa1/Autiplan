import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';

class CaregiverShell extends StatelessWidget {
  const CaregiverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: navigationShell,
      bottomNavigationBar: Container(
        height: AppSpacing.navBarHeight,
        decoration: const BoxDecoration(
          color: AppColors.permukaan,
          border: Border(top: BorderSide(color: AppColors.garis, width: 1)),
        ),
        child: Row(
          children: [
            _NavBarItem(
              icon: LucideIcons.house,
              label: 'Beranda',
              isSelected: navigationShell.currentIndex == 0,
              onTap: () => _onTap(0),
            ),
            _NavBarItem(
              icon: LucideIcons.calendarDays,
              label: 'Jadwal',
              isSelected: navigationShell.currentIndex == 1,
              onTap: () => _onTap(1),
            ),
            _NavBarItem(
              icon: LucideIcons.user,
              label: 'Akun',
              isSelected: navigationShell.currentIndex == 2,
              onTap: () => _onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.utama : AppColors.teksSekunder;
    final fontWeight = isSelected ? FontWeight.w600 : FontWeight.w500;

    return Expanded(
      child: InkWell(
        onTap: onTap,
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
    );
  }
}
