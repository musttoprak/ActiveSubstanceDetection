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
            // Python servisine istek gönder
            $response = Http::post('http://192.168.1.16:5000/predict', [
                'hasta_id' => $this->hasta_id,
                'hastalik_id' => $this->hastalik_id,
                'etken_madde_ids' => $this->etken_madde_ids,
                'exclude_ilac_ids' => $this->exclude_ilac_ids,
                // Ek bilgiler
                'hasta_demografik' => [
                    'yas' => $hasta->yas ?? null,
                    'cinsiyet' => $hasta->cinsiyet ?? null,
                    'vki' => $hasta->vki ?? null
                    // Diğer demografik bilgiler
                ],
                'hastalik_bilgileri' => $hastalik ? [
                    'id' => $hastalik->hastalik_id,
                    'hastalik_adi' => $hastalik->adi ?? $hastalik->hastalik_adi ?? '',
                    'hastalik_kategorisi' => $hastalik->kategori ?? $hastalik->hastalik_kategorisi ?? 'Bilinmiyor'
                ] : null,
                'etken_madde_bilgileri' => $etken_maddeler
            ]);

            // İsteğin yanıtını işle
            if ($response->successful()) {
                $results = $response->json();
                // ML servisinden gelen önerileri işle
                if (isset($results['recommendations'])) {
                    foreach ($results['recommendations'] as $recommendation) {
                        // Öneriyi veritabanına kaydet
                        IlacOnerisi::create([
                            'hasta_id' => $this->hasta_id,
                            'hastalik_id' => $this->hastalik_id,
                            'ilac_id' => $recommendation['ilac_id'],
                            'oneri_puani' => $recommendation['olaslik'] * 100,
                            'uygulanma_durumu' => false
                        ]);
                    }

                    Log::info("ML servisinden {$this->hasta_id} ID'li hasta için " .
                        count($results['recommendations']) . " adet ilaç önerisi alındı.");
                } else {
                    Log::warning("ML servisinden öneri gelmedi: " . json_encode($results));
                }
            } else {
                // Hata durumunda log oluştur
                Log::error("ML servisi hata döndü: " . $response->body());
                return ['message' => "ML servisi hata döndü: " . $response->body()];
            }
        } catch (\Exception $e) {
            Log::error("İlaç önerisi alınırken hata oluştu: " . $e->getMessage());
            return ['message' => "İlaç önerisi alınırken hata oluştu: " . $e->getMessage()];
        }

        return ['message' => "Bilinmeyen bir hata"];
    }
}
