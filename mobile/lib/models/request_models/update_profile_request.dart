import 'dart:io';

class UpdateProfileRequest {
  final String? name;
  final String? role;
  final File? profilePicture;

  UpdateProfileRequest({
    this.name,
    this.role,
    this.profilePicture,
  });

  // MultipartRequest için form verilerini oluşturur
  Map<String, dynamic> toFormData() {
    final map = <String, dynamic>{};

    if (name != null) map['name'] = name;
    if (role != null) map['role'] = role;

    return map;
  }
}