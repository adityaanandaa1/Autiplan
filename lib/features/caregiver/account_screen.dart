import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/calm_empty_screen.dart';
import '../../core/widgets/card_surface.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/providers.dart';
import 'account_sheets.dart';
import 'account_widgets.dart';

class CaregiverAccountScreen extends ConsumerWidget {
  const CaregiverAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final child = ref.watch(currentChildProvider);
    if (child == null) return const CalmEmptyScreen();

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
                  const AccountProfileCard(),
                  const SizedBox(height: AppSpacing.grid16),
                  _buildGroupLabel('Anak'),
                  CardSurface(
                    padding: const EdgeInsets.all(AppSpacing.grid16),
                    child: Column(
                      children: [
                        for (final child in state.children)
                          AccountChildRow(
                            child: child,
                            isLast: child == state.children.last,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  _buildGroupLabel(
                    'Profil ${child.name} · dipakai untuk saran',
                  ),
                  CardSurface(
                    padding: const EdgeInsets.all(AppSpacing.grid16),
                    child: Column(
                      children: [
                        AccountListRow(
                          icon: LucideIcons.heart,
                          label: 'Suka',
                          value: child.likes.join(', '),
                          onTap: () =>
                              showProfileListSheet(context, ref, child, 'Suka'),
                        ),
                        const AccountListDivider(),
                        AccountListRow(
                          icon: LucideIcons.sun,
                          label: 'Hindari',
                          value: child.avoids.join(', '),
                          onTap: () => showProfileListSheet(
                            context,
                            ref,
                            child,
                            'Hindari',
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          icon: LucideIcons.userPlus,
                          label: 'Tambah anak',
                          value: '',
                          onTap: () => showAddChildSheet(context, ref),
                        ),
                        const AccountListDivider(),
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
