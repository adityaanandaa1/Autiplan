import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/local_repository.dart';
import 'data/models/models.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final repo = LocalRepository(prefs);

  // Tanpa data tersimpan, pengguna mengisi profil lewat /profil-awal.
  final existingState = await repo.load();
  final initialState = existingState ?? AppState.empty();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialAppStateProvider.overrideWithValue(initialState),
      ],
      child: const AutiPlanApp(),
    ),
  );
}
