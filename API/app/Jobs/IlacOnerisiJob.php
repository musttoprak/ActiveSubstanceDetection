<?php

namespace App\Jobs;

use App\Models\Hasta;
use App\Models\Hastalik;
use App\Models\IlacOnerisi;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class IlacOnerisiJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public $hasta_id;
    public $hastalik_id;
    public $etken_madde_ids;
    public $exclude_ilac_ids;
    public $timeout = 300; // 5 dakikalık timeout - ML işlemleri uzun sürebilir

    public function __construct($hasta_id, $hastalik_id, $etken_madde_ids, $exclude_ilac_ids)
    {
        $this->hasta_id = $hasta_id;
        $this->hastalik_id = $hastalik_id;
        $this->etken_madde_ids = $etken_madde_ids;
        $this->exclude_ilac_ids = $exclude_ilac_ids;
    }

    public function handle()
    {
        // Hasta demografik bilgilerini çek
        $hasta = DB::table('hastalar')->where('hasta_id', $this->hasta_id)->first();

        // Hastalık bilgilerini çek
        $hastalik = null;
        if ($this->hastalik_id) {
            $hastalik = DB::table('hastaliklar')->where('hastalik_id', $this->hastalik_id)->first();
        }

        // Etken madde bilgilerini çek
        $etken_maddeler = [];
        if (!empty($this->etken_madde_ids)) {
            $etken_maddeler = DB::table('etken_maddeler')
                ->whereIn('etken_madde_id', $this->etken_madde_ids)
                ->get()
                ->toArray();
        }

        try {
            // Python ML servisine istek gönder (Güncellenmiş API)
            $response = Http::timeout(60)->post('http://192.168.1.16:5000/predict', [
                'hasta_id' => $this->hasta_id,
                'hastalik_id' => $this->hastalik_id,
                'etken_madde_ids' => $this->etken_madde_ids,
                'exclude_ilac_ids' => $this->exclude_ilac_ids,
                // Ek demografik bilgiler
                'hasta_demografik' => [
                    'hasta_id' => $this->hasta_id,
                    'yas' => $hasta->yas ?? null,
                    'cinsiyet' => $hasta->cinsiyet ?? null,
                    'vki' => $hasta->vki ?? null
                ],
                'hastalik_bilgileri' => $hastalik ? [
                    'hastalik_id' => $hastalik->hastalik_id,
                    'hastalik_adi' => $hastalik->adi ?? $hastalik->hastalik_adi ?? '',
                    'hastalik_kategorisi' => $hastalik->kategori ?? $hastalik->hastalik_kategorisi ?? 'Bilinmiyor'
                ] : null
            ]);

            // İsteğin yanıtını işle
            if ($response->successful()) {
                $results = $response->json();

                // Mevcut önerileri temizle - kullanıcı için tekrar öneri isteyebilir
                //IlacOnerisi::where('hasta_id', $this->hasta_id)
                //    ->where('hastalik_id', $this->hastalik_id)
                //    ->delete();

                // ML servisinden gelen önerileri işle
                // IlacOnerisiJob.php içinde handle() metodunda, ML servisinden öneri analiz kısmını güncelle
                if (isset($results['recommendations'])) {
                    Log::info("ML servisinden öneriler alındı. Veritabanına kaydetmeye başlanıyor...");
                    $savedCount = 0;

                    foreach ($results['recommendations'] as $recommendation) {
                        try {
                            // Öneriyi veritabanına kaydet
                            $oneri = new IlacOnerisi([
                                'hasta_id' => $this->hasta_id,
                                'hastalik_id' => $this->hastalik_id,
                                'ilac_id' => $recommendation['ilac_id'],
                                'oneri_puani' => $recommendation['oneri_puani'],
                                'uygulanma_durumu' => false
                            ]);

                            $saved = $oneri->save();

                            if ($saved) {
                                $savedCount++;
                                Log::info("Öneri #{$savedCount} başarıyla kaydedildi: İlaç ID {$recommendation['ilac_id']}");
                            } else {
                                Log::error("Öneri kaydedilemedi: İlaç ID {$recommendation['ilac_id']}");
                            }
                        } catch (\Exception $saveException) {
                            Log::error("Öneri kaydedilirken hata: " . $saveException->getMessage());
                            Log::error("Hata izleme: " . $saveException->getTraceAsString());
                        }
                    }

                    Log::info("Toplam {$savedCount} öneri kaydedildi (beklenen: " . count($results['recommendations']) . ")");

                    return [
                        'success' => true,
                        'message' => "İlaç önerileri işlendi. {$savedCount} öneri kaydedildi."
                    ];
                } else {
                    Log::warning("ML servisinden öneri gelmedi: " . json_encode($results));
                    return ['success' => false, 'message' => "ML servisinden öneri gelmedi."];
                }
            } else {
                // Hata durumunda log oluştur
                Log::error("ML servisi hata döndü: " . $response->body());
                return ['success' => false, 'message' => "ML servisi hata döndü: " . $response->body()];
            }
        } catch (\Exception $e) {
            Log::error("İlaç önerisi alınırken hata oluştu: " . $e->getMessage());
            return ['success' => false, 'message' => "İlaç önerisi alınırken hata oluştu: " . $e->getMessage()];
        }
    }
}
