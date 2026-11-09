import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/core/widgets/widgets.dart';
import 'package:autiplan/data/models/activity_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: buildParentTheme(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

ChildActivityCard _card(ChildActivityStatus status) => ChildActivityCard(
  icon: ActivityIcon.sepeda,
  title: 'Sepeda Santai',
  time: '16.00',
  status: status,
);

void main() {
  group('ChildActivityCard', () {
    testWidgets('Biasa: tanpa label dan tanpa ikon selesai', (tester) async {
      await tester.pumpWidget(_wrap(_card(ChildActivityStatus.normal)));
      expect(find.text('SEKARANG'), findsNothing);
      expect(find.text('BARU BERUBAH'), findsNothing);
      expect(find.text('SELESAI'), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('Sekarang: label SEKARANG dan tepi 2 px', (tester) async {
      await tester.pumpWidget(_wrap(_card(ChildActivityStatus.now)));
      expect(find.text('SEKARANG'), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ChildActivityCard),
              matching: find.byType(Material),
            )
            .first,
      );
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.side.width, AppSpacing.strokeAccent);
    });

    testWidgets('Berubah: label BARU BERUBAH tanpa tepi', (tester) async {
      await tester.pumpWidget(_wrap(_card(ChildActivityStatus.changed)));
      expect(find.text('BARU BERUBAH'), findsOneWidget);
      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ChildActivityCard),
              matching: find.byType(Material),
            )
            .first,
      );
      final shape = material.shape! as RoundedRectangleBorder;
      expect(shape.side, BorderSide.none);
    });

    testWidgets('Selesai: tanpa teks label, blok ikon opasitas 60%', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_card(ChildActivityStatus.completed)));
      expect(find.text('SELESAI'), findsNothing);
      expect(find.text('SEKARANG'), findsNothing);
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, AppColors.alphaSelesai);
    });
  });

  group('CalmSnackbar', () {
    Future<void> show(WidgetTester tester, {String? action}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildParentTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => CalmSnackbar.show(
                  context,
                  message: 'Tersimpan',
                  actionLabel: action,
                  onActionPressed: () {},
                ),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('tanpa aksi: 4 detik, tinggi 48', (tester) async {
      await show(tester);
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.duration, const Duration(seconds: 4));
      final surface = find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first;
      expect(tester.getSize(surface).height, AppSpacing.snackbarHeight);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Tersimpan'), findsNothing);
    });

    testWidgets('dengan aksi: 5 detik, hilang sendiri', (tester) async {
      await show(tester, action: 'Urungkan');
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.duration, const Duration(seconds: 5));
      expect(find.text('Urungkan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Tersimpan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Tersimpan'), findsNothing);
    });
  });

  group('ActivityRow Diubah', () {
    ActivityRow row({String? replaced, String? subtitle}) => ActivityRow(
      startTime: '20.00',
      icon: ActivityIcon.nonton,
      title: 'Nonton film bersama',
      status: ActivityRowStatus.changed,
      replacedTitle: replaced,
      subtitle: subtitle,
    );

    testWidgets('menampilkan Pengganti {judul lama}', (tester) async {
      await tester.pumpWidget(_wrap(row(replaced: 'Les dengan Pak Lana')));
      expect(find.text('Diubah'), findsOneWidget);
      expect(find.text('Pengganti Les dengan Pak Lana'), findsOneWidget);
    });

    testWidgets('tanpa judul lama tidak ada keterangan', (tester) async {
      await tester.pumpWidget(_wrap(row()));
      expect(find.textContaining('Pengganti'), findsNothing);
    });
  });
}
