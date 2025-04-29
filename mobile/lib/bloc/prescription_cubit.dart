// cubit/prescription_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/response_models/drug_recommendation_model.dart';
import '../models/response_models/prescription_response_model.dart';
import '../service/prescription_service.dart';

// States
abstract class PrescriptionState {}

class PrescriptionInitial extends PrescriptionState {}

class PrescriptionLoading extends PrescriptionState {}

class PrescriptionLoaded extends PrescriptionState {
  final List<PrescriptionResponseModel> prescriptions;

  PrescriptionLoaded(this.prescriptions);
}

class PrescriptionDetailLoading extends PrescriptionState {}

class PrescriptionDetailLoaded extends PrescriptionState {
  final bool isAddMedicine;
  final PrescriptionResponseModel prescription;

  PrescriptionDetailLoaded(this.prescription, this.isAddMedicine);
}

class PrescriptionRecommendationsLoading extends PrescriptionState {}

class PrescriptionRecommendationsLoaded extends PrescriptionState {
  final List<DrugRecommendationModel> recommendations;
  final PrescriptionResponseModel prescription;

  PrescriptionRecommendationsLoaded(this.recommendations, this.prescription);
}

class PrescriptionError extends PrescriptionState {
  final String message;

  PrescriptionError(this.message);
}

class PrescriptionDetailError extends PrescriptionError {
  final String receteNo;

  PrescriptionDetailError(super.message, this.receteNo);
}

class PrescriptionSuccess extends PrescriptionState {
  final String message;

  PrescriptionSuccess(this.message);
}

// Cubit
class PrescriptionCubit extends Cubit<PrescriptionState> {
  PrescriptionCubit() : super(PrescriptionInitial());

  int currentPage = 1;
  final int perPage = 15;
  bool hasMoreData = true;
  List<PrescriptionResponseModel> allPrescriptions = [];

  // Tüm reçeteleri getir
  Future<void> getAllPrescriptions({bool refresh = false}) async {
    if (refresh) {
      currentPage = 1;
      allPrescriptions = [];
      hasMoreData = true;
    }

    if (!hasMoreData && !refresh) {
      return;
    }

    if (state is PrescriptionLoading && !refresh) {
      return;
    }

    try {
      emit(PrescriptionLoading());

      final prescriptions = await PrescriptionService.getAllPrescriptions(
        page: currentPage,
        perPage: perPage,
      );

      if (prescriptions.isEmpty) {
        hasMoreData = false;
      } else {
        currentPage++;
        allPrescriptions.addAll(prescriptions);
      }

      emit(PrescriptionLoaded(allPrescriptions));
    } catch (e) {
      emit(PrescriptionError("Failed to fetch prescriptions: $e"));
    }
  }

  // Reçete detayını getir
  Future<void> getPrescriptionDetails(int id) async {
    emit(PrescriptionDetailLoading());
    try {
      final prescription = await PrescriptionService.getPrescriptionById(id);
      emit(PrescriptionDetailLoaded(prescription, false));
    } catch (e) {
      emit(PrescriptionError("Failed to fetch prescription details: $e"));
    }
  }

  // Hasta reçetelerini getir
  Future<void> getPatientPrescriptions(int hastaId) async {
    emit(PrescriptionLoading());
    try {
      final prescriptions =
      await PrescriptionService.getPatientPrescriptions(hastaId);
      emit(PrescriptionLoaded(prescriptions));
    } catch (e) {
      emit(PrescriptionError("Failed to fetch patient prescriptions: $e"));
    }
  }

  // QR kod ile reçete getir
  Future<void> getPrescriptionByQR(String receteNo,
      {bool isAddMedicine = false, PrescriptionResponseModel? prescription}) async {
    if (isAddMedicine) {
      emit(PrescriptionDetailLoaded(prescription!, true));
    } else {
      emit(PrescriptionDetailLoading());
    }
    try {
      final prescription =
      await PrescriptionService.getPrescriptionByQR(receteNo);
      emit(PrescriptionDetailLoaded(prescription, false));
    } catch (e) {
      emit(PrescriptionError("Failed to fetch prescription by QR: $e"));
    }
  }

