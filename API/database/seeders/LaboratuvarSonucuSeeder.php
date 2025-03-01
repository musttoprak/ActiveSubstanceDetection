<?php

namespace Database\Seeders;

use App\Models\Hasta;
use App\Models\HastaHastalik;
use App\Models\LaboratuvarSonucu;
use Illuminate\Database\Seeder;
use Faker\Factory as Faker;
use Carbon\Carbon;

class LaboratuvarSonucuSeeder extends Seeder
{
    // Laboratuvar testleri ve referans aralıkları
    private $laboratuvarTestleri = [
        // Hemogram
        [
            'test_turu' => 'Hemoglobin',
            'test_kodu' => 'HGB',
            'birim' => 'g/dL',
            'referans_aralik' => [
                'Erkek' => '13.5-17.5',
                'Kadın' => '12.0-15.5'
            ],
            'normalDegerAraligi' => [
                'Erkek' => [13.5, 17.5],
                'Kadın' => [12.0, 15.5]
            ]
        ],
        [
            'test_turu' => 'Hematokrit',
            'test_kodu' => 'HCT',
            'birim' => '%',
            'referans_aralik' => [
                'Erkek' => '38.8-50.0',
                'Kadın' => '34.9-44.5'
            ],
            'normalDegerAraligi' => [
                'Erkek' => [38.8, 50.0],
                'Kadın' => [34.9, 44.5]
            ]
        ],
        [
            'test_turu' => 'Beyaz Küre',
            'test_kodu' => 'WBC',
            'birim' => '10³/µL',
            'referans_aralik' => '4.5-11.0',
            'normalDegerAraligi' => [4.5, 11.0]
        ],
        [
            'test_turu' => 'Trombosit',
            'test_kodu' => 'PLT',
            'birim' => '10³/µL',
            'referans_aralik' => '150-450',
            'normalDegerAraligi' => [150, 450]
        ],

        // Biyokimya
        [
            'test_turu' => 'Glukoz',
            'test_kodu' => 'GLU',
            'birim' => 'mg/dL',
            'referans_aralik' => '70-100',
            'normalDegerAraligi' => [70, 100]
        ],
        [
            'test_turu' => 'HbA1c',
            'test_kodu' => 'HBA1C',
            'birim' => '%',
            'referans_aralik' => '4.0-6.0',
            'normalDegerAraligi' => [4.0, 6.0]
        ],
        [
            'test_turu' => 'Üre',
            'test_kodu' => 'BUN',
            'birim' => 'mg/dL',
            'referans_aralik' => '7-20',
            'normalDegerAraligi' => [7, 20]
        ],
        [
            'test_turu' => 'Kreatinin',
            'test_kodu' => 'CREA',
            'birim' => 'mg/dL',
            'referans_aralik' => [
                'Erkek' => '0.7-1.3',
                'Kadın' => '0.6-1.1'
            ],
            'normalDegerAraligi' => [
                'Erkek' => [0.7, 1.3],
                'Kadın' => [0.6, 1.1]
            ]
        ],
        [
            'test_turu' => 'AST',
            'test_kodu' => 'AST',
            'birim' => 'U/L',
            'referans_aralik' => '5-40',
            'normalDegerAraligi' => [5, 40]
        ],
        [
            'test_turu' => 'ALT',
            'test_kodu' => 'ALT',
            'birim' => 'U/L',
            'referans_aralik' => '7-56',
            'normalDegerAraligi' => [7, 56]
        ],
        [
            'test_turu' => 'Total Kolesterol',
            'test_kodu' => 'CHOL',
            'birim' => 'mg/dL',
            'referans_aralik' => '<200',
            'normalDegerAraligi' => [0, 200]
        ],
        [
            'test_turu' => 'LDL Kolesterol',
            'test_kodu' => 'LDL',
            'birim' => 'mg/dL',
            'referans_aralik' => '<130',
            'normalDegerAraligi' => [0, 130]
        ],
        [
            'test_turu' => 'HDL Kolesterol',
            'test_kodu' => 'HDL',
            'birim' => 'mg/dL',
            'referans_aralik' => '>40',
            'normalDegerAraligi' => [40, 100]
        ],
        [
            'test_turu' => 'Trigliserit',
            'test_kodu' => 'TG',
            'birim' => 'mg/dL',
            'referans_aralik' => '<150',
            'normalDegerAraligi' => [0, 150]
        ],

        // Tiroid
        [
            'test_turu' => 'TSH',
            'test_kodu' => 'TSH',
            'birim' => 'mIU/L',
            'referans_aralik' => '0.4-4.0',
            'normalDegerAraligi' => [0.4, 4.0]
        ],
        [
            'test_turu' => 'Serbest T4',
            'test_kodu' => 'FT4',
            'birim' => 'ng/dL',
            'referans_aralik' => '0.8-1.8',
            'normalDegerAraligi' => [0.8, 1.8]
        ],
        [
            'test_turu' => 'Serbest T3',
            'test_kodu' => 'FT3',
            'birim' => 'pg/mL',
            'referans_aralik' => '2.3-4.2',
            'normalDegerAraligi' => [2.3, 4.2]
        ],

        // Elektrolit
        [
            'test_turu' => 'Sodyum',
            'test_kodu' => 'Na',
            'birim' => 'mmol/L',
            'referans_aralik' => '135-145',
            'normalDegerAraligi' => [135, 145]
        ],
        [
            'test_turu' => 'Potasyum',
            'test_kodu' => 'K',
            'birim' => 'mmol/L',
            'referans_aralik' => '3.5-5.1',
            'normalDegerAraligi' => [3.5, 5.1]
        ],
        [
            'test_turu' => 'Klor',
            'test_kodu' => 'Cl',
            'birim' => 'mmol/L',
            'referans_aralik' => '98-107',
            'normalDegerAraligi' => [98, 107]
        ],
        [
            'test_turu' => 'Kalsiyum',
            'test_kodu' => 'Ca',
            'birim' => 'mg/dL',
            'referans_aralik' => '8.6-10.2',
            'normalDegerAraligi' => [8.6, 10.2]
        ],

        // Kardiyak
        [
            'test_turu' => 'CK-MB',
            'test_kodu' => 'CKMB',
            'birim' => 'ng/mL',
            'referans_aralik' => '<5.0',
            'normalDegerAraligi' => [0, 5.0]
        ],
        [
            'test_turu' => 'Troponin I',
            'test_kodu' => 'TNI',
            'birim' => 'ng/mL',
            'referans_aralik' => '<0.04',
            'normalDegerAraligi' => [0, 0.04]
        ],
        [
            'test_turu' => 'BNP',
            'test_kodu' => 'BNP',
            'birim' => 'pg/mL',
            'referans_aralik' => '<100',
            'normalDegerAraligi' => [0, 100]
        ]
    ];

