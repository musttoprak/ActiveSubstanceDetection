<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use PhpOffice\PhpSpreadsheet\IOFactory;
use Illuminate\Support\Facades\DB;

class ImportIlacData extends Command
{
    protected $signature = 'ilac:import {file : Excel dosyasının yolu}';
    protected $description = 'Excel dosyasından ilaç verilerini içe aktarır';

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
            $spreadsheet = IOFactory::load($filePath);
            $worksheet = $spreadsheet->getActiveSheet();
            $rows = $worksheet->toArray();

            // Başlıkları al (ilk satır)
            $headers = array_shift($rows);
            $headers = array_map('trim', $headers);

            // Başlıkları göster
            $this->info("Excel dosyasındaki sütunlar:");
            foreach ($headers as $index => $header) {
                $this->info("- $header (Sütun: " . ($index + 1) . ")");
            }

            // Satırları işle
            $excelData = [];
            foreach ($rows as $row) {
                if (empty(array_filter($row))) {
                    continue; // Boş satırları atla
                }

                $rowData = [];
                foreach ($headers as $index => $header) {
                    if (isset($row[$index])) {
                        $rowData[$header] = $row[$index];
                    }
                }

                $excelData[] = $rowData;
            }

            $this->info("Toplam " . count($excelData) . " satır bulundu.");

            // Sütun adlarını kontrol et
            if (count($excelData) > 0) {
                $this->info("Excel dosyasındaki sütunlar:");
                foreach (array_keys($excelData[0]) as $column) {
                    $this->info("- $column");
                }
            }

            // Veri güncelleme işlemini başlatalım
            $updated = 0;
            $inserted = 0;
            $relations = 0;
            $errors = 0;

            $progressBar = $this->output->createProgressBar(count($excelData));
            $progressBar->start();

            DB::beginTransaction();

