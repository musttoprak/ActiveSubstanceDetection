import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobile/models/api_response.dart';
import 'package:mobile/models/request_models/reminder_request_models.dart';
import 'package:mobile/service/reminder_service.dart';

import '../models/response_models/medication_reminder_model.dart';
// State
abstract class ReminderState extends Equatable {
  const ReminderState();

  @override
  List<Object?> get props => [];
}

class ReminderInitial extends ReminderState {}

class ReminderLoading extends ReminderState {}

class ReminderLoaded extends ReminderState {
  final List<MedicationReminder> reminders;
  final DateTime? selectedDate;

  const ReminderLoaded({
    required this.reminders,
    this.selectedDate,
  });

  @override
  List<Object?> get props => [reminders, selectedDate];
}

class ReminderError extends ReminderState {
  final String message;

  const ReminderError(this.message);

  @override
  List<Object> get props => [message];
}

// Cubit
class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit() : super(ReminderInitial());

  // Belirli bir tarih için hatırlatıcıları yükle
  Future<void> getRemindersForDate(DateTime date) async {
    emit(ReminderLoading());

    final ApiResponse<List<MedicationReminder>> response = await ReminderService.getRemindersByDate(date);

    if (response.success) {
      emit(ReminderLoaded(
        reminders: response.data ?? [],
        selectedDate: date,
      ));
    } else {
      emit(ReminderError(response.message));
    }
  }

  // Tüm hatırlatıcıları yükle (filtreli)
  Future<void> getReminders({
    DateTime? date,
    String? patientId,
    bool? isComplete,
  }) async {
    emit(ReminderLoading());

    final response = await ReminderService.getReminders(
      date: date,
      patientId: patientId,
      isComplete: isComplete,
    );

    if (response.success) {
      emit(ReminderLoaded(
        reminders: response.data ?? [],
        selectedDate: date,
      ));
    } else {
      emit(ReminderError(response.message));
    }
  }

  // Yeni hatırlatıcı oluştur
  Future<bool> createReminder(CreateReminderRequest request) async {
    emit(ReminderLoading());

    final response = await ReminderService.createReminder(request);

    if (response.success) {
      // Başarılı ise, hatırlatıcının tarihini seçili tarih olarak ayarla ve yeniden yükle
      final reminderDate = DateTime.parse(request.reminderDate);
      await getRemindersForDate(reminderDate);
      return true;
    } else {
      print(response.message);
      emit(ReminderError(response.message));
      return false;
    }
  }

  // Hatırlatıcı güncelle
  Future<bool> updateReminder(int reminderId, CreateReminderRequest request) async {
    final currentState = state;
    if (currentState is! ReminderLoaded) return false;

    final response = await ReminderService.updateReminder(reminderId, request);

    if (response.success) {
      // Başarılı ise, yeni tarihteki hatırlatıcıları yükle
      final reminderDate = DateTime.parse(request.reminderDate);
      await getRemindersForDate(reminderDate);
      return true;
    } else {
      // Mevcut tarihteki hatırlatıcıları tekrar yükle
      if (currentState.selectedDate != null) {
        await getRemindersForDate(currentState.selectedDate!);
      }
      return false;
    }
  }

  // Hatırlatıcı tamamlanma durumunu değiştir
  Future<bool> toggleComplete(int reminderId) async {
    final currentState = state;
    if (currentState is! ReminderLoaded) return false;

    // UI'da hemen güncelle
    final updatedReminders = currentState.reminders.map((reminder) {
      if (reminder.id == reminderId) {
        return MedicationReminder(
          id: reminder.id,
          userId: reminder.userId,
          patientId: reminder.patientId,
          patientName: reminder.patientName,
          medicationName: reminder.medicationName,
          dose: reminder.dose,
          reminderDate: reminder.reminderDate,
          reminderTime: reminder.reminderTime,
          notes: reminder.notes,
          isComplete: !reminder.isComplete,
          createdAt: reminder.createdAt,
          updatedAt: reminder.updatedAt,
        );
      }
      return reminder;
    }).toList();

    emit(ReminderLoaded(
      reminders: updatedReminders,
      selectedDate: currentState.selectedDate,
    ));

    // API'ya gönder
    final response = await ReminderService.toggleComplete(reminderId);

    if (!response.success) {
      // Hata durumunda eski duruma geri dön
      if (currentState.selectedDate != null) {
        await getRemindersForDate(currentState.selectedDate!);
      }
      return false;
    }

    return true;
  }

  // Hatırlatıcıyı sil
  Future<bool> deleteReminder(int reminderId) async {
    final currentState = state;
    if (currentState is! ReminderLoaded) return false;

    // UI'da hemen güncelle
    final updatedReminders = List<MedicationReminder>.from(currentState.reminders)
      ..removeWhere((reminder) => reminder.id == reminderId);

    emit(ReminderLoaded(
      reminders: updatedReminders,
      selectedDate: currentState.selectedDate,
    ));

    // API'ya gönder
    final response = await ReminderService.deleteReminder(reminderId);

    if (!response.success) {
      // Hata durumunda eski duruma geri dön
      if (currentState.selectedDate != null) {
        await getRemindersForDate(currentState.selectedDate!);
      }
      return false;
    }

    return true;
  }

  // Aylık etkinlikleri getir
  Future<List<String>> getMonthEvents(int year, int month) async {
    final response = await ReminderService.getMonthEvents(year, month);

    if (response.success) {
      return response.data ?? [];
    } else {
      return [];
    }
  }
}