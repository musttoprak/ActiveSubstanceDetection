<?php

namespace Database\Seeders;

use App\Models\Hastalik;
use Illuminate\Database\Seeder;

class HastalikSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        // Yaygın hastalıklar ve ICD-10 kodları
        $hastaliklar = [
            // Kardiyovasküler Hastalıklar
            [
                'icd_kodu' => 'I10',
                'hastalik_adi' => 'Hipertansiyon (Yüksek Tansiyon)',
                'hastalik_kategorisi' => 'Kardiyovasküler',
                'aciklama' => 'Kan basıncının normalden yüksek olması durumu. 140/90 mmHg ve üzeri değerler hipertansiyon olarak kabul edilir.'
            ],
            [
                'icd_kodu' => 'I20',
                'hastalik_adi' => 'Anjina Pektoris',
                'hastalik_kategorisi' => 'Kardiyovasküler',
                'aciklama' => 'Kalp kasına giden kan akışının azalması sonucu oluşan göğüs ağrısı.'
            ],
            [
                'icd_kodu' => 'I21',
                'hastalik_adi' => 'Miyokard Enfarktüsü (Kalp Krizi)',
                'hastalik_kategorisi' => 'Kardiyovasküler',
                'aciklama' => 'Kalp kasının bir bölümüne kan akışının tamamen kesilmesi sonucu oluşan kalp dokusu ölümü.'
            ],
            [
                'icd_kodu' => 'I50',
                'hastalik_adi' => 'Kalp Yetmezliği',
                'hastalik_kategorisi' => 'Kardiyovasküler',
                'aciklama' => 'Kalbin vücudun ihtiyaç duyduğu kan miktarını pompalayamaması durumu.'
            ],
            [
                'icd_kodu' => 'I48',
                'hastalik_adi' => 'Atriyal Fibrilasyon',
                'hastalik_kategorisi' => 'Kardiyovasküler',
                'aciklama' => 'Kalbin üst odacıklarının düzensiz ve hızlı kasılması sonucu oluşan kalp ritim bozukluğu.'
            ],

            // Solunum Sistemi Hastalıkları
            [
                'icd_kodu' => 'J45',
                'hastalik_adi' => 'Astım',
                'hastalik_kategorisi' => 'Solunum Sistemi',
                'aciklama' => 'Hava yollarının kronik enflamasyonu sonucu oluşan, tekrarlayan hırıltılı solunum, nefes darlığı ve öksürük ile karakterize hastalık.'
            ],
            [
                'icd_kodu' => 'J44',
                'hastalik_adi' => 'Kronik Obstrüktif Akciğer Hastalığı (KOAH)',
                'hastalik_kategorisi' => 'Solunum Sistemi',
                'aciklama' => 'Hava akımında kronik obstrüksiyon ile karakterize, genellikle ilerleyici bir akciğer hastalığı.'
            ],
            [
                'icd_kodu' => 'J18',
                'hastalik_adi' => 'Pnömoni (Zatürre)',
                'hastalik_kategorisi' => 'Solunum Sistemi',
                'aciklama' => 'Bakteriler, virüsler veya mantarlar gibi mikroorganizmalar tarafından oluşturulan akciğer enfeksiyonu.'
            ],

            // Endokrin Hastalıklar
            [
                'icd_kodu' => 'E11',
                'hastalik_adi' => 'Tip 2 Diabetes Mellitus',
                'hastalik_kategorisi' => 'Endokrin',
                'aciklama' => 'Vücudun insüline dirençli hale gelmesi veya insülin üretiminin azalması sonucu oluşan kronik metabolik hastalık.'
            ],
            [
                'icd_kodu' => 'E10',
                'hastalik_adi' => 'Tip 1 Diabetes Mellitus',
                'hastalik_kategorisi' => 'Endokrin',
                'aciklama' => 'Pankreasın yeterli insülin üretememesi sonucu oluşan kronik metabolik hastalık.'
            ],
            [
                'icd_kodu' => 'E05',
                'hastalik_adi' => 'Hipertiroidi',
                'hastalik_kategorisi' => 'Endokrin',
                'aciklama' => 'Tiroid bezinin aşırı çalışması sonucu tiroid hormonu fazlalığı.'
            ],
            [
                'icd_kodu' => 'E03',
                'hastalik_adi' => 'Hipotiroidi',
                'hastalik_kategorisi' => 'Endokrin',
                'aciklama' => 'Tiroid bezinin yeterince çalışmaması sonucu tiroid hormonu eksikliği.'
            ],

            // Sindirim Sistemi Hastalıkları
            [
                'icd_kodu' => 'K21',
                'hastalik_adi' => 'Gastroözofageal Reflü Hastalığı (GÖRH)',
                'hastalik_kategorisi' => 'Sindirim Sistemi',
                'aciklama' => 'Mide içeriğinin yemek borusuna geri kaçması sonucu oluşan kronik hastalık.'
            ],
            [
                'icd_kodu' => 'K29',
                'hastalik_adi' => 'Gastrit',
                'hastalik_kategorisi' => 'Sindirim Sistemi',
                'aciklama' => 'Mide mukozasının enflamasyonu.'
            ],
            [
                'icd_kodu' => 'K74',
                'hastalik_adi' => 'Karaciğer Sirozu',
                'hastalik_kategorisi' => 'Sindirim Sistemi',
                'aciklama' => 'Karaciğerin kronik hasarı sonucu oluşan skar dokusu ile karakterize ileri evre karaciğer hastalığı.'
            ],

            // Nörolojik Hastalıklar
            [
                'icd_kodu' => 'G20',
                'hastalik_adi' => 'Parkinson Hastalığı',
                'hastalik_kategorisi' => 'Nörolojik',
                'aciklama' => 'Beynin belirli bölgelerindeki hücrelerin harabiyeti sonucu oluşan, titreme, yavaşlık, katılık gibi belirtilerle karakterize kronik nörodejeneratif hastalık.'
            ],
            [
                'icd_kodu' => 'G30',
                'hastalik_adi' => 'Alzheimer Hastalığı',
                'hastalik_kategorisi' => 'Nörolojik',
                'aciklama' => 'Hafıza, düşünme ve davranış sorunlarına yol açan, ilerleyici beyin hastalığı.'
            ],
            [
                'icd_kodu' => 'G40',
                'hastalik_adi' => 'Epilepsi',
                'hastalik_kategorisi' => 'Nörolojik',
                'aciklama' => 'Beyindeki anormal elektriksel aktivite sonucu tekrarlayan nöbetlerle karakterize nörolojik hastalık.'
            ],
            [
                'icd_kodu' => 'G43',
                'hastalik_adi' => 'Migren',
                'hastalik_kategorisi' => 'Nörolojik',
                'aciklama' => 'Genellikle başın bir tarafında, ağır, zonklayıcı baş ağrısı ve çoğunlukla bulantı, kusma ve ışığa/sese karşı hassasiyet ile karakterize nörolojik hastalık.'
            ],

            // Psikiyatrik Hastalıklar
            [
                'icd_kodu' => 'F32',
                'hastalik_adi' => 'Depresyon',
                'hastalik_kategorisi' => 'Psikiyatrik',
                'aciklama' => 'Üzüntü, ilgi kaybı, suçluluk duygusu, düşük özgüven, uyku/iştah bozuklukları, düşük enerji ve konsantrasyon zayıflığı ile karakterize ruhsal bozukluk.'
            ],
            [
                'icd_kodu' => 'F41',
                'hastalik_adi' => 'Anksiyete Bozuklukları',
                'hastalik_kategorisi' => 'Psikiyatrik',
                'aciklama' => 'Aşırı kaygı, korku ve endişe ile karakterize ruhsal bozukluklar grubu.'
            ],
            [
                'icd_kodu' => 'F20',
                'hastalik_adi' => 'Şizofreni',
                'hastalik_kategorisi' => 'Psikiyatrik',
                'aciklama' => 'Düşünce, algı, duygu, davranış ve sosyal ilişkilerde bozukluklar ile karakterize kronik ruhsal hastalık.'
            ],

            // Kas-İskelet Sistemi Hastalıkları
            [
                'icd_kodu' => 'M17',
                'hastalik_adi' => 'Diz Osteoartriti',
                'hastalik_kategorisi' => 'Kas-İskelet Sistemi',
                'aciklama' => 'Diz ekleminde kıkırdak aşınması ve hasarı sonucu oluşan ağrı, sertlik ve hareket kısıtlılığı ile karakterize dejeneratif eklem hastalığı.'
            ],
            [
                'icd_kodu' => 'M16',
                'hastalik_adi' => 'Kalça Osteoartriti',
                'hastalik_kategorisi' => 'Kas-İskelet Sistemi',
                'aciklama' => 'Kalça ekleminde kıkırdak aşınması ve hasarı sonucu oluşan ağrı, sertlik ve hareket kısıtlılığı ile karakterize dejeneratif eklem hastalığı.'
            ],
            [
                'icd_kodu' => 'M81',
                'hastalik_adi' => 'Osteoporoz',
                'hastalik_kategorisi' => 'Kas-İskelet Sistemi',
                'aciklama' => 'Kemik mineral yoğunluğunun azalması sonucu kemiklerin zayıflaması ve kırılganlığının artması ile karakterize hastalık.'
            ],
            [
                'icd_kodu' => 'M54',
                'hastalik_adi' => 'Bel Ağrısı',
                'hastalik_kategorisi' => 'Kas-İskelet Sistemi',
                'aciklama' => 'Bel bölgesinde hissedilen ağrı, rahatsızlık hissi veya fonksiyon kaybı.'
            ],
            [
                'icd_kodu' => 'M10',
                'hastalik_adi' => 'Gut',
                'hastalik_kategorisi' => 'Kas-İskelet Sistemi',
                'aciklama' => 'Eklemlerde ürik asit kristallerinin birikmesi sonucu oluşan ağrılı artrit.'
            ],

            // Üriner Sistem Hastalıkları
            [
                'icd_kodu' => 'N18',
                'hastalik_adi' => 'Kronik Böbrek Hastalığı',
                'hastalik_kategorisi' => 'Üriner Sistem',
                'aciklama' => 'Böbreklerin filtreleme işlevini gerçekleştirmede yavaş ve giderek artan bir kayıp ile karakterize uzun süreli böbrek hasarı.'
            ],
            [
                'icd_kodu' => 'N20',
                'hastalik_adi' => 'Böbrek Taşı',
                'hastalik_kategorisi' => 'Üriner Sistem',
                'aciklama' => 'Böbreklerde veya idrar yollarında oluşan katı kristal birikimler.'
            ],
            [
                'icd_kodu' => 'N30',
                'hastalik_adi' => 'Sistit (Mesane İltihabı)',
                'hastalik_kategorisi' => 'Üriner Sistem',
                'aciklama' => 'Mesanenin enflamasyonu, genellikle bakteriyel enfeksiyon sonucu oluşur.'
            ],

            // Dermatolojik Hastalıklar
            [
                'icd_kodu' => 'L40',
                'hastalik_adi' => 'Psöriazis (Sedef Hastalığı)',
                'hastalik_kategorisi' => 'Dermatolojik',
                'aciklama' => 'Derinin hızlı hücre döngüsü sonucu oluşan, kırmızı, pullu yamalar ile karakterize kronik cilt hastalığı.'
            ],
            [
                'icd_kodu' => 'L20',
                'hastalik_adi' => 'Atopik Dermatit (Egzama)',
                'hastalik_kategorisi' => 'Dermatolojik',
                'aciklama' => 'Kaşıntılı, kırmızı, şişmiş ve çatlamış cilt ile karakterize kronik cilt hastalığı.'
            ]
        ];

        // Verileri kaydet
        foreach ($hastaliklar as $hastalik) {
            Hastalik::create($hastalik);
        }
    }
}
