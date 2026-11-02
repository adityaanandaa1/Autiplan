import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/activity_icon_data.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Ikon kegiatan untuk notifikasi activityStarted/activityDone (OT-15).
/// Model tidak menyimpan id kegiatan, jadi diturunkan dari judul pada teks
/// ("{anak} mulai {judul}" / "{anak} menyelesaikan {judul}"). Null bila tidak
/// ditemukan.
ActivityIcon? notificationActivityIcon(
  CaregiverNotification notif,
  AppState state,
) {
  final verb = switch (notif.type) {
    NotificationType.activityStarted => 'mulai',
    NotificationType.activityDone => 'menyelesaikan',
    _ => null,
  };
  if (verb == null) return null;
  for (final child in state.children) {
    final prefix = '${child.name} $verb ';
    if (!notif.text.startsWith(prefix)) continue;
    final title = notif.text.substring(prefix.length);
    for (final a in state.activities) {
      if (a.childId == child.id && a.title == title) return a.icon;
    }
  }
  return null;
}

class CaregiverNotificationsScreen extends ConsumerWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final clock = ref.watch(clockProvider);
    final now = clock.now;

    final todayNotifications = <CaregiverNotification>[];
    final olderNotifications = <CaregiverNotification>[];

    for (final notif in state.notifications) {
      final isToday =
          notif.at.year == now.year &&
          notif.at.month == now.month &&
          notif.at.day == now.day;
      if (isToday) {
        todayNotifications.add(notif);
      } else {
        olderNotifications.add(notif);
      }
    }

    todayNotifications.sort((a, b) => b.at.compareTo(a.at));
    olderNotifications.sort((a, b) => b.at.compareTo(a.at));

    // Mark all as read when opening screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final unreadIds = state.notifications
          .where((n) => !n.read)
          .map((n) => n.id)
          .toList();
      if (unreadIds.isNotEmpty) {
        final updatedNotifications = state.notifications
            .map((n) => unreadIds.contains(n.id) ? n.copyWith(read: true) : n)
            .toList();
        ref
            .read(appStateProvider.notifier)
            .updateState(state.copyWith(notifications: updatedNotifications));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Notifikasi',
              variant: CaregiverHeaderVariant.back,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: _buildNotificationList(
                todayNotifications,
                olderNotifications,
                state,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    List<CaregiverNotification> today,
    List<CaregiverNotification> older,
    AppState state,
  ) {
    if (today.isEmpty && older.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.grid16),
          child: Text('Belum ada notifikasi.', style: AppTypography.meta),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.grid16),
      children: [
        if (today.isNotEmpty) ...[
          Text('Hari ini', style: AppTypography.judulBagian),
          const SizedBox(height: AppSpacing.grid12),
          ...today.map((n) => _buildNotificationRow(n, state)),
        ],
        if (older.isNotEmpty) ...[
          if (today.isNotEmpty) const SizedBox(height: AppSpacing.grid24),
          Text('Sebelumnya', style: AppTypography.judulBagian),
          const SizedBox(height: AppSpacing.grid12),
          ...older.map((n) => _buildNotificationRow(n, state)),
        ],
      ],
    );
  }

  Widget _buildNotificationRow(CaregiverNotification notif, AppState state) {
    final (icon, color, bgColor) = _getIconAndColor(notif, state);
    final timeStr = DateFormat('HH.mm', 'id_ID').format(notif.at);

    return Container(
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
            child: Icon(icon, size: AppSpacing.iconSize20, color: color),
          ),
          const SizedBox(width: AppSpacing.grid12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.text, style: AppTypography.isi),
                if (notif.badge != null) ...[
                  const SizedBox(height: AppSpacing.grid4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.grid8,
                      vertical: AppSpacing.grid2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.utamaLembut,
                      borderRadius: AppRadius.pil,
                    ),
                    child: Text(
                      notif.badge!,
                      style: AppTypography.mikro.copyWith(
                        color: AppColors.utama,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.grid12),
          Text(timeStr, style: AppTypography.meta),
        ],
      ),
    );
  }

  (IconData, Color, Color) _getIconAndColor(
    CaregiverNotification notif,
    AppState state,
  ) {
    final activityIcon = notificationActivityIcon(notif, state);
    switch (notif.type) {
      case NotificationType.changeSeen:
        return (
          LucideIcons.circleCheckBig,
          AppColors.sukses,
          AppColors.suksesLembut,
        );
      case NotificationType.activityStarted:
        return (
          activityIcon != null
              ? lucideIconFor(activityIcon)
              : LucideIcons.calendar,
          AppColors.utama,
          AppColors.utamaLembut,
        );
      case NotificationType.activityDone:
        return (
          activityIcon != null
              ? lucideIconFor(activityIcon)
              : LucideIcons.calendar,
          AppColors.teks,
          AppColors.anakLembut,
        );
      case NotificationType.emergencyPressed:
        return (LucideIcons.phone, AppColors.bahaya, AppColors.bahayaLembut);
    }
  }
}
