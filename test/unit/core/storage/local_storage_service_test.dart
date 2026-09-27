import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thaheen_lms/core/storage/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageService Unit Tests (AAA Pattern)', () {
    test('getString returns stored value when key exists', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'test_key': 'test_value'});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      // Act
      final result = storage.getString('test_key');

      // Assert
      expect(result, equals('test_value'));
    });

    test('setString persists value to SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      // Act
      final success = await storage.setString('new_key', 'hello');
      final retrieved = storage.getString('new_key');

      // Assert
      expect(success, isTrue);
      expect(retrieved, equals('hello'));
    });

    test('remove deletes value from SharedPreferences', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'to_delete': 'val'});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      // Act
      final success = await storage.remove('to_delete');
      final retrieved = storage.getString('to_delete');

      // Assert
      expect(success, isTrue);
      expect(retrieved, isNull);
    });

    test('clear removes all entries', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'k1': 'v1', 'k2': 'v2'});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      // Act
      final success = await storage.clear();

      // Assert
      expect(success, isTrue);
      expect(storage.getString('k1'), isNull);
      expect(storage.getString('k2'), isNull);
    });

    test(
      'getProgressEnvelopeJson returns empty map when key is absent',
      () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final storage = LocalStorageService(prefs);

        // Act
        final envelope = storage.getProgressEnvelopeJson();

        // Assert
        expect(envelope, isEmpty);
      },
    );

    test('getProgressEnvelopeJson decodes valid JSON correctly', () async {
      // Arrange
      const jsonEnvelope =
          '{"schemaVersion":1,"records":{"l1":{"lastPositionSec":45}}}';
      SharedPreferences.setMockInitialValues({
        LocalStorageService.progressKey: jsonEnvelope,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      // Act
      final envelope = storage.getProgressEnvelopeJson();

      // Assert
      expect(envelope['schemaVersion'], equals(1));
      expect(envelope['records'], isA<Map<String, dynamic>>());
      expect(envelope['records']['l1']['lastPositionSec'], equals(45));
    });

    test('getProgressEnvelopeJson recovers gracefully on corrupt JSON and resets storage', () async {
      // Arrange
      const corruptData = 'INVALID_NOT_JSON_DATA{{{';
      SharedPreferences.setMockInitialValues({
        LocalStorageService.progressKey: corruptData,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      bool callbackInvoked = false;

      // Act
      final envelope = storage.getProgressEnvelopeJson(
        onCorruptDataRecovered: () {
          callbackInvoked = true;
        },
      );

      // Assert
      expect(envelope, isEmpty);
      expect(callbackInvoked, isTrue);
      // Key should have been cleared for data integrity
      expect(storage.getString(LocalStorageService.progressKey), isNull);
    });
  });
}
