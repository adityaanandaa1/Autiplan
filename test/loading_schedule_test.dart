import 'support/test_session.dart';
import 'dart:async';

import 'package:autiplan/app.dart';
import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';

/// Repositori yang baru memancarkan data saat tes menyuruhnya.
class _ManualRepository extends InMemoryRepository {
  final controller = StreamController<AppState>();

  @override
  Stream<AppState> watch() => controller.stream;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets(
    'sebelum data pertama tampil teks "Memuat jadwal", bukan jadwal kosong',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _ManualRepository();
      addTearDown(repo.controller.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWithValue(testCaregiverSession),
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider.overrideWithValue(Clock(() => fixtureNow)),
            repositoryProvider.overrideWithValue(repo),
          ],
          child: const AutiPlanApp(),
        ),
      );
      await tester.pump();

      expect(find.text('Memuat jadwal'), findsOneWidget);
      expect(find.text('Belum ada jadwal.'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      repo.controller.add(AppState.empty());
      await tester.pumpAndSettle();

      expect(find.text('Memuat jadwal'), findsNothing);
    },
  );
}
