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
}
