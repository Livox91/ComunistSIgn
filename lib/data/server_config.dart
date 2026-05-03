import 'package:shared_preferences/shared_preferences.dart';

/// Persists the server base URL across app launches.
///
/// On the Android emulator the host machine is reachable at 10.0.2.2.
/// On a physical phone you need your computer's LAN IP, e.g. http://192.168.1.42:5000.
/// Set it once via [setServerUrl] (e.g. from a settings screen) and all services
/// pick it up via [getServerUrl].
class ServerConfig {
  static const String _key = 'server_url';
  static const String defaultUrl = 'http://10.0.2.2:5000';

  static Future<String> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? defaultUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url.trim());
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
