import 'dart:convert';

class UserProfile {
  String name;
  bool theme;

  UserProfile({
    this.name = '',
    this.theme = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'theme': theme,
      };

  // Convert JSON map to a User object
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'],
      theme: json['theme'],
    );
  }

  // Serialize User to a JSON string
  String toRawJson() => jsonEncode(toJson());

  // Deserialize JSON string to a User object
  factory UserProfile.fromRawJson(String str) =>
      UserProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
