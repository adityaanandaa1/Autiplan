import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/auth_service.dart';
import 'data/backend_api.dart';
import 'data/providers.dart';
import 'data/reminder_service.dart';
import 'firebase_options.dart';

/// URL Worker dari `--dart-define=WORKER_URL=...`; kosong bila tidak diisi,
/// mis. saat mendemokan aplikasi tanpa backend.
const _workerUrl = String.fromEnvironment('WORKER_URL');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = fs.FirebaseFirestore.instance;
  db.settings = const fs.Settings(persistenceEnabled: true);
  final auth = FirebaseAuthService(fa.FirebaseAuth.instance);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(auth),
        reminderServiceProvider.overrideWithValue(
          FlutterLocalNotificationsReminderService(),
        ),
        if (_workerUrl.isNotEmpty)
          backendApiProvider.overrideWithValue(
            HttpBackendApi(baseUrl: _workerUrl, authService: auth),
          ),
      ],
      child: const AutiPlanApp(),
    ),
  );
}
