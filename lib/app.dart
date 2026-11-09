import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme/theme.dart';
import 'core/widgets/loading_schedule_screen.dart';
import 'data/models/models.dart';
import 'data/providers.dart';

class AutiPlanApp extends ConsumerStatefulWidget {
  const AutiPlanApp({super.key});

  @override
  ConsumerState<AutiPlanApp> createState() => _AutiPlanAppState();
}

class _AutiPlanAppState extends ConsumerState<AutiPlanApp> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    // Tema anak mengikuti anak yang sedang dipakai; tanpa anak, tema bawaan.
    final childTheme = ref.watch(currentChildProvider.select((c) => c?.theme));
    final childPalette = ChildPalette.fromTheme(
      childTheme ?? ChildTheme.lautTenang,
    );

    final theme = buildParentTheme(childPalette: childPalette);

    // Router baru dibuat setelah data pertama masuk: redirect awalnya
    // bergantung pada ada-tidaknya anak, dan state kosong sebelum itu bukan
    // berarti akun baru.
    if (ref.watch(repositoryReadyProvider).isLoading) {
      return MaterialApp(
        title: 'AutiPlan',
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const LoadingScheduleScreen(),
      );
    }
    final router = _router ??= createRouter(ref);

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
