// models/response_models/medication_usage_response_model.dart
import 'package:mobile/models/response_models/hastalik_response_model.dart';
import 'package:mobile/models/response_models/ilac_response_model.dart';

class MedicationUsageResponseModel {
  final int kullanimId;
  final int hastaId;
  final int ilacId;
  final int? hastaHastalikId;
  final DateTime baslangicTarihi;
  final DateTime? bitisTarihi;
  final String? dozaj;
  final String? kullanimTalimati;
  final String? etkinlikDegerlendirmesi;
  final String? yanEtkiRaporlari;
  final bool aktif;
  final IlacResponseModel? ilac;
  final HastalikResponseModel? hastalik;

  MedicationUsageResponseModel({
    required this.kullanimId,
    required this.hastaId,
    required this.ilacId,
    this.hastaHastalikId,
    required this.baslangicTarihi,
    this.bitisTarihi,
    this.dozaj,
    this.kullanimTalimati,
    this.etkinlikDegerlendirmesi,
    this.yanEtkiRaporlari,
    required this.aktif,
    this.ilac,
    this.hastalik,
  });

  factory MedicationUsageResponseModel.fromJson(Map<String, dynamic> json) {
    return MedicationUsageResponseModel(
      kullanimId: json['kullanim_id'],
      hastaId: json['hasta_id'],
      ilacId: json['ilac_id'],
      hastaHastalikId: json['hasta_hastalik_id'],
      baslangicTarihi: DateTime.parse(json['baslangic_tarihi']),
      bitisTarihi: json['bitis_tarihi'] != null ? DateTime.parse(json['bitis_tarihi']) : null,
      dozaj: json['dozaj'],
      kullanimTalimati: json['kullanim_talimatı'],
      etkinlikDegerlendirmesi: json['etkinlik_degerlendirmesi'],
      yanEtkiRaporlari: json['yan_etki_raporlari'],
      aktif: json['aktif'] == 1 || json['aktif'] == true,
      ilac: json['ilac'] != null ? IlacResponseModel.fromJson(json['ilac']) : null,
      hastalik: json['hastalik'] != null ? HastalikResponseModel.fromJson(json['hastalik']) : null,
    );
  }
}