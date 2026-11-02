import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/placeholder_screen.dart';
import '../features/caregiver/account_screen.dart';
import '../features/caregiver/caregiver_shell.dart';
import '../features/caregiver/home_screen.dart';
import '../features/caregiver/notifications_screen.dart';
import '../features/caregiver/schedule_screen.dart';
import '../features/caregiver/suggestions_screen.dart';
import '../features/dev/component_gallery_screen.dart';
import '../features/role_picker/role_picker_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'rolePicker',
        builder: (context, state) => const RolePickerScreen(),
      ),

      // ── Dev only ───────────────────────────────────────────────────
      if (kDebugMode)
        GoRoute(
          path: '/dev/komponen',
          name: 'componentGallery',
          builder: (context, state) => const ComponentGalleryScreen(),
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
        builder: (context, state) => const PlaceholderScreen(
          title: 'Jadwal Hari Ini',
          showBackButton: false,
          isChild: true,
          showRoleSwitch: true,
        ),
      ),
      GoRoute(
        path: '/anak/perubahan',
        name: 'childChanges',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Perubahan Jadwal',
          fallbackRoute: '/anak',
          isChild: true,
        ),
      ),
      GoRoute(
        path: '/anak/aktivitas/:id',
        name: 'childActivityDetail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlaceholderScreen(
            title: 'Detail Aktivitas ($id)',
            fallbackRoute: '/anak',
            isChild: true,
          );
        },
      ),
      GoRoute(
        path: '/anak/berhasil/:id',
        name: 'childSuccess',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlaceholderScreen(
            title: 'Berhasil ($id)',
            fallbackRoute: '/anak',
            isChild: true,
          );
        },
      ),
      GoRoute(
        path: '/anak/darurat',
        name: 'childEmergency',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Butuh Bantuan?',
          fallbackRoute: '/anak',
          isChild: true,
        ),
      ),
      GoRoute(
        path: '/anak/menelepon',
        name: 'childCalling',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Menelepon Pengasuh',
          fallbackRoute: '/anak',
          isChild: true,
        ),
      ),
      GoRoute(
        path: '/anak/tema',
        name: 'childTheme',
        builder: (context, state) => const PlaceholderScreen(
          title: 'Pilih Tema',
          fallbackRoute: '/anak',
          isChild: true,
        ),
      ),
    ],
  );
}
