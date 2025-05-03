import 'package:mobile/models/response_models/medicine_response_model.dart';
import 'package:mobile/models/response_models/patient_response_model.dart';
import 'package:mobile/models/response_models/prescription_response_model.dart';

import 'active_ingredient_response_model.dart';

class SearchResultsModel {
  final List<MedicineResponseModel> medications;
  final List<EtkenMaddeResponseModel> activeIngredients;
  final List<PatientResponseModel> patients;
  final List<PrescriptionResponseModel> recetes;

  SearchResultsModel({
    required this.medications,
    required this.activeIngredients,
    required this.patients,
    required this.recetes,
  });

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) {
    List<MedicineResponseModel> medications = [];
    List<EtkenMaddeResponseModel> activeIngredients = [];
    List<PatientResponseModel> patients = [];
    List<PrescriptionResponseModel> recetes = [];

    if (json['medications'] != null) {
      medications = (json['medications'] as List)
          .map((item) => MedicineResponseModel.fromJson(item))
          .toList();
    }

    if (json['activeIngredients'] != null) {
      activeIngredients = (json['activeIngredients'] as List)
          .map((item) => EtkenMaddeResponseModel.fromJson(item))
          .toList();
    }

    if (json['patients'] != null) {
      patients = (json['patients'] as List)
          .map((item) => PatientResponseModel.fromJson(item))
          .toList();
    }

    if (json['recetes'] != null) {
      recetes = (json['recetes'] as List)
          .map((item) => PrescriptionResponseModel.fromJson(item))
          .toList();
    }

    return SearchResultsModel(
      medications: medications,
      activeIngredients: activeIngredients,
      patients: patients,
      recetes: recetes,
    );
  }

  // Tüm sonuçların boş olup olmadığını kontrol et
  bool get isEmpty => medications.isEmpty && activeIngredients.isEmpty && patients.isEmpty && recetes.isEmpty;

  // Tüm sonuçların toplam sayısını döndür
  int get totalResults => medications.length + activeIngredients.length + patients.length+ recetes.length;
}