<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class ImportMedicineData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'import:medicine-data
                            {--ilaclar-path=C:\Projelerim\ActiveSubstanceDetection\Web-Scraping\ilaclar : İlaçlar JSON klasörü yolu}
                            {--etken-madde-path=C:\Projelerim\ActiveSubstanceDetection\Web-Scraping\etkin_madde : Etken madde JSON klasörü yolu}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'İlaç ve etken madde JSON verilerini veritabanına aktarır';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $ilaclarPath = $this->option('ilaclar-path');
        $etkenMaddePath = $this->option('etken-madde-path');

        // İlaç verilerini içe aktar
        $this->importMedicines($ilaclarPath);

        // Etken madde verilerini içe aktar
        $this->importActiveSubstances($etkenMaddePath);

        $this->info('Tüm veriler başarıyla içe aktarıldı!');
        return 0;
    }

    /**
     * İlaç JSON dosyalarını işle ve veritabanına aktar
     */
    private function importMedicines($path)
    {
        if (!File::exists($path)) {
            $this->error("İlaçlar klasörü bulunamadı: $path");
            return;
        }

        $files = File::files($path);
        $bar = $this->output->createProgressBar(count($files));
        $bar->start();

        $this->info("\nİlaç verileri aktarılıyor...");
        $totalImported = 0;
        $totalErrors = 0;

        foreach ($files as $file) {
            try {
                // Dosya adından kategori ID'sini ve ilac kodunu çıkar
                $filename = $file->getFilename();
                // Dosya formatı: 4-MTA5NTc.json gibi
                if (preg_match('/^(\d+)-([A-Za-z0-9]+)\.json$/', $filename, $matches)) {
                    $ilacKategoriId = intval($matches[1]);
                    $ilacKodu = $matches[2];
                } else {
                    // Dosya adı formatı eşleşmezse varsayılan değerleri kullan
                    $ilacKategoriId = null;
                    $ilacKodu = pathinfo($filename, PATHINFO_FILENAME);
                }

                // JSON verisini oku
                $jsonContent = File::get($file);

                // JSON içeriğini kontrol et ve temizle (gerekirse)
                $jsonContent = $this->cleanJsonContent($jsonContent);

                $jsonData = json_decode($jsonContent, true);

                if (json_last_error() !== JSON_ERROR_NONE) {
                    $this->error("JSON okunamadı: $filename - Hata: " . json_last_error_msg());
                    $totalErrors++;
                    $bar->advance();
                    continue;
                }

                // Basit veri yapısı kontrolü - eğer sadece "Adı" varsa ve "Ürün adı bulunamadı" ise
                $isMinimalData = isset($jsonData['Adı']) && $jsonData['Adı'] === "Ürün adı bulunamadı";

                // İlaç verisi hazırla
                $ilacData = [
                    'ilac_kodu' => $ilacKodu,
                    'ilac_kategori_id' => $ilacKategoriId,
                    'created_at' => now(),
                    'updated_at' => now(),
                ];

                // Eğer basit veri değilse ve gerekli alanlar varsa, detayları ekle
                if (!$isMinimalData && isset($jsonData['Adı'])) {
                    $ilacData['ilac_adi'] = $jsonData['Adı'];

                    if (isset($jsonData['ÖZET'])) {
                        $ilacData['barkod'] = $jsonData['ÖZET']['Barkod'] ?? null;
                        $ilacData['ilac_adi_firma'] = $jsonData['ÖZET']['İlaç Adı ve Firma'] ?? null;
                        $ilacData['recete_tipi'] = $jsonData['ÖZET']['Reçete Tipi'] ?? null;
                        $ilacData['perakende_satis_fiyati'] = $this->extractNumeric($jsonData['ÖZET']['Perakende Satış Fiyatı'] ?? '0');
                        $ilacData['depocu_satis_fiyati_kdv_dahil'] = $this->extractNumeric($jsonData['ÖZET']['Depocu Satış Fiyatı (KDV Dahil)'] ?? '0');
                        $ilacData['depocu_satis_fiyati_kdv_haric'] = $this->extractNumeric($jsonData['ÖZET']['Depocu Satış Fiyatı (KDV Hariç)'] ?? '0');
                        $ilacData['imalatci_satis_fiyati_kdv_haric'] = $this->extractNumeric($jsonData['ÖZET']['İmalatçı Satış Fiyatı (KDV Hariç)'] ?? '0');
                    }

                    if (isset($jsonData['SUT ÖZET']) && isset($jsonData['SUT ÖZET']['SGK Durumu'])) {
                        $ilacData['sgk_durumu'] = $jsonData['SUT ÖZET']['SGK Durumu'];
                    }

                    if (isset($jsonData['FIYAT HAREKETLERI']) && isset($jsonData['FIYAT HAREKETLERI']['Fiyat Hareketleri'])) {
                        $ilacData['fiyat_hareketleri'] = json_encode($jsonData['FIYAT HAREKETLERI']['Fiyat Hareketleri'], JSON_UNESCAPED_UNICODE);
                    }

                    if (isset($jsonData['EŞDEĞER'])) {
                        $ilacData['esdeger_ilaclar'] = json_encode($jsonData['EŞDEĞER'], JSON_UNESCAPED_UNICODE);
                    }
                } else {
                    // Minimal veri durumunda, sadece dosya adından gelen bilgileri kullan
                    $ilacData['ilac_adi'] = "İlaç " . $ilacKodu;
                }

                // İlaç bilgilerini veritabanına ekle veya güncelle
                $existingIlac = DB::table('ilaclar')
                    ->where(function ($query) use ($ilacData, $ilacKodu) {
                        if (!empty($ilacData['barkod'])) {
                            $query->where('barkod', $ilacData['barkod']);
                        }
                        $query->orWhere('ilac_kodu', $ilacKodu);
                    })
                    ->first();

                if ($existingIlac) {
                    DB::table('ilaclar')->where('ilac_id', $existingIlac->ilac_id)->update($ilacData);
                    $ilacId = $existingIlac->ilac_id;
                } else {
                    $ilacId = DB::table('ilaclar')->insertGetId($ilacData);
                }

                // Eğer basit veri değilse ve etken madde bilgisi varsa, ilişkileri kur
                if (!$isMinimalData && isset($jsonData['ETKIN MADDE']) && isset($jsonData['ETKIN MADDE']['Etkin Madde'])
                    && !empty($jsonData['ETKIN MADDE']['Etkin Madde'])) {

                    $etkenMaddeAdi = $jsonData['ETKIN MADDE']['Etkin Madde'];
                    $dozaj = $jsonData['ETKIN MADDE']['Dozaj'] ?? null;

                    // Etken madde var mı kontrol et, yoksa ekle
                    $etkenMadde = DB::table('etken_maddeler')
                        ->where('etken_madde_adi', $etkenMaddeAdi)
                        ->first();

                    if (!$etkenMadde) {
                        $etkenMaddeId = DB::table('etken_maddeler')->insertGetId([
                            'etken_madde_adi' => $etkenMaddeAdi,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    } else {
                        $etkenMaddeId = $etkenMadde->etken_madde_id;
                    }

                    // İlaç-etken madde ilişkisini ekle
                    $existingRelation = DB::table('ilac_etken_maddeler')
                        ->where('ilac_id', $ilacId)
                        ->where('etken_madde_id', $etkenMaddeId)
                        ->first();

                    if (!$existingRelation) {
                        DB::table('ilac_etken_maddeler')->insert([
                            'ilac_id' => $ilacId,
                            'etken_madde_id' => $etkenMaddeId,
                            'miktar' => $dozaj,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    } else {
                        DB::table('ilac_etken_maddeler')
                            ->where('ilac_id', $ilacId)
                            ->where('etken_madde_id', $etkenMaddeId)
                            ->update([
                                'miktar' => $dozaj,
                                'updated_at' => now(),
                            ]);
                    }
                }

                $totalImported++;
            } catch (\Exception $e) {
                $this->error("Hata: {$e->getMessage()} - Dosya: {$file->getFilename()}");
                $totalErrors++;
            }

            $bar->advance();
        }

        $bar->finish();
        $this->info("\n$totalImported ilaç başarıyla içe aktarıldı. $totalErrors hatalı kayıt.");
    }

    /**
     * JSON içeriğindeki sorunları temizle
     */
    private function cleanJsonContent($content)
    {
        // BOM karakteri temizle
        $content = preg_replace('/^\xEF\xBB\xBF/', '', $content);

        // Geçersiz UTF-8 karakterleri temizle
        $content = mb_convert_encoding($content, 'UTF-8', 'UTF-8');

        // Ters eğik çizgileri düzelt
        $content = str_replace('\\\\', '\\', $content);

        return $content;
    }

    /**
     * Etken madde JSON dosyalarını işle ve veritabanına aktar
     */
    private function importActiveSubstances($path)
    {
        if (!File::exists($path)) {
            $this->error("Etken madde klasörü bulunamadı: $path");
            return;
        }

        $files = File::files($path);
        $bar = $this->output->createProgressBar(count($files));
        $bar->start();

        $this->info("\nEtken madde verileri aktarılıyor...");
        $totalImported = 0;
        $totalErrors = 0;

        foreach ($files as $file) {
            try {
                // JSON verisini oku
                $jsonContent = File::get($file);

                // JSON içeriğini temizle
                $jsonContent = $this->cleanJsonContent($jsonContent);

                $jsonData = json_decode($jsonContent, true);

                if (json_last_error() !== JSON_ERROR_NONE) {
                    $this->error("JSON okunamadı: " . $file->getFilename() . " - Hata: " . json_last_error_msg());
                    $totalErrors++;
                    $bar->advance();
                    continue;
                }

                $etkenMaddeAdi = $jsonData['İlaç Adı'] ?? null;

                if (!$etkenMaddeAdi) {
                    $this->error("Etken madde adı bulunamadı: " . $file->getFilename());
                    $totalErrors++;
                    $bar->advance();
                    continue;
                }

                // Tablo verisi ve ek bilgiler
                $tableData = $jsonData['Genel Bilgi']['table_data'] ?? [];
                $additionalInfo = $jsonData['Genel Bilgi']['additional_info'] ?? [];

                // Veriyi hazırla
                $etkenMaddeData = [
                    'etken_madde_adi' => $etkenMaddeAdi,
                    'ingilizce_adi' => $tableData['İngilizce'] ?? null,
                    'net_kutle' => $tableData['Net Kütle'] ?? null,
                    'molekul_agirligi' => $tableData['Molekül Ağırlığı'] ?? null,
                    'formul' => $tableData['Formül'] ?? null,
                    'atc_kodlari' => $tableData['İlişkili ATC Kodları'] ?? null,
                    'genel_bilgi' => $additionalInfo['Genel Bilgi'] ?? null,
                    'etki_mekanizmasi' => $additionalInfo['Etki Mekanizması'] ?? null,
                    'farmakokinetik' => $additionalInfo['Farmakokinetik'] ?? null,
                    'resim_url' => $jsonData['Genel Bilgi']['image_src'] ?? null,
                    'mustahzarlar' => isset($jsonData['Müstahzarlar']) ?
                        json_encode($jsonData['Müstahzarlar'], JSON_UNESCAPED_UNICODE) : null,
                    'updated_at' => now(),
                ];

                // Etken maddeyi veritabanına ekle veya güncelle
                $existingEtkenMadde = DB::table('etken_maddeler')
                    ->where('etken_madde_adi', $etkenMaddeAdi)
                    ->first();

                if ($existingEtkenMadde) {
                    DB::table('etken_maddeler')
                        ->where('etken_madde_id', $existingEtkenMadde->etken_madde_id)
                        ->update($etkenMaddeData);
                } else {
                    $etkenMaddeData['created_at'] = now();
                    DB::table('etken_maddeler')->insert($etkenMaddeData);
                }

                $totalImported++;
            } catch (\Exception $e) {
                $this->error("Hata: {$e->getMessage()} - Dosya: " . $file->getFilename());
                $totalErrors++;
            }

            $bar->advance();
        }

        $bar->finish();
        $this->info("\n$totalImported etken madde başarıyla içe aktarıldı. $totalErrors hatalı kayıt.");
    }

    /**
     * Metin içerisinden sayısal değeri çıkarır
     */
    private function extractNumeric($value)
    {
        if (is_numeric($value)) {
            return $value;
        }

        // Sadece sayısal değeri çıkart (nokta ve virgül dahil)
        preg_match('/[0-9,.]+/', $value, $matches);

        if (isset($matches[0])) {
            // Türkçe formatını düzelt (virgülü noktaya çevir)
            $numericValue = str_replace(',', '.', $matches[0]);
            return floatval($numericValue);
        }

        return 0;
    }
}
