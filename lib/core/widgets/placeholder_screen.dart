import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/theme.dart';
import 'role_switch_button.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.fallbackRoute = '/',
    this.isChild = false,
    this.showRoleSwitch = false,
  });

  final String title;
  final bool showBackButton;
  final String fallbackRoute;
  final bool isChild;
  final bool showRoleSwitch;

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<ChildPalette>() ?? ChildPalette.lautTenang;
    final bgColor = isChild ? palette.anakLatar : AppColors.latar;
    final textColor = isChild ? palette.anakAksenKuat : AppColors.teks;
    final fontStyle = isChild
        ? AppTypography.judulAnak.copyWith(color: textColor)
        : AppTypography.judulHeader.copyWith(color: textColor);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.transparan,
        elevation: 0,
        leading: showBackButton
            ? IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: textColor),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(fallbackRoute);
                  }
                },
              )
            : null,
        title: Text(title, style: fontStyle),
        actions: showRoleSwitch
            ? [
                RoleSwitchButton(isChild: isChild),
                const SizedBox(width: AppSpacing.grid8),
              ]
            : null,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: fontStyle),
            const SizedBox(height: AppSpacing.grid8),
            Text(
              'Layar ini akan diimplementasikan pada tahap berikutnya.',
              textAlign: TextAlign.center,
              style: isChild ? AppTypography.sekunderAnak : AppTypography.meta,
            ),
            const SizedBox(height: AppSpacing.grid24),
            TextButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(LucideIcons.house, size: AppSpacing.iconSize18),
              label: const Text('Kembali ke Pilih Peran'),
            ),
          ],
        ),
      ),
    );
  }
}
