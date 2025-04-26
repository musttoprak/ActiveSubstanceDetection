<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        // İşlemlerin sırası önemli, ilişkili veriler için sıralamaya dikkat et
        $this->call([
            //HastalikSeeder::class,        // Önce hastalıkları oluştur
            //HastaSeeder::class,           // Sonra hastaları oluştur
            //HastaTibbiGecmisSeeder::class,// Tıbbi geçmişleri ekle
            //HastaHastalikSeeder::class,   // Hasta-hastalık ilişkileri
            //HastaIlacKullanimSeeder::class, // İlaç kullanım geçmişi
            //LaboratuvarSonucuSeeder::class, // Laboratuvar sonuçları
            ReceteSeeder::class             // Reçete oluşturur
        ]);
    }
}
