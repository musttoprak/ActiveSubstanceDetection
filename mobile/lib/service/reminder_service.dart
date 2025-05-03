import 'package:mobile/models/request_models/reminder_request_models.dart';
import 'package:mobile/models/response_models/medication_reminder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_response.dart';
import 'api_service.dart';

class ReminderService {
  // Tüm hatırlatıcıları getir
  static Future<ApiResponse<List<MedicationReminder>>> getReminders({
    DateTime? date,
    String? patientId,
    bool? isComplete,
  }) async {
    String endpoint = '/reminders';

    // URL parametreleri
    final queryParams = <String, String>{};
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }
    if (patientId != null) {
      queryParams['patient_id'] = patientId;
    }
    if (isComplete != null) {
      queryParams['is_complete'] = isComplete.toString();
    }

    // Query parametreleri varsa URL'e ekle
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      endpoint = '$endpoint?$queryString';
    }

    return await ApiService.get<List<MedicationReminder>>(
      endpoint,
      (data) => List<MedicationReminder>.from(
        data['data'].map((x) => MedicationReminder.fromJson(x)),
      ),
    );
  }

  // Belirli bir tarih için hatırlatıcıları getir
  static Future<ApiResponse<List<MedicationReminder>>> getRemindersByDate(
      DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0];

    return await ApiService.get<List<MedicationReminder>>(
      '/reminders/date/$dateString',
      (data) {
        if (data is Map<String, dynamic> && data['data'] is List) {
          return List<MedicationReminder>.from(
            data['data'].map((x) => MedicationReminder.fromJson(x)),
          );
        } else if (data is List) {
          // Eğer doğrudan liste dönüyorsa
          return List<MedicationReminder>.from(
            data.map((x) => MedicationReminder.fromJson(x)),
          );
        } else {
          throw Exception("Beklenmeyen veri formatı: $data");
        }
      },
    );
  }

  static Future<ApiResponse<List<String>>> getMonthEvents(
      int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    if (userId == null) {
      throw Exception("Kullanıcı ID bulunamadı.");
    }

    return await ApiService.get<List<String>>(
      '/reminders/month/$year/$month?user_id=$userId',
          (data) {
        if (data is List) {
          return List<String>.from(data);
        } else {
          throw Exception("Beklenmeyen veri formatı: ${data.toString()}");
        }
      },
    );
  }



  // Hatırlatıcı detayını getir
  static Future<ApiResponse<MedicationReminder>> getReminder(
      int reminderId) async {
    return await ApiService.get<MedicationReminder>(
      '/reminders/$reminderId',
      (data) {
        if (data is Map<String, dynamic> &&
            data['data'] is Map<String, dynamic>) {
          return MedicationReminder.fromJson(data['data']);
        } else {
          throw Exception("Beklenmeyen veri formatı: ${data.toString()}");
        }
      },
    );
  }

  // Yeni hatırlatıcı oluştur
  static Future<ApiResponse<MedicationReminder>> createReminder(
      CreateReminderRequest request) async {
    return await ApiService.post<MedicationReminder>(
      '/reminders',
      request.toJson(),
          (data) {
        if (data is Map<String, dynamic>) {
          return MedicationReminder.fromJson(data);
        } else {
          throw Exception("Beklenmeyen veri formatı: ${data.toString()}");
        }
      },
    );
  }

  // Hatırlatıcıyı güncelle
  static Future<ApiResponse<MedicationReminder>> updateReminder(
      int reminderId, CreateReminderRequest request) async {
    return await ApiService.put<MedicationReminder>(
      '/reminders/$reminderId',
      request.toJson(),
      (data) {
        if (data is Map<String, dynamic> &&
            data['data'] is Map<String, dynamic>) {
          return MedicationReminder.fromJson(data['data']);
        } else {
          throw Exception("Beklenmeyen veri formatı: ${data.toString()}");
        }
      },
    );
  }

  // Hatırlatıcının tamamlanma durumunu değiştir
  static Future<ApiResponse<MedicationReminder>> toggleComplete(
      int reminderId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id');

    if (userId == null) {
      throw Exception("Kullanıcı ID bulunamadı.");
    }

    return await ApiService.patch<MedicationReminder>(
      '/reminders/$reminderId/toggle-complete',
      {'user_id': userId},
      (data) {
        if (data is Map<String, dynamic> &&
            data['data'] is Map<String, dynamic>) {
          return MedicationReminder.fromJson(data['data']);
        } else {
          throw Exception("Beklenmeyen veri formatı: ${data.toString()}");
        }
      },
    );
  }

  // Hatırlatıcıyı sil
  static Future<ApiResponse<void>> deleteReminder(int reminderId) async {
    return await ApiService.delete<void>(
      '/reminders/$reminderId',
      (_) => null,
    );
  }
}
