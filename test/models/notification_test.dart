import 'package:flutter_test/flutter_test.dart';
import 'package:sansgato/models/notification.dart';

void main() {
  group('Notification Unit Tests', () {
    test('AppNotification.fromJson parses all fields correctly', () {
      final json = {
        'id': 1,
        'titre': 'Test Titre',
        'message': 'Test Message',
        'type': 'alert',
        'est_lu': true,
        'created_at': '2026-09-09T10:00:00Z'
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 1);
      expect(notif.titre, 'Test Titre');
      expect(notif.message, 'Test Message');
      expect(notif.type, 'alert');
      expect(notif.estLu, isTrue);
      expect(notif.createdAt.year, 2026);
    });

    test('AppNotification.fromJson handles missing optional fields', () {
      final json = {
        'id': 2,
        'created_at': '2026-09-09T10:00:00Z'
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 2);
      expect(notif.titre, ''); // Default
      expect(notif.message, ''); // Default
      expect(notif.type, 'info'); // Default
      expect(notif.estLu, isFalse); // Default
    });
  });
}
