<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpOffice\PhpSpreadsheet\IOFactory;
use Illuminate\Support\Facades\DB;

class ImportEtkenMaddeler extends Command
{
    protected $signature = 'ilac:import-etken-maddeler {file : Excel dosyasının yolu}';
    protected $description = 'Excel dosyasından etken maddeleri ve ilişkileri içe aktarır';

    public function handle()
    {
        $filePath = $this->argument('file');

        if (!file_exists($filePath)) {
            $this->error("Dosya bulunamadı: $filePath");
            return 1;
        }

        $this->info("Excel dosyası okunuyor...");

        try {
            // Excel dosyasını oku
            $reader = IOFactory::createReader('Xlsx');
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($filePath);
            $worksheet = $spreadsheet->getActiveSheet();
            $highestRow = $worksheet->getHighestRow();

            // Başlıkları oku (ilk satır)
            $headerRow = $worksheet->rangeToArray('A1:' . $worksheet->getHighestColumn() . '1', null, true, false)[0];
            $headers = array_map('trim', $headerRow);

            // Başlık bilgilerini göster
            $this->info("Excel dosyasındaki sütunlar:");
            foreach ($headers as $index => $header) {
                $column = \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($index);
                $this->info("- $header (Sütun: $column)");
            }

            // İlerleme çubuğu oluştur
            $progressBar = $this->output->createProgressBar($highestRow - 1);
            $progressBar->start();

            // İstatistikler
            $etkenMaddeEklenen = 0;
            $iliskiKurulan = 0;
            $hataSatiri = 0;

            // Olası etken madde sütun başlıkları
            $etkenMaddeKeys = ['ETKIN_MADDE', 'Etkin Madde', 'etkin_madde', 'etken_madde', 'etken_madde_adi', 'ETKEN MADDE', 'ETKIN MADDE'];

            // Etken madde sütunu kontrolü
            $etkenMaddeColumnIndex = null;
            foreach ($etkenMaddeKeys as $key) {
                $index = array_search($key, $headers);
                if ($index !== false) {
                    $etkenMaddeColumnIndex = $index;
                    $this->info("Etken madde sütunu bulundu: $key (Sütun: " . \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($index) . ")");
                    break;
                }
            }

            if ($etkenMaddeColumnIndex === null) {
                $this->error("Etken madde sütunu bulunamadı. Olası başlıklar: " . implode(", ", $etkenMaddeKeys));
                return 1;
            }

            // İlaç adı sütunu kontrolü
            $ilacAdiKeys = ['ILAC_ADI', 'Ilac Adi', 'İlaç Adı', 'ilac_adi', 'İLAÇ ADI', 'ILAC ADI'];
            $ilacAdiColumnIndex = null;

            foreach ($ilacAdiKeys as $key) {
                $index = array_search($key, $headers);
                if ($index !== false) {
                    $ilacAdiColumnIndex = $index;
                    $this->info("İlaç adı sütunu bulundu: $key (Sütun: " . \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($index) . ")");
                    break;
                }
            }

            if ($ilacAdiColumnIndex === null) {
                $this->error("İlaç adı sütunu bulunamadı. Olası başlıklar: " . implode(", ", $ilacAdiKeys));
                return 1;
            }

            // ATC kodu sütunu kontrolü (opsiyonel)
            $atcKoduKeys = ['ATC_KODU', 'Atc Kodu', 'atc_kodu', 'atc', 'ATC KODU'];
            $atcKoduColumnIndex = null;

            foreach ($atcKoduKeys as $key) {
                $index = array_search($key, $headers);
                if ($index !== false) {
                    $atcKoduColumnIndex = $index;
                    $this->info("ATC kodu sütunu bulundu: $key (Sütun: " . \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($index) . ")");
                    break;
                }
            }

            // Miktar sütunu kontrolü (opsiyonel)
            $miktarKeys = ['BIRIM_MIKTAR', 'Birim Miktar', 'birim_miktar', 'miktar', 'Miktar', 'BİRİM MİKTAR'];
            $miktarColumnIndex = null;

            foreach ($miktarKeys as $key) {
                $index = array_search($key, $headers);
                if ($index !== false) {
                    $miktarColumnIndex = $index;
                    $this->info("Miktar sütunu bulundu: $key (Sütun: " . \PhpOffice\PhpSpreadsheet\Cell\Coordinate::stringFromColumnIndex($index) . ")");
                    break;
                }
            }

            DB::beginTransaction();

            // Satırları işle (başlık satırını atla)
            for ($rowIndex = 2; $rowIndex <= $highestRow; $rowIndex++) {
                try {
                    // Satırı oku
                    $rowData = $worksheet->rangeToArray('A' . $rowIndex . ':' . $worksheet->getHighestColumn() . $rowIndex, null, true, false)[0];

                    // Boş satırları atla
                    if (empty(array_filter($rowData))) {
                        $progressBar->advance();
                        continue;
                    }

                    // İlaç adı ve etken madde bilgilerini al
                    $ilacAdi = isset($rowData[$ilacAdiColumnIndex]) ? trim($rowData[$ilacAdiColumnIndex]) : null;
                    $etkenMaddeAdi = isset($rowData[$etkenMaddeColumnIndex]) ? trim($rowData[$etkenMaddeColumnIndex]) : null;
                    $atcKodu = ($atcKoduColumnIndex !== null && isset($rowData[$atcKoduColumnIndex])) ? trim($rowData[$atcKoduColumnIndex]) : null;
                    $miktar = ($miktarColumnIndex !== null && isset($rowData[$miktarColumnIndex])) ? trim($rowData[$miktarColumnIndex]) : null;

                    // Boş değerleri atla
                    if (empty($ilacAdi) || empty($etkenMaddeAdi)) {
                        $progressBar->advance();
                        continue;
                    }

                    // İlaç ID'sini bul
                    $ilac = DB::table('ilaclar')->where('ilac_adi', $ilacAdi)->first();

                    if (!$ilac) {
                        $this->warn("\nİlaç bulunamadı: $ilacAdi (Satır: $rowIndex)");
                        $hataSatiri++;
                        $progressBar->advance();
                        continue;
                    }

                    $ilacId = $ilac->ilac_id;

                    // Etken madde isimlerini parçalara ayır (virgülle ayrılmış olabilir)
                    $etkenMaddeler = explode(',', $etkenMaddeAdi);

                    foreach ($etkenMaddeler as $etkenMadde) {
                        $etkenMadde = trim($etkenMadde);
                        if (empty($etkenMadde)) continue;

                        // Etken maddeyi bul veya oluştur
                        $etkenMaddeObj = DB::table('etken_maddeler')
                            ->where('etken_madde_adi', $etkenMadde)
                            ->first();

                        if (!$etkenMaddeObj) {
                            $etkenMaddeId = DB::table('etken_maddeler')->insertGetId([
                                'etken_madde_adi' => $etkenMadde,
                                'atc_kodlari' => $atcKodu,
                                'created_at' => now(),
                                'updated_at' => now()
                            ]);
                            $etkenMaddeEklenen++;
                        } else {
                            $etkenMaddeId = $etkenMaddeObj->etken_madde_id;

                            // Etken maddeyi güncelle (eğer ATC kodu varsa)
                            if (!empty($atcKodu) && (empty($etkenMaddeObj->atc_kodlari) || $etkenMaddeObj->atc_kodlari != $atcKodu)) {
                                DB::table('etken_maddeler')
                                    ->where('etken_madde_id', $etkenMaddeId)
                                    ->update([
                                        'atc_kodlari' => $atcKodu,
                                        'updated_at' => now()
                                    ]);
                            }
                        }

                        // İlaç ve etken madde ilişkisini kontrol et
                        $iliskiVar = DB::table('ilac_etken_maddeler')
                            ->where('ilac_id', $ilacId)
                            ->where('etken_madde_id', $etkenMaddeId)
                            ->exists();

                        if (!$iliskiVar) {
                            // İlişki yoksa ekle
                            DB::table('ilac_etken_maddeler')->insert([
                                'ilac_id' => $ilacId,
                                'etken_madde_id' => $etkenMaddeId,
                                'miktar' => $miktar,
                                'created_at' => now(),
                                'updated_at' => now()
                            ]);
                            $iliskiKurulan++;
                        } else {
                            // İlişki varsa güncelle (eğer miktar varsa)
                            if (!empty($miktar)) {
                                DB::table('ilac_etken_maddeler')
                                    ->where('ilac_id', $ilacId)
                                    ->where('etken_madde_id', $etkenMaddeId)
                                    ->update([
                                        'miktar' => $miktar,
                                        'updated_at' => now()
                                    ]);
                            }
                        }
                    }
                } catch (\Exception $e) {
                    $hataSatiri++;
                    $this->error("\nSatır $rowIndex işlenirken hata: " . $e->getMessage());
                }

                $progressBar->advance();

                // Her 100 satırda bir belleği temizle
                if ($rowIndex % 100 == 0) {
                    gc_collect_cycles();
                }
            }

            $progressBar->finish();
            $this->newLine(2);

            DB::commit();

            $this->info("Veri aktarımı başarılı:");
            $this->info("- $etkenMaddeEklenen etken madde eklendi");
            $this->info("- $iliskiKurulan ilişki kuruldu");

            if ($hataSatiri > 0) {
                $this->warn("- $hataSatiri satırda hata oluştu");
            }

        } catch (\Exception $e) {
            if (isset($spreadsheet)) {
                $spreadsheet->disconnectWorksheets();
                unset($spreadsheet);
            }

            DB::rollBack();
            $this->error("Veri aktarımı sırasında kritik hata: " . $e->getMessage());
            $this->error($e->getTraceAsString());
            return 1;
        }

        return 0;
    }
}
