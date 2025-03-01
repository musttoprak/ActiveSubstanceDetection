<?php

namespace Database\Seeders;

use App\Models\Hasta;
use App\Models\HastaTibbiGecmis;
use Illuminate\Database\Seeder;
use Faker\Factory as Faker;

class HastaTibbiGecmisSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $faker = Faker::create('tr_TR');

        // Tüm hastalar için tıbbi geçmiş oluştur
        $hastalar = Hasta::all();

        // Kronik hastalık listesi
        $kronikHastaliklar = [
            'Hipertansiyon', 'Tip 2 Diyabet', 'Astım', 'KOAH', 'Kalp Yetmezliği',
            'Koroner Arter Hastalığı', 'Hipotiroidi', 'Hipertiroidi', 'Kronik Böbrek Hastalığı',
            'Osteoartrit', 'Osteoporoz', 'Reflü', 'Migren', 'Epilepsi', 'Parkinson',
            'Alzheimer', 'Romatoid Artrit', 'Anemi', 'Sedef Hastalığı', 'Ülseratif Kolit'
        ];

        // Alerji listesi
        $alerjiler = [
            'Penisilin', 'Aspirin', 'İbuprofen', 'Sulfonamidler', 'Lateks',
            'Polen', 'Ev Tozu', 'Kedi Tüyü', 'Fındık', 'Süt', 'Yumurta', 'Buğday',
            'Çilek', 'Kabuklu Deniz Ürünleri', 'Soya', 'Bal', 'Arı Sokması'
        ];

        // Ameliyat listesi
        $ameliyatlar = [
            'Apendektomi', 'Kolesistektomi', 'Herni Onarımı', 'Katarakt Ameliyatı',
            'Bypass Ameliyatı', 'Sezaryen', 'Artroskopi', 'Tonsillektomi', 'Tiroidektomi',
            'Histerektomi', 'Mastektomi', 'Prostatektomi', 'Bademcik Ameliyatı',
            'Diz Protezi', 'Kalça Protezi', 'Omurga Füzyonu', 'Gaziler Tüplü Mide Ameliyatı'
        ];

        // Fiziksel aktivite düzeyleri
        $fizikselAktiviteler = [
            'Sedanter', 'Hafif aktif', 'Orta düzeyde aktif', 'Çok aktif', 'Ekstrem aktif'
        ];

        // Beslenme alışkanlıkları
        $beslenmeAliskanliklari = [
            'Dengeli beslenme', 'Vejetaryen', 'Vegan', 'Düşük karbonhidrat', 'Yüksek protein',
            'Akdeniz diyeti', 'Glutensiz', 'Laktoz içermeyen', 'Düzensiz beslenme',
            'Fast-food ağırlıklı', 'DASH diyeti'
        ];

        // Sigara kullanımı
        $sigaraKullanimi = [
            'Hiç kullanmadı', 'Eski kullanıcı (bırakalı 1-5 yıl oldu)',
            'Eski kullanıcı (bırakalı 5+ yıl oldu)', 'Günde 1-5 adet',
            'Günde 5-10 adet', 'Günde 10-20 adet', 'Günde 20+ adet'
        ];

        // Alkol tüketimi
        $alkolTuketimi = [
            'Hiç kullanmıyor', 'Nadiren (ayda 1-2 kez)', 'Haftalık (haftada 1-2 kez)',
            'Düzenli (haftada 3-5 kez)', 'Ağır (neredeyse her gün)'
        ];

        // Aile hastalıkları
        $aileHastaliklari = [
            'Hipertansiyon', 'Diyabet', 'Kalp Hastalığı', 'İnme', 'Alzheimer',
            'Parkinson', 'Çeşitli Kanserler', 'Astım', 'Alerji', 'Romatizmal Hastalıklar',
            'Böbrek Hastalıkları', 'Hemofili', 'Talasemi', 'Orak Hücre Anemisi'
        ];

        foreach ($hastalar as $hasta) {
            // Yaşa göre kronik hastalık olasılığını belirle
            $kronikHastalikOlasiligi = $hasta->yas < 40 ? 0.3 :
                ($hasta->yas < 65 ? 0.6 : 0.9);

            // Rastgele 0-3 kronik hastalık seç
            $hastaninKronikHastaliklari = [];
            if ($faker->boolean($kronikHastalikOlasiligi * 100)) {
                $hastalikSayisi = min(3, max(1, intval($hasta->yas / 20))); // yaşla artan hastalık sayısı
                $hastaninKronikHastaliklari = $faker->randomElements(
                    $kronikHastaliklar,
                    $faker->numberBetween(1, $hastalikSayisi)
                );
            }

            // Rastgele 0-2 alerji seç
            $hastaninAlerjileri = [];
            if ($faker->boolean(30)) { // %30 ihtimalle alerjisi var
                $hastaninAlerjileri = $faker->randomElements(
                    $alerjiler,
                    $faker->numberBetween(1, 2)
                );
            }

            // Rastgele 0-2 ameliyat seç
            $hastaninAmeliyatlari = [];
            // Yaşa göre ameliyat olasılığı
            $ameliyatOlasiligi = $hasta->yas < 30 ? 0.2 :
                ($hasta->yas < 50 ? 0.4 :
                    ($hasta->yas < 70 ? 0.6 : 0.8));

            if ($faker->boolean($ameliyatOlasiligi * 100)) {
                $hastaninAmeliyatlari = $faker->randomElements(
                    $ameliyatlar,
                    $faker->numberBetween(1, min(2, max(1, intval($hasta->yas / 25))))
                );
            }

            // Rastgele 0-3 aile hastalığı seç
            $hastaninAileHastaliklari = [];
            if ($faker->boolean(70)) { // %70 ihtimalle aile hastalığı var
                $hastaninAileHastaliklari = $faker->randomElements(
                    $aileHastaliklari,
                    $faker->numberBetween(1, 3)
                );
            }

            // Sigara kullanımı
            $sigaraIndex = $faker->boolean(50) ? 0 : $faker->numberBetween(1, count($sigaraKullanimi) - 1);
            $sigara = $sigaraKullanimi[$sigaraIndex];

            // Alkol tüketimi
            $alkolIndex = $faker->boolean(40) ? 0 : $faker->numberBetween(1, count($alkolTuketimi) - 1);
            $alkol = $alkolTuketimi[$alkolIndex];

            // Fiziksel aktivite (VKİ'ye göre ayarla)
            $aktiviteIndex = $hasta->vki < 25 ? $faker->numberBetween(1, 4) :
                ($hasta->vki < 30 ? $faker->numberBetween(0, 3) :
                    $faker->numberBetween(0, 2));
            $aktivite = $fizikselAktiviteler[$aktiviteIndex];

            // Beslenme alışkanlığı
            $beslenmeIndex = $faker->numberBetween(0, count($beslenmeAliskanliklari) - 1);
            $beslenme = $beslenmeAliskanliklari[$beslenmeIndex];

            // Tıbbi geçmiş oluştur
            HastaTibbiGecmis::create([
                'hasta_id' => $hasta->hasta_id,
                'kronik_hastaliklar' => !empty($hastaninKronikHastaliklari) ? implode(', ', $hastaninKronikHastaliklari) : null,
                'gecirilen_ameliyatlar' => !empty($hastaninAmeliyatlari) ? implode(', ', $hastaninAmeliyatlari) : null,
                'alerjiler' => !empty($hastaninAlerjileri) ? implode(', ', $hastaninAlerjileri) : null,
                'aile_hastaliklari' => !empty($hastaninAileHastaliklari) ? implode(', ', $hastaninAileHastaliklari) : null,
                'sigara_kullanimi' => $sigara,
                'alkol_tuketimi' => $alkol,
                'fiziksel_aktivite' => $aktivite,
                'beslenme_aliskanliklari' => $beslenme,
                'created_at' => $hasta->created_at,
                'updated_at' => $hasta->updated_at
            ]);
        }
    }
}
