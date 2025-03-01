<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CompleteMedicineActiveSubstanceRelationship extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'medicine:complete-relationships';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'İlaçlar ve etken maddeler arasındaki eksik ilişkileri tamamlar';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('İlaç ve etken madde ilişkileri tamamlanıyor...');

        // 1. Var olan ilişkileri kontrol et
        $existingRelationships = DB::table('ilac_etken_maddeler')->count();
        $this->info("Mevcut ilişki sayısı: $existingRelationships");

        // 2. İlaç adlarını kullanarak etken madde ilişkilerini kur
        $this->associateByDrugName();

        // 3. Varsa, SGK veri setindeki ilişkileri kullan
        $this->associateBySGKData();

        // 4. Barkod numaralarına göre aynı ilaçların etken maddelerini eşleştir
        $this->associateSimilarDrugs();

        // 5. İlaç-etken madde ilişki istatistiklerini görüntüle
        $this->showRelationshipStats();

        $this->info('İşlem tamamlandı.');

        return 0;
    }

    /**
     * İlaç adlarında geçen etken madde adlarını kullanarak ilişkileri kur
     */
    private function associateByDrugName()
    {
        $this->info('İlaç adlarından etken madde ilişkileri oluşturuluyor...');

        // Tüm etken maddeleri al
        $etkenMaddeler = DB::table('etken_maddeler')->get();
        $bar = $this->output->createProgressBar(count($etkenMaddeler));
        $bar->start();

        $totalAdded = 0;

        foreach ($etkenMaddeler as $etkenMadde) {
            // Etken madde adını içeren ilaçları bul
            $ilaclar = DB::table('ilaclar')
                ->whereRaw('UPPER(ilac_adi) LIKE ?', ['%' . strtoupper($etkenMadde->etken_madde_adi) . '%'])
                ->select('ilac_id', 'ilac_adi')
                ->get();

            foreach ($ilaclar as $ilac) {
                // İlişki var mı kontrol et
                $existingRelation = DB::table('ilac_etken_maddeler')
                    ->where('ilac_id', $ilac->ilac_id)
                    ->where('etken_madde_id', $etkenMadde->etken_madde_id)
                    ->exists();

                if (!$existingRelation) {
                    // Doz bilgisini ilacın adından çıkarmaya çalış
                    $dozaj = $this->extractDosageFromDrugName($ilac->ilac_adi, $etkenMadde->etken_madde_adi);

                    // İlişkiyi ekle
                    DB::table('ilac_etken_maddeler')->insert([
                        'ilac_id' => $ilac->ilac_id,
                        'etken_madde_id' => $etkenMadde->etken_madde_id,
                        'miktar' => $dozaj,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    $totalAdded++;
                }
            }
            $bar->advance();
        }

        $bar->finish();
        $this->info("\nİlaç adlarından $totalAdded yeni ilişki eklendi.");
    }

    /**
     * İlaç adından doz bilgisini çıkar
     */
    private function extractDosageFromDrugName($ilacAdi, $etkenMaddeAdi)
    {
        // Dozaj kalıpları (örn: 500 mg, 10 mg/ml, vb.)
        $patterns = [
            '/\b(\d+(?:\.\d+)?)\s*(?:mg|g|mcg|µg|ml|IU)\b/i',
            '/\b(\d+(?:\.\d+)?)\s*(?:mg|g|mcg|µg|ml|IU)\/(?:\d+(?:\.\d+)?)\s*(?:ml|g|tablet|kapsül)\b/i',
            '/\b(\d+(?:\.\d+)?)\s*%\b/i',
        ];

        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $ilacAdi, $matches)) {
                return $matches[0];
            }
        }

        return null;
    }

    /**
     * SGK veritabanındaki ilişkileri kullan
     * NOT: Bu fonksiyon SGK verisi varsa kullanılabilir
     */
    private function associateBySGKData()
    {
        $this->info('SGK verilerinden etken madde ilişkileri oluşturuluyor...');

        // Bu kısım SGK verisine erişiminiz varsa doldurulabilir
        // Örnek kod:
        /*
        $sgkIlacEtkenMaddeVerileri = DB::table('sgk_ilac_etken_madde')->get();

        foreach ($sgkIlacEtkenMaddeVerileri as $veri) {
            $ilac = DB::table('ilaclar')->where('barkod', $veri->barkod)->first();
            $etkenMadde = DB::table('etken_maddeler')->where('etken_madde_adi', $veri->etken_madde_adi)->first();

            if ($ilac && $etkenMadde) {
                // İlişki var mı kontrol et
                $existingRelation = DB::table('ilac_etken_maddeler')
                    ->where('ilac_id', $ilac->ilac_id)
                    ->where('etken_madde_id', $etkenMadde->etken_madde_id)
                    ->exists();

                if (!$existingRelation) {
                    // İlişkiyi ekle
                    DB::table('ilac_etken_maddeler')->insert([
                        'ilac_id' => $ilac->ilac_id,
                        'etken_madde_id' => $etkenMadde->etken_madde_id,
                        'miktar' => $veri->miktar,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }
        }
        */

        // SGK verisi olmadığı için bu bilgiyi loglayalım
        $this->info('SGK verileri mevcut olmadığı için bu adım atlandı. Gerekirse kodda düzenleme yapabilirsiniz.');
    }

    /**
     * Benzer ilaçların etken maddelerini eşleştir
     */
    private function associateSimilarDrugs()
    {
        $this->info('Benzer ilaçların etken madde ilişkileri kopyalanıyor...');

        // Barkodu olmayan ve etken maddesi olmayan ilaçları al
        $ilaclarWithoutActiveSubstance = DB::table('ilaclar')
            ->whereNotExists(function ($query) {
                $query->select(DB::raw(1))
                    ->from('ilac_etken_maddeler')
                    ->whereRaw('ilac_etken_maddeler.ilac_id = ilaclar.ilac_id');
            })
            ->whereNotNull('ilac_adi')
            ->where('ilac_adi', '!=', '')
            ->select('ilac_id', 'ilac_adi', 'barkod')
            ->get();

        $totalAdded = 0;
        $bar = $this->output->createProgressBar(count($ilaclarWithoutActiveSubstance));
        $bar->start();

        foreach ($ilaclarWithoutActiveSubstance as $ilac) {
            // İlaç adının ilk bölümünü al (örneğin "PAROL TABLET" -> "PAROL")
            $ilacNameParts = explode(' ', $ilac->ilac_adi);
            $ilacBaseName = $ilacNameParts[0];

            // Benzer adlı ve etken maddesi olan ilaçları bul
            $similarDrugs = DB::table('ilaclar')
                ->whereRaw('UPPER(ilac_adi) LIKE ?', ['%' . strtoupper($ilacBaseName) . '%'])
                ->whereExists(function ($query) {
                    $query->select(DB::raw(1))
                        ->from('ilac_etken_maddeler')
                        ->whereRaw('ilac_etken_maddeler.ilac_id = ilaclar.ilac_id');
                })
                ->select('ilac_id')
                ->get();

            foreach ($similarDrugs as $similarDrug) {
                // Benzer ilacın etken maddelerini al
                $etkenMaddeler = DB::table('ilac_etken_maddeler')
                    ->where('ilac_id', $similarDrug->ilac_id)
                    ->get();

                foreach ($etkenMaddeler as $etkenMadde) {
                    // İlişki var mı kontrol et
                    $existingRelation = DB::table('ilac_etken_maddeler')
                        ->where('ilac_id', $ilac->ilac_id)
                        ->where('etken_madde_id', $etkenMadde->etken_madde_id)
                        ->exists();

                    if (!$existingRelation) {
                        // İlişkiyi ekle
                        DB::table('ilac_etken_maddeler')->insert([
                            'ilac_id' => $ilac->ilac_id,
                            'etken_madde_id' => $etkenMadde->etken_madde_id,
                            'miktar' => $etkenMadde->miktar,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);

                        $totalAdded++;
                        // Bir adet etken madde ilişkisi ekledikten sonra diğer benzer ilaçlara geçelim
                        break 2;
                    }
                }
            }

            $bar->advance();
        }

        $bar->finish();
        $this->info("\nBenzer ilaçlardan $totalAdded yeni ilişki eklendi.");
    }

    /**
     * İlaç-etken madde ilişki istatistiklerini görüntüle
     */
    private function showRelationshipStats()
    {
        $this->info("\nİlaç-etken madde ilişki istatistikleri:");

        $totalDrugs = DB::table('ilaclar')->count();
        $drugsWithActiveSubstance = DB::table('ilaclar')
            ->whereExists(function ($query) {
                $query->select(DB::raw(1))
                    ->from('ilac_etken_maddeler')
                    ->whereRaw('ilac_etken_maddeler.ilac_id = ilaclar.ilac_id');
            })
            ->count();

        $totalActiveSubstances = DB::table('etken_maddeler')->count();
        $activeSubstancesWithDrugs = DB::table('etken_maddeler')
            ->whereExists(function ($query) {
                $query->select(DB::raw(1))
                    ->from('ilac_etken_maddeler')
                    ->whereRaw('ilac_etken_maddeler.etken_madde_id = etken_maddeler.etken_madde_id');
            })
            ->count();

        $totalRelationships = DB::table('ilac_etken_maddeler')->count();

        $this->info("Toplam ilaç sayısı: $totalDrugs");
        $this->info("Etken maddesi olan ilaç sayısı: $drugsWithActiveSubstance (%". round(($drugsWithActiveSubstance / $totalDrugs) * 100, 2) .")");
        $this->info("Toplam etken madde sayısı: $totalActiveSubstances");
        $this->info("İlacı olan etken madde sayısı: $activeSubstancesWithDrugs (%". round(($activeSubstancesWithDrugs / $totalActiveSubstances) * 100, 2) .")");
        $this->info("Toplam ilişki sayısı: $totalRelationships");

        // En çok ilaca sahip etken maddeler
        $this->info("\nEn çok ilaca sahip etken maddeler:");
        $topActiveSubstances = DB::table('ilac_etken_maddeler')
            ->join('etken_maddeler', 'ilac_etken_maddeler.etken_madde_id', '=', 'etken_maddeler.etken_madde_id')
            ->select('etken_maddeler.etken_madde_adi', DB::raw('COUNT(*) as ilac_sayisi'))
            ->groupBy('etken_maddeler.etken_madde_adi')
            ->orderBy('ilac_sayisi', 'desc')
            ->limit(10)
            ->get();

        foreach ($topActiveSubstances as $index => $as) {
            $this->info(($index + 1) . ". " . $as->etken_madde_adi . " (" . $as->ilac_sayisi . " ilaç)");
        }
    }
}
