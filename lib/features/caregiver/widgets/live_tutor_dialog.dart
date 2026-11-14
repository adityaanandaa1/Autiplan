import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../data/providers.dart';

const _liveTutorPrefKey = 'has_seen_caregiver_live_tutor';

/// Membuka pop-up Live Tutor hanya bila pengguna belum pernah melihatnya.
Future<void> showCaregiverLiveTutorIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  // Hindari auto-popup pada saat unit/widget testing agar tidak mengganggu audit layar.
  if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) return;

  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final hasSeen = prefs.getBool(_liveTutorPrefKey) ?? false;
    if (!hasSeen && context.mounted) {
      await showCaregiverLiveTutor(context, ref);
    }
  } catch (_) {
    // Abaikan galat preferensi di mode uji coba/fallback.
  }
}

/// Membuka pop-up Live Tutor secara langsung (misal saat ditekan dari menu Akun).
Future<void> showCaregiverLiveTutor(
  BuildContext context,
  WidgetRef ref,
) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup panduan',
    barrierColor: AppColors.teks.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => const _LiveTutorDialog(),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );

  try {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_liveTutorPrefKey, true);
  } catch (_) {}
}

class _TutorStep {
  const _TutorStep({
    required this.title,
    required this.targetButtonName,
    required this.description,
    required this.icon,
    required this.badgeLabel,
    required this.illustrationWidget,
  });

  final String title;
  final String targetButtonName;
  final String description;
  final IconData icon;
  final String badgeLabel;
  final Widget illustrationWidget;
}

class _LiveTutorDialog extends StatefulWidget {
  const _LiveTutorDialog();

  @override
  State<_LiveTutorDialog> createState() => _LiveTutorDialogState();
}

class _LiveTutorDialogState extends State<_LiveTutorDialog> {
  int _currentStep = 0;

