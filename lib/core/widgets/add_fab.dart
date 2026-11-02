import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

class AddFab extends StatelessWidget {
  const AddFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.utama,
      elevation: AppSpacing.fabElevation,
      child: const Icon(
        LucideIcons.plus,
        color: AppColors.teksDiAtasUtama,
        size: AppSpacing.iconSize24,
      ),
    );
  }
}
