import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates a stable random device ID on first launch and persists it.
/// Used to link guest orders to FCM tokens so payment reminders can be sent
/// even without a user account.
class DeviceIdService {
  static const _key = 'cc_device_id';
  static String? _cached;

  /// Returns the persisted device ID, creating one if it doesn't exist yet.
  static Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);

    if (id == null || id.isEmpty) {
      id = _generateId();
      await prefs.setString(_key, id);
    }

    _cached = id;
    return id;
  }

  static String _generateId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    // Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx (UUID-like, no dependency)
    String block(int len) =>
        List.generate(len, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${block(8)}-${block(4)}-${block(4)}-${block(4)}-${block(12)}';
  }
}
