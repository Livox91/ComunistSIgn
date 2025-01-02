import 'package:mcprj/domain/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static const String _userKey = 'user';
  static const String _firstTimeKey = 'firstTime';

  Future<void> saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toRawJson());
  }

  Future<UserProfile?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final user = userJson != null ? UserProfile.fromRawJson(userJson) : null;
    return user;
  }

  Future<void> setFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, false);
  }

  Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  Future<bool> hasUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }

  /// Remove user data from Shared Preferences
  Future<void> removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Check if a user is already saved in Shared Preferences
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }
}
