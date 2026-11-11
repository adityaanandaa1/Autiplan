import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/account_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late AppStateNotifier notifier;

  Future<void> openSheet(WidgetTester tester, String field) async {
    notifier = AppStateNotifier(InMemoryRepository(), buildFixtureState());
    final child = notifier.state.children.first;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWithValue(testCaregiverSession),
          clockProvider.overrideWithValue(Clock(() => fixtureNow)),
          appStateProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    showProfileListSheet(context, ref, child, field),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('teks yang diketik tanpa Enter ikut tersimpan saat Simpan', (
    tester,
  ) async {
    await openSheet(tester, 'Suka');
    final before = notifier.state.children.first.likes;
    await tester.enterText(find.byType(TextField), 'Menggambar');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(notifier.state.children.first.likes, [...before, 'Menggambar']);
  });

  testWidgets('Enter menambah dan mengosongkan kolom', (tester) async {
    await openSheet(tester, 'Hindari');
    await tester.enterText(find.byType(TextField), 'Suara keras');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Suara keras'), findsOneWidget); // chip, bukan isi kolom
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(notifier.state.children.first.avoids, contains('Suara keras'));
  });
}
