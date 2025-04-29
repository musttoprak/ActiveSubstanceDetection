import 'dart:convert';

import 'package:mobile/models/response_models/active_ingredient_response_model.dart';

class MedicineResponseModel {
  final int? ilacId;
  final String? ilacAdi;
  final String? barkod;
  final String? atcKodu;
  final String? ureticiFirma;
  final String? ilacKodu;
  final int? ilacKategoriId;
  final String? ilacAdiFirma;
  final double? perakendeSatisFiyati;
  final double? depocuSatisFiyatiKdvDahil;
  final double? depocuSatisFiyatiKdvHaric;
  final double? imalatciSatisFiyatiKdvHaric;
  final DateTime? fiyatTarihi;
  final String? sgkDurumu;
  final String? receteTipi;
  final String? etkiMekanizmasi;
  final String? farmakokinetik;
  final String? farmakodinamik;
  final String? endikasyonlar;
  final String? kontrendikasyonlar;
  final String? kullanimYolu;
  final String? yanEtkiler;
  final String? ilacEtkilesimleri;
  final String? ozelPopulasyonBilgileri;
  final String? uyarilarVeOnlemler;
  final String? formulasyon;
  final String? ambalajBilgisi;
  final String? miktar; // Pivot'dan gelen veri
  final List<dynamic>? etkenMaddeler;

  MedicineResponseModel({
    this.ilacId,
    this.ilacAdi,
    this.barkod,
    this.atcKodu,
    this.ureticiFirma,
    this.ilacKodu,
    this.ilacKategoriId,
    this.ilacAdiFirma,
    this.perakendeSatisFiyati,
    this.depocuSatisFiyatiKdvDahil,
    this.depocuSatisFiyatiKdvHaric,
    this.imalatciSatisFiyatiKdvHaric,
    this.fiyatTarihi,
    this.sgkDurumu,
    this.receteTipi,
    this.etkiMekanizmasi,
    this.farmakokinetik,
    this.farmakodinamik,
    this.endikasyonlar,
    this.kontrendikasyonlar,
    this.kullanimYolu,
    this.yanEtkiler,
    this.ilacEtkilesimleri,
    this.ozelPopulasyonBilgileri,
    this.uyarilarVeOnlemler,
    this.formulasyon,
    this.ambalajBilgisi,
    this.miktar,
    this.etkenMaddeler
  });

  factory MedicineResponseModel.fromJson(Map<String, dynamic> json) {
    return MedicineResponseModel(
      ilacId: json['ilac_id'] is String ? int.parse(json['ilac_id']) : json['ilac_id'],
      ilacAdi: json['ilac_adi'],
      barkod: json['barkod'],
      atcKodu: json['atc_kodu'],
      ureticiFirma: json['uretici_firma'],
      ilacKodu: json['ilac_kodu'],
      ilacKategoriId: json['ilac_kategori_id'] is String && json['ilac_kategori_id'].isNotEmpty
          ? int.parse(json['ilac_kategori_id'])
          : json['ilac_kategori_id'],
      ilacAdiFirma: json['ilac_adi_firma'],
      perakendeSatisFiyati: _parseDouble(json['perakende_satis_fiyati']),
      depocuSatisFiyatiKdvDahil: _parseDouble(json['depocu_satis_fiyati_kdv_dahil']),
      depocuSatisFiyatiKdvHaric: _parseDouble(json['depocu_satis_fiyati_kdv_haric']),
      imalatciSatisFiyatiKdvHaric: _parseDouble(json['imalatci_satis_fiyati_kdv_haric']),
      fiyatTarihi: json['fiyat_tarihi'] != null ? DateTime.parse(json['fiyat_tarihi']) : null,
      sgkDurumu: json['sgk_durumu'],
      receteTipi: json['recete_tipi'],
      etkiMekanizmasi: json['etki_mekanizmasi'],
      farmakokinetik: json['farmakokinetik'],
      farmakodinamik: json['farmakodinamik'],
      endikasyonlar: json['endikasyonlar'],
      kontrendikasyonlar: json['kontrendikasyonlar'],
      kullanimYolu: json['kullanim_yolu'],
      yanEtkiler: json['yan_etkiler'],
      ilacEtkilesimleri: json['ilac_etkilesimleri'],
      ozelPopulasyonBilgileri: json['ozel_populasyon_bilgileri'],
      uyarilarVeOnlemler: json['uyarilar_ve_onlemler'],
      formulasyon: json['formulasyon'],
      ambalajBilgisi: json['ambalaj_bilgisi'],
      miktar: json['pivot'] != null ? json['pivot']['miktar'] : json['miktar'],
      etkenMaddeler: json['etken_maddeler'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ilac_id': ilacId,
      'ilac_adi': ilacAdi,
      'barkod': barkod,
      'atc_kodu': atcKodu,
      'uretici_firma': ureticiFirma,
      'ilac_kodu': ilacKodu,
      'ilac_kategori_id': ilacKategoriId,
      'ilac_adi_firma': ilacAdiFirma,
      'perakende_satis_fiyati': perakendeSatisFiyati,
      'depocu_satis_fiyati_kdv_dahil': depocuSatisFiyatiKdvDahil,
      'depocu_satis_fiyati_kdv_haric': depocuSatisFiyatiKdvHaric,
      'imalatci_satis_fiyati_kdv_haric': imalatciSatisFiyatiKdvHaric,
      'fiyat_tarihi': fiyatTarihi?.toIso8601String(),
      'sgk_durumu': sgkDurumu,
      'recete_tipi': receteTipi,
      'etki_mekanizmasi': etkiMekanizmasi,
      'farmakokinetik': farmakokinetik,
      'farmakodinamik': farmakodinamik,
      'endikasyonlar': endikasyonlar,
      'kontrendikasyonlar': kontrendikasyonlar,
      'kullanim_yolu': kullanimYolu,
      'yan_etkiler': yanEtkiler,
      'ilac_etkilesimleri': ilacEtkilesimleri,
      'ozel_populasyon_bilgileri': ozelPopulasyonBilgileri,
      'uyarilar_ve_onlemler': uyarilarVeOnlemler,
      'formulasyon': formulasyon,
      'ambalaj_bilgisi': ambalajBilgisi,
      'miktar': miktar,
      'etkenMaddeler': etkenMaddeler,
    };
  }

  // Tip dönüşümü yardımcı fonksiyonu
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}