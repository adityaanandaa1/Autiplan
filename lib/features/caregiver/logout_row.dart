import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/calm_snackbar.dart';
import '../../data/providers.dart';
import 'account_widgets.dart';

/// Dialog "Anda yakin untuk keluar?". Hasil `true` hanya bila memilih "Ya";
/// "Tidak" atau menutup dialog memberi `false`.
Future<bool> showLogoutDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      contentPadding: const EdgeInsets.all(AppSpacing.grid20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Anda yakin untuk keluar?',
            textAlign: TextAlign.center,
            style: AppTypography.judulSheet,
          ),
          const SizedBox(height: AppSpacing.grid24),
          PrimaryButton(
            label: 'Ya',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Tidak',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );
  return confirmed ?? false;
}

/// Baris "Keluar" di layar Akun: minta konfirmasi, lalu tampilkan spinner
/// selama keluar berjalan dan abaikan ketukan berikutnya.
class LogoutRow extends ConsumerStatefulWidget {
  const LogoutRow({super.key});

  @override
  ConsumerState<LogoutRow> createState() => _LogoutRowState();
}

class _LogoutRowState extends ConsumerState<LogoutRow> {
  bool _signingOut = false;

  Future<void> _logout() async {
    if (_signingOut) return;
    final confirmed = await showLogoutDialog(context);
    if (!confirmed || !mounted) return;

    final session = ref.read(sessionNotifierProvider.notifier);
    setState(() => _signingOut = true);
    try {
      await session.signOut();
      // Sesi berganti; router mengarahkan ke /mulai dan layar ini dilepas.
    } on Object {
      if (mounted) {
        CalmSnackbar.show(
          context,
          message: 'Belum bisa keluar. Coba lagi sebentar.',
        );
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountListRow(
      icon: LucideIcons.logOut,
      label: 'Keluar',
      value: '',
      loading: _signingOut,
      onTap: _logout,
    );
  }
}
