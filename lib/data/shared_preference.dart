import 'package:mcprj/domain/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  static const String _userKey = 'user';

  Future<void> saveUser(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toRawJson());
  }

  Future<UserProfile?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      return UserProfile.fromRawJson(userJson);
    }
    return null;
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