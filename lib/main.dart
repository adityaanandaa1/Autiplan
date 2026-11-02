import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local_repository.dart';
import 'data/providers.dart';
import 'data/seed.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final repo = LocalRepository(prefs);

  // If repository is empty on first launch, initialize with seed
  final existingState = await repo.load();
  if (existingState == null) {
    await repo.save(buildSeedState());
  }

  final initialState = existingState ?? buildSeedState();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(repo, initialState),
        ),
      ],
      child: const AutiPlanApp(),
    ),
  );
}
