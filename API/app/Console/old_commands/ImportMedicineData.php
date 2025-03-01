<?php

namespace App\Console\old_commands;

use App\Models\Equivalent;
use App\Models\Medicine;
use App\Models\PriceMovement;
use Illuminate\Console\Command;

class ImportMedicineData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'import:medicine-data';


    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Command description';

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return void
     */
    public function handle()
    {
        $folder = 'C:\Projelerim\ActiveSubstanceDetection\Web-Scraping\ilaclar'; // JSON dosyalarının tam yolu

        // Dosya yolunu kontrol et
        if (!is_dir($folder)) {
            $this->error("Belirtilen klasör mevcut değil: $folder");
            return;
        }

        // Tüm JSON dosyalarını al
        $files = glob($folder . '/*.json');

        foreach ($files as $file) {
            $data = json_decode(file_get_contents($file), true);

            if (!$data) {
                $this->error("Geçersiz JSON dosyası: $file");
                continue;
            }

            // ÖZET anahtarını kontrol et
            if (!isset($data['ÖZET'])) {
                $this->warn("ÖZET anahtarı eksik: $file");
                continue;
            }

            // Medicine tablosuna kaydet
            $medicine = Medicine::updateOrCreate(
                ['name' => $data['Adı'] ?? null],
                [
                    'company' => $data['ÖZET']['İlaç Adı ve Firma'] ?? null,
                    'barcode' => $data['ÖZET']['Barkod'] ?? null,
                    'prescription_type' => $data['ÖZET']['Reçete Tipi'] ?? null,
                    'retail_price' => isset($data['ÖZET']['Perakende Satış Fiyatı']) && is_numeric($data['ÖZET']['Perakende Satış Fiyatı']) ? $data['ÖZET']['Perakende Satış Fiyatı'] : null,
                    'depot_price_with_vat' => isset($data['ÖZET']['Depocu Satış Fiyatı (KDV Dahil)']) && is_numeric($data['ÖZET']['Depocu Satış Fiyatı (KDV Dahil)']) ? $data['ÖZET']['Depocu Satış Fiyatı (KDV Dahil)'] : null,
                    'depot_price_without_vat' => isset($data['ÖZET']['Depocu Satış Fiyatı (KDV Hariç)']) && is_numeric($data['ÖZET']['Depocu Satış Fiyatı (KDV Hariç)']) ? $data['ÖZET']['Depocu Satış Fiyatı (KDV Hariç)'] : null,
                    'manufacturer_price_without_vat' => isset($data['ÖZET']['İmalatçı Satış Fiyatı (KDV Hariç)']) && is_numeric($data['ÖZET']['İmalatçı Satış Fiyatı (KDV Hariç)']) ? $data['ÖZET']['İmalatçı Satış Fiyatı (KDV Hariç)'] : null,
                    'vat_info' => $data['ÖZET']['KDV'] ?? null,
                    'price_date' => $data['ÖZET']['Fiyat Tarihi'] ?? null,
                    'active_substance' => $data['ETKIN MADDE']['Etkin Madde'] ?? null,
                    'dosage' => $data['ETKIN MADDE']['Dozaj'] ?? null,
                    'sgk_status' => $data['SUT ÖZET']['SGK Durumu'] ?? null,
                ]
            );

            // PriceMovements kaydet
            if (!empty($data['FIYAT HAREKETLERI']['Fiyat Hareketleri'])) {
                foreach ($data['FIYAT HAREKETLERI']['Fiyat Hareketleri'] as $movement) {
                    PriceMovement::create([
                        'medicine_id' => $medicine->id,
                        'date' => isset($movement['Tarih']) ? date('Y-m-d', strtotime($movement['Tarih'])) : null,
                        'transaction_type' => $movement['İşlem'] ?? null,
                        'isf' => isset($movement['İSF']) && is_numeric($movement['İSF']) ? $movement['İSF'] : null,
                        'dsf' => isset($movement['DSF']) && is_numeric($movement['DSF']) ? $movement['DSF'] : null,
                        'psf' => isset($movement['PSF']) && is_numeric($movement['PSF']) ? $movement['PSF'] : null,
                        'kf' => isset($movement['KF']) && is_numeric($movement['KF']) ? $movement['KF'] : null,
                        'ko' => isset($movement['KÖ']) && is_numeric($movement['KÖ']) ? $movement['KÖ'] : null,
                    ]);
                }
            }

            // Equivalents kaydet
            if (!empty($data['EŞDEĞER'])) {
                foreach ($data['EŞDEĞER'] as $equivalent) {
                    Equivalent::create([
                        'medicine_id' => $medicine->id,
                        'error' => $equivalent['Error'] ?? null,
                    ]);
                }
            }
        }

        $this->info('Tüm veriler başarıyla kaydedildi.');
    }
}
