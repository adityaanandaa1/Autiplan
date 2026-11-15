import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../data/models/app_state.dart';
import '../../../data/providers.dart';
import '../../../domain/routine_templates.dart';

const _liveTutorPrefKey = 'has_seen_caregiver_live_tutor';

/// Membuka pop-up Live Tutor hanya bila pengguna belum pernah melihatnya.
Future<void> showCaregiverLiveTutorIfNeeded(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final hasSeen = prefs.getBool(_liveTutorPrefKey) ?? false;
    if (!hasSeen && context.mounted) {
      await showCaregiverLiveTutor(context, ref);
    }
  } catch (e) {
    debugPrint('Live Tutor: gagal membaca penanda "sudah dilihat": $e');
  }
}

/// Membuka pop-up Live Tutor secara langsung (misal saat ditekan dari menu Akun).
Future<void> showCaregiverLiveTutor(BuildContext context, WidgetRef ref) async {
  // Ambil preferensi sebelum await: widget pemanggil bisa sudah dispose
  // setelah dialog tertutup, sehingga ref tidak aman dipakai lagi.
  SharedPreferences? prefs;
  try {
    prefs = ref.read(sharedPreferencesProvider);
  } catch (e) {
    debugPrint(
      'Live Tutor: preferensi tidak tersedia, penanda tidak disimpan: $e',
    );
  }

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup panduan',
    barrierColor: AppColors.teks.withValues(alpha: AppColors.alphaBayangan),
    transitionDuration: AppDurations.normal,
    pageBuilder: (ctx, anim1, anim2) => const _LiveTutorDialog(),
    transitionBuilder: (ctx, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppDurations.curve);
      return FadeTransition(opacity: curved, child: child);
    },
  );

  if (prefs == null) return;
  try {
    await prefs.setBool(_liveTutorPrefKey, true);
  } catch (e) {
    debugPrint('Live Tutor: gagal menyimpan penanda "sudah dilihat": $e');
  }
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

class _LiveTutorDialog extends ConsumerStatefulWidget {
  const _LiveTutorDialog();

  @override
  ConsumerState<_LiveTutorDialog> createState() => _LiveTutorDialogState();
}

