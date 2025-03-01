import 'package:mobile/models/response_models/hasta_hastalik_response_model.dart';
import 'package:mobile/models/response_models/hastalik_response_model.dart';
import 'package:mobile/models/response_models/lab_result_response_model.dart';
import 'package:mobile/models/response_models/medical_history_response_model.dart';
import 'package:mobile/models/response_models/medication_usage_response_model.dart,.dart';

class PatientResponseModel {
  final int hastaId;
  final String ad;
  final String soyad;
  final int yas;
  final String cinsiyet;
  final double? boy;
  final double? kilo;
  final double? vki;
  final DateTime? dogumTarihi;
  final String? tcKimlik;
  final String? telefon;
  final String? email;
  final String? adres;

  // İlişkili veriler
  final MedicalHistoryResponseModel? tibbiGecmis;
  final List<HastaHastalikResponseModel> hastaHastaliklar;
  final List<HastalikResponseModel> hastaliklar;
  final List<MedicationUsageResponseModel> ilacKullanim;
  final List<LabResultResponseModel> laboratuvarSonuclari;
  final List<MedicalHistoryResponseModel> ilacOnerileri;

  PatientResponseModel({
    required this.hastaId,
    required this.ad,
    required this.soyad,
    required this.yas,
    required this.cinsiyet,
    this.boy,
    this.kilo,
    this.vki,
    this.dogumTarihi,
    this.tcKimlik,
    this.telefon,
    this.email,
    this.adres,
    this.tibbiGecmis,
    this.hastaHastaliklar = const [],
    this.hastaliklar = const [],
    this.ilacKullanim = const [],
    this.laboratuvarSonuclari = const [],
    this.ilacOnerileri = const [],
  });

  String get tamAd => "$ad $soyad";

  factory PatientResponseModel.fromJson(Map<String, dynamic> json) {
    return PatientResponseModel(
      hastaId: json['hasta_id'],
      ad: json['ad'],
      soyad: json['soyad'],
      yas: json['yas'],
      cinsiyet: json['cinsiyet'],
      boy: json['boy']?.toDouble(),
      kilo: json['kilo']?.toDouble(),
      vki: json['vki']?.toDouble(),
      dogumTarihi: json['dogum_tarihi'] != null ? DateTime.parse(json['dogum_tarihi']) : null,
      tcKimlik: json['tc_kimlik'],
      telefon: json['telefon'],
      email: json['email'],
      adres: json['adres'],

      // İlişkili verileri parse et
      tibbiGecmis: json['tibbi_gecmis'] != null
          ? MedicalHistoryResponseModel.fromJson(json['tibbi_gecmis'])
          : null,

      hastaHastaliklar: (json['hasta_hastaliklar'] as List<dynamic>?)
          ?.map((e) => HastaHastalikResponseModel.fromJson(e))
          .toList() ?? [],

      hastaliklar: (json['hastaliklar'] as List<dynamic>?)
          ?.map((e) => HastalikResponseModel.fromJson(e))
          .toList() ?? [],

      ilacKullanim: (json['ilac_kullanim'] as List<dynamic>?)
          ?.map((e) => MedicationUsageResponseModel.fromJson(e))
          .toList() ?? [],

      laboratuvarSonuclari: (json['laboratuvar_sonuclari'] as List<dynamic>?)
          ?.map((e) => LabResultResponseModel.fromJson(e))
          .toList() ?? [],

      ilacOnerileri: (json['ilac_onerileri'] as List<dynamic>?)
          ?.map((e) => MedicalHistoryResponseModel.fromJson(e))
          .toList() ?? [],
    );
  }
}