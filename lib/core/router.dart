import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';
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
import '../features/onboarding/profile_setup_screen.dart';
import '../features/role_picker/role_picker_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Akun baru tanpa anak diarahkan mengisi profil dulu.
      final hasChildren = ref.read(appStateProvider).children.isNotEmpty;
      final atProfileSetup = state.matchedLocation == '/profil-awal';
      if (!hasChildren && !atProfileSetup) return '/profil-awal';
      if (hasChildren && atProfileSetup) return '/ortu/beranda';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'rolePicker',
        builder: (context, state) => const RolePickerScreen(),
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
