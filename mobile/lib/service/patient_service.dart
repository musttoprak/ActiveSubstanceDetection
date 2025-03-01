// service/patient_service.dart
import 'package:dio/dio.dart';
import 'package:mobile/service/sin_in_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/response_models/patient_response_model.dart';
import 'apiInfo.dart';

class PatientService {
  static Dio dio = Dio();

  // Tüm hastaları getir
  static Future<List<PatientResponseModel>> getAllPatients({int page = 1, int perPage = 15}) async {
    final url = "$baseUrl/hastalar";
    print("Request URL: $url");
    print("Page: $page, Per Page: $perPage");

    try {
      final response = await dio.get(
        url,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await getToken()}', // Token'ı al
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> && response.data.containsKey('data')) {
          final List data = response.data['data'];
          return data
              .map((item) => PatientResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      throw Exception("Failed to fetch patients: $e");
    }
  }

  // Hasta ara
  static Future<List<PatientResponseModel>> searchPatients(String query) async {
    final url = "$baseUrl/hastalar/search";
    print("Request URL: $url");
    print("Query: $query");

    try {
      final response = await dio.get(
        url,
        queryParameters: {'query': query},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await getToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> && response.data.containsKey('data')) {
          final List data = response.data['data'];
          return data
              .map((item) => PatientResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      throw Exception("Failed to search patients: $e");
    }
  }

  // Hasta detaylarını getir
  static Future<PatientResponseModel> getPatientById(int id) async {
    final url = "$baseUrl/hastalar/$id";
    print("Request URL: $url");

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await getToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> && response.data.containsKey('data')) {
          return PatientResponseModel.fromJson(response.data['data']);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      throw Exception("Failed to fetch patient details: $e");
    }
  }
}