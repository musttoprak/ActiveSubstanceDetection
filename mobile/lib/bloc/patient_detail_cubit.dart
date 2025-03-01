// cubit/patient_detail_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/models/response_models/medication_usage_response_model.dart,.dart';
import '../models/response_models/patient_response_model.dart';
import '../models/response_models/medical_history_response_model.dart';
import '../models/response_models/lab_result_response_model.dart';
import '../models/response_models/hasta_hastalik_response_model.dart';
import '../service/patient_service.dart';

class PatientDetailCubit extends Cubit<PatientDetailState> {
  int hastaId;
  PatientDetailCubit(this.hastaId) : super(PatientDetailInitial()){
    loadAllPatientData(hastaId);
  }

  Future<void> loadAllPatientData(int hastaId) async {
    emit(PatientDetailLoading());
    try {
      // Tek bir API çağrısıyla tüm hasta bilgilerini al
      final patientData = await PatientService.getPatientById(hastaId);

      // Burada patientData zaten tüm ilişkili verileri içeriyor
      emit(PatientAllDataLoaded(
        patient: patientData,
        medicalHistory: patientData.tibbiGecmis, // tibbi_gecmis
        labResults: patientData.laboratuvarSonuclari, // laboratuvar_sonuclari
        medications: patientData.ilacKullanim, // ilac_kullanim
        diseases: patientData.hastaHastaliklar, // hastaliklar
      ));
    } catch (e) {
      emit(PatientDetailError("Failed to load patient data: $e"));
    }
  }
}

abstract class PatientDetailState {}

class PatientDetailInitial extends PatientDetailState {}

class PatientDetailLoading extends PatientDetailState {}

class PatientDetailLoaded extends PatientDetailState {
  final PatientResponseModel patient;
  PatientDetailLoaded(this.patient);
}

class PatientMedicalHistoryLoading extends PatientDetailState {}

class PatientMedicalHistoryLoaded extends PatientDetailState {
  final MedicalHistoryResponseModel? medicalHistory;
  PatientMedicalHistoryLoaded(this.medicalHistory);
}

class PatientLabResultsLoading extends PatientDetailState {}

class PatientLabResultsLoaded extends PatientDetailState {
  final List<LabResultResponseModel> labResults;
  PatientLabResultsLoaded(this.labResults);
}

class PatientMedicationsLoading extends PatientDetailState {}

class PatientMedicationsLoaded extends PatientDetailState {
  final List<MedicationUsageResponseModel> medications;
  PatientMedicationsLoaded(this.medications);
}

class PatientDiseasesLoading extends PatientDetailState {}

class PatientDiseasesLoaded extends PatientDetailState {
  final List<HastaHastalikResponseModel> diseases;
  PatientDiseasesLoaded(this.diseases);
}

class PatientAllDataLoaded extends PatientDetailState {
  final PatientResponseModel patient;
  final MedicalHistoryResponseModel? medicalHistory;
  final List<LabResultResponseModel> labResults;
  final List<MedicationUsageResponseModel> medications;
  final List<HastaHastalikResponseModel> diseases;

  PatientAllDataLoaded({
    required this.patient,
    required this.medicalHistory,
    required this.labResults,
    required this.medications,
    required this.diseases,
  });
}

class PatientDetailError extends PatientDetailState {
  final String message;
  PatientDetailError(this.message);
}