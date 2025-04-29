// service/patient_service.dart
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:mobile/models/response_models/hasta_hastalik_response_model.dart';
import 'package:mobile/models/response_models/lab_result_response_model.dart';
import 'package:mobile/models/response_models/medical_history_response_model.dart';
import 'package:mobile/models/response_models/medication_usage_response_model.dart,.dart';
import 'package:mobile/service/sin_in_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/response_models/patient_response_model.dart';
import 'apiInfo.dart';

class PatientService {
  static Dio dio = Dio();

  // Tüm hastaları getir
  static Future<List<PatientResponseModel>> getAllPatients(
      {int page = 1, int perPage = 15}) async {
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
            'Authorization': 'Bearer ${await getToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        print("Response received successfully");

        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data') &&
            response.data['data'] is Map<String, dynamic> &&
            response.data['data'].containsKey('data')) {
          final List data = response.data['data']['data'];
          return data
              .map((item) => PatientResponseModel.fromJson(item))
              .toList();
        } else {
          print(
              "Unexpected response format. Data structure: ${response.data.runtimeType}");
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
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
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final List data = response.data['data']['data']; // 👈 değişen yer
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
      print(response.data);

      // Düzeltilmiş kod - Backend'den gelen yapıya uygun
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('data')) {
        final data = response.data['data']; // Sadece 'data' anahtarını al

        return PatientResponseModel.fromJson(data);
      } else {
        throw Exception("Unexpected response format");
      }
    } catch (e) {
      throw Exception("Failed to fetch patient details: $e");
    }
  }

  // Hasta Tıbbi Geçmişini getir
  static Future<MedicalHistoryResponseModel?> getPatientMedicalHistory(
      int hastaId) async {
    final url = "$baseUrl/hastalar/$hastaId/tibbi-gecmis";
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
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          if (response.data['data'] == null) {
            return null;
          }
          return MedicalHistoryResponseModel.fromJson(response.data['data']);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch patient medical history: $e");
    }
  }

// Laboratuvar Sonuçlarını getir
  static Future<List<LabResultResponseModel>> getPatientLabResults(
      int hastaId) async {
    final url = "$baseUrl/hastalar/$hastaId/laboratuvar-sonuclari";
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
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final List data = response.data['data'];
          return data
              .map((item) => LabResultResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch patient lab results: $e");
    }
  }

// İlaç Kullanım Bilgilerini getir
  static Future<List<MedicationUsageResponseModel>> getPatientMedications(
      int hastaId) async {
    final url = "$baseUrl/hastalar/$hastaId/ilac-kullanim";
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
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final List data = response.data['data'];
          return data
              .map((item) => MedicationUsageResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch patient medications: $e");
    }
  }

// Hastalık Bilgilerini getir
  static Future<List<HastaHastalikResponseModel>> getPatientDiseases(
      int hastaId) async {
    final url = "$baseUrl/hastalar/$hastaId/hastaliklar";
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
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final List data = response.data['data'];
          return data
              .map((item) => HastaHastalikResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch patient diseases: $e");
    }
  }
}
