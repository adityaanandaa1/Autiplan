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
import '../common/backend_failure_message.dart';

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
    if (_submitting) return;
    final code = _code.text.trim();
    // Ambil semua dependensi sebelum await: notifier sesi hidup lebih lama
    // daripada layar ini, jadi klaim yang sukses selalu membentuk sesi.
    final auth = ref.read(authServiceProvider);
    final backend = ref.read(backendApiProvider);
    final session = ref.read(sessionNotifierProvider.notifier);
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await auth.signInAnonymously();
      final link = await backend.claimPairingCode(code);
      session.adoptChildSession(familyId: link.familyId, childId: link.childId);
      // Sesi berganti; router mengarahkan ke /anak.
    } on AuthException catch (e) {
      _show(e.message);
    } on BackendException catch (e) {
      _show(e.failure.claimMessage);
    } on Object {
      _show(BackendFailure.unknown.claimMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _show(String message) {
    if (mounted) setState(() => _message = message);
  }

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
