import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/card_surface.dart';
import '../../../core/widgets/suggestion_card.dart';
import '../../../data/models/models.dart';
import 'suggestion_detail_sheet.dart';

class ScheduleEmptyDay extends StatelessWidget {
  const ScheduleEmptyDay({
    super.key,
    required this.childName,
    this.suggestion,
    this.onUseTemplate,
  });

  final String childName;
  final Suggestion? suggestion;
  final VoidCallback? onUseTemplate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CardSurface(
          child: Column(
            children: [
              Container(
                width: AppSpacing.iconTileLarge,
                height: AppSpacing.iconTileLarge,
                decoration: BoxDecoration(
                  color: AppColors.anakLembut,
                  borderRadius: AppRadius.ubinIkon10,
                ),
                child: const Icon(
                  LucideIcons.calendarDays,
                  size: AppSpacing.iconSize22,
                  color: AppColors.teks,
                ),
              ),
              const SizedBox(height: AppSpacing.grid12),
              const Text(
                'Belum ada jadwal di hari ini',
                style: AppTypography.judulBaris,
              ),
              const SizedBox(height: AppSpacing.grid6),
              Text(
                'Tambahkan kegiatan supaya $childName tahu rencananya lebih awal.',
                style: AppTypography.isi,
                textAlign: TextAlign.center,
              ),
              if (onUseTemplate != null) ...[
                const SizedBox(height: AppSpacing.grid16),
                SizedBox(
                  height: AppSpacing.buttonHeightParent,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onUseTemplate,
                    icon: const Icon(
                      LucideIcons.sparkles,
                      size: AppSpacing.iconSize18,
                    ),
                    label: const Text('Gunakan Template Rutinitas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.utama,
                      side: const BorderSide(color: AppColors.utama),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.tombolOrangTua,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (suggestion != null) ...[
          const SizedBox(height: AppSpacing.grid12),
          SuggestionCard(
            label: 'Saran untuk hari kosong',
            content: suggestion!.body,
            actionLabel: suggestion!.actionLabel,
            onTap: () =>
                showSuggestionDetailSheet(context, suggestion: suggestion!),
          ),
        ],
      ],
    );
  }
}
