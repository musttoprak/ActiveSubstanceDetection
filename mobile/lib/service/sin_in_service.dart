import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mobile/models/request_models/login_request_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/response_models/login_response_model.dart';

import 'apiInfo.dart';

class SignInService {
  static Dio dio = Dio();

  static Future<LoginResponseModel> login(
      LoginRequestModel requestModel) async {
    final url = "$baseUrl/login";
    print("Request URL: $url");
    print("Request data: ${jsonEncode(requestModel.toJson())}");

    try {
      final response = await dio.post(
        url,
        data: requestModel.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print("Response Data: $data");
        return LoginResponseModel.fromJson(data);
      } else {
        return LoginResponseModel(
            error: true,
            message: "Sunucu hatası: ${response.statusMessage}"
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        String errorMessage = "Giriş bilgileriniz hatalı";
        if (e.response?.data != null && e.response?.data['error'] != null) {
          errorMessage = e.response?.data['error'];
        }
        return LoginResponseModel(
            error: true,
            message: errorMessage
        );
      }

      return LoginResponseModel(
          error: true,
          message: "Giriş işlemi başarısız: ${e.message ?? 'Bilinmeyen hata'}"
      );
    } catch (e) {
      return LoginResponseModel(
          error: true,
          message: "Giriş işlemi başarısız: $e"
      );
    }
  }
}

Future<String> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token') ?? '';
}
