import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme/theme.dart';
import 'data/providers.dart';

class AutiPlanApp extends ConsumerStatefulWidget {
  const AutiPlanApp({super.key});

  @override
  ConsumerState<AutiPlanApp> createState() => _AutiPlanAppState();
}

class _AutiPlanAppState extends ConsumerState<AutiPlanApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  @override
  Widget build(BuildContext context) {
    // Watch AppState to retrieve active child theme
    final appState = ref.watch(appStateProvider);
    final rafi = appState.children.firstWhere(
      (c) => c.name.toLowerCase() == 'rafi',
      orElse: () => appState.children.first,
    );
    final childPalette = ChildPalette.fromTheme(rafi.theme);

    return MaterialApp.router(
      title: 'AutiPlan',
      debugShowCheckedModeBanner: false,
      theme: buildParentTheme(childPalette: childPalette),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router,
    );
  }
}
