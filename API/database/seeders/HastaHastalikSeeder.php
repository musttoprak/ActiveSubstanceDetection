<?php

namespace Database\Seeders;

use App\Models\Hasta;
use App\Models\Hastalik;
use App\Models\HastaHastalik;
use App\Models\HastaTibbiGecmis;
use Illuminate\Database\Seeder;
use Faker\Factory as Faker;
use Carbon\Carbon;

class HastaHastalikSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $faker = Faker::create('tr_TR');

        // Tüm hastaları ve hastalıkları al
        $hastalar = Hasta::all();
        $hastaliklar = Hastalik::all();

        // Hastalık kategorileri
        $hastalikKategorileri = Hastalik::select('hastalik_kategorisi')
            ->distinct()
            ->pluck('hastalik_kategorisi')
            ->toArray();

        // Yaş gruplarına göre hastalık olasılıkları
        $yasGruplarinaGoreHastaliklar = [
            // Genç (18-35)
            'genç' => [
                'Psikiyatrik' => 0.15,      // Depresyon, anksiyete
                'Nörolojik' => 0.05,        // Migren
                'Solunum Sistemi' => 0.1,   // Astım
                'Dermatolojik' => 0.12,     // Sedef, egzama
                'Kas-İskelet Sistemi' => 0.08, // Bel ağrısı
                'Endokrin' => 0.05,         // Tip 1 diyabet
                'Sindirim Sistemi' => 0.1,  // Reflü
                'Kardiyovasküler' => 0.02,  // Hipertansiyon (nadir)
                'Üriner Sistem' => 0.05     // Sistit
            ],
            // Orta yaş (36-65)
            'orta' => [
                'Kardiyovasküler' => 0.25,   // Hipertansiyon, koroner arter hastalığı
                'Endokrin' => 0.2,          // Tip 2 diyabet, tiroid hastalıkları
                'Kas-İskelet Sistemi' => 0.15, // Bel/boyun ağrısı, erken osteoartrit
                'Sindirim Sistemi' => 0.15,   // Reflü, gastrit
                'Psikiyatrik' => 0.1,        // Depresyon, anksiyete
                'Solunum Sistemi' => 0.1,    // KOAH, astım
                'Nörolojik' => 0.1,          // Migren
                'Üriner Sistem' => 0.08,     // Böbrek taşı
                'Dermatolojik' => 0.05       // Sedef
            ],
            // Yaşlı (66+)
            'yaşlı' => [
                'Kardiyovasküler' => 0.4,     // Hipertansiyon, kalp yetmezliği, atriyal fibrilasyon
                'Kas-İskelet Sistemi' => 0.35, // Osteoartrit, osteoporoz
                'Endokrin' => 0.25,           // Tip 2 diyabet
                'Nörolojik' => 0.2,           // Parkinson, Alzheimer
                'Solunum Sistemi' => 0.2,     // KOAH
                'Üriner Sistem' => 0.15,      // Kronik böbrek hastalığı
                'Sindirim Sistemi' => 0.1,    // Reflü, karaciğer sirozu
                'Psikiyatrik' => 0.05,        // Depresyon
                'Dermatolojik' => 0.03        // Cilt sorunları
            ]
        ];

        // Cinsiyet bazlı hastalık olasılıkları (çarpan olarak)
        $cinsiyeteGoreHastalikCarpanlari = [
            // Erkeklerde daha sık görülenler
            'Erkek' => [
                'Kardiyovasküler' => 1.3,   // Erkeklerde kalp hastalıkları daha sık
                'Üriner Sistem' => 0.8,     // Kadınlarda sistit daha sık
                'Kas-İskelet Sistemi' => 0.9, // Kadınlarda osteoporoz daha sık
                'Psikiyatrik' => 0.8,       // Kadınlarda depresyon/anksiyete daha sık
                'Endokrin' => 1.0,          // Benzer sıklıkta
                'Sindirim Sistemi' => 1.1,  // Erkeklerde biraz daha sık
                'Nörolojik' => 0.9,         // Kadınlarda migren daha sık
                'Solunum Sistemi' => 1.1,   // Erkeklerde KOAH daha sık (sigara)
                'Dermatolojik' => 1.0       // Benzer sıklıkta
            ],
            // Kadınlarda daha sık görülenler
            'Kadın' => [
                'Kardiyovasküler' => 0.8,   // Erkeklerde daha sık
                'Üriner Sistem' => 1.2,     // Kadınlarda sistit daha sık
                'Kas-İskelet Sistemi' => 1.1, // Kadınlarda osteoporoz daha sık
                'Psikiyatrik' => 1.2,       // Kadınlarda depresyon/anksiyete daha sık
                'Endokrin' => 1.1,          // Kadınlarda tiroid hastalıkları daha sık
                'Sindirim Sistemi' => 0.9,  // Erkeklerde biraz daha sık
                'Nörolojik' => 1.1,         // Kadınlarda migren daha sık
                'Solunum Sistemi' => 0.9,   // Erkeklerde KOAH daha sık
                'Dermatolojik' => 1.0       // Benzer sıklıkta
            ]
        ];

        foreach ($hastalar as $hasta) {
            // Yaş grubunu belirle
            $yasGrubu = $hasta->yas < 36 ? 'genç' :
                ($hasta->yas < 66 ? 'orta' : 'yaşlı');

            // Kronik hastalık verisini kullan
            $tibbiGecmis = HastaTibbiGecmis::where('hasta_id', $hasta->hasta_id)->first();
            $kronikHastaliklar = [];

            if ($tibbiGecmis && $tibbiGecmis->kronik_hastaliklar) {
                $kronikHastaliklar = explode(', ', $tibbiGecmis->kronik_hastaliklar);
            }

            // 1-4 arası hastalık ekle (yaşla artar)
            $hastalikSayisi = $yasGrubu == 'genç' ? $faker->numberBetween(1, 2) :
                ($yasGrubu == 'orta' ? $faker->numberBetween(1, 3) :
                    $faker->numberBetween(2, 4));

            $eklenenHastalikIdleri = [];

            // Önce kronik hastalıklardan eşleşenleri ekle
            if (!empty($kronikHastaliklar)) {
                foreach ($kronikHastaliklar as $kronikHastalik) {
                    // Kronik hastalık adına benzer hastalıkları bul
                    $benzerHastaliklar = Hastalik::where('hastalik_adi', 'like', "%$kronikHastalik%")
                        ->orWhere('aciklama', 'like', "%$kronikHastalik%")
                        ->get();

                    if ($benzerHastaliklar->count() > 0) {
                        // Rastgele bir eşleşen hastalık seç
                        $seciliHastalik = $benzerHastaliklar->random();

                        // Hastalığı ekle
                        $this->hastaligaHastaEkle($hasta, $seciliHastalik, $faker);
                        $eklenenHastalikIdleri[] = $seciliHastalik->hastalik_id;

                        // Yeterli sayıda hastalık eklendiyse döngüden çık
                        if (count($eklenenHastalikIdleri) >= $hastalikSayisi) {
                            break;
                        }
                    }
                }
            }

            // Hedeflenen sayıya ulaşılmadıysa yeni hastalıklar ekle
            $kalanHastalikSayisi = $hastalikSayisi - count($eklenenHastalikIdleri);

            if ($kalanHastalikSayisi > 0) {
                for ($i = 0; $i < $kalanHastalikSayisi; $i++) {
                    // Yaş ve cinsiyete göre hastalık kategorisi seç
                    $kategori = $this->kategoriBelirle($yasGruplarinaGoreHastaliklar[$yasGrubu], $cinsiyeteGoreHastalikCarpanlari[$hasta->cinsiyet]);

                    // Seçilen kategorideki hastalıkları bul
                    $kategoriHastaliklari = Hastalik::where('hastalik_kategorisi', $kategori)
                        ->whereNotIn('hastalik_id', $eklenenHastalikIdleri)
                        ->get();

                    if ($kategoriHastaliklari->count() > 0) {
                        // Rastgele bir hastalık seç
                        $seciliHastalik = $kategoriHastaliklari->random();

                        // Hastalığı ekle
                        $this->hastaligaHastaEkle($hasta, $seciliHastalik, $faker);
                        $eklenenHastalikIdleri[] = $seciliHastalik->hastalik_id;
                    }
                }
            }
        }
    }

    /**
     * Olasılıklara göre bir hastalık kategorisi belirle
     */
    private function kategoriBelirle($yasOlasiliklari, $cinsiyetCarpanlari)
    {
        $toplamOlasilik = 0;
        $carpimliOlasiliklar = [];

        // Yaş ve cinsiyet olasılıklarını çarp
        foreach ($yasOlasiliklari as $kategori => $yasProbability) {
            $carpimliOlasilik = $yasProbability * ($cinsiyetCarpanlari[$kategori] ?? 1.0);
            $carpimliOlasiliklar[$kategori] = $carpimliOlasilik;
            $toplamOlasilik += $carpimliOlasilik;
        }

        // Rasgele bir sayı seç
        $rastgeleSayi = mt_rand() / mt_getrandmax() * $toplamOlasilik;
        $kumulatifOlasilik = 0;

        // Kümülatif olasılığı geçene kadar ilerle
        foreach ($carpimliOlasiliklar as $kategori => $olasilik) {
            $kumulatifOlasilik += $olasilik;
            if ($rastgeleSayi <= $kumulatifOlasilik) {
                return $kategori;
            }
        }

        // Varsayılan olarak ilk kategoriyi döndür
        return array_key_first($yasOlasiliklari);
    }

    /**
     * Hasta-hastalık ilişkisi oluştur
     */
    private function hastaligaHastaEkle($hasta, $hastalik, $faker)
    {
        // Hastanın yaşına göre teşhis tarihi oluştur (son 10 yıl içinde)
        $maxYil = min(10, $hasta->yas);
        $teshisTarihi = $faker->dateTimeBetween("-{$maxYil} years", 'now')->format('Y-m-d');

        // Hastalık şiddeti
        $siddet = $faker->randomElement(['Hafif', 'Orta', 'Şiddetli']);

        // Aktiflik durumu (eski tarihli hastalıklar iyileşmiş olabilir)
        $aktif = $faker->boolean(70); // %70 ihtimalle hala aktif

        if (!$aktif) {
            // İyileştiğini belirten not ekle
            $notlar = "Hasta bu hastalıktan " . Carbon::parse($teshisTarihi)->addMonths($faker->numberBetween(3, 24))->format('Y-m-d') . " tarihinde iyileşti.";
        } else {
            $notlar = $faker->optional(0.7)->sentences(2, true); // %70 ihtimalle notlar ekle
        }

        // Hasta-hastalık ilişkisini oluştur
        HastaHastalik::create([
            'hasta_id' => $hasta->hasta_id,
            'hastalik_id' => $hastalik->hastalik_id,
            'teshis_tarihi' => $teshisTarihi,
            'siddet' => $siddet,
            'notlar' => $notlar,
            'aktif' => $aktif,
            'created_at' => Carbon::parse($teshisTarihi),
            'updated_at' => now()
        ]);
    }
}
