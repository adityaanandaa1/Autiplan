import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/providers.dart';

/// A-08: Menelepon (HANDOFF §12 A-08).
class ChildCallingScreen extends ConsumerStatefulWidget {
  const ChildCallingScreen({super.key});

  @override
  ConsumerState<ChildCallingScreen> createState() => _ChildCallingScreenState();
}

class _ChildCallingScreenState extends ConsumerState<ChildCallingScreen> {
  bool _showBackup = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 30), () {
      if (mounted) setState(() => _showBackup = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ChildPalette>()!;
    final caregiverName = ref.watch(
      appStateProvider.select((s) => s.settings.caregiverName),
    );
    final caregiverLabel = caregiverName.isEmpty ? 'pengasuh' : caregiverName;
    final caregiverSentenceStart = caregiverName.isEmpty
        ? 'Pengasuh'
        : caregiverName;
    final hasBackup = ref.watch(
      appStateProvider.select((s) => s.settings.backupNumber.isNotEmpty),
    );

    return Scaffold(
      backgroundColor: palette.anakLatar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.utamaLembut,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.anakAksenLembut,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initialsOf(caregiverName),
                            style: AppTypography.inisialBesar,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.grid24),
                      Text(
                        'Menelepon $caregiverLabel…',
                        style: AppTypography.judulAnak,
                      ),
                      const SizedBox(height: AppSpacing.grid12),
                      Text(
                        'Tarik napas pelan-pelan. $caregiverSentenceStart akan segera menjawab.',
                        style: AppTypography.isiAnak,
                        textAlign: TextAlign.center,
                      ),
                      if (hasBackup) ...[
                        const SizedBox(height: AppSpacing.grid24),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.grid16),
                          decoration: BoxDecoration(
                            color: AppColors.permukaan,
                            borderRadius: AppRadius.kartuAnak,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.info,
                                size: AppSpacing.iconSize20,
                                color: palette.anakAksenKuat,
                              ),
                              const SizedBox(width: AppSpacing.grid12),
                              Expanded(
                                child: Text(
                                  'Kalau $caregiverLabel belum menjawab, HP akan menelepon kontak cadangan.',
                                  style: AppTypography.isiAnak.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_showBackup && hasBackup) ...[
                ChildButton(
                  label: 'Telepon kontak cadangan',
                  variant: ChildButtonVariant.outline,
                  onPressed: _callBackup,
                ),
                const SizedBox(height: AppSpacing.grid12),
              ],
              ChildButton(
                label: 'Tutup panggilan',
                variant: ChildButtonVariant.outline,
                onPressed: () => context.go('/anak'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callBackup() async {
    final state = ref.read(appStateProvider);
    final uri = Uri(scheme: 'tel', path: state.settings.backupNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