class _LiveTutorDialogState extends ConsumerState<_LiveTutorDialog> {
  int _currentStep = 0;

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  List<_TutorStep> _buildSteps(AppState state) {
    final settings = state.settings;
    final names = state.children.map((c) => c.name).toList();
    final namesText = names.isEmpty ? 'anak' : names.join(' dan ');
    return [
      _TutorStep(
        title: 'Pemilihan & Filter Anak',
        targetButtonName: 'Pemilih Anak di Beranda & Jadwal',
        badgeLabel: '1 dari 5 · Pengalihan Anak',
        icon: LucideIcons.users,
        description:
            'Di tab Beranda (di bawah sapaan) dan tab Jadwal (di bagian atas daftar), ketuk nama anak pada pemilih untuk beralih antara $namesText. Setiap anak memiliki jadwal dan pengaturan kemandirian yang terpisah.',
        illustrationWidget: _buildChildSegmentIllustration(state),
      ),
      _TutorStep(
        title: 'Kalender & Navigasi Mingguan',
        targetButtonName: 'Tab Jadwal: Strip Tanggal & Panah Minggu',
        badgeLabel: '2 dari 5 · Waktu & Kalender',
        icon: LucideIcons.calendar,
        description:
            'Buka tab Jadwal. Gunakan panah kiri/kanan atau geser dengan jari untuk berpindah minggu. Titik kecil di bawah angka tanggal menandakan adanya jadwal kegiatan pada hari itu.',
        illustrationWidget: _buildCalendarIllustration(),
      ),
      _TutorStep(
        title: 'Tambah Jadwal & Template Rutinitas',
        targetButtonName: 'Tombol Tambah (+) di Tab Jadwal',
        badgeLabel: '3 dari 5 · Input Lebih Praktis',
        icon: LucideIcons.sparkles,
        description:
            'Tidak perlu mengetik dari nol! Di tab Jadwal, tekan tombol (+) untuk menambah jadwal, lalu pilih Template Rutinitas (${allRoutineTemplates.length} pilihan kegiatan) untuk memasukkan jadwal pagi, sekolah, sore, dan malam dengan cepat.',
        illustrationWidget: _buildTemplateIllustration(),
      ),
      _TutorStep(
        title: 'Jeda Transisi & Waktu Tenang',
        targetButtonName:
            'Aturan ${settings.minGapMinutes} Menit & Waktu Tenang',
        badgeLabel: '4 dari 5 · Sensorik Ramah Autis',
        icon: LucideIcons.moon,
        description:
            'Aplikasi menjaga jeda minimal ${settings.minGapMinutes} menit antar-kegiatan agar anak tidak stres, serta mengingatkan waktu tenang tanpa gawai (Quiet Time) ${settings.quietTimeMinutes} menit sebelum tidur. Angka ini bisa diubah di tab Akun.',
        illustrationWidget: _buildQuietTimeIllustration(
          settings.quietTimeMinutes,
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(ref.watch(appStateProvider));
    final step = steps[_currentStep];
    final isLast = _currentStep == steps.length - 1;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.grid20),
          child: Material(
            color: AppColors.permukaan,
            elevation: AppSpacing.fabElevation,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.grid20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(step),
                    const SizedBox(height: AppSpacing.grid16),
                    AnimatedSwitcher(
                      duration: AppDurations.normal,
                      switchInCurve: AppDurations.curve,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
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
                              style: AppTypography.isiDetail.copyWith(
                                color: AppColors.teksSekunder,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.grid20),
                    _buildStepIndicators(steps.length),
                    const SizedBox(height: AppSpacing.grid20),
                    _buildNavigationButtons(isLast),
                  ],
                ),
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

  Widget _buildStepIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          AnimatedContainer(
            duration: AppDurations.normal,
            width: i == _currentStep ? AppSpacing.grid20 : AppSpacing.grid8,
            height: AppSpacing.grid8,
            decoration: BoxDecoration(
              color: i == _currentStep ? AppColors.utama : AppColors.garis,
              borderRadius: AppRadius.pil,
            ),
          ),
          if (i < count - 1) const SizedBox(width: AppSpacing.grid6),
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
              style: AppTypography.meta.copyWith(color: AppColors.teksSekunder),
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

  Widget _segment(String label, {required bool selected}) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grid12,
          vertical: AppSpacing.grid6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.utama : AppColors.permukaan,
          borderRadius: AppRadius.segmenTerpilih,
        ),
        child: Text(
          label,
          style: AppTypography.meta.copyWith(
            color: selected
                ? AppColors.teksDiAtasUtama
                : AppColors.teksSekunder,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildChildSegmentIllustration(AppState state) {
    final labels = state.children
        .take(2)
        .map((c) => '${c.name} · ${c.age} th')
        .toList();
    if (labels.isEmpty) labels.add('Nama Anak');
    if (labels.length == 1) labels.add('Anak lain');
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
          _segment(labels[0], selected: true),
          const SizedBox(width: AppSpacing.grid8),
          _segment(labels[1], selected: false),
        ],
      ),
    );
  }

  Widget _buildCalendarIllustration() {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
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
          const Icon(
            LucideIcons.chevronLeft,
            size: AppSpacing.iconSize16,
            color: AppColors.teksSekunder,
          ),
          for (var i = 0; i < 7; i++)
            _calendarDay(
              _dayLabels[i],
              DateTime(monday.year, monday.month, monday.day + i),
              isToday: i == now.weekday - 1,
            ),
          const Icon(
            LucideIcons.chevronRight,
            size: AppSpacing.iconSize16,
            color: AppColors.teksSekunder,
          ),
        ],
      ),
    );
  }

  Widget _calendarDay(String label, DateTime date, {required bool isToday}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.mikro.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.teksSekunder,
          ),
        ),
        const SizedBox(height: AppSpacing.grid2),
        Container(
          width: AppSpacing.grid24,
          height: AppSpacing.grid24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday ? AppColors.utama : AppColors.transparan,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${date.day}',
            style: AppTypography.mikro.copyWith(
              color: isToday ? AppColors.teksDiAtasUtama : AppColors.teks,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.grid2),
        Container(
          width: AppSpacing.weekDot,
          height: AppSpacing.weekDot,
          decoration: BoxDecoration(
            color: isToday ? AppColors.anakAksen : AppColors.transparan,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _illustrationBox({
    required Color color,
    required Color borderColor,
    required Widget leading,
    required String title,
    required String subtitle,
    required Color titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.grid14,
        vertical: AppSpacing.grid10,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.kolomIsian,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: AppSpacing.grid10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.meta.copyWith(
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: AppTypography.mikro.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.teksSekunder,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateIllustration() {
    return _illustrationBox(
      color: AppColors.utamaLembut,
      borderColor: AppColors.utama.withValues(alpha: AppColors.alphaBayangan),
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.grid6),
        decoration: const BoxDecoration(
          color: AppColors.utama,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.sparkles,
          size: AppSpacing.iconSize16,
          color: AppColors.teksDiAtasUtama,
        ),
      ),
      title: 'Template Rutinitas (${allRoutineTemplates.length} Pilihan)',
      subtitle: 'Paket Pagi · Sekolah · Sore · Malam',
      titleColor: AppColors.utama,
    );
  }

  Widget _buildQuietTimeIllustration(int quietMinutes) {
    return _illustrationBox(
      color: AppColors.saranLembut,
      borderColor: AppColors.saranTeks.withValues(
        alpha: AppColors.alphaBayangan,
      ),
      leading: const Icon(
        LucideIcons.moon,
        size: AppSpacing.iconSize20,
        color: AppColors.saranTeks,
      ),
      title: 'Waktu Tenang (Quiet Time)',
      subtitle: 'Bebas layar gawai $quietMinutes mnt sebelum tidur',
      titleColor: AppColors.saranTeks,
    );
  }

  Widget _buildEmergencyIllustration() {
    return _illustrationBox(
      color: AppColors.anakLembut,
      borderColor: AppColors.anakAksen.withValues(
        alpha: AppColors.alphaBayangan,
      ),
      leading: const Icon(
        LucideIcons.phoneCall,
        size: AppSpacing.iconSize20,
        color: AppColors.utama,
      ),
      title: 'Tombol Darurat Satu Sentuhan',
      subtitle: 'Sisi anak: tenang, aman, langsung menelepon',
      titleColor: AppColors.teks,
    );
  }
}
