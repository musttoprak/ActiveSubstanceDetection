import 'package:dio/dio.dart';
import 'package:mobile/models/response_models/prescription_response_model.dart';
import 'package:mobile/models/response_models/search_result_model.dart';
import 'apiInfo.dart';

class PagesService {
  static final dio = Dio();

  // Arama sonuçlarını direkt model nesneleri olarak döndüren metot
  static Future<SearchResultsModel> fetchSearchResults(String query) async {
    if (query.isEmpty) {
      // Boş sorgu için boş sonuç döndür
      return SearchResultsModel(
          medications: [], activeIngredients: [], patients: [], recetes: []);
    }

    // API URL'si
    String url = '$baseUrl/general/search';
    final response = await dio.get(url, queryParameters: {
      'query': query,
    });
    print(response.realUri);
    if (response.statusCode == 200) {
      // API yanıtını doğrudan SearchResultsModel'e dönüştür
      return SearchResultsModel.fromJson(response.data);
    } else {
      throw Exception('Arama yapılırken bir hata oluştu');
    }
  }

  // QR kod ile reçete getir
  static Future<PrescriptionResponseModel> getPrescriptionByQR(
      String receteNo) async {
    final url = "$baseUrl/general/$receteNo";

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
          throw Exception("Beklenmeyen yanıt formatı");
        }
      } else {
        throw Exception("Sunucu hatası: ${response.statusMessage}");
      }
    } catch (e) {
      print("Hata: $e");
      throw Exception("QR ile reçete getirilemedi: $e");
    }
  }

  // İlaç detay sayfası veri çekme
  static Future<Map<String, dynamic>> getMedicineDetails(int medicineId) async {
    final url = "$baseUrl/ilaclar/$medicineId";

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception("İlaç detayları alınamadı");
      }
    } catch (e) {
      print("Hata: $e");
      throw Exception("İlaç detayları yüklenirken hata oluştu: $e");
    }
  }

  // Etken madde detay sayfası veri çekme
  static Future<Map<String, dynamic>> getActiveIngredientDetails(
      int activeIngredientId) async {
    final url = "$baseUrl/etken-maddeler/$activeIngredientId";

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception("Etken madde detayları alınamadı");
      }
    } catch (e) {
      print("Hata: $e");
      throw Exception("Etken madde detayları yüklenirken hata oluştu: $e");
    }
  }

  // Hasta detay sayfası veri çekme
  static Future<Map<String, dynamic>> getPatientDetails(int patientId) async {
    final url = "$baseUrl/hastalar/$patientId";

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception("Hasta detayları alınamadı");
      }
    } catch (e) {
      print("Hata: $e");
      throw Exception("Hasta detayları yüklenirken hata oluştu: $e");
    }
  }
}
