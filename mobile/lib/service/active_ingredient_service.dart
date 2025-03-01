import 'package:dio/dio.dart';

import '../models/response_models/active_ingredient_response_model.dart';
import 'apiInfo.dart';

class ActiveIngredientService {
  static Dio dio = Dio();

  static Future<List<ActiveIngredientResponseModel>> searchActiveIngredients(
      String query) async {
    final url = "$baseUrl/preparations/search";
    print("Request URL: $url");
    print("Query: $query");

    try {
      final response = await dio.get(
        url,
        queryParameters: {'name': query},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          final List data = response.data['data'];
          return data
              .map((item) => ActiveIngredientResponseModel.fromJson(item))
              .toList();
        } else if (response.data is List<dynamic>) {
          return response.data
              .map((item) => ActiveIngredientResponseModel.fromJson(item))
              .toList();
        } else {
          throw Exception("Unexpected response format");
        }
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      throw Exception("Failed to fetch active ingredients: $e");
    }
  }

  // Fetch detailed information about an active ingredient by ID
  static Future<ActiveIngredientResponseModel> getActiveIngredientById(
      int id) async {
    final url = "$baseUrl/preparations/$id";
    print("Request URL: $url");

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
        final data = response.data is Map<String, dynamic> ? response.data : {};
        return ActiveIngredientResponseModel.fromJson(data);
      } else {
        throw Exception("Server error: ${response.statusMessage}");
      }
    } catch (e) {
      throw Exception("Failed to fetch active ingredient details: $e");
    }
  }
}
