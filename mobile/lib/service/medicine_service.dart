import 'dart:developer';

import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/response_models/medicine_response_model.dart';
import '../models/response_models/active_ingredient_response_model.dart';
import 'apiInfo.dart';

class MedicineService {
  static final dio = Dio();

  // Son sayfalama meta verilerini saklamak için
  static Map<String, dynamic> _lastPaginationMetadata = {};

  static Future<List<MedicineResponseModel>> searchMedicines(
      String query, {
        int page = 1,
        int perPage = 15
      }) async {
    final url = "$baseUrl/ilaclar/search";
    print("Request URL: $url");
    print("Query: $query, Page: $page, PerPage: $perPage");

    try {
      final response = await dio.get(
        url,
        queryParameters: {
          'query': query,
          'page': page,
          'per_page': perPage
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      print(response.realUri);
      if (response.statusCode == 200) {
        print("Raw response structure: ${response.data.keys.toList()}");

        // API yanıt yapısını analiz et ve dönüştür
        if (!response.data.containsKey('data')) {
          print("WARNING: 'data' key not found in response");
          throw Exception("API response does not contain 'data' key");
        }

        // Pagination meta verilerini sakla
        _storePaginationMetadata(response.data);

        var apiData = response.data['data'];
        print("Pagination structure keys: ${apiData.keys.toList()}");

        var items = apiData['data'];

        if (items == null) {
          print("WARNING: 'data' array not found in pagination data");
          return []; // Return an empty list instead of throwing an exception
        }



        return items.map<MedicineResponseModel>((item) {
          try {
            return MedicineResponseModel.fromJson(item);
          } catch (e, stackTrace) {
            print("Error parsing medicine: $e");
            print("Error stack trace: $stackTrace");
            print("Problematic medicine data: $item");
            // You might want to log this error or handle it differently
            // For now, we'll throw to prevent processing invalid data
            throw Exception("Failed to parse medicine item: $e");
          }
        }).toList();

      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e, stackTrace) {
      print("Error: $e");
      print("Stack trace: $stackTrace");
      throw Exception("Failed to fetch medicines: $e");
    }
  }

  static Future<List<MedicineResponseModel>> getMedicines( {
        int page = 1,
        int perPage = 15
      }) async {
    final url = "$baseUrl/ilaclar";
    print("Request URL: $url");
    print("Page: $page, PerPage: $perPage");

    try {
      final response = await dio.get(
        url,
        queryParameters: {
          'page': page,
          'per_page': perPage
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      print(response.realUri);
      if (response.statusCode == 200) {
        print("Raw response structure: ${response.data.keys.toList()}");

        // API yanıt yapısını analiz et ve dönüştür
        if (!response.data.containsKey('data')) {
          print("WARNING: 'data' key not found in response");
          throw Exception("API response does not contain 'data' key");
        }

        // Pagination meta verilerini sakla
        _storePaginationMetadata(response.data);

        var apiData = response.data['data'];
        print("Pagination structure keys: ${apiData.keys.toList()}");

        var items = apiData['data'];

        if (items == null) {
          print("WARNING: 'data' array not found in pagination data");
          return []; // Return an empty list instead of throwing an exception
        }



        return items.map<MedicineResponseModel>((item) {
          try {
            return MedicineResponseModel.fromJson(item);
          } catch (e, stackTrace) {
            print("Error parsing medicine: $e");
            print("Error stack trace: $stackTrace");
            print("Problematic medicine data: $item");
            // You might want to log this error or handle it differently
            // For now, we'll throw to prevent processing invalid data
            throw Exception("Failed to parse medicine item: $e");
          }
        }).toList();

      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e, stackTrace) {
      print("Error: $e");
      print("Stack trace: $stackTrace");
      throw Exception("Failed to fetch medicines: $e");
    }
  }

  static Future<MedicineResponseModel> getMedicineDetails(int id) async {
    final url = "$baseUrl/ilaclar/$id";

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
        var data = response.data['data'];
        return MedicineResponseModel.fromJson(data);
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch medicine details: $e");
    }
  }

  static Future<List<EtkenMaddeResponseModel>> getActiveIngredients(int ilacId) async {
    final url = "$baseUrl/ilaclar/$ilacId/etken-maddeler";

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
        _storePaginationMetadata(response.data);

        var apiData = response.data['data'];
        var items = apiData is Map && apiData.containsKey('data')
            ? apiData['data']
            : apiData;

        if (items is List) {
          return items.map((item) {
            try {
              return EtkenMaddeResponseModel.fromJson(item);
            } catch (e) {
              print("Error parsing active ingredient: $e");
              return null;
            }
          }).whereType<EtkenMaddeResponseModel>().toList();
        } else {
          throw Exception("Unexpected active ingredients response format");
        }
      } else {
        throw Exception("Server error when fetching active ingredients: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch active ingredients: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getFiyatHareketleri(int ilacId) async {
    final url = "$baseUrl/ilaclar/$ilacId/fiyat-hareketleri";

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
        var data = response.data['data'];

        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception("Unexpected price movements response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch price movements: $e");
    }
  }

  static Future<List<MedicineResponseModel>> getEsdegerIlaclar(int ilacId) async {
    final url = "$baseUrl/ilaclar/$ilacId/esdeger-ilaclar";

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
        var data = response.data['data'];

        if (data is List) {
          return data.map((item) {
            try {
              return MedicineResponseModel.fromJson(item);
            } catch (e) {
              print("Error parsing equivalent medicine: $e");
              return null;
            }
          }).whereType<MedicineResponseModel>().toList();
        } else {
          throw Exception("Unexpected equivalent medicines response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch equivalent medicines: $e");
    }
  }

  static Future<List<MedicineResponseModel>> getSimilarMedicines(int ilacId) async {
    final url = "$baseUrl/ilaclar/$ilacId/benzer-ilaclar";

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
        var data = response.data['data'];

        if (data is List) {
          return data.map((item) {
            try {
              return MedicineResponseModel.fromJson(item);
            } catch (e) {
              print("Error parsing similar medicine: $e");
              return null;
            }
          }).whereType<MedicineResponseModel>().toList();
        } else {
          throw Exception("Unexpected similar medicines response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch similar medicines: $e");
    }
  }

  // Sayfalama meta verilerini çıkar ve sakla
  static void _storePaginationMetadata(Map<String, dynamic> response) {
    try {
      var data = response['data'];
      if (data is Map && data.containsKey('current_page')) {
        _lastPaginationMetadata = {
          'current_page': data['current_page'],
          'last_page': data['last_page'],
          'per_page': data['per_page'],
          'total': data['total'],
        };
        print("Pagination metadata stored: $_lastPaginationMetadata");
      }
    } catch (e) {
      print("Error extracting pagination metadata: $e");
      _lastPaginationMetadata = {};
    }
  }

  // Son saklanmış meta verileri getir
  static Future<Map<String, dynamic>> getLastPaginationMetadata() async {
    return _lastPaginationMetadata;
  }
}