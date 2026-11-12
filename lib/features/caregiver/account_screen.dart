import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/calm_empty_screen.dart';
import '../../core/widgets/card_surface.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import 'account_sheets.dart';
import 'account_widgets.dart';
import 'child_list_sheet.dart';
import 'pairing_sheet.dart';

class CaregiverAccountScreen extends ConsumerWidget {
  const CaregiverAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    if (ref.watch(currentChildProvider) == null) {
      return const CalmEmptyScreen();
    }

    final linkedDevices = ref.watch(linkedDevicesProvider).value ?? const [];
    final linkedChild = linkedChildNamesOf(linkedDevices, state.children);

    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            const CaregiverHeader(title: 'Akun'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
                children: [
                  _buildGroupLabel('Anak'),
                  CardSurface(
                    padding: const EdgeInsets.all(AppSpacing.grid16),
                    child: Column(
                      children: [
                        AccountListRow(
                          icon: LucideIcons.users,
                          label: 'Daftar anak',
                          value: '',
                          onTap: () => showChildListSheet(context, ref),
                        ),
                        for (final c in state.children) ...[
                          const AccountListDivider(),
                          _buildDeviceRow(context, ref, c, linkedDevices),
                        ],
                        const AccountListDivider(),
                        AccountListRow(
                          icon: LucideIcons.userPlus,
                          label: 'Tambah anak',
                          value: '',
                          onTap: () => showAddChildSheet(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  AccountProfileCard(linkedChildName: linkedChild),
                  const SizedBox(height: AppSpacing.grid16),
                  _buildGroupLabel('Pengaturan'),
                  CardSurface(
                    padding: const EdgeInsets.all(AppSpacing.grid16),
                    child: Column(
                      children: [
                        AccountListRow(
                          icon: LucideIcons.bell,
                          label: 'Pengingat sebelum kegiatan',
                          value:
                              '${state.settings.reminderMinutesBefore} menit',
                          onTap: () => showReminderSheet(context, ref),
                        ),
                        const AccountListDivider(),
                        AccountListRow(
                          icon: LucideIcons.slidersHorizontal,
                          label: 'Batas saran',
                          value:
                              'Jeda ${state.settings.minGapMinutes} mnt · ${state.settings.independenceStreakDays} hari',
                          onTap: () => showLimitsSheet(context, ref),
                        ),
                        const AccountListDivider(),
                        AccountListRow(
                          icon: LucideIcons.phone,
                          label: 'Nomor darurat',
                          value: state.settings.emergencyNumber,
                          onTap: () => showEmergencyNumbersSheet(context, ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  _buildGroupLabel('Akun'),
                  CardSurface(
                    padding: const EdgeInsets.all(AppSpacing.grid16),
                    child: Column(
                      children: [
                        AccountListRow(
                          icon: LucideIcons.logOut,
                          label: 'Keluar',
                          value: '',
                          onTap: () => ref
                              .read(sessionNotifierProvider.notifier)
                              .signOut(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Satu baris per anak: "Hubungkan HP {anak}" bila belum ada HP, atau
  /// "Putuskan HP {anak}" bila sudah terhubung.
  Widget _buildDeviceRow(
    BuildContext context,
    WidgetRef ref,
    Child c,
    List<LinkedDevice> linkedDevices,
  ) {
    final linked = linkedDevices.any((d) => d.childId == c.id);
    return AccountListRow(
      icon: linked ? LucideIcons.unlink : LucideIcons.smartphone,
      label: linked ? 'Putuskan HP ${c.name}' : 'Hubungkan HP ${c.name}',
      value: linked ? 'Terhubung' : 'Belum terhubung',
      onTap: () => linked
          ? showUnlinkDialog(context, ref, c)
          : showPairingSheet(context, ref, c),
    );
  }

  Widget _buildGroupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grid8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: AppTypography.meta),
      ),
    );
  }
}
