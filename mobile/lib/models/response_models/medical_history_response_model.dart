// models/response_models/medical_history_response_model.dart
class MedicalHistoryResponseModel {
  final int tibbiGecmisId;
  final int hastaId;
  final String? kronikHastaliklar;
  final String? gecirilenAmeliyatlar;
  final String? alerjiler;
  final String? aileHastaliklari;
  final String? sigaraKullanimi;
  final String? alkolTuketimi;
  final String? fizikselAktivite;
  final String? beslenmeAliskanliklari;

  MedicalHistoryResponseModel({
    required this.tibbiGecmisId,
    required this.hastaId,
    this.kronikHastaliklar,
    this.gecirilenAmeliyatlar,
    this.alerjiler,
    this.aileHastaliklari,
    this.sigaraKullanimi,
    this.alkolTuketimi,
    this.fizikselAktivite,
    this.beslenmeAliskanliklari,
  });

  factory MedicalHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return MedicalHistoryResponseModel(
      tibbiGecmisId: json['tibbi_gecmis_id'],
      hastaId: json['hasta_id'],
      kronikHastaliklar: json['kronik_hastaliklar'],
      gecirilenAmeliyatlar: json['gecirilen_ameliyatlar'],
      alerjiler: json['alerjiler'],
      aileHastaliklari: json['aile_hastaliklari'],
      sigaraKullanimi: json['sigara_kullanimi'],
      alkolTuketimi: json['alkol_tuketimi'],
      fizikselAktivite: json['fiziksel_aktivite'],
      beslenmeAliskanliklari: json['beslenme_aliskanliklari'],
    );
  }
}