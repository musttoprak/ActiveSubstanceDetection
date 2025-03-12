import 'dart:convert';
import 'package:dio/dio.dart';

class MustahzarModel {
  final String? adi;
  final String? barkod;
  final String? firma;
  final String? fiyat;
  final String? sgkDurumu;
  final String? etkenMaddeMiktari;
  final String? receteTipi;

  MustahzarModel({
    this.adi,
    this.barkod,
    this.firma,
    this.fiyat,
    this.sgkDurumu,
    this.etkenMaddeMiktari,
    this.receteTipi,
  });

  factory MustahzarModel.fromJson(Map<String, dynamic> json) {
    return MustahzarModel(
      adi: json['adi'],
      barkod: json['barkod'],
      firma: json['firma'],
      fiyat: json['fiyat'],
      sgkDurumu: json['sgk_durumu'],
      etkenMaddeMiktari: json['etken_madde_miktari'],
      receteTipi: json['recete_tipi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adi': adi,
      'barkod': barkod,
      'firma': firma,
      'fiyat': fiyat,
      'sgk_durumu': sgkDurumu,
      'etken_madde_miktari': etkenMaddeMiktari,
      'recete_tipi': receteTipi,
    };
  }
}

class EtkenMaddeResponseModel {
  final int etkenMaddeId;
  final String etkenMaddeAdi;
  final String? ingilizceAdi;
  final String? netKutle;
  final String? molekulAgirligi;
  final String? formul;
  final String? atcKodlari;
  final String? genelBilgi;
  final String? etkiMekanizmasi;
  final String? farmakokinetik;
  final String? resimUrl;
  final List<MustahzarModel>? mustahzarlar;
  final String? etkenMaddeKategorisi;
  final String? aciklama;

  EtkenMaddeResponseModel({
    required this.etkenMaddeId,
    required this.etkenMaddeAdi,
    this.ingilizceAdi,
    this.netKutle,
    this.molekulAgirligi,
    this.formul,
    this.atcKodlari,
    this.genelBilgi,
    this.etkiMekanizmasi,
    this.farmakokinetik,
    this.resimUrl,
    this.mustahzarlar,
    this.etkenMaddeKategorisi,
    this.aciklama,
  });

  factory EtkenMaddeResponseModel.fromJson(Map<String, dynamic> json) {
    // Mustahzarlar alanını işle
    List<MustahzarModel>? mustahzarlarList;
    if (json['mustahzarlar'] != null) {
      dynamic mustahzarlarData = json['mustahzarlar'];
      print(mustahzarlarData);
      // Eğer String olarak geldiyse JSON'a dönüştür
      if (mustahzarlarData is String) {
        try {
          mustahzarlarData = jsonDecode(mustahzarlarData);
        } catch (e) {
          print("Mustahzarlar JSON decode hatası: $e");
          mustahzarlarData = [];
        }
      }

      // Liste olarak işle
      if (mustahzarlarData is List) {
        mustahzarlarList = mustahzarlarData
            .map((item) => item is Map<String, dynamic>
            ? MustahzarModel.fromJson(item)
            : MustahzarModel())
            .toList();
      } else if (mustahzarlarData is Map) {
        // Eğer map ise ve anahtarları varsa, değerleri liste olarak al
        mustahzarlarList = mustahzarlarData.values
            .map((item) => item is Map<String, dynamic>
            ? MustahzarModel.fromJson(item)
            : MustahzarModel())
            .toList();
      }
    }

    return EtkenMaddeResponseModel(
      etkenMaddeId: json['etken_madde_id'] is String
          ? int.parse(json['etken_madde_id'])
          : json['etken_madde_id'],
      etkenMaddeAdi: json['etken_madde_adi'],
      ingilizceAdi: json['ingilizce_adi'],
      netKutle: json['net_kutle'],
      molekulAgirligi: json['molekul_agirligi'],
      formul: json['formul'],
      atcKodlari: json['atc_kodlari'],
      genelBilgi: json['genel_bilgi'],
      etkiMekanizmasi: json['etki_mekanizmasi'],
      farmakokinetik: json['farmakokinetik'],
      resimUrl: json['resim_url'],
      mustahzarlar: mustahzarlarList,
      etkenMaddeKategorisi: json['etken_madde_kategorisi'],
      aciklama: json['aciklama'],
    );
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>>? mustahzarlarJson;
    if (mustahzarlar != null) {
      mustahzarlarJson = mustahzarlar!.map((m) => m.toJson()).toList();
    }

    return {
      'etken_madde_id': etkenMaddeId,
      'etken_madde_adi': etkenMaddeAdi,
      'ingilizce_adi': ingilizceAdi,
      'net_kutle': netKutle,
      'molekul_agirligi': molekulAgirligi,
      'formul': formul,
      'atc_kodlari': atcKodlari,
      'genel_bilgi': genelBilgi,
      'etki_mekanizmasi': etkiMekanizmasi,
      'farmakokinetik': farmakokinetik,
      'resim_url': resimUrl,
      'mustahzarlar': mustahzarlarJson,
      'etken_madde_kategorisi': etkenMaddeKategorisi,
      'aciklama': aciklama,
    };
  }
}