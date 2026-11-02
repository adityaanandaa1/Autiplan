import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// A-09: Pilih tema (HANDOFF §12 A-09).
class ChildThemeScreen extends ConsumerStatefulWidget {
  const ChildThemeScreen({super.key});

  @override
  ConsumerState<ChildThemeScreen> createState() => _ChildThemeScreenState();
}

class _ChildThemeScreenState extends ConsumerState<ChildThemeScreen> {
  ChildTheme? _selected;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final child = state.children.firstWhere((c) => c.name == 'Rafi');
    _selected ??= child.theme;

    final palette = Theme.of(context).extension<ChildPalette>()!;

    return Scaffold(
      backgroundColor: palette.anakLatar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChildBackHeader(title: 'Pilih Tema', onBack: () => context.go('/anak')),
              const SizedBox(height: AppSpacing.grid24),
              Expanded(
                child: ListView(
                  children: [
                    for (final theme in ChildTheme.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sectionGapChild),
                        child: _buildThemeCard(theme, child.theme),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.grid20),
              ChildButton(
                label: 'Pakai tema ini',
                enabled: _selected != child.theme,
                onPressed: () => _applyTheme(child),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(ChildTheme theme, ChildTheme current) {
    final pal = ChildPalette.fromTheme(theme);
    final isSelected = _selected == theme;
    final isCurrent = theme == current;

    return GestureDetector(
      onTap: () => setState(() => _selected = theme),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.grid16),
        decoration: BoxDecoration(
          color: pal.anakLatar,
          borderRadius: AppRadius.kartuAnak,
          border: isSelected
              ? Border.all(color: pal.anakAksen, width: AppSpacing.strokeAccent)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.permukaan,
                    borderRadius: AppRadius.kartuAnak,
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: pal.anakAksenLembut,
                        borderRadius: AppRadius.ubinIkonKartuAnak,
                      ),
                      child: Icon(
                        Icons.circle,
                        size: 24,
                        color: pal.anakAksenKuat,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.grid16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_themeName(theme), style: AppTypography.kegiatanAnak),
                      if (isCurrent) ...[
                        const SizedBox(height: AppSpacing.grid4),
                        Text(
                          'Sedang dipakai',
                          style: AppTypography.sekunderAnak.copyWith(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: pal.anakAksen, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _themeName(ChildTheme theme) {
    switch (theme) {
      case ChildTheme.lautTenang: return 'Laut Tenang';
      case ChildTheme.padangHijau: return 'Padang Hijau';
      case ChildTheme.pagiHangat: return 'Pagi Hangat';
    }
  }

  Future<void> _applyTheme(Child child) async {
    final state = ref.read(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    
    final updated = state.copyWith(
      children: [
        for (final c in state.children)
          c.id == child.id ? c.copyWith(theme: _selected!) : c,
      ],
    );

    notifier.updateState(updated);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) context.go('/anak');
  }
}
