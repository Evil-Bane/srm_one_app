import 'package:shared_preferences/shared_preferences.dart';

class UserCredentials {
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';

  /// Saves the user's credentials (email and password) to persistent storage.
  static Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
  }

  /// Retrieves the user's credentials.
  /// Returns a map with keys 'email' and 'password' if they exist, otherwise null.
  static Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);
    if (email != null && password != null) {
      return {
        'email': email,
        'password': password,
      };
    }
    return null;
  }

  /// Deletes the user's saved credentials.
  static Future<void> deleteCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
  }
}