    // Hastalık kategorilerine göre anormal test olasılıkları
    private $hastalikKategorisiTestOlasiliklari = [
        'Kardiyovasküler' => [
            'Troponin I' => 0.3, // Kalp krizi geçirenler için
            'BNP' => 0.4,       // Kalp yetmezliği için
            'CK-MB' => 0.25,     // Kalp krizi geçirenler için
            'Sodyum' => 0.1,     // Diüretik kullananlar için
            'Potasyum' => 0.15,  // Diüretik kullananlar için
            'Total Kolesterol' => 0.6, // Hiperkolesterolemi
            'LDL Kolesterol' => 0.7,
            'HDL Kolesterol' => 0.5
        ],
        'Endokrin' => [
            'Glukoz' => 0.7,     // Diyabet hastaları yüksek olasılıkla anormal
            'HbA1c' => 0.75,     // Diyabet hastaları yüksek olasılıkla anormal
            'TSH' => 0.6,        // Tiroid hastalıkları için
            'Serbest T4' => 0.55, // Tiroid hastalıkları için
            'Serbest T3' => 0.5,  // Tiroid hastalıkları için
            'Potasyum' => 0.15    // Endokrin bozukluğu sonucu elektrolit dengesizliği
        ],
        'Sindirim Sistemi' => [
            'AST' => 0.4,        // Karaciğer hastalıkları
            'ALT' => 0.45,       // Karaciğer hastalıkları
            'Total Kolesterol' => 0.3
        ],
        'Üriner Sistem' => [
            'Üre' => 0.6,        // Böbrek hastalıkları
            'Kreatinin' => 0.65, // Böbrek hastalıkları
            'Sodyum' => 0.25,    // Elektrolit dengesizliği
            'Potasyum' => 0.3,   // Elektrolit dengesizliği
            'Klor' => 0.2        // Elektrolit dengesizliği
        ],
        'Kas-İskelet Sistemi' => [
            'Kalsiyum' => 0.35,  // Osteoporoz hastaları için
            'AST' => 0.15,       // Kas hasarı durumunda
            'ALT' => 0.1         // Kas hasarı durumunda
        ],
        'Solunum Sistemi' => [
            'Hemoglobin' => 0.2, // Kronik solunum hastalıklarında düşük olabilir
            'Hematokrit' => 0.2
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

        // Tüm hastaları al
        $hastalar = Hasta::with('hastaHastaliklar.hastalik')->get();

        foreach ($hastalar as $hasta) {
            // Hasta için rastgele 5-15 laboratuvar sonucu oluştur
            $testSayisi = $faker->numberBetween(5, 15);

            // Hastanın hastalık kategorilerini al
            $hastalikKategorileri = $hasta->hastaHastaliklar
                ->pluck('hastalik.hastalik_kategorisi')
                ->unique()
                ->toArray();

            // Testlerin tarih aralığı (son 2 yıl içinde)
            $baslangicTarihi = now()->subYears(2);
            $bitisTarihi = now();

            // Rastgele testler oluştur
            for ($i = 0; $i < $testSayisi; $i++) {
                // Rastgele bir test seç
                $test = $faker->randomElement($this->laboratuvarTestleri);

                // Rastgele bir test tarihi oluştur
                $testTarihi = $faker->dateTimeBetween($baslangicTarihi, $bitisTarihi)->format('Y-m-d');

                // Test değeri belirle (normal mi anormal mı?)
                $anormalOlasiligi = 0.1; // Varsayılan olarak %10 anormal

                // Hastanın hastalık kategorilerine göre anormal olasılığını güncelle
                foreach ($hastalikKategorileri as $kategori) {
                    if (isset($this->hastalikKategorisiTestOlasiliklari[$kategori][$test['test_turu']])) {
                        $anormalOlasiligi = max($anormalOlasiligi, $this->hastalikKategorisiTestOlasiliklari[$kategori][$test['test_turu']]);
                    }
                }

                // Değeri belirle
                $normalMi = !$faker->boolean($anormalOlasiligi * 100);
                $deger = $this->generateTestValue($test, $hasta->cinsiyet, $normalMi);

                // Referans aralığını belirle
                $referansAralik = is_array($test['referans_aralik']) ?
                    $test['referans_aralik'][$hasta->cinsiyet] :
                    $test['referans_aralik'];

                // Notlar (anormal değerler için)
                $notlar = null;
                if (!$normalMi) {
                    $notlar = $faker->optional(0.7)->randomElement([
                        'Tekrar test önerilir.',
                        'Klinik değerlendirme gereklidir.',
                        'Önceki değerlerle karşılaştırılmalıdır.',
                        'Hasta ilaç kullanıyor olabilir.',
                        'Diyet değişikliği önerilir.',
                        'Kontrol testi planlanmalıdır.',
                        'Hasta açlık durumu sorgulanmalıdır.'
                    ]);
                }

                // Laboratuvar sonucu oluştur
                LaboratuvarSonucu::create([
                    'hasta_id' => $hasta->hasta_id,
                    'test_turu' => $test['test_turu'],
                    'test_kodu' => $test['test_kodu'],
                    'deger' => $deger,
                    'birim' => $test['birim'],
                    'referans_aralik' => $referansAralik,
                    'normal_mi' => $normalMi,
                    'test_tarihi' => $testTarihi,
                    'notlar' => $notlar,
                    'created_at' => Carbon::parse($testTarihi),
                    'updated_at' => Carbon::parse($testTarihi)
                ]);
            }
        }
    }

    /**
     * Test değeri oluştur (normal veya anormal)
     */
    private function generateTestValue($test, $cinsiyet, $normalMi)
    {
        $faker = Faker::create();

        // Normal değer aralığını belirle
        $normalAralik = isset($test['normalDegerAraligi'][$cinsiyet]) ?
            $test['normalDegerAraligi'][$cinsiyet] :
            $test['normalDegerAraligi'];

        if ($normalMi) {
            // Normal değer aralığında bir değer döndür
            return $faker->randomFloat(2, $normalAralik[0], $normalAralik[1]);
        } else {
            // Anormal değer döndür (aralığın altında veya üstünde)
            if ($faker->boolean()) {
                // Aralığın altında
                $altLimit = max(0, $normalAralik[0] - ($normalAralik[1] - $normalAralik[0]));
                return $faker->randomFloat(2, $altLimit, $normalAralik[0] - 0.01);
            } else {
                // Aralığın üstünde
                $ustLimit = $normalAralik[1] + ($normalAralik[1] - $normalAralik[0]);
                return $faker->randomFloat(2, $normalAralik[1] + 0.01, $ustLimit);
            }
        }
    }
}
