import 'package:flutter/material.dart';

class MedicationReminder {
  final String id;
  final String patientId;
  final String patientName;
  final String medicationName;
  final String dose;
  final TimeOfDay time;
  final String notes;
  bool isComplete;

  MedicationReminder({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.medicationName,
    required this.dose,
    required this.time,
    required this.notes,
    required this.isComplete,
  });
}