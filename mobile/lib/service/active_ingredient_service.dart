import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/response_models/active_ingredient_response_model.dart';
import '../models/response_models/medicine_response_model.dart';
import 'apiInfo.dart';

class ActiveIngredientService {
  static final dio = Dio();

  // Son sayfalama meta verilerini saklamak için
  static Map<String, dynamic> _lastPaginationMetadata = {};

  static Future<List<EtkenMaddeResponseModel>> searchActiveIngredients(
      String query, {
        int page = 1,
        int perPage = 15
      }) async {
    final url = "$baseUrl/etken-maddeler/search";

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

      if (response.statusCode == 200) {
        print("Raw response structure: ${response.data.keys.toList()}");

        // Adım 1: Ana API yanıt yapısını kontrol et
        if (!response.data.containsKey('data')) {
          print("WARNING: 'data' key not found in response, full response: $response");
          throw Exception("API response does not contain 'data' key");
        }

        // Pagination meta verilerini sakla
        _storePaginationMetadata(response.data);

        // Adım 2: Pagination veri yapısını kontrol et
        var apiData = response.data['data'];
        print("Pagination structure keys: ${apiData.keys.toList()}");

        // Adım 3: Veri listesini kontrol et
        if (!apiData.containsKey('data')) {
          print("WARNING: 'data' key not found in pagination data, full structure: $apiData");
          throw Exception("API pagination data does not contain 'data' key");
        }

        var items = apiData['data'];
        print("Items count: ${items != null ? items.length : 'null'}");

        if (items is List) {
          print("First item structure: ${items.isNotEmpty ? items.first.keys.toList() : 'empty list'}");

          if (items.isNotEmpty) {
            var firstItem = items.first;
            if (firstItem.containsKey('etken_madde_id')) {
              print("etken_madde_id example: ${firstItem['etken_madde_id']} (${firstItem['etken_madde_id'].runtimeType})");
            }
          }

          return items.map((item) {
            try {
              print("Processing item: ${item['etken_madde_adi']}");
              var model = EtkenMaddeResponseModel.fromJson(item);
              print("Successfully parsed: ${model.etkenMaddeAdi}");
              return model;
            } catch (e, stackTrace) {
              print("Error parsing item: $e");
              print("Error stack trace: $stackTrace");
              print("Problematic item: $item");
              if (item['etken_madde_id'] != null) {
                print("etken_madde_id type: ${item['etken_madde_id'].runtimeType}");
                print("etken_madde_id value: ${item['etken_madde_id']}");
              }
              // Hata durumunda null döndür
              return null;
            }
          }).whereType<EtkenMaddeResponseModel>().toList();
        } else {
          throw Exception("Unexpected response format: ${response.data}");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e, stackTrace) {
      print("Error: $e");
      print("Stack trace: $stackTrace");
      throw Exception("Failed to fetch active ingredients: $e");
    }
  }

  static Future<List<EtkenMaddeResponseModel>> getActiveIngredients({
        int page = 1,
        int perPage = 15
      }) async {
    final url = "$baseUrl/etken-maddeler";

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

      if (response.statusCode == 200) {
        print("Raw response structure: ${response.data.keys.toList()}");

        // Adım 1: Ana API yanıt yapısını kontrol et
        if (!response.data.containsKey('data')) {
          print("WARNING: 'data' key not found in response, full response: $response");
          throw Exception("API response does not contain 'data' key");
        }

        // Pagination meta verilerini sakla
        _storePaginationMetadata(response.data);

        // Adım 2: Pagination veri yapısını kontrol et
        var apiData = response.data['data'];
        print("Pagination structure keys: ${apiData.keys.toList()}");

        // Adım 3: Veri listesini kontrol et
        if (!apiData.containsKey('data')) {
          print("WARNING: 'data' key not found in pagination data, full structure: $apiData");
          throw Exception("API pagination data does not contain 'data' key");
        }

        var items = apiData['data'];
        print("Items count: ${items != null ? items.length : 'null'}");

        if (items is List) {
          print("First item structure: ${items.isNotEmpty ? items.first.keys.toList() : 'empty list'}");

          if (items.isNotEmpty) {
            var firstItem = items.first;
            if (firstItem.containsKey('etken_madde_id')) {
              print("etken_madde_id example: ${firstItem['etken_madde_id']} (${firstItem['etken_madde_id'].runtimeType})");
            }
          }

          return items.map((item) {
            try {
              print("Processing item: ${item['etken_madde_adi']}");
              var model = EtkenMaddeResponseModel.fromJson(item);
              print("Successfully parsed: ${model.etkenMaddeAdi}");
              return model;
            } catch (e, stackTrace) {
              print("Error parsing item: $e");
              print("Error stack trace: $stackTrace");
              print("Problematic item: $item");
              if (item['etken_madde_id'] != null) {
                print("etken_madde_id type: ${item['etken_madde_id'].runtimeType}");
                print("etken_madde_id value: ${item['etken_madde_id']}");
              }
              // Hata durumunda null döndür
              return null;
            }
          }).whereType<EtkenMaddeResponseModel>().toList();
        } else {
          throw Exception("Unexpected response format: ${response.data}");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e, stackTrace) {
      print("Error: $e");
      print("Stack trace: $stackTrace");
      throw Exception("Failed to fetch active ingredients: $e");
    }
  }

  // Sayfalama meta verilerini çıkar ve sakla
  static void _storePaginationMetadata(Map<String, dynamic> response) {
    try {
      var data = response['data'];
      _lastPaginationMetadata = {
        'current_page': data['current_page'],
        'last_page': data['last_page'],
        'per_page': data['per_page'],
        'total': data['total'],
      };
      print("Pagination metadata stored: $_lastPaginationMetadata");
    } catch (e) {
      print("Error extracting pagination metadata: $e");
      _lastPaginationMetadata = {};
    }
  }

  // Son saklanmış meta verileri getir
  static Future<Map<String, dynamic>> getLastPaginationMetadata() async {
    return _lastPaginationMetadata;
  }

  static Future<EtkenMaddeResponseModel> getActiveIngredientDetails(int id) async {
    final url = "$baseUrl/etken-maddeler/$id";

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      print(response.realUri);
      if (response.statusCode == 200) {
        var data = response.data['data'];
        return EtkenMaddeResponseModel.fromJson(data);
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Failed to fetch active ingredient details: $e");
    }
  }

  static Future<List<MedicineResponseModel>> getRelatedMedicines(int etkenMaddeId, {
    int page = 1,
    int perPage = 15
  }) async {
    // İlişkili ilaçlar için API rotasını kullan
    final url = "$baseUrl/etken-maddeler/$etkenMaddeId/ilaclar";
    print("Fetching medicines for etken madde ID: $etkenMaddeId");

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
        _storePaginationMetadata(response.data);

        // API yanıt yapısını analiz et
        print("Medicine API response structure: ${response.data.keys.toList()}");

        var apiData = response.data['data'];

        // İlaç verileri pagination içinde gelebileceğinden
        var items = apiData is Map && apiData.containsKey('data')
            ? apiData['data']
            : apiData;

        print("Medicine items count: ${items.length}");

        if (items is List) {
          return items.map((item) {
            try {
              return MedicineResponseModel.fromJson(item);
            } catch (e, stackTrace) {
              print("Error parsing medicine: $e");
              print("Error stack trace: $stackTrace");
              print("Problematic medicine data: $item");
              return null;
            }
          }).whereType<MedicineResponseModel>().toList();
        } else {
          throw Exception("Unexpected medicines response format: ${response.data}");
        }
      } else {
        throw Exception("Server error when fetching medicines: ${response.statusMessage}");
      }
    } catch (e, stackTrace) {
      print("Error fetching medicines: $e");
      print("Stack trace: $stackTrace");
      throw Exception("Failed to fetch related medicines: $e");
    }
  }
}