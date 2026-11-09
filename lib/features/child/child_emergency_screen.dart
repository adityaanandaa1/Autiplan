import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/clock.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// A-07: Konfirmasi darurat (HANDOFF §12 A-07).
class ChildEmergencyScreen extends ConsumerWidget {
  const ChildEmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                title: 'Butuh Bantuan?',
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
                onPressed: () => _call(context, ref),
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

  Future<void> _call(BuildContext context, WidgetRef ref) async {
    final state = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final clock = ref.read(clockProvider);

    final child = ref.read(currentChildProvider);
    final childName = child?.name ?? 'Anak';
    final updated = state.copyWith(
      notifications: [
        ...state.notifications,
        CaregiverNotification(
          id: const Uuid().v4(),
          type: NotificationType.emergencyPressed,
          text: '$childName menekan tombol bantuan',
          at: clock.now,
          read: false,
        ),
      ],
    );
    notifier.updateState(updated);

    final uri = Uri(scheme: 'tel', path: state.settings.emergencyNumber);
    try {
      if (state.settings.emergencyNumber.isNotEmpty &&
          await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telepon tidak tersedia di perangkat ini'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telepon tidak tersedia di perangkat ini'),
          ),
        );
      }
    }

    if (context.mounted) context.push('/anak/menelepon');
  }
}
