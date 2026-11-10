import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/domain/suggestion_engine.dart';
import 'package:autiplan/features/caregiver/account_screen.dart';
import 'package:autiplan/features/caregiver/account_sheets.dart';
import 'package:autiplan/features/caregiver/forms/icon_picker_sheet.dart';
import 'package:autiplan/features/caregiver/forms/time_picker_sheet.dart';
import 'package:autiplan/features/caregiver/pairing_sheet.dart';
import 'package:autiplan/features/caregiver/widgets/delete_activity_dialog.dart';
import 'package:autiplan/features/caregiver/widgets/suggestion_detail_sheet.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/features/caregiver/home_screen.dart';
import 'package:autiplan/features/caregiver/notifications_screen.dart';
import 'package:autiplan/features/caregiver/schedule_screen.dart';
import 'package:autiplan/features/caregiver/suggestions_screen.dart';
import 'package:autiplan/features/caregiver/widgets/add_activity_sheet.dart';
import 'package:autiplan/features/caregiver/widgets/edit_activity_sheet.dart';
import 'package:autiplan/features/child/child_activity_screen.dart';
import 'package:autiplan/features/child/child_calling_screen.dart';
import 'package:autiplan/features/child/child_change_screen.dart';
import 'package:autiplan/features/child/child_emergency_screen.dart';
import 'package:autiplan/features/child/child_home_screen.dart';
import 'package:autiplan/features/child/child_success_screen.dart';
import 'package:autiplan/features/child/child_theme_screen.dart';
import 'package:autiplan/features/onboarding/link_device_screen.dart';
import 'package:autiplan/features/onboarding/profile_setup_screen.dart';
import 'package:autiplan/features/onboarding/sign_in_screen.dart';
import 'package:autiplan/features/onboarding/sign_up_screen.dart';
import 'package:autiplan/features/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_backend_api.dart';
import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

// Audit aksesibilitas HANDOFF §14: target sentuh 48 dp, label Semantics pada
// semua yang bisa ditekan, kontras teks, di 360 dp dan skala teks 1.3.
void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    ChildTheme childTheme = ChildTheme.lautTenang,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initializeDateFormatting('id_ID');
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWithValue(testCaregiverSession),
          sharedPreferencesProvider.overrideWithValue(prefs),
          linkedDevicesProvider.overrideWith((ref) => Stream.value(const [])),
          authServiceProvider.overrideWithValue(FakeAuthService()),
          backendApiProvider.overrideWithValue(FakeBackendApi()),
          appStateProvider.overrideWith(
            (ref) =>
                AppStateNotifier(InMemoryRepository(), buildFixtureState()),
          ),
          clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [GoRoute(path: '/', builder: (_, _) => screen)],
          ),
          theme: buildParentTheme(
            childPalette: ChildPalette.fromTheme(childTheme),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  final fixture = buildFixtureState();
  final rafi = fixture.children.firstWhere((c) => c.name == 'Rafi');
  final activity = fixture.activities.firstWhere(
    (a) => a.childId == rafi.id && a.title == 'Les',
    orElse: () => fixture.activities.first,
  );

  final screens = <String, Widget>{
    'Beranda orang tua': const CaregiverHomeScreen(),
    'Jadwal orang tua': const CaregiverScheduleScreen(),
    'Akun orang tua': const CaregiverAccountScreen(),
    'Notifikasi orang tua': const CaregiverNotificationsScreen(),
    'Saran orang tua': const CaregiverSuggestionsScreen(),
    'Form tambah kegiatan': Scaffold(
      body: AddActivitySheet(childId: rafi.id, initialDate: fixtureNow),
    ),
    'Form ubah kegiatan': Scaffold(
      body: EditActivitySheet(activity: activity, child: rafi),
    ),
    'Beranda anak': const ChildHomeScreen(),
    'Kegiatan anak': const ChildActivityScreen(
      activityId: 'rafi-sekolah-20260501',
    ),
    'Sukses anak': const ChildSuccessScreen(
      activityId: 'rafi-sekolah-20260501',
    ),
    'Perubahan anak': const ChildChangeScreen(),
    'Darurat anak': const ChildEmergencyScreen(),
    'Menelepon anak': const ChildCallingScreen(),
    'Tema anak': const ChildThemeScreen(),
    'Selamat datang': const WelcomeScreen(),
    'Masuk': const SignInScreen(),
    'Daftar': const SignUpScreen(),
    'Profil awal': const ProfileSetupScreen(),
    'Tautan HP anak': const LinkDeviceScreen(),
  };

  screens.forEach((name, screen) {
    group(name, () {
      testWidgets('target sentuh minimal 48 dp', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester, screen);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        handle.dispose();
      });
      testWidgets('semua yang bisa ditekan berlabel', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester, screen);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
      testWidgets('kontras teks memadai', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester, screen);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    });
  });

  // Kontras layar anak di ketiga tema (Laut Tenang, Padang Hijau, Pagi Hangat).
  const childScreens = ['Beranda anak', 'Kegiatan anak', 'Sukses anak'];
  for (final theme in ChildTheme.values) {
    for (final name in childScreens) {
      testWidgets('$name kontras di tema ${theme.name}', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester, screens[name]!, childTheme: theme);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }

  // Sheet dan dialog: dibuka setelah frame pertama lewat penolong kecil.
  final sheets = <String, void Function(BuildContext, WidgetRef)>{
    'Pemilih ikon': (c, r) => showIconPickerSheet(c),
    'Pemilih waktu': (c, r) => showDateTimePickerSheet(
      c,
      initialDate: fixtureNow,
      initialStart: const TimeOfDayLite(9, 0),
    ),
    'Dialog hapus': (c, r) =>
        showDeleteActivityDialog(c, activity: activity, childName: rafi.name),
    'Detail saran': (c, r) => showSuggestionDetailSheet(
      c,
      suggestion: generateSuggestions(fixture, fixtureNow, rafi.id).first,
    ),
    'Sheet pengingat': (c, r) => showReminderSheet(c, r),
    'Sheet batas saran': (c, r) => showLimitsSheet(c, r),
    'Sheet nomor darurat': (c, r) => showEmergencyNumbersSheet(c, r),
    'Sheet tambah anak': (c, r) => showAddChildSheet(c, r),
    'Sheet profil Suka': (c, r) => showProfileListSheet(c, r, rafi, 'Suka'),
    'Sheet pairing': (c, r) => showPairingSheet(c, r, rafi),
  };
  sheets.forEach((name, open) {
    group(name, () {
      for (final entry in {
        'target sentuh minimal 48 dp': androidTapTargetGuideline,
        'semua yang bisa ditekan berlabel': labeledTapTargetGuideline,
        'kontras teks memadai': textContrastGuideline,
      }.entries) {
        testWidgets(entry.key, (tester) async {
          final handle = tester.ensureSemantics();
          await pumpScreen(tester, _Opener(open));
          await tester.pump(const Duration(milliseconds: 600));
          expect(
            find.byType(BottomSheet).evaluate().length +
                find.byType(AlertDialog).evaluate().length,
            1,
          );
          await expectLater(tester, meetsGuideline(entry.value));
          handle.dispose();
        });
      }
    });
  });
}

class _Opener extends ConsumerStatefulWidget {
  const _Opener(this.open);
  final void Function(BuildContext, WidgetRef) open;

  @override
  ConsumerState<_Opener> createState() => _OpenerState();
}

class _OpenerState extends ConsumerState<_Opener> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.open(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