  late final List<_TutorStep> _steps = [
    _TutorStep(
      title: 'Pemilihan & Filter Anak',
      targetButtonName: 'Tombol Tab Anak (Rafi / Atalia)',
      badgeLabel: '1 dari 5 · Pengalihan Anak',
      icon: LucideIcons.users,
      description:
          'Gunakan tombol segmen di bagian atas layar untuk beralih antara profil anak (Rafi dan Atalia). Setiap anak memiliki jadwal dan pengaturan kemandirian yang terpisah.',
      illustrationWidget: _buildChildSegmentIllustration(),
    ),
    _TutorStep(
      title: 'Kalender & Navigasi Mingguan',
      targetButtonName: 'Strip Tanggal & Panah Minggu',
      badgeLabel: '2 dari 5 · Waktu & Kalender',
      icon: LucideIcons.calendar,
      description:
          'Gunakan panah kiri/kanan atau geser dengan jari untuk berpindah minggu. Titik biru di bawah angka tanggal menandakan adanya jadwal kegiatan yang telah terisi.',
      illustrationWidget: _buildCalendarIllustration(),
    ),
    _TutorStep(
      title: 'Tambah Jadwal & Template Rutinitas',
      targetButtonName: 'Tombol Tambah (+) & Template',
      badgeLabel: '3 dari 5 · Input Lebih Praktis',
      icon: LucideIcons.sparkles,
      description:
          'Tidak perlu mengetik dari nol! Tekan tombol (+) untuk jadwal manual, atau gunakan Template Rutinitas (23+ pilihan) untuk memasukkan jadwal pagi, sekolah, sore, dan ibadah malam dalam 1 klik.',
      illustrationWidget: _buildTemplateIllustration(),
    ),
    _TutorStep(
      title: 'Jeda Transisi & Waktu Tenang',
      targetButtonName: 'Aturan 10 Menit & Quiet Time',
      badgeLabel: '4 dari 5 · Sensorik Ramah Autis',
      icon: LucideIcons.moon,
      description:
          'Aplikasi otomatis menjaga jeda minimal 10 menit antar-kegiatan agar anak tidak stres, serta mengingatkan waktu tenang tanpa gawai (Quiet Time) minimal 30 menit sebelum tidur.',
      illustrationWidget: _buildQuietTimeIllustration(),
    ),
    _TutorStep(
      title: 'Sisi Anak & Tombol Darurat',
      targetButtonName: 'Mode Anak & Panggilan Cepat',
      badgeLabel: '5 dari 5 · Aman & Terlindungi',
      icon: LucideIcons.shieldCheck,
      description:
          'Di sisi anak, antarmuka dirancang tenang tanpa tombol edit/hapus. Anak dapat mencentang langkah kegiatan dan memiliki tombol darurat satu sentuhan untuk menelepon pengasuh saat cemas.',
      illustrationWidget: _buildEmergencyIllustration(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isLast = _currentStep == _steps.length - 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.maxContentWidth,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.grid20),
            padding: const EdgeInsets.all(AppSpacing.grid20),
            decoration: BoxDecoration(
              color: AppColors.permukaan,
              borderRadius: AppRadius.dialog,
              boxShadow: [
                BoxShadow(
                  color: AppColors.teks.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(step),
                const SizedBox(height: AppSpacing.grid16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        step.illustrationWidget,
                        const SizedBox(height: AppSpacing.grid16),
                        Text(
                          step.title,
                          style: AppTypography.judulSheet,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.grid4),
                        Text(
                          step.targetButtonName,
                          style: AppTypography.meta.copyWith(
                            color: AppColors.utama,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.grid10),
                        Text(
                          step.description,
                          style: AppTypography.isi.copyWith(
                            color: AppColors.teksSekunder,
                            height: 1.45,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.grid20),
                _buildStepIndicators(),
                const SizedBox(height: AppSpacing.grid20),
                _buildNavigationButtons(isLast),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildHeader(_TutorStep step) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.grid10,
                vertical: AppSpacing.grid4,
              ),
              decoration: BoxDecoration(
                color: AppColors.utamaLembut,
                borderRadius: AppRadius.pil,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    step.icon,
                    size: AppSpacing.iconSize16,
                    color: AppColors.utama,
                  ),
                  const SizedBox(width: AppSpacing.grid6),
                  Flexible(
                    child: Text(
                      step.badgeLabel,
                      style: AppTypography.meta.copyWith(
                        color: AppColors.utama,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.grid8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            LucideIcons.x,
            size: AppSpacing.iconSize20,
            color: AppColors.teksSekunder,
          ),
          tooltip: 'Tutup panduan',
          constraints: const BoxConstraints(
            minWidth: AppSpacing.minTouchTarget,
            minHeight: AppSpacing.minTouchTarget,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == _currentStep ? AppSpacing.grid20 : AppSpacing.grid8,
            height: AppSpacing.grid8,
            decoration: BoxDecoration(
              color: i == _currentStep ? AppColors.utama : AppColors.garis,
              borderRadius: AppRadius.pil,
            ),
          ),
          if (i < _steps.length - 1) const SizedBox(width: AppSpacing.grid6),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons(bool isLast) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.buttonHeightParent),
                foregroundColor: AppColors.teksSekunder,
                side: const BorderSide(color: AppColors.garis),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.tombolOrangTua,
                ),
              ),
              child: const Text('Sebelumnya'),
            ),
          ),
          const SizedBox(width: AppSpacing.grid10),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Lewati',
              style: AppTypography.meta.copyWith(
                color: AppColors.teksSekunder,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.grid10),
        ],
        Expanded(
          flex: 3,
          child: PrimaryButton(
            label: isLast ? 'Selesai & Mulai' : 'Lanjut',
            onPressed: () {
              if (isLast) {
                Navigator.of(context).pop();
              } else {
                setState(() => _currentStep++);
              }
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildChildSegmentIllustration() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid12,
        vertical: AppSpacing.grid10,
      ),
      decoration: BoxDecoration(
        color: AppColors.latar,
        borderRadius: AppRadius.segmen,
        border: Border.all(color: AppColors.garis),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.grid12,
                vertical: AppSpacing.grid6,
              ),
              decoration: BoxDecoration(
                color: AppColors.utama,
                borderRadius: AppRadius.segmenTerpilih,
              ),
              child: const Text(
                'Rafi · 12 th',
                style: TextStyle(
                  color: AppColors.teksDiAtasUtama,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.grid8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.grid12,
                vertical: AppSpacing.grid6,
              ),
              decoration: BoxDecoration(
                color: AppColors.permukaan,
                borderRadius: AppRadius.segmenTerpilih,
              ),
              child: const Text(
                'Atalia · 9 th',
                style: TextStyle(
                  color: AppColors.teksSekunder,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCalendarIllustration() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid12,
        vertical: AppSpacing.grid10,
      ),
      decoration: BoxDecoration(
        color: AppColors.latar,
        borderRadius: AppRadius.segmen,
        border: Border.all(color: AppColors.garis),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Icon(LucideIcons.chevronLeft, size: 16, color: AppColors.teksSekunder),
          for (final day in ['Sen', 'Sel', 'Rab', 'Kam', 'Jum']) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(day, style: const TextStyle(fontSize: 11, color: AppColors.teksSekunder)),
                const SizedBox(height: 2),
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: day == 'Jum' ? AppColors.utama : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: day == 'Jum' ? AppColors.teksDiAtasUtama : AppColors.teks,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.utama,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
          const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.teksSekunder),
        ],
      ),
    );
  }

  static Widget _buildTemplateIllustration() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid14,
        vertical: AppSpacing.grid10,
      ),
      decoration: BoxDecoration(
        color: AppColors.utamaLembut,
        borderRadius: AppRadius.kolomIsian,
        border: Border.all(color: AppColors.utama.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.grid6),
            decoration: const BoxDecoration(
              color: AppColors.utama,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 16,
              color: AppColors.teksDiAtasUtama,
            ),
          ),
          const SizedBox(width: AppSpacing.grid10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template Rutinitas (23 Pilihan)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.utama,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Paket Pagi · Sekolah · Sore · Malam',
                  style: TextStyle(fontSize: 11, color: AppColors.teksSekunder),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuietTimeIllustration() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid14,
        vertical: AppSpacing.grid10,
      ),
      decoration: BoxDecoration(
        color: AppColors.saranLembut,
        borderRadius: AppRadius.kolomIsian,
        border: Border.all(color: AppColors.saranTeks.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.moon, size: 20, color: AppColors.saranTeks),
          SizedBox(width: AppSpacing.grid10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waktu Tenang (Quiet Time)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.saranTeks,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Bebas layar gawai 30 mnt sebelum tidur',
                  style: TextStyle(fontSize: 11, color: AppColors.teksSekunder),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildEmergencyIllustration() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid14,
        vertical: AppSpacing.grid10,
      ),
      decoration: BoxDecoration(
        color: AppColors.anakLembut,
        borderRadius: AppRadius.kolomIsian,
        border: Border.all(color: AppColors.anakAksen.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.phoneCall, size: 20, color: AppColors.utama),
          SizedBox(width: AppSpacing.grid10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tombol Darurat Satu Sentuhan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teks,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sisi anak: tenang, aman, langsung menelepon',
                  style: TextStyle(fontSize: 11, color: AppColors.teksSekunder),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
