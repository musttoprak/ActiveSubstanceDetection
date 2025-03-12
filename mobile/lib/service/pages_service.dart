import 'package:dio/dio.dart';
import 'apiInfo.dart';

class PagesService {
  static final dio = Dio();

  // Son sayfalama meta verilerini saklamak için
  static Map<String, dynamic> _lastPaginationMetadata = {};

  static Future<List<dynamic>> fetchSearchResults(
      String query, String category) async {
    // API URL'si
    String url = '$baseUrl/general/search';
    final response = await dio.get(url, queryParameters: {
      'query': query,
      'category': category,
    });

    if (response.statusCode == 200) {
      return response.data['results'];
    } else {
      throw Exception('Arama yapılırken bir hata oluştu');
    }
  }

  // Barkod ile ilaç bilgilerini API'den çeken fonksiyon
  static Future<void> fetchMedicineDetails(String barcode) async {
    final response = await dio.get('https://yourapiurl.com/medicine/$barcode');
    if (response.statusCode == 200) {
      // API'den gelen ilaç bilgisiyle işlem yapabilirsiniz
      print(response.data);
    } else {
      throw Exception('Barkod ile ilaç bulunamadı');
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
