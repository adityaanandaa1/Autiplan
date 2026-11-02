import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../core/widgets/card_surface.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/suggestion_engine.dart';
import 'widgets/suggestion_detail_sheet.dart';

class CaregiverSuggestionsScreen extends ConsumerWidget {
  const CaregiverSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;

    final child = state.children.firstWhere((c) => c.id == selectedChildId);
    final suggestions = generateSuggestions(state, now, selectedChildId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Saran untuk ${child.name}',
              variant: CaregiverHeaderVariant.back,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
                children: [
                  CardSurface(
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.info,
                          size: AppSpacing.iconSize20,
                          color: AppColors.teksSekunder,
                        ),
                        const SizedBox(width: AppSpacing.grid12),
                        Expanded(
                          child: Text(
                            'Saran dibuat otomatis dari pola jadwal dan profil ${child.name}. '
                            'Anda yang memutuskan.',
                            style: AppTypography.kecil.copyWith(
                              color: AppColors.teksSekunder,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.grid24),
                    Text(
                      '${suggestions.length} saran baru',
                      style: AppTypography.judulBagian,
                    ),
                    const SizedBox(height: AppSpacing.grid12),
                    ...suggestions.map((s) => _buildSuggestionRow(context, s)),
                  ] else ...[
                    const SizedBox(height: AppSpacing.grid24),
                    const Center(
                      child: Text(
                        'Belum ada saran. Kami akan memberi tahu kalau ada pola '
                        'yang perlu diperhatikan.',
                        style: AppTypography.meta,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.grid24),
                  Text('Cek otomatis', style: AppTypography.judulBagian),
                  const SizedBox(height: AppSpacing.grid12),
                  _buildAutoCheckItem(
                    'Waktu tenang sebelum tidur',
                    'Layar < 30 menit sebelum tidur',
                  ),
                  _buildAutoCheckItem(
                    'Jeda antar kegiatan',
                    'Minimal 10 menit',
                  ),
                  _buildAutoCheckItem(
                    'Latihan mandiri',
                    'Selesai tepat waktu 5 hari berturut',
                  ),
                  _buildAutoCheckItem(
                    'Hari kosong',
                    'Sesuai minat ${child.name}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionRow(BuildContext context, Suggestion suggestion) {
    final (icon, iconColor, bgColor) = _getSuggestionIcon(suggestion.type);
    return InkWell(
      onTap: () {
        showSuggestionDetailSheet(context, suggestion: suggestion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.garis,
              width: AppSpacing.strokeThin,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.iconTile40,
              height: AppSpacing.iconTile40,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.ubinIkon10,
              ),
              child: Icon(icon, size: AppSpacing.iconSize20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.grid12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(suggestion.title, style: AppTypography.judulBaris),
                  const SizedBox(height: AppSpacing.grid2),
                  Text(
                    suggestion.body,
                    style: AppTypography.meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.grid8),
            const Icon(
              LucideIcons.chevronRight,
              size: AppSpacing.iconSize20,
              color: AppColors.teksSekunder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCheckItem(String label, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid12),
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.garis, width: AppSpacing.strokeThin),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circleCheckBig,
            size: AppSpacing.iconSize20,
            color: AppColors.sukses,
          ),
          const SizedBox(width: AppSpacing.grid12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.isi),
                const SizedBox(height: AppSpacing.grid2),
                Text(description, style: AppTypography.meta),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.independence:
        return (
          LucideIcons.sparkles,
          AppColors.saranTeks,
          AppColors.saranLembut
        );
      case SuggestionType.quietTime:
        return (LucideIcons.moon, AppColors.saranTeks, AppColors.saranLembut);
      case SuggestionType.emptyDay:
        return (LucideIcons.sun, AppColors.saranTeks, AppColors.saranLembut);
      case SuggestionType.transitionGap:
        return (
          LucideIcons.hourglass,
          AppColors.saranTeks,
          AppColors.saranLembut
        );
    }
  }
}

