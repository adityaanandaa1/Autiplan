import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/theme.dart';

class ChangeNoticeCard extends StatelessWidget {
  const ChangeNoticeCard({
    super.key,
    required this.childName,
    required this.hasUnread,
    this.seenAt,
    this.onTap,
  });

  final String childName;
  final bool hasUnread;
  final DateTime? seenAt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = hasUnread
        ? 'Belum dibuka $childName'
        : seenAt != null
            ? 'Dilihat $childName pukul ${_formatTime(seenAt!)}'
            : '';

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.kartuOrangTua,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.anakLembut,
          borderRadius: AppRadius.kartuOrangTua,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.anakAksen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.messageSquare,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perubahan jadwal',
                    style: AppTypography.judulBaris,
                  ),
                  if (statusText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: AppTypography.meta,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.teksSekunder,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  }
}
