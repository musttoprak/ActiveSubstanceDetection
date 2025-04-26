// service/prescription_service.dart
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import '../models/response_models/drug_recommendation_model.dart';
import '../models/response_models/prescription_response_model.dart';
import 'apiInfo.dart';
import 'sin_in_service.dart';

class PrescriptionService {
  static Dio dio = Dio();

  // Tüm reçeteleri getir
  static Future<List<PrescriptionResponseModel>> getAllPrescriptions({
    int page = 1,
    int perPage = 15,
  }) async {
    final url = "$baseUrl/receteler";

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
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final data = response.data['data']['data'];
          return List<PrescriptionResponseModel>.from(
            data.map((x) => PrescriptionResponseModel.fromJson(x)),
          );
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch prescriptions: $e");
    }
  }

  // Reçete detayını getir
  static Future<PrescriptionResponseModel> getPrescriptionById(int id) async {
    final url = "$baseUrl/receteler/$id";

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          return PrescriptionResponseModel.fromJson(response.data['data']);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch prescription details: $e");
    }
  }

  // Hasta reçetelerini getir
  static Future<List<PrescriptionResponseModel>> getPatientPrescriptions(
      int hastaId) async {
    final url = "$baseUrl/receteler/hasta/$hastaId";

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final data = response.data['data'];
          return List<PrescriptionResponseModel>.from(
            data.map((x) => PrescriptionResponseModel.fromJson(x)),
          );
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch patient prescriptions: $e");
    }
  }

  // QR kod ile reçete getir
  static Future<PrescriptionResponseModel> getPrescriptionByQR(
      String receteNo) async {
    final url = "$baseUrl/receteler/qr/$receteNo";

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          return PrescriptionResponseModel.fromJson(response.data['data']);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch prescription by QR: $e");
    }
  }

  /// service/prescription_service.dart içinde güncelleme
  static Future<void> getPrescriptionRecommendations(int receteId) async {
    final url = "$baseUrl/receteler/$receteId/oneriler";

    try {
      final response = await dio.post(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusMessage}");
      }

      // Debug için gönderilen verileri kontrol et
      print("Recommendation request data: ${response.data}");

    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to request prescription recommendations: $e");
    }
  }

// Reçeteye önerilen ilaçları getir - bu metot doğru, sadece hasta ve hastalığa göre filtreliyor
  static Future<List<DrugRecommendationModel>> getPrescriptionSuggestions(
      int receteId) async {
    final url = "$baseUrl/receteler/$receteId/oneriler";

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      print(url);
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          final data = response.data['data'];
          return List<DrugRecommendationModel>.from(
            data.map((x) => DrugRecommendationModel.fromJson(x)),
          );
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch prescription suggestions: $e");
    }
  }
  
  // Önerilen ilacı reçeteye ekle
  static Future<PrescriptionMedicationModel> addSuggestionToPrescription(
      int receteId,
      int oneriId, {
        String? dozaj,
        String? kullanimTalimati,
        int miktar = 1,
      }) async {
    final url = "$baseUrl/receteler/$receteId/oneriler/$oneriId/ekle";

    try {
      final response = await dio.post(
        url,
        data: {
          'dozaj': dozaj,
          'kullanim_talimati': kullanimTalimati,
          'miktar': miktar,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          return PrescriptionMedicationModel.fromJson(response.data['data']);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to add suggestion to prescription: $e");
    }
  }

  // Yeni reçete oluştur
  static Future<PrescriptionResponseModel> createPrescription({
    required int hastaId,
    required int hastalikId,
    int? doktorId,
    required String tarih,
    String? notlar,
    List<Map<String, dynamic>>? ilaclar,
  }) async {
    final url = "$baseUrl/receteler";

    try {
      final response = await dio.post(
        url,
        data: {
          'hasta_id': hastaId,
          'hastalik_id': hastalikId,
          'doktor_id': doktorId,
          'tarih': tarih,
          'notlar': notlar,
          'ilaclar': ilaclar,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          return PrescriptionResponseModel.fromJson(response.data['data']);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to create prescription: $e");
    }
  }

  // Reçeteyi güncelle
  static Future<PrescriptionResponseModel> updatePrescription({
    required int receteId,
    int? hastaId,
    int? hastalikId,
    int? doktorId,
    String? tarih,
    String? notlar,
    String? durum,
    bool? aktif,
    List<Map<String, dynamic>>? ilaclar,
  }) async {
    final url = "$baseUrl/receteler/$receteId";

    final data = <String, dynamic>{};
    if (hastaId != null) data['hasta_id'] = hastaId;
    if (hastalikId != null) data['hastalik_id'] = hastalikId;
    if (doktorId != null) data['doktor_id'] = doktorId;
    if (tarih != null) data['tarih'] = tarih;
    if (notlar != null) data['notlar'] = notlar;
    if (durum != null) data['durum'] = durum;
    if (aktif != null) data['aktif'] = aktif;
    if (ilaclar != null) data['ilaclar'] = ilaclar;

    try {
      final response = await dio.put(
        url,
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('data')) {
          return PrescriptionResponseModel.fromJson(response.data['data']);
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to update prescription: $e");
    }
  }

  // Reçeteyi sil
  static Future<void> deletePrescription(int receteId) async {
    final url = "$baseUrl/receteler/$receteId";

    try {
      final response = await dio.delete(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to delete prescription: $e");
    }
  }
}