import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/auth_service.dart';
import '../../data/backend_api.dart';
import '../../data/providers.dart';
import '../../data/session/device_session.dart';
import '../caregiver/forms/form_field.dart';

/// `/hubungkan`: HP anak memasukkan kode 6 angka dari orang tua, lalu klaim
/// lewat Worker. Berhasil: masuk anonim, klaim, lalu sesi [ChildSession].
class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({super.key});

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  final _code = TextEditingController();
  String? _message;
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      final link = await ref.read(backendApiProvider).claimPairingCode(code);
      if (!mounted) return;
      ref
          .read(sessionNotifierProvider.notifier)
          .adoptChildSession(familyId: link.familyId, childId: link.childId);
      // Sesi berganti; router mengarahkan ke /anak.
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } on BackendException catch (e) {
      if (mounted) setState(() => _message = _messageFor(e.failure));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _messageFor(BackendFailure failure) => switch (failure) {
    BackendFailure.invalidCode => 'Kode belum cocok. Coba periksa lagi.',
    BackendFailure.expiredCode => 'Kode sudah tidak berlaku. Minta kode baru.',
    BackendFailure.tooManyAttempts =>
      'Terlalu banyak percobaan. Coba lagi nanti.',
    BackendFailure.offline => 'Belum ada internet. Coba lagi nanti.',
    BackendFailure.unknown => 'Belum bisa menghubungkan. Coba lagi sebentar.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Hubungkan HP',
              variant: CaregiverHeaderVariant.back,
              onBack: () => context.go('/mulai'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
                children: [
                  Text(
                    'Minta kode 6 angka dari orang tua.',
                    style: AppTypography.isi,
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const FormLabel('Kode'),
                  FormTextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: (_) => setState(() => _message = null),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.grid8),
                    Text(
                      _message!,
                      style: AppTypography.meta.copyWith(
                        color: AppColors.saranTeks,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.grid16),
                  PrimaryButton(
                    label: 'Hubungkan',
                    enabled: !_submitting && _code.text.trim().isNotEmpty,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
