import 'dart:async';

import 'package:autiplan/data/providers.dart';
import 'package:autiplan/data/session/device_session.dart';
import 'package:autiplan/data/session/session_notifier.dart';
import 'package:autiplan/features/caregiver/logout_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_service.dart';

class _FailingSignOutAuth extends FakeAuthService {
  @override
  Future<void> signOut() => Future.error(StateError('gagal'));
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<SessionNotifier> pumpRow(
    WidgetTester tester, {
    FakeAuthService? auth,
    Future<void> Function()? beforeSignOut,
  }) async {
    final notifier = SessionNotifier(
      auth ?? FakeAuthService(),
      prefs,
      beforeSignOut: beforeSignOut,
    );
    await notifier.signIn('ortu@example.com', 'password123');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionNotifierProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(home: Scaffold(body: LogoutRow())),
      ),
    );
    return notifier;
  }

  testWidgets('mengetuk Keluar menampilkan konfirmasi, belum keluar', (
    tester,
  ) async {
    final notifier = await pumpRow(tester);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(find.text('Anda yakin untuk keluar?'), findsOneWidget);
    expect(find.text('Ya'), findsOneWidget);
    expect(find.text('Tidak'), findsOneWidget);
    expect(notifier.state, isA<CaregiverSession>());
  });

  testWidgets('Tidak menutup dialog dan sesi tetap', (tester) async {
    final notifier = await pumpRow(tester);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();

    expect(find.text('Anda yakin untuk keluar?'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(notifier.state, isA<CaregiverSession>());
  });

  testWidgets('Ya menampilkan spinner sampai keluar selesai', (tester) async {
    final gate = Completer<void>();
    final notifier = await pumpRow(tester, beforeSignOut: () => gate.future);

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(notifier.state, isA<CaregiverSession>());

    // Ketukan kedua saat loading tidak membuka dialog lagi.
    await tester.tap(find.text('Keluar'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Anda yakin untuk keluar?'), findsNothing);

    gate.complete();
    await tester.pump();
    await tester.pump();

    expect(notifier.state, const UnlinkedSession());
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('keluar gagal: spinner hilang dan muncul pesan tenang', (
    tester,
  ) async {
    final notifier = await pumpRow(tester, auth: _FailingSignOutAuth());

    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya'));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Belum bisa keluar. Coba lagi sebentar.'), findsOneWidget);
    expect(notifier.state, isA<CaregiverSession>());
  });
}