            try {
                foreach ($excelData as $row) {
                    try {
                        // Eksik alanlar için null değer atama
                        $row = array_map(function ($value) {
                            return $value !== '' ? $value : null;
                        }, $row);

                        // İlaç kaydını kontrol et veya oluştur
                        if (!isset($row['ilac_adi']) && !isset($row['ILAC_ADI'])) {
                            // Doğru sütun adını bulmaya çalış
                            foreach ($row as $key => $value) {
                                if (stripos($key, 'ilac') !== false && stripos($key, 'adi') !== false) {
                                    $row['ilac_adi'] = $value;
                                    break;
                                }
                            }

                            if (!isset($row['ilac_adi'])) {
                                $this->warn("İlaç adı bulunamadı, bu satır atlanıyor.");
                                continue;
                            }
                        }

                        $ilacAdi = $row['ilac_adi'] ?? $row['ILAC_ADI'] ?? '';
                        $ilac = DB::table('ilaclar')->where('ilac_adi', $ilacAdi)->first();

                        if (!$ilac) {
                            // Barkod ile bulunamadı, ilac_adi ile deneyelim
                            $ilac = DB::table('ilaclar')
                                ->where('ilac_adi', $row['ILAC_ADI'] ?? '')
                                ->first();
                        }

                        if ($ilac) {
                            // Mevcut ilacı güncelle
                            $updateData = [];

                            // Dinamik olarak veritabanı alanlarını eşleştir
                            $fieldMappings = [
                                'barkod' => ['barkod', 'BARKOD', 'barkod_no'],
                                'atc_kodu' => ['atc_kodu', 'ATC_KODU', 'atc'],
                                'uretici_firma' => ['uretici_firma', 'FIRMA_ADI', 'firma_adi'],
                                'depocu_satis_fiyati_kdv_haric' => ['depocu_satis_fiyati_kdv_haric', 'KDV HARIC DEPOCUYA SATIS TL FIYATI'],
                                'depocu_satis_fiyati_kdv_dahil' => ['depocu_satis_fiyati_kdv_dahil', 'KDV HARIC DEPOCU SATIS TL FIYATI'],
                                'perakende_satis_fiyati' => ['perakende_satis_fiyati', 'PERAKENDE SATIS TL FIYATI'],
                                'fiyat_tarihi' => ['fiyat_tarihi', 'FIYAT TARIHI'],
                                'ilac_kodu' => ['ilac_kodu', 'BARKOD'],
                                'recete_tipi' => ['recete_tipi', 'RECETE']
                            ];

                            foreach ($fieldMappings as $dbField => $excelFields) {
                                foreach ($excelFields as $excelField) {
                                    if (isset($row[$excelField])) {
                                        $updateData[$dbField] = $row[$excelField];
                                        break;
                                    }
                                }
                            }

                            // Sadece güncellenecek veri varsa güncelle
                            if (!empty($updateData)) {
                                $updateData['updated_at'] = now();

                                DB::table('ilaclar')
                                    ->where('ilac_id', $ilac->ilac_id)
                                    ->update($updateData);

                                $updated++;
                            }

                            $ilacId = $ilac->ilac_id;
                        } else {
                            // Yeni ilaç için veri hazırla
                            $insertData = [
                                'ilac_adi' => $ilacAdi,
                                'created_at' => now(),
                                'updated_at' => now()
                            ];

                            // Dinamik olarak veritabanı alanlarını eşleştir
                            $fieldMappings = [
                                'barkod' => ['barkod', 'BARKOD', 'barkod_no'],
                                'atc_kodu' => ['atc_kodu', 'ATC_KODU', 'atc'],
                                'uretici_firma' => ['uretici_firma', 'FIRMA_ADI', 'firma_adi'],
                                'depocu_satis_fiyati_kdv_haric' => ['depocu_satis_fiyati_kdv_haric', 'KDV HARIC DEPOCUYA SATIS TL FIYATI'],
                                'depocu_satis_fiyati_kdv_dahil' => ['depocu_satis_fiyati_kdv_dahil', 'KDV HARIC DEPOCU SATIS TL FIYATI'],
                                'perakende_satis_fiyati' => ['perakende_satis_fiyati', 'PERAKENDE SATIS TL FIYATI'],
                                'fiyat_tarihi' => ['fiyat_tarihi', 'FIYAT TARIHI'],
                                'ilac_kodu' => ['ilac_kodu', 'BARKOD'],
                                'recete_tipi' => ['recete_tipi', 'RECETE']
                            ];

                            foreach ($fieldMappings as $dbField => $excelFields) {
                                foreach ($excelFields as $excelField) {
                                    if (isset($row[$excelField])) {
                                        $insertData[$dbField] = $row[$excelField];
                                        break;
                                    }
                                }
                            }

                            // Yeni ilaç ekle
                            $ilacId = DB::table('ilaclar')->insertGetId($insertData);
                            $inserted++;
                        }

                        // Etken maddeleri işle
                        $etkenMaddeField = null;
                        foreach (['ETKIN_MADDE', 'etkin_madde', 'etken_madde', 'etken_madde_adi'] as $field) {
                            if (isset($row[$field]) && !empty($row[$field])) {
                                $etkenMaddeField = $field;
                                break;
                            }
                        }

                        if ($etkenMaddeField) {
                            // Etken madde isimlerini parçalara ayır (virgülle ayrılmış olabilir)
                            $etkenMaddeler = explode(',', $row[$etkenMaddeField]);

                            foreach ($etkenMaddeler as $etkenMaddeAdi) {
                                $etkenMaddeAdi = trim($etkenMaddeAdi);
                                if (empty($etkenMaddeAdi)) continue;

                                // Etken maddeyi bul veya oluştur
                                $etkenMadde = DB::table('etken_maddeler')
                                    ->where('etken_madde_adi', $etkenMaddeAdi)
                                    ->first();

                                if (!$etkenMadde) {
                                    $etkenMaddeData = [
                                        'etken_madde_adi' => $etkenMaddeAdi,
                                        'created_at' => now(),
                                        'updated_at' => now()
                                    ];

                                    // ATC kodu ekle
                                    foreach (['ATC_KODU', 'atc_kodu', 'atc'] as $field) {
                                        if (isset($row[$field]) && !empty($row[$field])) {
                                            $etkenMaddeData['atc_kodlari'] = $row[$field];
                                            break;
                                        }
                                    }

                                    $etkenMaddeId = DB::table('etken_maddeler')->insertGetId($etkenMaddeData);
                                } else {
                                    $etkenMaddeId = $etkenMadde->etken_madde_id;

                                    // Etken maddeyi güncelle (ATC kodları)
                                    $atcKoduField = null;
                                    foreach (['ATC_KODU', 'atc_kodu', 'atc'] as $field) {
                                        if (isset($row[$field]) && !empty($row[$field])) {
                                            $atcKoduField = $field;
                                            break;
                                        }
                                    }

                                    if ($atcKoduField) {
                                        DB::table('etken_maddeler')
                                            ->where('etken_madde_id', $etkenMaddeId)
                                            ->update([
                                                'atc_kodlari' => $row[$atcKoduField],
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
                                    // İlişki yok, yeni ilişki ekle
                                    $iliskiData = [
                                        'ilac_id' => $ilacId,
                                        'etken_madde_id' => $etkenMaddeId,
                                        'created_at' => now(),
                                        'updated_at' => now()
                                    ];

                                    // Miktar bilgisi arama
                                    foreach (['BIRIM_MIKTAR', 'birim_miktar', 'miktar'] as $field) {
                                        if (isset($row[$field]) && !empty($row[$field])) {
                                            $iliskiData['miktar'] = $row[$field];
                                            break;
                                        }
                                    }

                                    DB::table('ilac_etken_maddeler')->insert($iliskiData);
                                    $relations++;
                                } else {
                                    // İlişki varsa, miktar bilgisini güncelle
                                    $miktarField = null;
                                    foreach (['BIRIM_MIKTAR', 'birim_miktar', 'miktar'] as $field) {
                                        if (isset($row[$field]) && !empty($row[$field])) {
                                            $miktarField = $field;
                                            break;
                                        }
                                    }

                                    if ($miktarField) {
                                        DB::table('ilac_etken_maddeler')
                                            ->where('ilac_id', $ilacId)
                                            ->where('etken_madde_id', $etkenMaddeId)
                                            ->update([
                                                'miktar' => $row[$miktarField],
                                                'updated_at' => now()
                                            ]);
                                    }
                                }
                            }
                        }
                    } catch (\Exception $e) {
                        $errors++;
                        $this->error("\nSatır işlenirken hata: " . $e->getMessage());
                    }

                    $progressBar->advance();
                }

                $progressBar->finish();
                $this->newLine(2);

                DB::commit();

                $this->info("Veri aktarımı başarılı:");
                $this->info("- $updated ilaç güncellendi");
                $this->info("- $inserted yeni ilaç eklendi");
                $this->info("- $relations ilişki kuruldu");

                if ($errors > 0) {
                    $this->warn("- $errors satırda hata oluştu");
                }

            } catch (\Exception $e) {
                DB::rollBack();
                $this->error("Veri aktarımı sırasında kritik hata: " . $e->getMessage());
                return 1;
            }
        } catch (\Exception $e) {
            $this->error("Excel dosyası okunurken hata: " . $e->getMessage());
            return 1;
        }

        return 0;
    }
}
