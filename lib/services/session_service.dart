import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { customer, driver }

class SessionService {
  static const _keyRole = 'towlink_role';
  static const _keyPhone = 'towlink_phone';
  static const _keyName = 'towlink_name';
  static const _keyDriverId = 'towlink_driver_id';

  static Future<void> saveSession({
    required UserRole role,
    required String phone,
    required String name,
    int? driverId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRole, role.name);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyName, name);
    if (driverId != null) {
      await prefs.setInt(_keyDriverId, driverId);
    }
  }

  static Future<UserRole?> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyRole);
    if (value == null) return null;
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.customer,
    );
  }

  static Future<String?> loadPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhone);
  }

  static Future<String?> loadName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<int?> loadDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDriverId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
