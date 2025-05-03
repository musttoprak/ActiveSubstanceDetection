import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/service/apiInfo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';

class ApiService {
  // HTTP header oluşturma metodu
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET isteği
  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);
      print(response.request?.url);
      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse(
        status: 'error',
        message: 'İnternet bağlantısı yok',
        success: false,
      );
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Bir hata oluştu: $e',
        success: false,
      );
    }
  }

  // POST isteği
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    dynamic body,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      print(url);
      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse(
        status: 'error',
        message: 'İnternet bağlantısı yok',
        success: false,
      );
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Bir hata oluştu: $e',
        success: false,
      );
    }
  }

  // PUT isteği
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    dynamic body,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse(
        status: 'error',
        message: 'İnternet bağlantısı yok',
        success: false,
      );
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Bir hata oluştu: $e',
        success: false,
      );
    }
  }

  // PATCH isteği
  static Future<ApiResponse<T>> patch<T>(
    String endpoint,
    dynamic body,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse(
        status: 'error',
        message: 'İnternet bağlantısı yok',
        success: false,
      );
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Bir hata oluştu: $e',
        success: false,
      );
    }
  }

  // DELETE isteği
  static Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      final response = await http.delete(url, headers: headers);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse(
        status: 'error',
        message: 'İnternet bağlantısı yok',
        success: false,
      );
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Bir hata oluştu: $e',
        success: false,
      );
    }
  }

  // Multipart POST isteği (dosya yüklemek için)
  static Future<ApiResponse<T>> multipartPost<T>(
    String endpoint,
    Map<String, dynamic> fields,
    Map<String, File> files,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = await _getHeaders();

      // multipart isteği oluştur
      var request = http.MultipartRequest('POST', url);

      // header'ları ekle
      request.headers
          .addAll(Map<String, String>.from(headers)..remove('Content-Type'));

      // alan bilgilerini ekle
      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // dosyaları ekle
      for (var entry in files.entries) {
        final file = entry.value;
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        final multipartFile = http.MultipartFile(
          entry.key,
          stream,
          length,
          filename: file.path.split('/').last,
        );

        request.files.add(multipartFile);
      }

      // isteği gönder ve cevabı al
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse(
        status: 'error',
        message: 'İnternet bağlantısı yok',
        success: false,
      );
    } catch (e) {
      return ApiResponse(
        status: 'error',
        message: 'Bir hata oluştu: $e',
        success: false,
      );
    }
  }

  // HTTP yanıtını işleme
  static ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromJson,
  ) {
    try {
      final jsonData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>.fromJson(jsonData, fromJson);
      } else {
        print(jsonData);
        // HTTP hata kodları için özel mesajlar
        String errorMessage = 'Bir hata oluştu'; // Varsayılan hata mesajı

        if (jsonData['message'] != null) {
          // 'message' altındaki 'content' öğesini kontrol et
          var content = jsonData['message'];

          if (content is String) {
            errorMessage = content;
          } else {
            errorMessage = jsonData['message']['content'][0] ?? errorMessage;
          }
        }

        print('HATA MESAJI: $errorMessage');

        if (response.statusCode == 401) {
          // Oturum geçersiz, kullanıcıyı logout yap
          _handleUnauthorized();
          errorMessage = 'Oturumunuz sonlanmıştır, lütfen tekrar giriş yapın';
        }

        return ApiResponse(
          status: 'error',
          message: errorMessage,
          success: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('HATA MESAJI: $e');
      debugPrint('STACK TRACE: $stackTrace');
      return ApiResponse(
        status: 'error',
        message: 'Yanıt işlenirken bir hata oluştu: $e',
        success: false,
      );
    }
  }

  // Yetkisiz erişim (401) durumunda kullanıcıyı logout yap
  static Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('id');
    // Burada kullanıcıyı login sayfasına yönlendirme kodu eklenebilir
  }
}
