// models/response_models/drug_recommendation_model.dart
import 'package:mobile/models/response_models/ilac_response_model.dart';

class DrugRecommendationModel {
  final int oneriId;
  final int hastaId;
  final int hastalikId;
  final int ilacId;
  final double oneriPuani;
  final String? oneriSebebi;
  final bool uygulanmaDurumu;
  final String? doktorGeribildirimi;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IlacResponseModel? ilac;

  DrugRecommendationModel({
    required this.oneriId,
    required this.hastaId,
    required this.hastalikId,
    required this.ilacId,
    required this.oneriPuani,
    this.oneriSebebi,
    required this.uygulanmaDurumu,
    this.doktorGeribildirimi,
    required this.createdAt,
    required this.updatedAt,
    this.ilac,
  });

  factory DrugRecommendationModel.fromJson(Map<String, dynamic> json) {
    return DrugRecommendationModel(
      oneriId: json['oneri_id'],
      hastaId: json['hasta_id'],
      hastalikId: json['hastalik_id'],
      ilacId: json['ilac_id'],
      oneriPuani: json['oneri_puani'].toDouble(),
      oneriSebebi: json['oneri_sebebi'],
      uygulanmaDurumu: json['uygulanma_durumu'] ?? false,
      doktorGeribildirimi: json['doktor_geribildirimi'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      ilac: json['ilac'] != null ? IlacResponseModel.fromJson(json['ilac']) : null,
    );
  }
}