// models/response_models/hasta_hastalik_response_model.dart
import 'package:mobile/models/response_models/hastalik_response_model.dart';

class HastaHastalikResponseModel {
  final int hastaHastalikId;
  final int hastaId;
  final int hastalikId;
  final DateTime teshisTarihi;
  final String? siddet;
  final String? notlar;
  final bool aktif;
  final HastalikResponseModel? hastalik;

  HastaHastalikResponseModel({
    required this.hastaHastalikId,
    required this.hastaId,
    required this.hastalikId,
    required this.teshisTarihi,
    this.siddet,
    this.notlar,
    required this.aktif,
    this.hastalik,
  });

  factory HastaHastalikResponseModel.fromJson(Map<String, dynamic> json) {
    return HastaHastalikResponseModel(
      hastaHastalikId: json['hasta_hastalik_id'],
      hastaId: json['hasta_id'],
      hastalikId: json['hastalik_id'],
      teshisTarihi: DateTime.parse(json['teshis_tarihi']),
      siddet: json['siddet'],
      notlar: json['notlar'],
      aktif: json['aktif'] == 1 || json['aktif'] == true,
      hastalik: json['hastalik'] != null ? HastalikResponseModel.fromJson(json['hastalik']) : null,
    );
  }
}