import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/clock.dart';
import 'core/router.dart';
import 'core/theme/theme.dart';
import 'core/widgets/loading_schedule_screen.dart';
import 'data/models/models.dart';
import 'domain/reminder_plan.dart';
import 'data/providers.dart';
import 'data/session/device_session.dart';

class AutiPlanApp extends ConsumerStatefulWidget {
  const AutiPlanApp({super.key});

  @override
  ConsumerState<AutiPlanApp> createState() => _AutiPlanAppState();
}

class _AutiPlanAppState extends ConsumerState<AutiPlanApp> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<DeviceSession>(
      sessionProvider,
      (_, next) => _registerPush(next),
      fireImmediately: true,
    );
    ref.listenManual<AppState>(
      appStateProvider,
      (_, _) => _syncReminders(),
      fireImmediately: true,
    );
    ref.listenManual<DeviceSession>(
      sessionProvider,
      (_, _) => _syncReminders(),
    );
  }

  /// Jadwalkan ulang pengingat tiap state berubah; hanya di HP orang tua.
  void _syncReminders() {
    final service = ref.read(reminderServiceProvider);
    final session = ref.read(sessionProvider);
    final Future<void> job = session is CaregiverSession
        ? service.reschedule(
            planReminders(
              ref.read(appStateProvider),
              ref.read(clockProvider).now,
            ),
          )
        : service.cancelAll();
    unawaited(
      job.catchError((Object e) {
        debugPrint('Pengingat belum bisa dijadwalkan: $e');
      }),
    );
  }

  void _registerPush(DeviceSession session) {
    if (session is! CaregiverSession) return;
    unawaited(
      ref
          .read(pushServiceProvider)
          .registerCaregiverDevice(session.familyId)
          .catchError((Object e) {
            debugPrint('Gagal mendaftarkan push orang tua: $e');
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema anak mengikuti anak yang sedang dipakai; tanpa anak, tema bawaan.
    final childTheme = ref.watch(currentChildProvider.select((c) => c?.theme));
    final childPalette = ChildPalette.fromTheme(
      childTheme ?? ChildTheme.lautTenang,
    );

    final theme = buildParentTheme(childPalette: childPalette);

    // Selama data belum dimuat (termasuk setelah sesi berubah), tampilkan
    // teks "Memuat jadwal" supaya anak tidak melihat jadwal kosong sesaat.
    if (ref.watch(repositoryReadyProvider).isLoading) {
      return MaterialApp(
        title: 'AutiPlan',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const LoadingScheduleScreen(),
      );
    }
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AutiPlan',
      debugShowCheckedModeBanner: false,
      theme: theme,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
