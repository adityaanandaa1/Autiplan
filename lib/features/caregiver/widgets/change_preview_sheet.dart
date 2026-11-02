import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../data/models/models.dart';
import '../forms/sheet_scaffold.dart';

class ChangePreviewSheet extends StatelessWidget {
  const ChangePreviewSheet({
    super.key,
    required this.childName,
    required this.before,
    required this.after,
    required this.message,
  });

  final String childName;
  final ActivitySnapshot before;
  final ActivitySnapshot after;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Tampilan di HP $childName',
      subtitle: 'Format tenang Dulu → Sekarang',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTile(
                  label: 'DULU',
                  title: before.shortTitle,
                  icon: before.icon,
                  time: before.start.toString(),
                  color: AppColors.teksSekunder,
                ),
              ),
              const SizedBox(width: AppSpacing.grid12),
              Expanded(
                child: _buildTile(
                  label: 'SEKARANG',
                  title: after.shortTitle,
                  icon: after.icon,
                  time: after.start.toString(),
                  color: AppColors.utama,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.grid16),
            Container(
              padding: const EdgeInsets.all(AppSpacing.grid14),
              decoration: const BoxDecoration(
                color: AppColors.saranLembut,
                borderRadius: AppRadius.kartuSaran,
              ),
              child: Text(
                'Pesan dari Ibu: "$message"',
                style: AppTypography.kecil,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTile({
    required String label,
    required String title,
    required ActivityIcon icon,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid12),
      decoration: const BoxDecoration(
        color: AppColors.latar,
        borderRadius: AppRadius.kolomIsian,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.mikro.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.grid6),
          Icon(lucideIconFor(icon), size: AppSpacing.iconSize24, color: color),
          const SizedBox(height: AppSpacing.grid6),
          Text(title, style: AppTypography.judulBaris),
          Text(time, style: AppTypography.meta),
        ],
      ),
    );
  }
}
