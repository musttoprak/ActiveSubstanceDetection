<?php

namespace Database\Seeders;

use App\Models\Hasta;
use App\Models\HastaHastalik;
use App\Models\Ilac;
use App\Models\HastaIlacKullanim;
use App\Models\IlacEtkenMadde;
use Illuminate\Database\Seeder;
use Faker\Factory as Faker;
use Carbon\Carbon;

class HastaIlacKullanimSeeder extends Seeder
{
    // Hastalık kategorilerine göre ilaç-etken madde ilişkileri
    private $hastalikKategorisiIlacIliskileri = [
        'Kardiyovasküler' => [
            'ilaçlar' => [
                'ramipril', 'amlodipin', 'atorvastatin', 'metoprolol', 'enalapril',
                'lisinopril', 'valsartan', 'kandesartan', 'propranolol', 'bisoprolol',
                'losartan', 'simvastatin', 'warfarin', 'aspirin', 'klopidogrel',
                'furosemid', 'spironolakton', 'hidroklorotiyazid', 'digoksin', 'diltiyazem'
            ],
            'dozajlar' => ['5 mg', '10 mg', '20 mg', '25 mg', '40 mg', '50 mg', '75 mg', '100 mg']
        ],
        'Solunum Sistemi' => [
            'ilaçlar' => [
                'salbutamol', 'flutikazon', 'budesonid', 'formoterol', 'tiotropium',
                'montelukast', 'teofilin', 'ipratropium', 'roflumilast', 'zafirlukast',
                'desloratadin', 'setirizin', 'feksofenadin', 'levosetirizin', 'loratadin'
            ],
            'dozajlar' => ['5 mg', '10 mg', '20 mg', '100 mcg', '200 mcg', '400 mcg', '250 mcg/puff', '500 mcg/puff']
        ],
        'Endokrin' => [
            'ilaçlar' => [
                'metformin', 'glimepirid', 'insülin glarjin', 'insülin aspart', 'dapagliflozin',
                'empagliflozin', 'sitagliptin', 'pioglitazon', 'liraglutid', 'eksenatid',
                'levotiroksin', 'propiltiourasil', 'karbimazol', 'metimazol'
            ],
            'dozajlar' => ['500 mg', '850 mg', '1000 mg', '2 mg', '4 mg', '100 U/ml', '10 mcg', '25 mcg', '50 mcg', '100 mcg']
        ],
        'Sindirim Sistemi' => [
            'ilaçlar' => [
                'omeprazol', 'pantoprazol', 'esomeprazol', 'lansoprazol', 'rabeprazol',
                'ranitidin', 'famotidin', 'simetidin', 'misoprostol', 'sukralfat',
                'domperidon', 'metoklopramid', 'ondansetron', 'loperamid', 'mesalazin'
            ],
            'dozajlar' => ['10 mg', '20 mg', '40 mg', '30 mg', '150 mg', '300 mg', '4 mg', '8 mg']
        ],
        'Nörolojik' => [
            'ilaçlar' => [
                'levodopa/karbidopa', 'pramipeksol', 'ropinirol', 'rasajilin', 'selejilin',
                'donepezil', 'memantin', 'rivastigmin', 'galantamin', 'topiramat',
                'lamotrijin', 'valproik asit', 'karbamazepin', 'levetirasetam', 'pregabalin',
                'gabapentin', 'sumatriptan', 'rizatriptan', 'zolmitriptan', 'amitriptilin'
            ],
            'dozajlar' => ['100 mg', '200 mg', '250 mg', '300 mg', '500 mg', '5 mg', '10 mg', '25 mg', '50 mg', '100 mg/ml']
        ],
        'Psikiyatrik' => [
            'ilaçlar' => [
                'fluoksetin', 'sertralin', 'paroksetin', 'essitalopram', 'venlafaksin',
                'duloksetin', 'mirtazapin', 'bupropion', 'amitriptilin', 'klomipramin',
                'alprazolam', 'diazepam', 'lorazepam', 'klonazepam', 'olanzapin',
                'risperidon', 'ketiapin', 'aripiprazol', 'ziprasidon', 'haloperidol'
            ],
            'dozajlar' => ['5 mg', '10 mg', '20 mg', '25 mg', '37.5 mg', '50 mg', '75 mg', '100 mg', '150 mg', '300 mg']
        ],
        'Kas-İskelet Sistemi' => [
            'ilaçlar' => [
                'diklofenak', 'ibuprofen', 'naproksen', 'meloksikam', 'selekoksib',
                'indometasin', 'etodolak', 'etorikoksib', 'piroksikam', 'tenoksikam',
                'alendronat', 'risedronat', 'zoledronik asit', 'denosumab', 'teriparatid',
                'kolşisin', 'allopurinol', 'febuksostat', 'prednizolon', 'metilprednizolon'
            ],
            'dozajlar' => ['50 mg', '75 mg', '100 mg', '200 mg', '400 mg', '500 mg', '600 mg', '800 mg', '10 mg', '15 mg', '20 mg', '4 mg', '8 mg', '16 mg']
        ],
        'Üriner Sistem' => [
            'ilaçlar' => [
                'furosemid', 'hidroklorotiyazid', 'spironolakton', 'amlodipin', 'valsartan',
                'enalapril', 'lisinopril', 'losartan', 'tamsulosin', 'silodosin',
                'alfuzosin', 'finasterid', 'dutasterid', 'tolterodin', 'solifenasin',
                'darifenasin', 'nitrofurantoin', 'siprofloksasin', 'nitrofurantoin', 'trimetoprim/sülfametoksazol'
            ],
            'dozajlar' => ['20 mg', '25 mg', '40 mg', '50 mg', '75 mg', '100 mg', '0.4 mg', '5 mg', '10 mg', '480 mg']
        ],
        'Dermatolojik' => [
            'ilaçlar' => [
                'metotreksat', 'siklosporin', 'asitretin', 'apremilast', 'adalimumab',
                'etanersept', 'infliksimab', 'ustekinumab', 'sekukinumab', 'guselkumab',
                'azatioprin', 'mikofenolat mofetil', 'dapson', 'hidroksiklorokin', 'takrolimus',
                'pimekrolimus', 'betametazon', 'mometazon', 'klobetazol', 'kalsipotriol/betametazon'
            ],
            'dozajlar' => ['2.5 mg', '5 mg', '7.5 mg', '10 mg', '15 mg', '20 mg', '25 mg', '40 mg', '50 mg', '100 mg', '200 mg', '300 mg']
        ]
    ];

