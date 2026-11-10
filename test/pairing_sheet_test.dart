import 'package:autiplan/data/backend_api.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/pairing_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_backend_api.dart';
import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';

class _RecordingRepository extends InMemoryRepository {
  final List<String> unlinked = [];
  Object? unlinkError;

  @override
  Future<void> unlinkChildDevice(String childId) async {
    final e = unlinkError;
    if (e != null) throw e;
    unlinked.add(childId);
  }
}

void main() {
  late FakeBackendApi backend;
  late _RecordingRepository repo;
  late Child rafi;

  setUp(() {
    backend = FakeBackendApi();
    repo = _RecordingRepository();
    rafi = buildFixtureState().children.first.copyWith(id: 'c1', name: 'Rafi');
  });

  Widget host(void Function(BuildContext, WidgetRef) onTap) => ProviderScope(
    overrides: [
      backendApiProvider.overrideWithValue(backend),
      repositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => onTap(context, ref),
            child: const Text('buka'),
          ),
        ),
      ),
    ),
  );

  testWidgets('sheet menampilkan kode 654321; Buat kode baru membuat ulang', (
    tester,
  ) async {
    await tester.pumpWidget(host((c, r) => showPairingSheet(c, r, rafi)));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text('Hubungkan HP Rafi'), findsOneWidget);
    expect(find.text('654321'), findsOneWidget);
    expect(backend.createCalls, 1);

    backend.code = '111222';
    await tester.tap(find.text('Buat kode baru'));
    await tester.pumpAndSettle();
    expect(backend.createCalls, 2);
    expect(find.text('111222'), findsOneWidget);
  });

  testWidgets('galat create ditampilkan tenang', (tester) async {
    backend.nextFailure = BackendFailure.offline;
    await tester.pumpWidget(host((c, r) => showPairingSheet(c, r, rafi)));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada internet. Coba lagi nanti.'), findsOneWidget);
    expect(find.text('654321'), findsNothing);
  });

  testWidgets('Putuskan memanggil unlinkChildDevice dan menyatakan berhasil', (
    tester,
  ) async {
    await tester.pumpWidget(host((c, r) => showUnlinkDialog(c, r, rafi)));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.text('Putuskan HP Rafi?'), findsOneWidget);
    await tester.tap(find.text('Putuskan'));
    await tester.pumpAndSettle();
    expect(repo.unlinked, ['c1']);
    expect(find.text('HP Rafi sudah diputuskan'), findsOneWidget);
  });

  testWidgets('Batal tidak memutuskan', (tester) async {
    await tester.pumpWidget(host((c, r) => showUnlinkDialog(c, r, rafi)));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(repo.unlinked, isEmpty);
  });

  testWidgets('putus gagal: pesan tenang, bukan "sudah diputuskan"', (
    tester,
  ) async {
    repo.unlinkError = Exception('x');
    await tester.pumpWidget(host((c, r) => showUnlinkDialog(c, r, rafi)));
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Putuskan'));
    await tester.pumpAndSettle();
    expect(find.text('HP Rafi sudah diputuskan'), findsNothing);
    expect(
      find.text('Belum bisa memutuskan. Coba lagi sebentar.'),
      findsOneWidget,
    );
  });
}
