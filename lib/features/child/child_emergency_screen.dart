import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/notify_helper.dart';
import '../../data/providers.dart';

/// A-07: Konfirmasi darurat (HANDOFF §12 A-07).

class ChildEmergencyScreen extends ConsumerStatefulWidget {
  const ChildEmergencyScreen({super.key});

  @override
  ConsumerState<ChildEmergencyScreen> createState() =>
      _ChildEmergencyScreenState();
}

class _ChildEmergencyScreenState extends ConsumerState<ChildEmergencyScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ChildPalette>()!;
    final caregiverName = ref.watch(
      appStateProvider.select((s) => s.settings.caregiverName),
    );
    final caregiverLabel = caregiverName.isEmpty ? 'pengasuh' : caregiverName;

    return Scaffold(
      backgroundColor: palette.anakLatar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
          child: Column(
            children: [
              ChildBackHeader(
                title: 'Butuh bantuan?',
                onBack: () => context.go('/anak'),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: palette.anakAksenLembut,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.phone,
                          size: 60,
                          color: palette.anakAksenKuat,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.grid24),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: AppColors.utamaLembut,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initialsOf(caregiverName),
                            style: AppTypography.inisialBesar,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.grid16),
                      Text(caregiverLabel, style: AppTypography.judulAnak),
                      const SizedBox(height: AppSpacing.grid12),
                      Text(
                        'Tekan tombol di bawah untuk menelepon $caregiverLabel.',
                        style: AppTypography.isiAnak,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              ChildButton(
                label: 'Telepon $caregiverLabel',
                onPressed: () => _call(),
              ),
              const SizedBox(height: AppSpacing.grid12),
              ChildButton(
                label: 'Tidak jadi',
                variant: ChildButtonVariant.text,
                onPressed: () => context.go('/anak'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _call() async {
    if (_busy) return;
    _busy = true;
    try {
      final number = ref.read(appStateProvider).settings.emergencyNumber;
      if (number.isNotEmpty) {
        try {
          await ref.read(phoneLauncherProvider)(
            Uri(scheme: 'tel', path: number),
          );
        } catch (e) {
          debugPrint('Gagal membuka telepon: $e');
        }
      }
      if (!mounted) return;

      // Baca state SESUDAH peluncur telepon, agar tidak menimpa snapshot baru.
      final state = ref.read(appStateProvider);
      final childName = ref.read(currentChildProvider)?.name ?? 'Anak';
      final notifId = const Uuid().v4();
      final written = ref
          .read(appStateProvider.notifier)
          .updateStateAndWait(
            state.copyWith(
              notifications: [
                ...state.notifications,
                CaregiverNotification(
                  id: notifId,
                  type: NotificationType.emergencyPressed,
                  text: '$childName menekan tombol bantuan',
                  at: ref.read(clockProvider).now,
                  read: false,
                ),
              ],
            ),
          );
      notifyParentAfterWrite(
        ref,
        written: written,
        notificationId: notifId,
        label: 'darurat',
      );
    } catch (e) {
      debugPrint('Gagal mencatat darurat: $e');
    } finally {
      _busy = false;
    }
    if (mounted) context.push('/anak/menelepon');
  }
}
