import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

/// Header layar anak: ikon `arrowLeft` 26 + judul 22 SemiBold.
/// Tanpa [title] hanya tombol kembali (layar A-06).
class ChildBackHeader extends StatelessWidget {
  const ChildBackHeader({super.key, this.title, required this.onBack});

  final String? title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Kembali',
          excludeSemantics: true,
          child: InkResponse(
            onTap: onBack,
            child: const SizedBox(
              width: AppSpacing.minTouchTarget,
              height: AppSpacing.minTouchTarget,
              child: Icon(
                LucideIcons.arrowLeft,
                size: AppSpacing.iconSize26,
                color: AppColors.teks,
              ),
            ),
          ),
        ),
        if (title != null) ...[
          const SizedBox(width: AppSpacing.grid8),
          Expanded(child: Text(title!, style: AppTypography.judulAnak)),
        ],
      ],
    );
  }
}
