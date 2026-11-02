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
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.utama.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontParent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          backgroundColor: Colors.white,
          foregroundColor: AppColors.teks,
          side: const BorderSide(color: AppColors.garis),
          disabledForegroundColor: AppColors.teks.withValues(alpha: 0.4),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontParent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.bahaya.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontParent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          backgroundColor: Colors.white,
          foregroundColor: AppColors.bahaya,
          side: const BorderSide(color: AppColors.bahaya),
          disabledForegroundColor: AppColors.bahaya.withValues(alpha: 0.4),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.tombolOrangTua,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontParent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
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
        disabledForegroundColor: AppColors.utama.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.minTouchTarget),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTypography.fontParent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
