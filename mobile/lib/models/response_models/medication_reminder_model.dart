import 'package:flutter/material.dart';

class MedicationReminder {
  final int id;
  final String userId;
  final String patientId;
  final String patientName;
  final String medicationName;
  final String dose;
  final DateTime reminderDate;
  final String reminderTime;
  final String? notes;
  final bool isComplete;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationReminder({
    required this.id,
    required this.userId,
    required this.patientId,
    required this.patientName,
    required this.medicationName,
    required this.dose,
    required this.reminderDate,
    required this.reminderTime,
    this.notes,
    required this.isComplete,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      id: json['id'],
      userId: json['user_id'].toString(),
      patientId: json['patient_id'],
      patientName: json['patient_name'],
      medicationName: json['medication_name'],
      dose: json['dose'],
      reminderDate: DateTime.parse(json['reminder_date']),
      reminderTime: json['reminder_time'],
      notes: json['notes'],
      isComplete: json['is_complete'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'patient_id': patientId,
      'patient_name': patientName,
      'medication_name': medicationName,
      'dose': dose,
      'reminder_date': reminderDate.toIso8601String().split('T')[0],
      'reminder_time': reminderTime,
      'notes': notes,
      'is_complete': isComplete,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // DateTime ve TimeOfDay nesnesi olarak hatırlatıcı zamanını alma
  TimeOfDay getTimeOfDay() {
    final parts = reminderTime.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}