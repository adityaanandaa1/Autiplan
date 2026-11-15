import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/calm_snackbar.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/auth_service.dart';
import '../../data/providers.dart';

/// `/cek-email`: penjelasan setelah tautan atur ulang kata sandi dikirim.
class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  /// Jeda sebelum tautan boleh dikirim ulang.
  static const resendDelaySeconds = 30;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> {
  Timer? _timer;
  int _secondsLeft = CheckEmailScreen.resendDelaySeconds;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = CheckEmailScreen.resendDelaySeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    String? failure;
    try {
      await ref.read(authServiceProvider).sendPasswordReset(widget.email);
    } on AuthException catch (e) {
      // Email tidak terdaftar tidak boleh terlihat berbeda dari yang berhasil.
      if (e.message != 'Email atau kata sandi belum cocok.') {
        failure = e.message;
      }
    } on Object {
      failure = authFallbackMessage;
    }
    if (!mounted) return;
    setState(() => _sending = false);
    if (failure == null) {
      _startCountdown();
      CalmSnackbar.show(context, message: 'Tautan sudah dikirim ulang.');
    } else {
      CalmSnackbar.show(context, message: failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _secondsLeft > 0;
    return Scaffold(
      backgroundColor: AppColors.permukaan,
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Cek email kamu',
              variant: CaregiverHeaderVariant.back,
              onBack: () => context.go('/masuk'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
                children: [
                  Text(
                    'Kami mengirim tautan ke ${widget.email}, kalau email itu '
                    'terdaftar.',
                    style: AppTypography.isi,
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const _Step(number: 1, text: 'Buka email di HP ini.'),
                  const _Step(number: 2, text: 'Tekan tautan di dalamnya.'),
                  const _Step(number: 3, text: 'Buat kata sandi baru.'),
                  const SizedBox(height: AppSpacing.grid8),
                  Text(
                    'Tidak ketemu? Lihat folder spam.',
                    style: AppTypography.meta.copyWith(
                      color: AppColors.teksSekunder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid24),
                  PrimaryButton(
                    label: waiting
                        ? 'Kirim ulang tautan ($_secondsLeft)'
                        : 'Kirim ulang tautan',
                    enabled: !waiting && !_sending,
                    onPressed: _resend,
                  ),
                  const SizedBox(height: AppSpacing.grid12),
                  SecondaryButton(
                    label: 'Kembali ke Masuk',
                    onPressed: () => context.go('/masuk'),
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

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grid8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.grid24,
            child: Text('$number.', style: AppTypography.judulBaris),
          ),
          Expanded(child: Text(text, style: AppTypography.isi)),
        ],
      ),
    );
  }
}
