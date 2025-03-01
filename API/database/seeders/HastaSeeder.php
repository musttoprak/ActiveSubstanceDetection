<?php

namespace Database\Seeders;

use App\Models\Hasta;
use Illuminate\Database\Seeder;
use Faker\Factory as Faker;

class HastaSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        $faker = Faker::create('tr_TR'); // Türkçe fake data oluştur

        // 100 hasta oluştur
        for ($i = 0; $i < 100; $i++) {
            $cinsiyet = $faker->randomElement(['Erkek', 'Kadın']);
            $boy = $cinsiyet == 'Erkek' ?
                $faker->numberBetween(160, 190) : // Erkek için boy aralığı
                $faker->numberBetween(150, 180);  // Kadın için boy aralığı

            $kilo = $cinsiyet == 'Erkek' ?
                $faker->numberBetween(60, 110) : // Erkek için kilo aralığı
                $faker->numberBetween(45, 95);   // Kadın için kilo aralığı

            // Boy ve kiloya göre VKİ hesapla (kg/m²)
            $boyMetre = $boy / 100; // cm'den m'ye çevir
            $vki = round($kilo / ($boyMetre * $boyMetre), 2);

            // Yaş grupları daha gerçekçi olsun
            $yasGrubu = $faker->randomElement(['genç', 'orta', 'yaşlı']);
            $yas = $yasGrubu == 'genç' ? $faker->numberBetween(18, 35) :
                ($yasGrubu == 'orta' ? $faker->numberBetween(36, 65) :
                    $faker->numberBetween(66, 90));

            // TC Kimlik numarası oluştur (11 haneli)
            $tcKimlik = '';
            // İlk rakam 0 olamaz
            $tcKimlik .= $faker->numberBetween(1, 9);
            // Diğer 10 rakamı ekle
            for ($j = 0; $j < 10; $j++) {
                $tcKimlik .= $faker->numberBetween(0, 9);
            }

            // Doğum tarihi oluştur (yaşa uygun)
            $dogumTarihi = $faker->dateTimeBetween('-' . ($yas + 1) . ' years', '-' . $yas . ' years')->format('Y-m-d');

            Hasta::create([
                'ad' => $faker->firstName($cinsiyet == 'Erkek' ? 'male' : 'female'),
                'soyad' => $faker->lastName,
                'yas' => $yas,
                'cinsiyet' => $cinsiyet,
                'boy' => $boy,
                'kilo' => $kilo,
                'vki' => $vki,
                'dogum_tarihi' => $dogumTarihi,
                'tc_kimlik' => $tcKimlik,
                'telefon' => $faker->phoneNumber,
                'email' => $faker->unique()->safeEmail,
                'adres' => $faker->address,
                'created_at' => $faker->dateTimeBetween('-2 years', 'now'),
                'updated_at' => now()
            ]);
        }
    }
}