  // Reçete için ilaç önerisi al
  Future<void> requestPrescriptionRecommendations(int receteId,
      PrescriptionResponseModel prescription) async {
    try {
      // İlaç önerisi isteği gönder
      await PrescriptionService.getPrescriptionRecommendations(receteId);

      await Future.delayed(Duration(seconds: 2));
      print("kuyruğa bakıyoruz");
      // Önerileri çek
      await getPrescriptionSuggestions(receteId, prescription);
      print("baktık");
    } catch (e) {
      emit(PrescriptionError("İlaç önerisi isteği başarısız: $e"));
    }
  }

  // Reçeteye önerilen ilaçları getir
  Future<void> getPrescriptionSuggestions(int receteId,
      PrescriptionResponseModel prescription) async {
    try {
      print("loading");
      final recommendations =
      await PrescriptionService.getPrescriptionSuggestions(receteId);
      print("service de ");
      emit(PrescriptionRecommendationsLoaded(recommendations, prescription));
    } catch (e) {
      emit(PrescriptionError("Failed to fetch prescription suggestions: $e"));
    }
  }

  // Önerilen ilacı reçeteye ekle
  Future<void> addSuggestionToPrescription(String receteNo,
      int receteId,
      PrescriptionRecommendationsLoaded addState,
      int oneriId, {
        String? dozaj,
        String? kullanimTalimati,
        int miktar = 1,
      }) async {
    try {
      await PrescriptionService.addSuggestionToPrescription(
        receteId,
        oneriId,
        dozaj: dozaj,
        kullanimTalimati: kullanimTalimati,
        miktar: miktar,
      );
      print("eklenmiş olması lazım");
      // Reçete detaylarını yenile
      getPrescriptionByQR(receteNo, isAddMedicine: true, prescription: addState.prescription);
      print("veri çekildi");
      //emit(PrescriptionSuccess("Suggestion added to prescription successfully"));
    } catch (e) {
      emit(PrescriptionError("Failed to add suggestion to prescription: $e"));
    }
  }

  // Yeni reçete oluştur
  Future<void> createPrescription({
    required int hastaId,
    required int hastalikId,
    int? doktorId,
    required String tarih,
    String? notlar,
    List<Map<String, dynamic>>? ilaclar,
  }) async {
    emit(PrescriptionLoading());
    try {
      final prescription = await PrescriptionService.createPrescription(
        hastaId: hastaId,
        hastalikId: hastalikId,
        doktorId: doktorId,
        tarih: tarih,
        notlar: notlar,
        ilaclar: ilaclar,
      );

      emit(PrescriptionDetailLoaded(prescription, false));
    } catch (e) {
      emit(PrescriptionError("Failed to create prescription: $e"));
    }
  }

  // Reçeteyi güncelle
  Future<void> updatePrescription({
    required int receteId,
    int? hastaId,
    int? hastalikId,
    int? doktorId,
    String? tarih,
    String? notlar,
    String? durum,
    bool? aktif,
    List<Map<String, dynamic>>? ilaclar,
  }) async {
    emit(PrescriptionLoading());
    try {
      final prescription = await PrescriptionService.updatePrescription(
        receteId: receteId,
        hastaId: hastaId,
        hastalikId: hastalikId,
        doktorId: doktorId,
        tarih: tarih,
        notlar: notlar,
        durum: durum,
        aktif: aktif,
        ilaclar: ilaclar,
      );

      emit(PrescriptionDetailLoaded(prescription, false));
    } catch (e) {
      emit(PrescriptionError("Failed to update prescription: $e"));
    }
  }

  // Reçeteyi sil
  Future<void> deletePrescription(int receteId) async {
    try {
      await PrescriptionService.deletePrescription(receteId);
      emit(PrescriptionSuccess("Prescription deleted successfully"));

      // Tüm reçeteleri yenile
      getAllPrescriptions(refresh: true);
    } catch (e) {
      emit(PrescriptionError("Failed to delete prescription: $e"));
    }
  }
}
