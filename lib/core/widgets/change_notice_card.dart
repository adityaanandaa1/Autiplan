import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/models/change_notice.dart';
import '../theme/theme.dart';
import 'card_surface.dart';

/// Ringkasan notice hari ini untuk kartu "Perlu perhatian" (OT-02/03):
/// notice terbaru + jumlah perubahan lain.
class NoticeSummary {
  const NoticeSummary(this.latest, this.otherCount);

  final ChangeNotice latest;
  final int otherCount;
}

/// Notice terbaru (sentAt terbesar; bila sama, yang terakhir di daftar).
NoticeSummary? summarizeNotices(List<ChangeNotice> notices) {
  if (notices.isEmpty) return null;
  var latest = notices.first;
  for (final n in notices.skip(1)) {
    if (!n.sentAt.isBefore(latest.sentAt)) latest = n;
  }
  return NoticeSummary(latest, notices.length - 1);
}

/// "{judul lama} → {judul baru}, {jam}". Notice hapus (after null) memakai
/// "Waktu bebas" dan jam kegiatan semula, seperti tampilan anak (A-02).
String noticeChangeLine(ChangeNotice notice) {
  final after = notice.after;
  if (after == null) {
    return '${notice.before.title} → Waktu bebas, ${notice.before.start}';
  }
  return '${notice.before.title} → ${after.title}, ${after.start}';
}

class ChangeNoticeCard extends StatelessWidget {
  const ChangeNoticeCard({
    super.key,
    required this.childName,
    required this.hasUnread,
    this.seenAt,
    this.changeLine,
    this.otherCount = 0,
    this.onTap,
  });

  final String childName;

  /// Status notice terbaru: true = belum dibuka anak.
  final bool hasUnread;
  final DateTime? seenAt;

  /// Baris "{lama} → {baru}, {jam}".
  final String? changeLine;

  /// Jumlah perubahan lain hari ini ("+n perubahan lain").
  final int otherCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = hasUnread
        ? 'Belum dibuka $childName'
        : seenAt != null
        ? 'Dilihat $childName pukul ${_formatTime(seenAt!)}'
        : '';
    final pillBg = hasUnread ? AppColors.saranLembut : AppColors.suksesLembut;
    final pillFg = hasUnread ? AppColors.saranTeks : AppColors.sukses;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.kartuOrangTua,
      child: CardSurface(
        child: Row(
          children: [
            Container(
              width: AppSpacing.iconTile40,
              height: AppSpacing.iconTile40,
              decoration: const BoxDecoration(
                color: AppColors.utamaLembut,
                borderRadius: AppRadius.ubinIkon10,
              ),
              child: const Icon(
                LucideIcons.refreshCw,
                size: AppSpacing.iconSize20,
                color: AppColors.utama,
              ),
            ),
            const SizedBox(width: AppSpacing.grid12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perubahan terkirim ke $childName',
                    style: AppTypography.judulBaris,
                  ),
                  if (changeLine != null) ...[
                    const SizedBox(height: AppSpacing.grid2),
                    Text(changeLine!, style: AppTypography.meta),
                  ],
                  if (statusText.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.grid8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.grid10,
                        vertical: AppSpacing.grid4,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: AppRadius.pil,
                      ),
                      child: Text(
                        statusText,
                        style: AppTypography.mikro.copyWith(color: pillFg),
                      ),
                    ),
                  ],
                  if (otherCount > 0) ...[
                    const SizedBox(height: AppSpacing.grid8),
                    Text(
                      '+$otherCount perubahan lain',
                      style: AppTypography.meta,
                    ),
                  ],
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

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';
  }
}
