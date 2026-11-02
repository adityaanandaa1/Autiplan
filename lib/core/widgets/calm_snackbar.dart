import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

class CalmSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final hasAction = actionLabel != null;

    final snackBar = SnackBar(
      padding: const EdgeInsets.only(left: AppSpacing.grid16),
      content: SizedBox(
        height: AppSpacing.snackbarHeight,
        child: Row(
          children: [
            const Icon(
              LucideIcons.check,
              size: AppSpacing.iconSize20,
              color: AppColors.teksDiAtasUtama,
            ),
            const SizedBox(width: AppSpacing.grid12),
            Expanded(child: Text(message, style: AppTypography.pesanSnackbar)),
            if (hasAction)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onActionPressed?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.anakLembut,
                  minimumSize: const Size(
                    AppSpacing.minTouchTarget,
                    AppSpacing.snackbarHeight,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.grid16,
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: AppTypography.tautanAksi.copyWith(
                    color: AppColors.anakLembut,
                  ),
                ),
              ),
          ],
        ),
      ),
      backgroundColor: AppColors.teks,
      behavior: SnackBarBehavior.floating,
      duration: hasAction
          ? AppDurations.snackbarDenganAksi
          : AppDurations.snackbar,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.snackbar),
    );

    messenger.showSnackBar(snackBar);
  }
}
