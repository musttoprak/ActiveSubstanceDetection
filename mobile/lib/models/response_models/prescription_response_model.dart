// models/response_models/prescription_response_model.dart
import 'package:mobile/models/response_models/hastalik_response_model.dart';
import 'package:mobile/models/response_models/ilac_response_model.dart';

import 'hasta_response_model.dart';

class PrescriptionResponseModel {
  final int receteId;
  final int hastaId;
  final int hastalikId;
  final String receteNo;
  final String tarih;
  final String? notlar;
  final String durum;
  final bool aktif;
  final DateTime createdAt;
  final DateTime updatedAt;
  final HastaResponseModel? hasta;
  final HastalikResponseModel? hastalik;
  final String? doktor;
  final List<PrescriptionMedicationModel> ilaclar;

  PrescriptionResponseModel({
    required this.receteId,
    required this.hastaId,
    required this.hastalikId,
    required this.receteNo,
    required this.tarih,
    this.notlar,
    required this.durum,
    required this.aktif,
    required this.createdAt,
    required this.updatedAt,
    this.hasta,
    this.hastalik,
    this.doktor,
    required this.ilaclar,
  });

  factory PrescriptionResponseModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionResponseModel(
      receteId: json['recete_id'],
      hastaId: json['hasta_id'],
      hastalikId: json['hastalik_id'],
      receteNo: json['recete_no'],
      tarih: json['tarih'],
      notlar: json['notlar'],
      durum: json['durum'],
      aktif: json['aktif'] == 1 ? true : false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      hasta: json['hasta'] != null ? HastaResponseModel.fromJson(json['hasta']) : null,
      hastalik: json['hastalik'] != null ? HastalikResponseModel.fromJson(json['hastalik']) : null,
      doktor: json['doktor'],
      ilaclar: json['ilaclar'] != null
          ? List<PrescriptionMedicationModel>.from(
          json['ilaclar'].map((x) => PrescriptionMedicationModel.fromJson(x)))
          : [],
    );
  }
}

class PrescriptionMedicationModel {
  final int receteIlacId;
  final int receteId;
  final int ilacId;
  final String? dozaj;
  final String? kullanimTalimati;
  final int miktar;
  final IlacResponseModel? ilac;

  PrescriptionMedicationModel({
    required this.receteIlacId,
    required this.receteId,
    required this.ilacId,
    this.dozaj,
    this.kullanimTalimati,
    required this.miktar,
    this.ilac,
  });

  factory PrescriptionMedicationModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicationModel(
      receteIlacId: json['recete_ilac_id'],
      receteId: json['recete_id'],
      ilacId: json['ilac_id'],
      dozaj: json['dozaj'],
      kullanimTalimati: json['kullanim_talimati'],
      miktar: json['miktar'] ?? 1,
      ilac: json['ilac'] != null ? IlacResponseModel.fromJson(json['ilac']) : null,
    );
  }
}