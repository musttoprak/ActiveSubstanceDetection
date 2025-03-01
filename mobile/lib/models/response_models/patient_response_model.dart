// models/response_models/patient_response_model.dart
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
    );
  }
}