class CreateReminderRequest {
  final String userId;
  final String patientId;
  final String patientName;
  final String medicationName;
  final String dose;
  final String reminderTime; // HH:mm formatında
  final String reminderDate; // YYYY-MM-DD formatında
  final String? notes;

  CreateReminderRequest({
    required this.userId,
    required this.patientId,
    required this.patientName,
    required this.medicationName,
    required this.dose,
    required this.reminderTime,
    required this.reminderDate,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'patient_id': patientId,
      'patient_name': patientName,
      'medication_name': medicationName,
      'dose': dose,
      'reminder_time': reminderTime,
      'reminder_date': reminderDate,
      'notes': notes,
    };
  }
}