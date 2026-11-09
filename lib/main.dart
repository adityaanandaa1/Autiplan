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

  // Akun baru mulai dari data kosong; pengguna mengisi profil lewat
  // /profil-awal. Data lama yang tersimpan tetap dipakai bila ada.
  final existingState = await repo.load();
  final initialState = existingState ?? AppState.empty();

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
