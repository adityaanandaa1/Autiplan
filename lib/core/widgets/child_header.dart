import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

class ChildHeader extends StatelessWidget {
  const ChildHeader({
    super.key,
    required this.greeting,
    required this.childName,
    this.onEmergencyPressed,
    this.showEmergencyButton = true,
  });

  final String greeting;
  final String childName;
  final VoidCallback? onEmergencyPressed;
  final bool showEmergencyButton;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ChildPalette>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.sekunderAnak,
                ),
                const SizedBox(height: 4),
                Text(
                  childName,
                  style: AppTypography.sapaanAnak,
                ),
              ],
            ),
          ),
          if (showEmergencyButton) ...[
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.anakAksenLembut,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onEmergencyPressed,
                icon: Icon(
                  LucideIcons.phone,
                  size: 24,
                  color: palette.anakAksenKuat,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
