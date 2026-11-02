import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../data/models/models.dart';

Future<bool?> showDeleteActivityDialog(
  BuildContext context, {
  required Activity activity,
  required String childName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      contentPadding: const EdgeInsets.all(AppSpacing.grid20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.iconTileLarge,
            height: AppSpacing.iconTileLarge,
            decoration: const BoxDecoration(
              color: AppColors.bahayaLembut,
              borderRadius: AppRadius.ubinIkon10,
            ),
            child: const Icon(
              LucideIcons.trash2,
              size: AppSpacing.iconSize24,
              color: AppColors.bahaya,
            ),
          ),
          const SizedBox(height: AppSpacing.grid16),
          const Text('Hapus jadwal ini?', style: AppTypography.judulSheet),
          const SizedBox(height: AppSpacing.grid8),
          Text(
            '${activity.title} (${activity.start.toString()} – ${activity.end != null ? activity.end!.toString() : "Pagi"}) akan hilang dari jadwal $childName. $childName akan menerima pemberitahuan dengan tampilan yang tenang.',
            textAlign: TextAlign.center,
            style: AppTypography.kecil.copyWith(color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.grid24),
          DangerButton(
            label: 'Hapus jadwal',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Batal',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );
}
