import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/caregiver_nav_bar.dart';

class CaregiverShell extends StatelessWidget {
  const CaregiverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(CaregiverTab tab) {
    final index = tab.index;
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
      bottomNavigationBar: CaregiverNavBar(
        currentTab: CaregiverTab.values[navigationShell.currentIndex],
        onTabSelected: _onTap,
      ),
    );
  }
}
