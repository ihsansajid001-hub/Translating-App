import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Auth tokens
  Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    return _prefs.getString('auth_token');
  }

  Future<void> saveRefreshToken(String token) async {
    await _prefs.setString('refresh_token', token);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString('refresh_token');
  }

  Future<void> clearAuth() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('user_data');
  }

  // User data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString('user_data', userData.toString());
  }

  Future<String?> getUserData() async {
    return _prefs.getString('user_data');
  }

  // Settings
  Future<void> saveLanguage(String language) async {
    await _prefs.setString('preferred_language', language);
  }

  Future<String> getLanguage() async {
    return _prefs.getString('preferred_language') ?? 'en';
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }

  Future<String> getThemeMode() async {
    return _prefs.getString('theme_mode') ?? 'system';
  }

  // Session history
  Future<void> saveSessionHistory(String sessionId, List<Map<String, dynamic>> history) async {
    // Implement local history storage
  }

  Future<List<Map<String, dynamic>>> getSessionHistory(String sessionId) async {
    // Implement local history retrieval
    return [];
  }
}
