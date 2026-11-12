import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend_api.dart';
import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late AppStateNotifier notifier;

  Widget wrap({int childCount = 2}) {
    final rafi = buildFixtureState().children.first.copyWith(
      id: 'child-1',
      name: 'Rafi',
      fullName: 'Rafi Pratama',
    );
    final children = [
      rafi,
      if (childCount > 1)
        rafi.copyWith(id: 'child-2', name: 'Atalia', fullName: 'Atalia Putri'),
    ];
    notifier = AppStateNotifier(
      InMemoryRepository(),
      buildFixtureState().copyWith(children: children),
    );
    return ProviderScope(
      overrides: [
        sessionProvider.overrideWithValue(testCaregiverSession),
        clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        backendApiProvider.overrideWithValue(FakeBackendApi()),
        linkedDevicesProvider.overrideWith((ref) => Stream.value(const [])),
        appStateProvider.overrideWith((ref) => notifier),
      ],
      child: const MaterialApp(home: CaregiverAccountScreen()),
    );
  }

  Future<void> openList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Daftar anak'));
    await tester.tap(find.text('Daftar anak'));
    await tester.pumpAndSettle();
  }

  testWidgets('daftar menampilkan setiap anak dengan aksi ubah dan hapus', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await openList(tester);
    // Layar Akun tidak lagi menampilkan nama lengkap, jadi hanya di sheet.
    expect(find.text('Rafi Pratama'), findsOneWidget);
    expect(find.text('Atalia Putri'), findsOneWidget);
    expect(find.byTooltip('Ubah Atalia'), findsOneWidget);
    expect(find.byTooltip('Hapus Atalia'), findsOneWidget);
  });

  testWidgets('ubah: nama panggilan baru tersimpan', (tester) async {
    await tester.pumpWidget(wrap());
    await openList(tester);
    await tester.tap(find.byTooltip('Ubah Atalia'));
    await tester.pumpAndSettle();
    expect(find.text('Ubah Atalia'), findsOneWidget);
    final nickname = find.widgetWithText(TextField, 'Atalia');
    await tester.enterText(nickname, 'Talia');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(notifier.state.children.map((c) => c.name), ['Rafi', 'Talia']);
    expect(notifier.state.children.last.id, 'child-2');
  });

  testWidgets('hapus: anak dan jadwalnya hilang setelah konfirmasi', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    final before = notifier.state.activities.length;
    await openList(tester);
    await tester.tap(find.byTooltip('Hapus Atalia'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Atalia?'), findsOneWidget);
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(notifier.state.children.map((c) => c.id), ['child-1']);
    expect(
      notifier.state.activities.where((a) => a.childId == 'child-2'),
      isEmpty,
    );
    expect(notifier.state.activities.length, lessThanOrEqualTo(before));
  });

  testWidgets('batal hapus tidak mengubah apa pun', (tester) async {
    await tester.pumpWidget(wrap());
    await openList(tester);
    await tester.tap(find.byTooltip('Hapus Atalia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(notifier.state.children.length, 2);
  });

  testWidgets('anak satu-satunya tidak bisa dihapus', (tester) async {
    await tester.pumpWidget(wrap(childCount: 1));
    await openList(tester);
    expect(find.byTooltip('Ubah Rafi'), findsOneWidget);
    expect(find.byTooltip('Hapus Rafi'), findsNothing);
  });

  testWidgets('Suka dan Hindari dipilih per anak dari daftar', (tester) async {
    await tester.pumpWidget(wrap());
    await openList(tester);
    // Anak kedua (Atalia): tombol Suka ke-2 dalam daftar.
    await tester.tap(find.textContaining('Suka (').last);
    await tester.pumpAndSettle();
    expect(find.text('Suka (Atalia)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Menggambar');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    final atalia = notifier.state.children.last;
    expect(atalia.likes, contains('Menggambar'));
    expect(notifier.state.children.first.likes, isNot(contains('Menggambar')));
  });
}
