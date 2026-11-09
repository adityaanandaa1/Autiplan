import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/phone_number.dart';
import '../caregiver/forms/form_field.dart';
import '../caregiver/forms/form_utils.dart';

/// `/profil-awal`: isi profil pengasuh dan anak pertama (akun baru).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _caregiverName = TextEditingController();
  final _childFullName = TextEditingController();
  final _childNickname = TextEditingController();
  final _childAge = TextEditingController();
  final _emergencyNumber = TextEditingController();
  final _backupNumber = TextEditingController();

  String? _emergencyError;
  String? _backupError;

  static const _phoneErrorText = 'Nomor belum sesuai. Contoh: 081234567890.';
  static const _maxNameLength = 40;
  static const _minAge = 1;
  static const _maxAge = 18;

  @override
  void dispose() {
    _caregiverName.dispose();
    _childFullName.dispose();
    _childNickname.dispose();
    _childAge.dispose();
    _emergencyNumber.dispose();
    _backupNumber.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _caregiverName.text.trim().isNotEmpty &&
      _childFullName.text.trim().isNotEmpty &&
      _childNickname.text.trim().isNotEmpty &&
      _age != null &&
      _emergencyNumber.text.trim().isNotEmpty;

  /// Umur yang sah, atau null. Hanya digit, karena `int.tryParse` menerima
  /// tanda dan heksadesimal.
  int? get _age {
    final raw = _childAge.text.trim();
    if (!RegExp(r'^\d+$').hasMatch(raw)) return null;
    final age = int.tryParse(raw);
    if (age == null || age < _minAge || age > _maxAge) return null;
    return age;
  }

  void _save() {
    final emergency = normalizePhoneNumber(_emergencyNumber.text);
    final backup = normalizePhoneNumber(_backupNumber.text);
    final emergencyValid = isValidPhoneNumber(emergency);
    final backupValid = backup.isEmpty || isValidPhoneNumber(backup);
    setState(() {
      _emergencyError = emergencyValid ? null : _phoneErrorText;
      _backupError = backupValid ? null : _phoneErrorText;
    });
    if (!emergencyValid || !backupValid) return;

    final childId = generateId('child');
    final child = Child(
      id: childId,
      name: _childNickname.text.trim(),
      fullName: _childFullName.text.trim(),
      age: _age!,
      theme: ChildTheme.lautTenang,
      likes: const [],
      avoids: const [],
    );

    final state = ref.read(appStateProvider);
    final updated = state.copyWith(
      children: [child],
      settings: state.settings.copyWith(
        caregiverName: _caregiverName.text.trim(),
        emergencyNumber: emergency,
        backupNumber: backup,
      ),
    );

    ref.read(appStateProvider.notifier).updateState(updated);
    ref.read(selectedChildIdProvider.notifier).state = childId;
    context.go('/ortu/beranda');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            const CaregiverHeader(title: 'Kenalan dulu'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
                children: [
                  const FormLabel('Nama panggilan kamu'),
                  FormTextField(
                    controller: _caregiverName,
                    hint: 'Bu Sari',
                    maxLength: _maxNameLength,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const FormLabel('Nama lengkap anak'),
                  FormTextField(
                    controller: _childFullName,
                    maxLength: _maxNameLength,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const FormLabel('Nama panggilan anak'),
                  FormTextField(
                    controller: _childNickname,
                    maxLength: _maxNameLength,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const FormLabel('Umur anak'),
                  FormTextField(
                    controller: _childAge,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const FormLabel('Nomor darurat'),
                  FormTextField(
                    controller: _emergencyNumber,
                    keyboardType: TextInputType.phone,
                    errorText: _emergencyError,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const FormLabel('Kontak cadangan', optional: 'opsional'),
                  FormTextField(
                    controller: _backupNumber,
                    keyboardType: TextInputType.phone,
                    errorText: _backupError,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.grid24),
                  PrimaryButton(
                    label: 'Mulai pakai AutiPlan',
                    enabled: _canSave,
                    onPressed: _save,
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
