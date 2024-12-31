import 'dart:convert';

class UserProfile {
  String name;
  String email;
  String? profileImage;
  String? phoneNumber;

  UserProfile({
    required this.name,
    required this.email,
    this.profileImage,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'name': name,
      };

  // Convert JSON map to a User object
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'],
      name: json['name'],
    );
  }

  // Serialize User to a JSON string
  String toRawJson() => jsonEncode(toJson());

  // Deserialize JSON string to a User object
  factory UserProfile.fromRawJson(String str) =>
      UserProfile.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
