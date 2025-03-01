// models/response_models/lab_result_response_model.dart
class LabResultResponseModel {
  final int sonucId;
  final int hastaId;
  final String testTuru;
  final String? testKodu;
  final String deger;
  final String? birim;
  final String? referansAralik;
  final bool normalMi;
  final DateTime testTarihi;
  final String? notlar;

  LabResultResponseModel({
    required this.sonucId,
    required this.hastaId,
    required this.testTuru,
    this.testKodu,
    required this.deger,
    this.birim,
    this.referansAralik,
    required this.normalMi,
    required this.testTarihi,
    this.notlar,
  });

  factory LabResultResponseModel.fromJson(Map<String, dynamic> json) {
    return LabResultResponseModel(
      sonucId: json['sonuc_id'],
      hastaId: json['hasta_id'],
      testTuru: json['test_turu'],
      testKodu: json['test_kodu'],
      deger: json['deger'],
      birim: json['birim'],
      referansAralik: json['referans_aralik'],
      normalMi: json['normal_mi'] == 1 || json['normal_mi'] == true,
      testTarihi: DateTime.parse(json['test_tarihi']),
      notlar: json['notlar'],
    );
  }
}