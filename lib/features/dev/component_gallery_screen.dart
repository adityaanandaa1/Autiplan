import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/activity_icon.dart';

class ComponentGalleryScreen extends ConsumerStatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  ConsumerState<ComponentGalleryScreen> createState() =>
      _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState
    extends ConsumerState<ComponentGalleryScreen> {
  CaregiverTab _currentTab = CaregiverTab.home;
  int _segmentIndex = 0;
  DateTime _selectedDate = DateTime(2026, 5, 1);
  final List<DateTime> _weekDates = List.generate(
    7,
    (i) => DateTime(2026, 4, 27).add(Duration(days: i)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.grid16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'CaregiverHeader - Main',
                CaregiverHeader(
                  title: 'Beranda',
                  showBell: true,
                  bellHasBadge: true,
                  onBellTap: () {},
                ),
              ),
              _buildSection(
                'CaregiverHeader - Back',
                CaregiverHeader(
                  title: 'Notifikasi',
                  variant: CaregiverHeaderVariant.back,
                  onBack: () {},
                ),
              ),
              _buildSection(
                'WeekStrip',
                CardSurface(
                  child: WeekStrip(
                    dates: _weekDates,
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                    },
                    datesWithActivities: {
                      DateTime(2026, 4, 28),
                      DateTime(2026, 5, 1),
                      DateTime(2026, 5, 2),
                    },
                  ),
                ),
              ),
              _buildSection(
                'ChildSegmented',
                ChildSegmented(
                  children: const [
                    ChildSegmentData(name: 'Rafi', age: 12),
                    ChildSegmentData(name: 'Atalia', age: 9),
                  ],
                  selectedIndex: _segmentIndex,
                  onSegmentSelected: (index) {
                    setState(() => _segmentIndex = index);
                  },
                ),
              ),
              _buildSection(
                'DaySummary',
                DaySummary(
                  date: DateTime(2026, 5, 1),
                  completedCount: 1,
                  totalCount: 5,
                ),
              ),
              _buildSection(
                'ActivityRow - Normal',
                ActivityRow(
                  startTime: '18.00',
                  icon: ActivityIcon.ngaji,
                  title: 'Ngaji di Rumah',
                  status: ActivityRowStatus.normal,
                  onTap: () {},
                ),
              ),
              _buildSection(
                'ActivityRow - Now',
                ActivityRow(
                  startTime: '16.00',
                  icon: ActivityIcon.sepeda,
                  title: 'Sepeda Santai',
                  status: ActivityRowStatus.now,
                  onTap: () {},
                ),
              ),
              _buildSection(
                'ActivityRow - Completed',
                ActivityRow(
                  startTime: '07.00',
                  icon: ActivityIcon.sekolah,
                  title: 'Sekolah',
                  status: ActivityRowStatus.completed,
                  onTap: () {},
                ),
              ),
              _buildSection(
                'ActivityRow - Changed',
                ActivityRow(
                  startTime: '20.00',
                  icon: ActivityIcon.nonton,
                  title: 'Nonton film bersama',
                  replacedTitle: 'Les dengan Pak Lana',
                  status: ActivityRowStatus.changed,
                  onTap: () {},
                ),
              ),
              _buildSection(
                'SuggestionCard',
                SuggestionCard(
                  content:
                      'Sepeda Santai selesai tepat waktu 5 hari berturut-turut.',
                  actionLabel: 'Lihat saran',
                  onTap: () {},
                ),
              ),
              _buildSection(
                'ChangeNoticeCard - Unread',
                ChangeNoticeCard(
                  childName: 'Rafi',
                  hasUnread: true,
                  onTap: () {},
                ),
              ),
              _buildSection(
                'ChangeNoticeCard - Seen',
                ChangeNoticeCard(
                  childName: 'Rafi',
                  hasUnread: false,
                  seenAt: DateTime(2026, 5, 1, 16, 0),
                  onTap: () {},
                ),
              ),
              _buildSection(
                'Buttons',
                Column(
                  children: [
                    PrimaryButton(label: 'Tombol Utama', onPressed: () {}),
                    const SizedBox(height: AppSpacing.grid12),
                    SecondaryButton(label: 'Tombol Sekunder', onPressed: () {}),
                    const SizedBox(height: AppSpacing.grid12),
                    DangerButton(label: 'Tombol Bahaya', onPressed: () {}),
                    const SizedBox(height: AppSpacing.grid12),
                    DangerOutlineButton(
                      label: 'Tombol Bahaya Outline',
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.grid12),
                    AppTextButton(label: 'Tombol Teks', onPressed: () {}),
                    const SizedBox(height: AppSpacing.grid12),
                    PrimaryButton(
                      label: 'Tombol Nonaktif',
                      onPressed: () {},
                      enabled: false,
                    ),
                  ],
                ),
              ),
              _buildSection(
                'Sisi anak (Laut Tenang)',
                _buildChildPreview(ChildPalette.lautTenang),
              ),
              _buildSection(
                'Sisi anak (Padang Hijau)',
                _buildChildPreview(ChildPalette.padangHijau),
              ),
              _buildSection(
                'Sisi anak (Pagi Hangat)',
                _buildChildPreview(ChildPalette.pagiHangat),
              ),
              const SizedBox(height: AppSpacing.fabClearance),
            ],
          ),
        ),
      ),
      floatingActionButton: AddFab(
        onPressed: () {
          CalmSnackbar.show(
            context,
            message: 'Jadwal berhasil ditambahkan',
            actionLabel: 'Urungkan',
            onActionPressed: () {},
          );
        },
      ),
      bottomNavigationBar: CaregiverNavBar(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          setState(() => _currentTab = tab);
        },
      ),
    );
  }

  Widget _buildChildPreview(ChildPalette palette) {
    return Theme(
      data: Theme.of(context).copyWith(extensions: [palette]),
      child: Container(
        color: palette.anakLatar,
        padding: const EdgeInsets.all(AppSpacing.screenPaddingChild),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ChildHeader(
              greeting: 'Jumat, 1 Mei',
              childName: 'Halo, Rafi!',
            ),
            ChildBackHeader(title: 'Jadwal kamu berubah', onBack: () {}),
            const SizedBox(height: AppSpacing.sectionGapChild),
            ChildBackHeader(onBack: () {}),
            const SizedBox(height: AppSpacing.sectionGapChild),
            ChildActivityCard(
              icon: ActivityIcon.ngaji,
              title: 'Ngaji di Rumah',
              time: '18.00',
              status: ChildActivityStatus.normal,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sectionGapChild),
            ChildActivityCard(
              icon: ActivityIcon.sepeda,
              title: 'Sepeda Santai',
              time: '16.00',
              status: ChildActivityStatus.now,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sectionGapChild),
            ChildActivityCard(
              icon: ActivityIcon.nonton,
              title: 'Nonton film bersama',
              time: '20.00',
              status: ChildActivityStatus.changed,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.sectionGapChild),
            ChildActivityCard(
              icon: ActivityIcon.sekolah,
              title: 'Sekolah',
              time: '07.00',
              status: ChildActivityStatus.completed,
              onTap: () {},
            ),
            const SizedBox(height: AppSpacing.grid24),
            ChildButton(label: 'Oke, aku mengerti', onPressed: () {}),
            const SizedBox(height: AppSpacing.grid12),
            ChildButton(
              label: 'Telepon kontak cadangan',
              variant: ChildButtonVariant.outline,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.grid12),
            ChildButton(
              label: 'Tidak jadi',
              variant: ChildButtonVariant.text,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.grid12),
            ChildButton(
              label: 'Tombol nonaktif',
              onPressed: null,
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.grid24),
            const Center(child: Mascot()),
            const SizedBox(height: AppSpacing.grid24),
            Align(
              alignment: Alignment.centerRight,
              child: EmergencyButton(onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.grid24),
        Text(title, style: AppTypography.judulBagian),
        const SizedBox(height: AppSpacing.grid12),
        child,
      ],
    );
  }
}
