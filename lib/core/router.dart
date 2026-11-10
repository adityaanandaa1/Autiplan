import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
import '../data/session/device_session.dart';
import '../features/caregiver/account_screen.dart';
import '../features/caregiver/caregiver_shell.dart';
import '../features/caregiver/home_screen.dart';
import '../features/caregiver/notifications_screen.dart';
import '../features/caregiver/schedule_screen.dart';
import '../features/caregiver/suggestions_screen.dart';
import '../features/child/child_activity_screen.dart';
import '../features/child/child_calling_screen.dart';
import '../features/child/child_change_screen.dart';
import '../features/child/child_emergency_screen.dart';
import '../features/child/child_home_screen.dart';
import '../features/child/child_success_screen.dart';
import '../features/child/child_theme_screen.dart';
import '../features/onboarding/link_device_screen.dart';
import '../features/onboarding/profile_setup_screen.dart';
import '../features/onboarding/sign_in_screen.dart';
import '../features/onboarding/sign_up_screen.dart';
import '../features/onboarding/welcome_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Router aplikasi. Dibuat lewat provider supaya redirect dievaluasi ulang
/// saat sesi atau jumlah anak berubah (lewat [refreshListenable]).
final routerProvider = Provider<GoRouter>((ref) => createRouter(ref));

GoRouter createRouter(Ref ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final hasChildren = ref.read(appStateProvider).children.isNotEmpty;
      return redirectFor(
        session,
        path: state.matchedLocation,
        hasChildren: hasChildren,
      );
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(
        path: '/mulai',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/masuk',
        name: 'signIn',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/daftar',
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/hubungkan',
        name: 'linkDevice',
        builder: (context, state) => const LinkDeviceScreen(),
      ),

      GoRoute(
        path: '/profil-awal',
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ── Caregiver shell with bottom nav ───────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CaregiverShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ortu/beranda',
                name: 'caregiverHome',
                builder: (context, state) => const CaregiverHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ortu/jadwal',
                name: 'caregiverSchedule',
                builder: (context, state) => const CaregiverScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ortu/akun',
                name: 'caregiverAccount',
                builder: (context, state) => const CaregiverAccountScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Caregiver stand-alone routes (no bottom nav) ──────────────
      GoRoute(
        path: '/ortu/notifikasi',
        name: 'caregiverNotifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaregiverNotificationsScreen(),
      ),
      GoRoute(
        path: '/ortu/saran',
        name: 'caregiverSuggestions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CaregiverSuggestionsScreen(),
      ),

      // ── Child routes ──────────────────────────────────────────────
      GoRoute(
        path: '/anak',
        name: 'childHome',
        builder: (context, state) => const ChildHomeScreen(),
      ),
      GoRoute(
        path: '/anak/perubahan',
        name: 'childChanges',
        builder: (context, state) => const ChildChangeScreen(),
      ),
      GoRoute(
        path: '/anak/aktivitas/:id',
        name: 'childActivityDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChildActivityScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/anak/berhasil/:id',
        name: 'childSuccess',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ChildSuccessScreen(activityId: id);
        },
      ),
      GoRoute(
        path: '/anak/darurat',
        name: 'childEmergency',
        builder: (context, state) => const ChildEmergencyScreen(),
      ),
      GoRoute(
        path: '/anak/menelepon',
        name: 'childCalling',
        builder: (context, state) => const ChildCallingScreen(),
      ),
      GoRoute(
        path: '/anak/tema',
        name: 'childTheme',
        builder: (context, state) => const ChildThemeScreen(),
      ),
    ],
  );
}

/// Menghasilkan rute tujuan dari sesi. Lihat tabel redirectFor di rencana.
String? redirectFor(
  DeviceSession session, {
  required String path,
  required bool hasChildren,
}) {
  switch (session) {
    case UnlinkedSession():
      if (path == '/mulai' ||
          path == '/masuk' ||
          path == '/daftar' ||
          path == '/hubungkan') {
        return null;
      }
      return '/mulai';

    case CaregiverSession():
      if (!hasChildren) {
        return path == '/profil-awal' ? null : '/profil-awal';
      }
      if (_isStart(path) ||
          _isAuth(path) ||
          _isChildPath(path) ||
          path == '/profil-awal') {
        return '/ortu/beranda';
      }
      return null;

    case ChildSession():
      return _isChildPath(path) ? null : '/anak';
  }
}

bool _isStart(String path) => path == '/';

bool _isAuth(String path) =>
    path == '/mulai' ||
    path.startsWith('/mulai/') ||
    path == '/masuk' ||
    path == '/daftar' ||
    path == '/hubungkan';

bool _isChildPath(String path) => path == '/anak' || path.startsWith('/anak/');

/// Memberi tahu GoRouter untuk mengevaluasi ulang redirect saat sesi atau
/// jumlah anak berubah, tanpa membuat ulang router.
final _routerRefreshProvider = Provider<Listenable>((ref) {
  final notifier = _RouterRefresh();
  ref.onDispose(notifier.dispose);
  ref.listen(sessionProvider, (_, _) => notifier.refresh());
  ref.listen(
    appStateProvider.select((s) => s.children.length),
    (_, _) => notifier.refresh(),
  );
  return notifier;
});

class _RouterRefresh extends ChangeNotifier {
  // `notifyListeners` itu protected; ini pintu publik untuk provider di atas.
  void refresh() => notifyListeners();
}
