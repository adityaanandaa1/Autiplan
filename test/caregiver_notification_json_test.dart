import 'package:autiplan/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('at ditulis sebagai UTC (berakhiran Z) dan kembali sama persis', () {
    final at = DateTime(2026, 11, 11, 9, 30);
    final n = CaregiverNotification(
      id: 'n1',
      type: NotificationType.emergencyPressed,
      text: 'Rafi menekan tombol bantuan',
      at: at,
      read: false,
    );

    final json = n.toJson();
    expect(json['at'] as String, endsWith('Z'));

    final back = CaregiverNotification.fromJson(json);
    expect(back.at, at);
    expect(back.at.isUtc, isFalse);
  });

  test('data lama tanpa zona waktu tetap terbaca', () {
    final back = CaregiverNotification.fromJson({
      'id': 'n1',
      'type': 'emergencyPressed',
      'text': 't',
      'at': '2026-11-11T09:30:00.000',
      'read': false,
    });
    expect(back.at, DateTime(2026, 11, 11, 9, 30));
  });
}
