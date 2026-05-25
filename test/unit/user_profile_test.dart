import 'package:flutter_test/flutter_test.dart';
import 'package:campuschow/models/user.dart';

void main() {
  group('UserProfile Unit Tests', () {
    test('should parse correctly with "id" field', () {
      final json = {
        'id': 'user_123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'role': 'user',
        'walletBalance': 1000.0,
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, equals('user_123'));
      expect(user.name, equals('John Doe'));
      expect(user.email, equals('john@example.com'));
      expect(user.role, equals('user'));
    });

    test('should parse correctly with "_id" field', () {
      final json = {
        '_id': 'user_456',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'role': 'STORE_OWNER',
        'walletBalance': 500.0,
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, equals('user_456'));
      expect(user.name, equals('Jane Doe'));
      expect(user.email, equals('jane@example.com'));
      expect(user.role, equals('STORE_OWNER'));
    });

    test('should handle missing fields with defaults', () {
      final json = {
        'id': 'user_789',
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, equals('user_789'));
      expect(user.name, equals(''));
      expect(user.email, equals(''));
      expect(user.role, equals('user'));
      expect(user.walletBalance, equals(0.0));
    });

    test('should serialize to "id" field', () {
      final user = UserProfile(
        id: 'user_123',
        name: 'John Doe',
        email: 'john@example.com',
        walletBalance: 1000.0,
        role: 'user',
      );

      final json = user.toJson();

      expect(json['id'], equals('user_123'));
      expect(json['_id'], isNull);
    });
  });
}