    private $etkinlikOlasiliklari = [
        'Hafif' => [
            'Çok İyi' => 10,
            'İyi' => 30,
            'Orta' => 40,
            'Düşük' => 15,
            'Etkisiz' => 5
        ],
        'Orta' => [
            'Çok İyi' => 15,
            'İyi' => 35,
            'Orta' => 30,
            'Düşük' => 15,
            'Etkisiz' => 5
        ],
        'Şiddetli' => [
            'Çok İyi' => 25,
            'İyi' => 30,
            'Orta' => 25,
            'Düşük' => 15,
            'Etkisiz' => 5
        ]
    ];

    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $faker = Faker::create('tr_TR');

        // Hasta-hastalık ilişkilerini al
        $hastaHastaliklar = HastaHastalik::with(['hasta', 'hastalik'])->get();

        // İlaç veritabanındaki mevcut ilaçları al
        $ilaclar = Ilac::all();

        // İlaç sayısı yetersizse, ilaç örnekleri oluştur
        if ($ilaclar->count() < 100) {
            $this->createSampleDrugs();
            $ilaclar = Ilac::all();
        }

        // Her hasta-hastalık ilişkisi için ilaç kullanımları oluştur
        foreach ($hastaHastaliklar as $hastaHastalik) {
            // Hastalık kategorisini al
            $hastalikKategorisi = $hastaHastalik->hastalik->hastalik_kategorisi;

            // Kategoride spesifik ilaç listesi yoksa, rastgele ilaçlar seç
            if (!isset($this->hastalikKategorisiIlacIliskileri[$hastalikKategorisi])) {
                $seciliIlaclar = $ilaclar->random($faker->numberBetween(1, 3))->pluck('ilac_id')->toArray();
            } else {
                // Kategoriye özgü ilaçları bul
                $hedefIlaclar = $this->hastalikKategorisiIlacIliskileri[$hastalikKategorisi]['ilaçlar'];
                $seciliIlaclar = [];

                // İlaç adında eşleşenlerden 1-3 ilaç seç
                $kategoriIlaclari = [];
                foreach ($hedefIlaclar as $hedefIlac) {
                    $bulIlaclar = $ilaclar->filter(function($ilac) use ($hedefIlac) {
                        return stripos($ilac->ilac_adi, $hedefIlac) !== false;
                    })->values();

                    if ($bulIlaclar->count() > 0) {
                        $kategoriIlaclari = array_merge($kategoriIlaclari, $bulIlaclar->pluck('ilac_id')->toArray());
                    }
                }

                // Eğer kategori ilaçları bulunamazsa, rastgele ilaçlar seç
                if (empty($kategoriIlaclari)) {
                    $seciliIlaclar = $ilaclar->random($faker->numberBetween(1, 3))->pluck('ilac_id')->toArray();
                } else {
                    // 1-3 ilaç kullanımı oluştur
                    $ilacSayisi = min(count($kategoriIlaclari), $faker->numberBetween(1, 3));
                    $seciliIlaclar = $faker->randomElements($kategoriIlaclari, $ilacSayisi);
                }
            }

            // Her seçili ilaç için kullanım kaydı oluştur
            foreach ($seciliIlaclar as $ilacId) {
                // Başlangıç tarihi (teşhis tarihinden sonra)
                $baslangicTarihi = Carbon::parse($hastaHastalik->teshis_tarihi)
                    ->addDays($faker->numberBetween(0, 14)); // 0-14 gün sonra

                // Aktiflik durumu (hastalık aktifse ve şanslıysa ilaç kullanımı aktif)
                $aktif = $hastaHastalik->aktif && $faker->boolean(80);

                // Bitiş tarihi (aktif değilse rastgele bir tarih)
                $bitisTarihi = null;
                if (!$aktif) {
                    $bitisSuresi = $faker->numberBetween(1, 24); // 1-24 ay kullanım
                    $bitisTarihi = $baslangicTarihi->copy()->addMonths($bitisSuresi);

                    // Eğer bitiş tarihi bugünden sonraysa, bugün olarak ayarla
                    if ($bitisTarihi->isAfter(now())) {
                        $bitisTarihi = now();
                        $aktif = false;
                    }
                }

                // Dozaj bilgisi - kategoriye özgü dozaj veya genel
                if (isset($this->hastalikKategorisiIlacIliskileri[$hastalikKategorisi]['dozajlar'])) {
                    $dozaj = $faker->randomElement($this->hastalikKategorisiIlacIliskileri[$hastalikKategorisi]['dozajlar']);
                } else {
                    $dozaj = $faker->randomElement(['5 mg', '10 mg', '20 mg', '25 mg', '50 mg', '100 mg', '200 mg', '500 mg']);
                }

                // Kullanım talimatı
                $kullanimTalimati = $faker->randomElement([
                    'Günde 1 kez',
                    'Günde 2 kez',
                    'Günde 3 kez',
                    'Sabah-akşam 1 tablet',
                    'Sabah 1, akşam 2 tablet',
                    'Yemeklerden 30 dk önce',
                    'Yemeklerden sonra',
                    'Aç karnına',
                    'Tok karnına',
                    'Gün aşırı 1 tablet',
                    'Haftada 1 kez',
                    'İhtiyaç halinde'
                ]);

                // Etkinlik değerlendirmesi (bitiş tarihi varsa)
                $etkinlikDegerlendirmesi = null;
                $yanEtkiRaporlari = null;

                if ($bitisTarihi !== null) {
                    // Hastalık şiddetine göre etkinlik olasılığı belirle
                    $siddet = $hastaHastalik->siddet ?? 'Orta';
                    $etkinlikProbabilities = $this->etkinlikOlasiliklari[$siddet];

                    // Etkinlik değerlendirmesi rastgele seç (ağırlıklı)
                    $sum = array_sum($etkinlikProbabilities);
                    $rand = $faker->numberBetween(1, $sum);
                    $running = 0;

                    foreach ($etkinlikProbabilities as $etkinlik => $prob) {
                        $running += $prob;
                        if ($rand <= $running) {
                            $etkinlikDegerlendirmesi = $etkinlik;
                            break;
                        }
                    }

                    // Yan etki raporları (kötü etkinliklerde daha muhtemel)
                    $yanEtkiOlasiligi = $etkinlikDegerlendirmesi == 'Etkisiz' ? 70 :
                        ($etkinlikDegerlendirmesi == 'Düşük' ? 50 :
                            ($etkinlikDegerlendirmesi == 'Orta' ? 30 :
                                ($etkinlikDegerlendirmesi == 'İyi' ? 15 : 5)));

                    if ($faker->boolean($yanEtkiOlasiligi)) {
                        $yanEtkiler = [
                            'Bulantı', 'Kusma', 'Baş ağrısı', 'Baş dönmesi', 'İshal',
                            'Kabızlık', 'Uyku hali', 'Uykusuzluk', 'Cilt döküntüsü',
                            'Mide ağrısı', 'İştahsızlık', 'Yorgunluk', 'Ağız kuruluğu',
                            'Kaşıntı', 'Kas krampları', 'Öksürük', 'Alerjik reaksiyon'
                        ];

                        $yanEtkiSayisi = $faker->numberBetween(1, 3);
                        $raporlananYanEtkiler = $faker->randomElements($yanEtkiler, $yanEtkiSayisi);
                        $yanEtkiRaporlari = implode(', ', $raporlananYanEtkiler);
                    }
                }

                // İlaç kullanım kaydı oluştur
                HastaIlacKullanim::create([
                    'hasta_id' => $hastaHastalik->hasta_id,
                    'ilac_id' => $ilacId,
                    'hasta_hastalik_id' => $hastaHastalik->hasta_hastalik_id,
                    'baslangic_tarihi' => $baslangicTarihi,
                    'bitis_tarihi' => $bitisTarihi,
                    'dozaj' => $dozaj,
                    'kullanim_talimatı' => $kullanimTalimati,
                    'etkinlik_degerlendirmesi' => $etkinlikDegerlendirmesi,
                    'yan_etki_raporlari' => $yanEtkiRaporlari,
                    'aktif' => $aktif,
                    'created_at' => $baslangicTarihi,
                    'updated_at' => $bitisTarihi ?? now()
                ]);
            }
        }
    }

    /**
     * Örnek ilaç verileri oluştur
     */
    private function createSampleDrugs()
    {
        $faker = Faker::create('tr_TR');

        // Tüm kategorilerdeki ilaçları düz bir diziye çıkar
        $tumIlacIsimleri = [];
        foreach ($this->hastalikKategorisiIlacIliskileri as $kategori => $data) {
            $tumIlacIsimleri = array_merge($tumIlacIsimleri, $data['ilaçlar']);
        }

        // İlaç üreticileri
        $ilacUreticileri = [
            'Pfizer', 'Novartis', 'Roche', 'Sanofi', 'Merck', 'GSK', 'AstraZeneca',
            'Johnson & Johnson', 'Abbvie', 'Bayer', 'Lilly', 'Bristol-Myers Squibb',
            'Novo Nordisk', 'Boehringer Ingelheim', 'Amgen', 'Gilead', 'Biogen',
            'Teva', 'Allergan', 'Celgene'
        ];

        // Türk ilaç firmaları
        $turkIlacFirmalari = [
            'Abdi İbrahim', 'Bilim İlaç', 'Eczacıbaşı', 'Nobel İlaç', 'İ.E. Ulagay',
            'Mustafa Nevzat', 'Koçak Farma', 'Deva Holding', 'Santa Farma', 'İlko İlaç',
            'Ali Raif İlaç', 'Biofarma', 'Pharmactive', 'World Medicine', 'Sanovel'
        ];

        // Tüm üreticileri birleştir
        $tumUreticiler = array_merge($ilacUreticileri, $turkIlacFirmalari);

        // İlaç formları
        $ilacFormlari = [
            'tablet', 'film tablet', 'kapsül', 'draje', 'şurup', 'oral solüsyon',
            'enjeksiyon', 'ampul', 'flakon', 'süspansiyon', 'toz', 'merhem', 'krem',
            'jel', 'sprey', 'damla', 'şase', 'inhaler'
        ];

        // Her bir ilaç için veri oluştur
        foreach ($tumIlacIsimleri as $ilacIsmi) {
            // Rastgele bir üretici seç
            $uretici = $faker->randomElement($tumUreticiler);

            // Rastgele bir form seç
            $form = $faker->randomElement($ilacFormlari);

            // Rastgele bir doz seç
            $doz = $faker->randomElement(['5 mg', '10 mg', '20 mg', '25 mg', '40 mg', '50 mg', '75 mg', '100 mg', '200 mg', '500 mg']);

            // Ambalaj bilgisi
            $ambalaj = $faker->randomElement(['10 tablet', '14 tablet', '20 tablet', '28 tablet', '30 tablet', '60 tablet', '90 tablet', '100 tablet',
                '100 ml', '150 ml', '200 ml', '5 ampul', '10 ampul', '1 flakon']);

            // İlaç adı oluştur
            $ilacAdi = strtoupper($ilacIsmi) . ' ' . strtoupper($form) . ' ' . $doz . ' ' . $ambalaj;

            // İlaç-firma adı
            $ilacAdiFirma = strtoupper($ilacIsmi) . ' - ' . $uretici;

            // Barkod oluştur (13 haneli)
            $barkod = '86';  // Türkiye ülke kodu ile başlat
            $barkod .= $faker->numerify('###########');

            // Fiyat bilgileri
            $imalatciFiyat = $faker->randomFloat(2, 5, 1000);
            $depocuFiyatHaric = $imalatciFiyat * 1.085; // %8.5 marj
            $depocuFiyatDahil = $depocuFiyatHaric * 1.1; // %10 KDV
            $perakendeFiyat = $depocuFiyatHaric * 1.25; // %25 marj

            // Reçete tipi
            $receteTipi = $faker->randomElement([
                'Normal Reçete', 'Kırmızı Reçete', 'Yeşil Reçete', 'Turuncu Reçete',
                'Mor Reçete', 'Reçetesiz'
            ]);

            // İlaç oluştur
            $ilac = Ilac::create([
                'ilac_adi' => $ilacAdi,
                'barkod' => $barkod,
                'uretici_firma' => $uretici,
                'ilac_adi_firma' => $ilacAdiFirma,
                'recete_tipi' => "| $ilacAdiFirma |",
                'formulasyon' => $form,
                'ambalaj_bilgisi' => $ambalaj,
                'perakende_satis_fiyati' => $perakendeFiyat,
                'depocu_satis_fiyati_kdv_dahil' => $depocuFiyatDahil,
                'depocu_satis_fiyati_kdv_haric' => $depocuFiyatHaric,
                'imalatci_satis_fiyati_kdv_haric' => $imalatciFiyat,
                'fiyat_tarihi' => now()->subMonths($faker->numberBetween(0, 12)),
                'created_at' => now(),
                'updated_at' => now()
            ]);
        }
    }
}
