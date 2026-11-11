import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/calm_snackbar.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../../domain/phone_number.dart';
import 'forms/form_field.dart';
import 'forms/form_utils.dart';

/// Sheet daftar chip (Suka / Hindari), teks bebas maks 5 (§OT-14).
void showProfileListSheet(
  BuildContext context,
  WidgetRef ref,
  Child child,
  String field,
) {
  final isLikes = field == 'Suka';
  final items = [...(isLikes ? child.likes : child.avoids)];
  final input = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        // Menambah isi kolom ke daftar, lalu mengosongkan kolom.
        void addItem(String text) {
          final t = text.trim();
          if (t.isNotEmpty && items.length < 5 && !items.contains(t)) {
            setSheetState(() => items.add(t));
          }
          input.clear();
        }

        return _SheetFrame(
          title: '$field (${child.name})',
          children: [
            Wrap(
              spacing: AppSpacing.grid8,
              runSpacing: AppSpacing.grid8,
              children: items
                  .map(
                    (item) => InputChip(
                      label: Text(item),
                      onDeleted: () => setSheetState(() => items.remove(item)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.grid12),
            Text(
              'Tulis lalu tekan Enter untuk menambah, atau langsung Simpan (maks 5).',
              style: AppTypography.meta,
            ),
            TextField(
              controller: input,
              textInputAction: TextInputAction.done,
              onSubmitted: addItem,
              decoration: const InputDecoration(hintText: 'Tambah item'),
            ),
            const SizedBox(height: AppSpacing.grid16),
            PrimaryButton(
              label: 'Simpan',
              onPressed: () {
                // Teks yang belum ditambah dengan Enter ikut disimpan.
                addItem(input.text);
                final state = ref.read(appStateProvider);
                final current = state.children.firstWhere(
                  (c) => c.id == child.id,
                  orElse: () => child,
                );
                final updated = current.copyWith(
                  likes: isLikes ? items : current.likes,
                  avoids: isLikes ? current.avoids : items,
                );
                ref
                    .read(appStateProvider.notifier)
                    .updateState(
                      state.copyWith(
                        children: [
                          for (final c in state.children)
                            c.id == child.id ? updated : c,
                        ],
                      ),
                    );
                Navigator.of(ctx).pop();
                CalmSnackbar.show(
                  context,
                  message: 'Profil ${child.name} diperbarui',
                );
              },
            ),
            const SizedBox(height: AppSpacing.grid8),
            SecondaryButton(
              label: 'Batal',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    ),
  );
}

/// Sheet pengingat: stepper 5–30 menit.
void showReminderSheet(BuildContext context, WidgetRef ref) {
  final current = ref.read(appStateProvider).settings.reminderMinutesBefore;
  var value = current;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _SheetFrame(
        title: 'Pengingat sebelum kegiatan',
        children: [
          _StepperRow(
            label: 'Sebelum kegiatan',
            value: '$value menit',
            onMinus: () =>
                setSheetState(() => value = (value - 5).clamp(5, 30)),
            onPlus: () => setSheetState(() => value = (value + 5).clamp(5, 30)),
          ),
          const SizedBox(height: AppSpacing.grid16),
          PrimaryButton(
            label: 'Simpan',
            onPressed: () {
              final state = ref.read(appStateProvider);
              ref
                  .read(appStateProvider.notifier)
                  .updateState(
                    state.copyWith(
                      settings: state.settings.copyWith(
                        reminderMinutesBefore: value,
                      ),
                    ),
                  );
              Navigator.of(ctx).pop();
              CalmSnackbar.show(
                context,
                message: 'Pengingat disimpan: $value menit',
              );
            },
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Batal',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Sheet batas saran: tiga stepper (§OT-14).
void showLimitsSheet(BuildContext context, WidgetRef ref) {
  final settings = ref.read(appStateProvider).settings;
  var gap = settings.minGapMinutes;
  var streak = settings.independenceStreakDays;
  var quiet = settings.quietTimeMinutes;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _SheetFrame(
        title: 'Batas saran',
        children: [
          _StepperRow(
            label: 'Jeda minimal',
            value: '$gap mnt',
            onMinus: () => setSheetState(() => gap = (gap - 5).clamp(5, 30)),
            onPlus: () => setSheetState(() => gap = (gap + 5).clamp(5, 30)),
          ),
          _StepperRow(
            label: 'Hari berturut-turut',
            value: '$streak hari',
            onMinus: () =>
                setSheetState(() => streak = (streak - 1).clamp(3, 10)),
            onPlus: () =>
                setSheetState(() => streak = (streak + 1).clamp(3, 10)),
          ),
          _StepperRow(
            label: 'Waktu tenang',
            value: '$quiet mnt',
            onMinus: () =>
                setSheetState(() => quiet = (quiet - 5).clamp(15, 60)),
            onPlus: () =>
                setSheetState(() => quiet = (quiet + 5).clamp(15, 60)),
          ),
          const SizedBox(height: AppSpacing.grid16),
          PrimaryButton(
            label: 'Simpan',
            onPressed: () {
              final state = ref.read(appStateProvider);
              ref
                  .read(appStateProvider.notifier)
                  .updateState(
                    state.copyWith(
                      settings: state.settings.copyWith(
                        minGapMinutes: gap,
                        independenceStreakDays: streak,
                        quietTimeMinutes: quiet,
                      ),
                    ),
                  );
              Navigator.of(ctx).pop();
              CalmSnackbar.show(context, message: 'Batas saran disimpan');
            },
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Batal',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Sheet nomor darurat: dua kolom (§OT-14).
void showEmergencyNumbersSheet(BuildContext context, WidgetRef ref) {
  final settings = ref.read(appStateProvider).settings;
  final primary = TextEditingController(text: settings.emergencyNumber);
  final backup = TextEditingController(text: settings.backupNumber);
  const invalidNumberText = 'Nomor belum sesuai. Contoh: 081234567890.';
  String? primaryError;
  String? backupError;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => _SheetFrame(
        title: 'Nomor darurat',
        children: [
          const Text('Nomor utama', style: AppTypography.meta),
          TextField(
            controller: primary,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '081234567890',
              errorText: primaryError,
            ),
          ),
          const SizedBox(height: AppSpacing.grid12),
          const Text('Kontak cadangan', style: AppTypography.meta),
          TextField(
            controller: backup,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '081298765432',
              errorText: backupError,
            ),
          ),
          const SizedBox(height: AppSpacing.grid16),
          PrimaryButton(
            label: 'Simpan',
            onPressed: () {
              final primaryNumber = normalizePhoneNumber(primary.text);
              final backupNumber = normalizePhoneNumber(backup.text);
              final primaryValid = isValidPhoneNumber(primaryNumber);
              final backupValid =
                  backupNumber.isEmpty || isValidPhoneNumber(backupNumber);
              if (!primaryValid || !backupValid) {
                setSheetState(() {
                  primaryError = primaryValid ? null : invalidNumberText;
                  backupError = backupValid ? null : invalidNumberText;
                });
                return;
              }
              final state = ref.read(appStateProvider);
              ref
                  .read(appStateProvider.notifier)
                  .updateState(
                    state.copyWith(
                      settings: state.settings.copyWith(
                        emergencyNumber: primaryNumber,
                        backupNumber: backupNumber,
                      ),
                    ),
                  );
              Navigator.of(ctx).pop();
              CalmSnackbar.show(context, message: 'Nomor darurat disimpan');
            },
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Batal',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Sheet "Tambah anak": nama lengkap, nama panggilan, umur.
void showAddChildSheet(BuildContext context, WidgetRef ref) =>
    showChildFormSheet(context, ref);

/// Sheet form anak. Tanpa [existing] menambah anak baru; dengan [existing]
/// mengubah nama dan umur anak itu (id, tema, dan profil tetap).
void showChildFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Child? existing,
}) {
  final fullName = TextEditingController(text: existing?.fullName ?? '');
  final nickname = TextEditingController(text: existing?.name ?? '');
  final age = TextEditingController(text: existing?.age.toString() ?? '');

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        final ageValue = RegExp(r'^\d+$').hasMatch(age.text.trim())
            ? int.tryParse(age.text.trim())
            : null;
        final canSave =
            fullName.text.trim().isNotEmpty &&
            nickname.text.trim().isNotEmpty &&
            ageValue != null &&
            ageValue >= 1 &&
            ageValue <= 18;

        return _SheetFrame(
          title: existing == null ? 'Tambah anak' : 'Ubah ${existing.name}',
          children: [
            const FormLabel('Nama lengkap anak'),
            FormTextField(
              controller: fullName,
              onChanged: (_) => setSheetState(() {}),
            ),
            const SizedBox(height: AppSpacing.grid12),
            const FormLabel('Nama panggilan anak'),
            FormTextField(
              controller: nickname,
              onChanged: (_) => setSheetState(() {}),
            ),
            const SizedBox(height: AppSpacing.grid12),
            const FormLabel('Umur anak'),
            FormTextField(
              controller: age,
              keyboardType: TextInputType.number,
              onChanged: (_) => setSheetState(() {}),
            ),
            const SizedBox(height: AppSpacing.grid16),
            PrimaryButton(
              label: 'Simpan',
              enabled: canSave,
              onPressed: () {
                final state = ref.read(appStateProvider);
                final base = existing;
                final List<Child> children;
                if (base == null) {
                  children = [
                    ...state.children,
                    Child(
                      id: generateId('child'),
                      name: nickname.text.trim(),
                      fullName: fullName.text.trim(),
                      age: ageValue!,
                      theme: ChildTheme.lautTenang,
                      likes: const [],
                      avoids: const [],
                    ),
                  ];
                } else {
                  final edited = base.copyWith(
                    name: nickname.text.trim(),
                    fullName: fullName.text.trim(),
                    age: ageValue!,
                  );
                  children = [
                    for (final c in state.children)
                      c.id == base.id ? edited : c,
                  ];
                }
                ref
                    .read(appStateProvider.notifier)
                    .updateState(state.copyWith(children: children));
                Navigator.of(ctx).pop();
              },
            ),
            const SizedBox(height: AppSpacing.grid8),
            SecondaryButton(
              label: 'Batal',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        );
      },
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: AppTypography.judulSheet),
          const SizedBox(height: AppSpacing.grid16),
          ...children,
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.isi)),
          IconButton(
            tooltip: 'Kurangi',
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: AppSpacing.iconSize20),
          ),
          Text(value, style: AppTypography.judulBaris),
          IconButton(
            tooltip: 'Tambah',
            onPressed: onPlus,
            icon: const Icon(Icons.add, size: AppSpacing.iconSize20),
          ),
        ],
      ),
    );
  }
}
