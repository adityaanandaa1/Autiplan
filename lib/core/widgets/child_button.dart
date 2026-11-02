import 'package:flutter/material.dart';
import '../theme/theme.dart';

enum ChildButtonVariant { primary, outline, text }

/// Tombol anak: tinggi 56, bulat penuh, tanpa merah.
class ChildButton extends StatelessWidget {
  const ChildButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ChildButtonVariant.primary,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChildButtonVariant variant;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ChildPalette>()!;
    final callback = enabled ? onPressed : null;
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.tombolAnak);
    final disabledFg = palette.anakAksenKuat.withValues(
      alpha: AppColors.alphaNonaktif,
    );

    final Widget button;
    switch (variant) {
      case ChildButtonVariant.primary:
        button = ElevatedButton(
          onPressed: callback,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.anakAksenKuat,
            foregroundColor: AppColors.teksDiAtasUtama,
            disabledBackgroundColor: disabledFg,
            disabledForegroundColor: AppColors.teksDiAtasUtama,
            shape: shape,
            elevation: 0,
          ),
          child: Text(label, style: AppTypography.tombolAnak),
        );
      case ChildButtonVariant.outline:
        button = OutlinedButton(
          onPressed: callback,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.permukaan,
            foregroundColor: palette.anakAksenKuat,
            disabledForegroundColor: disabledFg,
            side: BorderSide(
              color: enabled
                  ? palette.anakAksen
                  : palette.anakAksen.withValues(
                      alpha: AppColors.alphaNonaktif,
                    ),
              width: AppSpacing.strokeAccent,
            ),
            shape: shape,
          ),
          child: Text(label, style: AppTypography.tombolAnak),
        );
      case ChildButtonVariant.text:
        button = TextButton(
          onPressed: callback,
          style: TextButton.styleFrom(
            foregroundColor: palette.anakAksenKuat,
            disabledForegroundColor: disabledFg,
            shape: shape,
          ),
          child: Text(label, style: AppTypography.tombolAnakTeks),
        );
    }

    return SizedBox(
      height: AppSpacing.buttonHeightChild,
      width: double.infinity,
      child: button,
    );
  }
}
