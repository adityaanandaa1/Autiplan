import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/calm_snackbar.dart';
import '../../data/backend_api.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Sheet "Hubungkan HP {anak}": buat kode 6 angka, tampilkan, dan tombol
/// "Buat kode baru".
void showPairingSheet(BuildContext context, WidgetRef ref, Child child) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _PairingSheet(child: child),
  );
}

class _PairingSheet extends ConsumerStatefulWidget {
  const _PairingSheet({required this.child});

  final Child child;

  @override
  ConsumerState<_PairingSheet> createState() => _PairingSheetState();
}

class _PairingSheetState extends ConsumerState<_PairingSheet> {
  PairingCode? _pairing;
  String? _message;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _create();
  }

  Future<void> _create() async {
    setState(() {
      _creating = true;
      _message = null;
    });
    try {
      final result = await ref
          .read(backendApiProvider)
          .createPairingCode(widget.child.id);
      if (mounted) setState(() => _pairing = result);
    } on BackendException catch (e) {
      if (mounted) setState(() => _message = _messageFor(e.failure));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  static String _messageFor(BackendFailure failure) => switch (failure) {
    BackendFailure.offline => 'Belum ada internet. Coba lagi nanti.',
    BackendFailure.invalidCode => 'Anak belum bisa dihubungkan. Coba lagi.',
    BackendFailure.expiredCode => 'Kode sudah tidak berlaku. Buat kode baru.',
    BackendFailure.tooManyAttempts => 'Coba lagi sebentar lagi.',
    BackendFailure.unknown => 'Belum bisa membuat kode. Coba lagi sebentar.',
  };

  @override
  Widget build(BuildContext context) {
    final pairing = _pairing;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.sheetAtas,
      ),
      padding: const EdgeInsets.all(AppSpacing.grid20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hubungkan HP ${widget.child.name}',
            style: AppTypography.judulSheet,
          ),
          const SizedBox(height: AppSpacing.grid16),
          Text(
            'Masukkan kode ini di HP ${widget.child.name}. Berlaku 10 menit.',
            style: AppTypography.isi,
          ),
          const SizedBox(height: AppSpacing.grid16),
          if (pairing != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.grid16),
              decoration: const BoxDecoration(
                color: AppColors.utamaLembut,
                borderRadius: AppRadius.kolomIsian,
              ),
              child: Text(
                pairing.code,
                textAlign: TextAlign.center,
                style: AppTypography.logo,
              ),
            ),
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.grid12),
            Text(
              _message!,
              style: AppTypography.meta.copyWith(color: AppColors.saranTeks),
            ),
          ],
          const SizedBox(height: AppSpacing.grid16),
          PrimaryButton(
            label: 'Buat kode baru',
            enabled: !_creating,
            onPressed: _create,
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Tutup',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Dialog "Putuskan HP {anak}?": hapus dokumen `devices/{uid}` anak.
Future<void> showUnlinkDialog(
  BuildContext context,
  WidgetRef ref,
  Child child,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      contentPadding: const EdgeInsets.all(AppSpacing.grid20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Putuskan HP ${child.name}?', style: AppTypography.judulSheet),
          const SizedBox(height: AppSpacing.grid8),
          Text(
            'HP ${child.name} tidak akan menerima jadwal sampai dihubungkan lagi.',
            textAlign: TextAlign.center,
            style: AppTypography.kecil.copyWith(color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.grid24),
          DangerButton(
            label: 'Putuskan',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Batal',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );

  if (confirmed != true) return;
  await ref.read(repositoryProvider).unlinkChildDevice(child.id);
  if (context.mounted) {
    CalmSnackbar.show(context, message: 'HP ${child.name} sudah diputuskan');
  }
}
