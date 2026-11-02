import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Tombol darurat anak: lingkaran putih, tepi 2 px aksen, bayangan halus.
/// Penempatan (kanan-bawah, 16 dari tepi) diatur oleh layar pemakai;
/// konten layar memberi ruang bawah `AppSpacing.emergencyClearance`.
class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ChildPalette>()!;

    return Semantics(
      button: true,
      label: 'Butuh bantuan',
      excludeSemantics: true,
      child: SizedBox(
        width: AppSpacing.emergencyButtonSize,
        height: AppSpacing.emergencyButtonSize,
        child: Material(
          color: AppColors.permukaan,
          elevation: AppSpacing.emergencyElevation,
          shadowColor: palette.anakAksenKuat.withValues(
            alpha: AppColors.alphaBayangan,
          ),
          shape: CircleBorder(
            side: BorderSide(
              color: palette.anakAksen,
              width: AppSpacing.strokeAccent,
            ),
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Icon(
              LucideIcons.phone,
              size: AppSpacing.iconSize24,
              color: palette.anakAksenKuat,
            ),
          ),
        ),
      ),
    );
  }
}
