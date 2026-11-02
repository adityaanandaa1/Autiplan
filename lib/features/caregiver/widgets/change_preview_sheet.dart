import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../data/models/models.dart';
import '../forms/sheet_scaffold.dart';

/// Pratinjau kecil "Dulu → Sekarang" di HP anak (§8.7), bergaya A-02:
/// ubin Dulu (opasitas 60%, tanpa tepi) → ikon `arrowRight` → ubin Sekarang
/// (tepi 2 `anakAksen`), lalu kotak alasan berisi pesan untuk anak.
class ChangePreviewSheet extends StatelessWidget {
  const ChangePreviewSheet({
    super.key,
    required this.childName,
    required this.before,
    required this.after,
    required this.message,
    this.palette = ChildPalette.lautTenang,
  });

  final String childName;
  final ActivitySnapshot before;
  final ActivitySnapshot after;
  final String message;

  /// Warna tema anak (A-09), supaya pratinjau sama dengan tampilan di HP anak.
  final ChildPalette palette;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Dulu → Sekarang',
      subtitle: 'di HP $childName',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Opacity(
                  opacity: AppColors.alphaSelesai,
                  child: _tile(
                    label: 'Dulu',
                    snapshot: before,
                    labelColor: AppColors.teksSekunder,
                    highlighted: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.grid8,
                ),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: AppSpacing.iconSize24,
                  color: palette.anakAksenKuat,
                ),
              ),
              Expanded(
                child: _tile(
                  label: 'Sekarang',
                  snapshot: after,
                  labelColor: palette.anakAksenKuat,
                  highlighted: true,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.grid16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.grid16),
              decoration: BoxDecoration(
                color: palette.anakAksenLembut,
                borderRadius: AppRadius.kartuAnak,
              ),
              child: Text(message, style: AppTypography.isiAnak),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tile({
    required String label,
    required ActivitySnapshot snapshot,
    required Color labelColor,
    required bool highlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid12),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.kartuAnak,
        border: highlighted
            ? Border.all(
                color: palette.anakAksen,
                width: AppSpacing.strokeAccent,
              )
            : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelAnak.copyWith(color: labelColor),
          ),
          const SizedBox(height: AppSpacing.grid8),
          Container(
            width: AppSpacing.iconTileLarge,
            height: AppSpacing.iconTileLarge,
            decoration: BoxDecoration(
              color: palette.anakAksenLembut,
              borderRadius: AppRadius.ubinIkonKartuAnak,
            ),
            child: Icon(
              lucideIconFor(snapshot.icon),
              size: AppSpacing.iconSize26,
              color: palette.anakAksenKuat,
            ),
          ),
          const SizedBox(height: AppSpacing.grid8),
          Text(
            snapshot.shortTitle,
            textAlign: TextAlign.center,
            style: AppTypography.kegiatanAnak,
          ),
          Text(snapshot.start.toString(), style: AppTypography.jamAnak),
        ],
      ),
    );
  }
}
