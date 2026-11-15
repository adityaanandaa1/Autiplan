import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/features/caregiver/forms/form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildParentTheme(),
  home: Scaffold(
    backgroundColor: AppColors.permukaan,
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

Container _boxOf(WidgetTester tester) => tester.widget<Container>(
  find
      .descendant(of: find.byType(FormBox), matching: find.byType(Container))
      .first,
);

Color _ringColor(WidgetTester tester) =>
    ((_boxOf(tester).foregroundDecoration! as BoxDecoration).border! as Border)
        .top
        .color;

void main() {
  testWidgets('tema tidak memberi garis tepi bawaan pada kolom isian', (
    tester,
  ) async {
    final theme = buildParentTheme().inputDecorationTheme;
    expect(theme.filled, isFalse);
    expect(theme.border, InputBorder.none);
    expect(theme.enabledBorder, InputBorder.none);
    expect(theme.focusedBorder, InputBorder.none);
  });

  testWidgets('FormTextField tanpa oval; cincin hanya saat aktif', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(FormTextField(controller: controller)));

    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.border, InputBorder.none);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(decoration.filled, isFalse);

    expect(_ringColor(tester), AppColors.transparan);
    expect(
      (_boxOf(tester).decoration! as BoxDecoration).color,
      AppColors.latar,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(_ringColor(tester), AppColors.utama);
    expect(
      ((_boxOf(tester).foregroundDecoration! as BoxDecoration).border!
              as Border)
          .top
          .width,
      AppSpacing.strokeFocus,
    );

    // Fokus tidak boleh membuat ulang TextField: teks tetap bisa diketik.
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    expect(controller.text, '123');

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(_ringColor(tester), AppColors.transparan);
  });

  testWidgets('teks berada di tengah kotak setinggi 48', (tester) async {
    final controller = TextEditingController(text: 'Halo');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(FormTextField(controller: controller)));

    final box = tester.getRect(find.byType(FormBox));
    final text = tester.getRect(find.byType(EditableText));
    expect(box.height, AppSpacing.minTouchTarget);
    expect(text.center.dy, closeTo(box.center.dy, 1.0));
  });
}
