import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Maskot AutiPlan: karakter kalender sederhana (CustomPaint, tanpa aset).
/// Hanya dipakai di layar A-06. Warna dari tema anak, tanpa gradien.
class Mascot extends StatelessWidget {
  const Mascot({super.key, this.size = AppSpacing.mascotSize});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<ChildPalette>()!;
    return Semantics(
      label: 'Maskot AutiPlan',
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _MascotPainter(
          body: AppColors.permukaan,
          band: palette.anakAksen,
          detail: palette.anakAksenKuat,
          cheek: palette.anakAksenLembut,
        ),
      ),
    );
  }
}

// Semua ukuran di bawah adalah pecahan dari sisi kanvas (skala maskot).
class _MascotPainter extends CustomPainter {
  _MascotPainter({
    required this.body,
    required this.band,
    required this.detail,
    required this.cheek,
  });

  final Color body;
  final Color band;
  final Color detail;
  final Color cheek;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bodyRect = Rect.fromLTWH(s * 0.1, s * 0.16, s * 0.8, s * 0.74);
    final bodyShape = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(s * 0.14),
    );

    canvas.drawRRect(bodyShape, Paint()..color = body);

    // Pita atas kalender.
    canvas.save();
    canvas.clipRRect(bodyShape);
    canvas.drawRect(
      Rect.fromLTWH(bodyRect.left, bodyRect.top, bodyRect.width, s * 0.2),
      Paint()..color = band,
    );
    canvas.restore();

    canvas.drawRRect(
      bodyShape,
      Paint()
        ..color = band
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02,
    );

    // Dua cincin penjilid.
    final ring = Paint()
      ..color = detail
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.05;
    for (final x in [0.32, 0.68]) {
      canvas.drawLine(Offset(s * x, s * 0.08), Offset(s * x, s * 0.24), ring);
    }

    // Mata dan senyum.
    final eye = Paint()..color = detail;
    canvas.drawCircle(Offset(s * 0.38, s * 0.55), s * 0.04, eye);
    canvas.drawCircle(Offset(s * 0.62, s * 0.55), s * 0.04, eye);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(s * 0.5, s * 0.62),
        width: s * 0.2,
        height: s * 0.14,
      ),
      0.2,
      2.74,
      false,
      Paint()
        ..color = detail
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.03,
    );

    // Pipi.
    final cheekPaint = Paint()..color = cheek;
    canvas.drawCircle(Offset(s * 0.27, s * 0.64), s * 0.05, cheekPaint);
    canvas.drawCircle(Offset(s * 0.73, s * 0.64), s * 0.05, cheekPaint);
  }

  @override
  bool shouldRepaint(_MascotPainter old) =>
      old.body != body ||
      old.band != band ||
      old.detail != detail ||
      old.cheek != cheek;
}
