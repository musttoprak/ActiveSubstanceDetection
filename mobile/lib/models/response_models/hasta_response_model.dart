// models/response_models/patient_response_model.dart
class HastaResponseModel {
  final int hastaId;
  final String ad;
  final String soyad;
  final int? yas;
  final String? cinsiyet;
  final double? boy;
  final double? kilo;
  final double? vki;
  final DateTime? dogumTarihi;
  final String? tcKimlik;
  final String? telefon;
  final String? email;
  final String? adres;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  HastaResponseModel({
    required this.hastaId,
    required this.ad,
    required this.soyad,
    this.yas,
    this.cinsiyet,
    this.boy,
    this.kilo,
    this.vki,
    this.dogumTarihi,
    this.tcKimlik,
    this.telefon,
    this.email,
    this.adres,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Tam ad getter'ı
  String get tamAd => "$ad $soyad";

  factory HastaResponseModel.fromJson(Map<String, dynamic> json) {
    return HastaResponseModel(
      hastaId: json['hasta_id'],
      ad: json['ad'] ?? '',
      soyad: json['soyad'] ?? '',
      yas: json['yas'],
      cinsiyet: json['cinsiyet'],
      boy: json['boy'] != null ? double.parse(json['boy'].toString()) : null,
      kilo: json['kilo'] != null ? double.parse(json['kilo'].toString()) : null,
      vki: json['vki'] != null ? double.parse(json['vki'].toString()) : null,
      dogumTarihi: json['dogum_tarihi'] != null ? DateTime.parse(json['dogum_tarihi']) : null,
      tcKimlik: json['tc_kimlik'],
      telefon: json['telefon'],
      email: json['email'],
      adres: json['adres'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  // JSON'a dönüştürme metodu (gerektiğinde)
  Map<String, dynamic> toJson() {
    return {
      'hasta_id': hastaId,
      'ad': ad,
      'soyad': soyad,
      'yas': yas,
      'cinsiyet': cinsiyet,
      'boy': boy,
      'kilo': kilo,
      'vki': vki,
      'dogum_tarihi': dogumTarihi?.toIso8601String(),
      'tc_kimlik': tcKimlik,
      'telefon': telefon,
      'email': email,
      'adres': adres,
    };
  }
}