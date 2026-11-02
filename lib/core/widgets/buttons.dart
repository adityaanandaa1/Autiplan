import 'package:flutter/material.dart';
import '../theme/theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeightParent,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.utama,
          foregroundColor: AppColors.teksDiAtasUtama,
          disabledBackgroundColor: AppColors.utama.withValues(
            alpha: AppColors.alphaNonaktif,
          ),
          disabledForegroundColor: AppColors.teksDiAtasUtama.withValues(
            alpha: AppColors.alphaNonaktif,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
          elevation: 0,
        ),
        child: Text(label, style: AppTypography.tombol),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeightParent,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.permukaan,
          foregroundColor: AppColors.teks,
          side: const BorderSide(color: AppColors.garis),
          disabledForegroundColor: AppColors.teks.withValues(
            alpha: AppColors.alphaNonaktif,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
        ),
        child: Text(label, style: AppTypography.tombol),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeightParent,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bahaya,
          foregroundColor: AppColors.teksDiAtasUtama,
          disabledBackgroundColor: AppColors.bahaya.withValues(
            alpha: AppColors.alphaNonaktif,
          ),
          disabledForegroundColor: AppColors.teksDiAtasUtama.withValues(
            alpha: AppColors.alphaNonaktif,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
          elevation: 0,
        ),
        child: Text(label, style: AppTypography.tombol),
      ),
    );
  }
}

class DangerOutlineButton extends StatelessWidget {
  const DangerOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeightParent,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.permukaan,
          foregroundColor: AppColors.bahaya,
          side: const BorderSide(color: AppColors.bahaya),
          disabledForegroundColor: AppColors.bahaya.withValues(
            alpha: AppColors.alphaNonaktif,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
        ),
        child: Text(label, style: AppTypography.tombol),
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.utama,
        disabledForegroundColor: AppColors.utama.withValues(
          alpha: AppColors.alphaNonaktif,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grid16,
          vertical: AppSpacing.grid12,
        ),
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
      ),
      child: Text(label, style: AppTypography.tombol),
    );
  }
}
