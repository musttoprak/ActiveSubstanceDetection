// models/response_models/hastalik_response_model.dart
class HastalikResponseModel {
  final int hastalikId;
  final String icdKodu;
  final String hastalikAdi;
  final String? hastalikKategorisi;
  final String? aciklama;

  HastalikResponseModel({
    required this.hastalikId,
    required this.icdKodu,
    required this.hastalikAdi,
    this.hastalikKategorisi,
    this.aciklama,
  });

  factory HastalikResponseModel.fromJson(Map<String, dynamic> json) {
    return HastalikResponseModel(
      hastalikId: json['hastalik_id'],
      icdKodu: json['icd_kodu'],
      hastalikAdi: json['hastalik_adi'],
      hastalikKategorisi: json['hastalik_kategorisi'],
      aciklama: json['aciklama'],
    );
  }
}