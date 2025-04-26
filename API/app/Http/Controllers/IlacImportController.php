<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;
use App\Imports\IlacImport;
use Illuminate\Support\Facades\DB;

class IlacImportController extends Controller
{
    public function showImportForm()
    {
        return view('ilac-import');
    }

    public function import(Request $request)
    {
        $request->validate([
            'excel_file' => 'required|mimes:xlsx,xls,csv',
        ]);

        try {
            // Excel dosyasındaki verileri toplayalım
            $excelData = [];
            Excel::import(new IlacImport($excelData), $request->file('excel_file'));

            // Veri güncelleme işlemini başlatalım
            $updated = 0;
            $inserted = 0;
            $relations = 0;

            DB::beginTransaction();

            try {
                foreach ($excelData as $row) {
                    // İlaç kaydını kontrol et veya oluştur
                    $ilac = DB::table('ilaclar')->where('ilac_adi', $row['ILAC_ADI'])->first();

                    if ($ilac) {
                        // Mevcut ilacı güncelle
                        DB::table('ilaclar')
                            ->where('ilac_id', $ilac->ilac_id)
                            ->update([
                                'barkod' => $row['BARKOD'] ?? $ilac->barkod,
                                'atc_kodu' => $row['ATC_KODU'] ?? $ilac->atc_kodu,
                                'uretici_firma' => $row['FIRMA_ADI'] ?? $ilac->uretici_firma,
                                'depocu_satis_fiyati_kdv_haric' => $row['DEPOCU_SATIS_FIYATI_KDV_HARIC'] ?? $ilac->depocu_satis_fiyati_kdv_haric,
                                'depocu_satis_fiyati_kdv_dahil' => $row['DEPOCU_SATIS_FIYATI_KDV_DAHIL'] ?? $ilac->depocu_satis_fiyati_kdv_dahil,
                                'perakende_satis_fiyati' => $row['PERAKENDE_SATIS_FIYATI'] ?? $ilac->perakende_satis_fiyati,
                                'fiyat_tarihi' => $row['FIYAT_TARIHI'] ?? $ilac->fiyat_tarihi,
                                'ilac_kodu' => $row['BARKOD'] ?? $ilac->ilac_kodu,
                                'recete_tipi' => $row['RECETE_TIPI'] ?? $ilac->recete_tipi,
                                'updated_at' => now()
                            ]);
                        $updated++;
                        $ilacId = $ilac->ilac_id;
                    } else {
                        // Yeni ilaç ekle
                        $ilacId = DB::table('ilaclar')->insertGetId([
                            'ilac_adi' => $row['ILAC_ADI'],
                            'barkod' => $row['BARKOD'] ?? null,
                            'atc_kodu' => $row['ATC_KODU'] ?? null,
                            'uretici_firma' => $row['FIRMA_ADI'] ?? null,
                            'depocu_satis_fiyati_kdv_haric' => $row['DEPOCU_SATIS_FIYATI_KDV_HARIC'] ?? null,
                            'depocu_satis_fiyati_kdv_dahil' => $row['DEPOCU_SATIS_FIYATI_KDV_DAHIL'] ?? null,
                            'perakende_satis_fiyati' => $row['PERAKENDE_SATIS_FIYATI'] ?? null,
                            'fiyat_tarihi' => $row['FIYAT_TARIHI'] ?? null,
                            'ilac_kodu' => $row['BARKOD'] ?? null,
                            'recete_tipi' => $row['RECETE_TIPI'] ?? null,
                            'created_at' => now(),
                            'updated_at' => now()
                        ]);
                        $inserted++;
                    }

                    // Etken maddeleri işle
                    if (!empty($row['ETKIN_MADDE'])) {
                        // Etken madde isimlerini parçalara ayır (virgülle ayrılmış olabilir)
                        $etkenMaddeler = explode(',', $row['ETKIN_MADDE']);

                        foreach ($etkenMaddeler as $etkenMaddeAdi) {
                            $etkenMaddeAdi = trim($etkenMaddeAdi);
                            if (empty($etkenMaddeAdi)) continue;

                            // Etken maddeyi bul veya oluştur
                            $etkenMadde = DB::table('etken_maddeler')
                                ->where('etken_madde_adi', $etkenMaddeAdi)
                                ->first();

                            if (!$etkenMadde) {
                                $etkenMaddeId = DB::table('etken_maddeler')->insertGetId([
                                    'etken_madde_adi' => $etkenMaddeAdi,
                                    'atc_kodlari' => $row['ATC_KODU'] ?? null,
                                    'created_at' => now(),
                                    'updated_at' => now()
                                ]);
                            } else {
                                $etkenMaddeId = $etkenMadde->etken_madde_id;

                                // Etken maddeyi güncelle
                                if (isset($row['ATC_KODU'])) {
                                    DB::table('etken_maddeler')
                                        ->where('etken_madde_id', $etkenMaddeId)
                                        ->update([
                                            'atc_kodlari' => $row['ATC_KODU'],
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
                                    'miktar' => $row['BIRIM_MIKTAR'] ?? null,
                                    'created_at' => now(),
                                    'updated_at' => now()
                                ]);
                                $relations++;
                            } else {
                                // İlişki varsa güncelle
                                if (isset($row['BIRIM_MIKTAR'])) {
                                    DB::table('ilac_etken_maddeler')
                                        ->where('ilac_id', $ilacId)
                                        ->where('etken_madde_id', $etkenMaddeId)
                                        ->update([
                                            'miktar' => $row['BIRIM_MIKTAR'],
                                            'updated_at' => now()
                                        ]);
                                }
                            }
                        }
                    }
                }

                DB::commit();

                return redirect()->back()->with('success',
                    "Veri aktarımı başarılı: $updated ilaç güncellendi, $inserted yeni ilaç eklendi, $relations ilişki kuruldu.");

            } catch (\Exception $e) {
                DB::rollBack();
                return redirect()->back()->with('error', 'Veri aktarımı sırasında hata: ' . $e->getMessage());
            }
        } catch (\Exception $e) {
            return redirect()->back()->with('error', 'Excel dosyası okunurken hata: ' . $e->getMessage());
        }
    }
}
