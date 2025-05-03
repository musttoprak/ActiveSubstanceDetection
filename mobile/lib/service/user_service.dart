import 'dart:io';
import 'package:mobile/models/request_models/update_profile_request.dart';
import 'package:mobile/models/response_models/user_model.dart';

import '../models/api_response.dart';
import 'api_service.dart';

class UserService {
  // Kullanıcı profili getir
  static Future<ApiResponse<UserProfile>> getProfile() async {
    return await ApiService.get<UserProfile>(
      '/profile',
          (data) => UserProfile.fromJson(data['data']),
    );
  }

  // Kullanıcı profilini güncelle
  static Future<ApiResponse<UserProfile>> updateProfile(UpdateProfileRequest request) async {
    // Dosya yükleme varsa multipart isteği kullan
    if (request.profilePicture != null) {
      return await ApiService.multipartPost<UserProfile>(
        '/profile',
        request.toFormData(),
        {'profile_picture': request.profilePicture!},
            (data) => UserProfile.fromJson(data['data']),
      );
    } else {
      // Dosya yoksa normal put isteği yap
      return await ApiService.post<UserProfile>(
        '/profile',
        request.toFormData(),
            (data) => UserProfile.fromJson(data['data']),
      );
    }
  }
}