<?php

namespace Database\Seeders;

use App\Models\Hasta;
use App\Models\Hastalik;
use App\Models\Ilac;
use App\Models\Recete;
use App\Models\ReceteIlac;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class ReceteSeeder extends Seeder
{
    public function run()
    {
        // Var olan hasta ve hastalıklar
        $hastalar = Hasta::all();
        $hastaliklar = Hastalik::all();
        $ilaclar = Ilac::all();

        if ($hastalar->isEmpty() || $hastaliklar->isEmpty() || $ilaclar->isEmpty()) {
            $this->command->error('Hasta, hastalık ve ilaç verilerinin olduğundan emin olun!');
            return;
        }

        $durumlar = ['Onaylandı', 'Beklemede', 'İptal Edildi'];
        $dozajlar = ['1x1', '2x1', '3x1', '1x2', '2x2', 'Günde 1 tablet', 'Günde 2 tablet', 'Sabah-Akşam 1 tablet'];
        $kullanimTalimatlari = [
            'Yemeklerden sonra alınız',
            'Aç karnına alınız',
            'Tok karnına alınız',
            'Bol su ile alınız',
            'Gece yatmadan önce alınız',
            'Sabah aç karnına alınız',
            'Su ile çözüp içiniz',
            'Yemek aralarında alınız',
            'Günde 3 defa alınız'
        ];

        // 10 adet reçete oluştur
        for ($i = 1; $i <= 10; $i++) {
            $hasta = $hastalar->random();
            $hastalik = $hastaliklar->random();

            // Reçete numarası oluştur
            $receteNo = 'RX-' . date('Ymd') . '-' . Str::upper(Str::random(6));

            // Reçete oluştur
            $recete = Recete::create([
                'hasta_id' => $hasta->hasta_id,
                'hastalik_id' => $hastalik->hastalik_id,
                //'doktor_id' => rand(1, 5), // Varsayılan olarak 1-5 arası doktor ID
                'recete_no' => $receteNo,
                'tarih' => now()->subDays(rand(0, 30))->format('Y-m-d'),
                'notlar' => rand(0, 1) ? 'Düzenli kullanılması önemlidir.' : null,
                'durum' => $durumlar[array_rand($durumlar)],
                'aktif' => rand(0, 10) > 2 // Çoğunlukla aktif
            ]);

            // Her reçeteye 1-4 adet ilaç ekle
            $receteIlacSayisi = rand(1, 4);
            $seciliIlaclar = $ilaclar->random($receteIlacSayisi);

            foreach ($seciliIlaclar as $ilac) {
                ReceteIlac::create([
                    'recete_id' => $recete->recete_id,
                    'ilac_id' => $ilac->ilac_id,
                    'dozaj' => $dozajlar[array_rand($dozajlar)],
                    'kullanim_talimati' => $kullanimTalimatlari[array_rand($kullanimTalimatlari)],
                    'miktar' => rand(1, 3)
                ]);
            }

            $this->command->info("Reçete oluşturuldu: {$receteNo} (Hasta: {$hasta->ad} {$hasta->soyad}, Hastalık: {$hastalik->hastalik_adi})");
        }
    }
}
