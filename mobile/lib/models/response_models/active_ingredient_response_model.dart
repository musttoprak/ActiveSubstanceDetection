class ActiveIngredientResponseModel {
  final int id;
  final String name;
  final String? image_src;
  final String? weight;
  final String? molecular_weight;
  final String? formula;
  final String? related_atc_codes;
  final String? cas;
  final String? general_info;
  final String? mechanism;
  final String? pharmacokinetics;
  final String? company;
  final String? barcode;
  final String? prescription_type;
  final String? retail_price;
  final String? depot_price_with_vat;
  final String? depot_price_without_vat;
  final String? manufacturer_price_without_vat;
  final String? vat_info;
  final String? price_date;
  final String? active_substance;
  final String? dosage;
  final String? sgk_status;
  final List<Preparation>? preparations;

  ActiveIngredientResponseModel({
    required this.id,
    required this.name,
    this.image_src,
    this.weight,
    this.molecular_weight,
    this.formula,
    this.related_atc_codes,
    this.cas,
    this.general_info,
    this.mechanism,
    this.pharmacokinetics,
    this.company,
    this.barcode,
    this.prescription_type,
    this.retail_price,
    this.depot_price_with_vat,
    this.depot_price_without_vat,
    this.manufacturer_price_without_vat,
    this.vat_info,
    this.price_date,
    this.active_substance,
    this.dosage,
    this.sgk_status,
    this.preparations
  });

  factory ActiveIngredientResponseModel.fromJson(Map<String, dynamic> json) {
    print(json);
    return ActiveIngredientResponseModel(
      id: json['id'],
      name: json['name'],
      image_src: json['image_src'],
      weight: json['weight'],
      molecular_weight: json['molecular_weight'],
      formula: json['formula'],
      related_atc_codes: json['related_atc_codes'],
      cas: json['cas'],
      general_info: json['general_info'],
      mechanism: json['mechanism'],
      pharmacokinetics: json['pharmacokinetics'],
      company: json['company'],
      barcode: json['barcode'],
      prescription_type: json['prescription_type'],
      retail_price: json['retail_price'],
      depot_price_with_vat: json['depot_price_with_vat'],
      depot_price_without_vat: json['depot_price_without_vat'],
      manufacturer_price_without_vat: json['manufacturer_price_without_vat'],
      vat_info: json['vat_info'],
      price_date: json['price_date'],
      active_substance: json['active_substance'],
      dosage: json['dosage'],
      sgk_status: json['sgk_status'],
      preparations: (json['preparations'] as List<dynamic>?)
          ?.map((e) => Preparation.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_src': image_src,
      'weight': weight,
      'molecular_weight': molecular_weight,
      'formula': formula,
      'related_atc_codes': related_atc_codes,
      'cas': cas,
      'general_info': general_info,
      'mechanism': mechanism,
      'pharmacokinetics': pharmacokinetics,
      'company': company,
      'barcode': barcode,
      'prescription_type': prescription_type,
      'retail_price': retail_price,
      'depot_price_with_vat': depot_price_with_vat,
      'depot_price_without_vat': depot_price_without_vat,
      'manufacturer_price_without_vat': manufacturer_price_without_vat,
      'vat_info': vat_info,
      'price_date': price_date,
      'active_substance': active_substance,
      'dosage': dosage,
      'sgk_status': sgk_status,
      'preparations': preparations?.map((e) => e.toJson()).toList(),
    };
  }
}

class Preparation {
  final int id;
  final String name;
  final String? company;
  final String? sgk_status;
  final String? link;

  Preparation({
    required this.id,
    required this.name,
    this.company,
    this.sgk_status,
    this.link,
  });

  factory Preparation.fromJson(Map<String, dynamic> json) {
    return Preparation(
      id: json['id'],
      name: json['name'],
      company: json['company'],
      sgk_status: json['sgk_status'],
      link: json['link'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'sgk_status': sgk_status,
      'link': link,
    };
  }
}
