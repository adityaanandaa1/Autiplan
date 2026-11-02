import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/theme.dart';

/// Demo-only shortcut back to the role picker (HANDOFF 10.3, see DECISIONS).
///
/// Shown on both home screens so the roles can be swapped without hunting.
class RoleSwitchButton extends StatelessWidget {
  const RoleSwitchButton({super.key, this.isChild = false});

  final bool isChild;

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<ChildPalette>() ?? ChildPalette.lautTenang;
    final color = isChild ? palette.anakAksenKuat : AppColors.utama;
    final style = isChild ? AppTypography.isiAnak : AppTypography.judulBaris;

    return TextButton.icon(
      onPressed: () => context.go('/'),
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
      ),
      icon: const Icon(LucideIcons.arrowLeftRight, size: AppSpacing.iconSize18),
      label: Text('Ganti peran', style: style.copyWith(color: color)),
    );
  }
}
