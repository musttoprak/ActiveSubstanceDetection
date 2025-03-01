// models/response_models/ilac_response_model.dart
class IlacResponseModel {
  final int ilacId;
  final String ilacAdi;
  final String? barkod;
  final String? atcKodu;
  final String? ureticiFirma;
  final String? ilacAdiFirma;

  IlacResponseModel({
    required this.ilacId,
    required this.ilacAdi,
    this.barkod,
    this.atcKodu,
    this.ureticiFirma,
    this.ilacAdiFirma,
  });

  factory IlacResponseModel.fromJson(Map<String, dynamic> json) {
    return IlacResponseModel(
      ilacId: json['ilac_id'],
      ilacAdi: json['ilac_adi'],
      barkod: json['barkod'],
      atcKodu: json['atc_kodu'],
      ureticiFirma: json['uretici_firma'],
      ilacAdiFirma: json['ilac_adi_firma'],
    );
  }
}