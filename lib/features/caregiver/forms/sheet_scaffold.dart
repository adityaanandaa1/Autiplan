import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';

/// Kerangka bottom sheet orang tua: pegangan, judul, subjudul, tombol tutup.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.sheetAtas,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.grid8),
            Container(
              width: AppSpacing.grid40,
              height: AppSpacing.grid4,
              decoration: BoxDecoration(
                color: AppColors.garis,
                borderRadius: AppRadius.pil,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.grid20,
                AppSpacing.grid12,
                AppSpacing.grid8,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTypography.judulSheet),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.grid2),
                          Text(subtitle!, style: AppTypography.meta),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    icon: const Icon(
                      LucideIcons.x,
                      size: AppSpacing.iconSize24,
                    ),
                    color: AppColors.teksSekunder,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.grid20,
                  AppSpacing.grid12,
                  AppSpacing.grid20,
                  AppSpacing.grid24,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
