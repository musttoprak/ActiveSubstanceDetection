// cubit/patient_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/response_models/patient_response_model.dart';
import '../service/patient_service.dart';

class PatientCubit extends Cubit<PatientState> {
  PatientCubit() : super(PatientInitial());

  int currentPage = 1;
  final int perPage = 15;
  bool hasMoreData = true;
  List<PatientResponseModel> allPatients = [];

  // Tüm hastaları getir
  Future<void> getAllPatients({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      allPatients = [];
      hasMoreData = true;
    }

    if (!hasMoreData && !refresh) {
      return;
    }

    if (state is PatientLoading && !refresh) {
      return;
    }

    try {
      emit(PatientLoading());

      final patients = await PatientService.getAllPatients(
        page: currentPage,
        perPage: perPage,
      );

      if (patients.isEmpty) {
        hasMoreData = false;
      } else {
        currentPage++;
        allPatients.addAll(patients);
      }

      emit(PatientLoaded(allPatients));
    } catch (e) {
      emit(PatientError("Failed to fetch patients: $e"));
    }
  }

  // Hasta ara
  Future<void> searchPatients(String query) async {
    emit(PatientLoading());
    try {
      if (query.isEmpty) {
        getAllPatients(refresh: true);
        return;
      }

      final patients = await PatientService.searchPatients(query);
      emit(PatientLoaded(patients));
    } catch (e) {
      emit(PatientError("Failed to search patients: $e"));
    }
  }

  // Hasta detaylarını getir
  Future<void> getPatientDetails(int id) async {
    emit(PatientDetailLoading());
    try {
      final patient = await PatientService.getPatientById(id);
      emit(PatientDetailLoaded(patient));
    } catch (e) {
      emit(PatientError("Failed to fetch patient details: $e"));
    }
  }
}

// State sınıfları
abstract class PatientState {}

class PatientInitial extends PatientState {}

class PatientLoading extends PatientState {}

class PatientLoaded extends PatientState {
  final List<PatientResponseModel> patients;
  PatientLoaded(this.patients);
}

class PatientDetailLoading extends PatientState {}

class PatientDetailLoaded extends PatientState {
  final PatientResponseModel patient;
  PatientDetailLoaded(this.patient);
}

class PatientError extends PatientState {
  final String message;
  PatientError(this.message);
}