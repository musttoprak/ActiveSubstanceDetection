class UserProfile {
  final int id;
  final String email;
  final String name;
  final String role;
  final String? profilePicture;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      name: json['name'] ?? 'Kullanıcı',
      role: json['role'] ?? 'Eczacı',
      profilePicture: json['profile_picture'],
    );
  }
}