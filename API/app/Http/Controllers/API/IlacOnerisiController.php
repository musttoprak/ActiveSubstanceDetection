<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Jobs\IlacOnerisiJob;
use App\Models\Hasta;
use App\Models\Hastalik;
use App\Models\HastaHastalik;
use App\Models\Ilac;
use App\Models\IlacOnerisi;
use App\Models\HastaIlacKullanim;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class IlacOnerisiController extends Controller
{

    public function ilacOner(Request $request): \Illuminate\Http\JsonResponse
    {
        $hasta_id = $request->input('hasta_id');
        $hastalik_id = $request->input('hastalik_id');
        $etken_madde_ids = $request->input('etken_madde_ids');
        $exclude_ilac_ids = $request->input('exclude_ilac_ids');

        IlacOnerisiJob::dispatch($hasta_id,$hastalik_id,$etken_madde_ids,$exclude_ilac_ids);

        return response()->json(["message" => "İstek kuyruğa alındı"]);
    }

    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $hastaId = $request->input('hasta_id');
        $hastalikId = $request->input('hastalik_id');
        $ilacId = $request->input('ilac_id');
        $minPuan = $request->input('min_puan');
        $maxPuan = $request->input('max_puan');
        $uygulanma = $request->input('uygulanma_durumu');

        $query = IlacOnerisi::with(['hasta', 'hastalik', 'ilac']);

        // Filtreleme
        if ($hastaId) {
            $query->where('hasta_id', $hastaId);
        }

        if ($hastalikId) {
            $query->where('hastalik_id', $hastalikId);
        }

        if ($ilacId) {
            $query->where('ilac_id', $ilacId);
        }

        if ($minPuan !== null && $maxPuan !== null) {
            $query->whereBetween('oneri_puani', [$minPuan, $maxPuan]);
        } elseif ($minPuan !== null) {
            $query->where('oneri_puani', '>=', $minPuan);
        } elseif ($maxPuan !== null) {
            $query->where('oneri_puani', '<=', $maxPuan);
        }

        if ($uygulanma !== null) {
            $query->where('uygulanma_durumu', $uygulanma == 'true' || $uygulanma == 1);
        }

        $ilacOnerileri = $query->orderBy('oneri_puani', 'desc')->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilacOnerileri,
            'message' => 'İlaç önerileri başarıyla listelendi'
        ]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'required|exists:hastalar,hasta_id',
            'hastalik_id' => 'required|exists:hastaliklar,hastalik_id',
            'ilac_id' => 'required|exists:ilaclar,ilac_id',
            'oneri_puani' => 'required|numeric|min:0|max:100',
            'oneri_sebebi' => 'nullable|string',
            'uygulanma_durumu' => 'boolean',
            'doktor_geribildirimi' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Hastanın belirtilen hastalığa sahip olup olmadığını kontrol et
        $hastaHastalik = HastaHastalik::where('hasta_id', $request->hasta_id)
            ->where('hastalik_id', $request->hastalik_id)
            ->exists();

        if (!$hastaHastalik) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hasta belirtilen hastalığa sahip değil'
            ], 400);
        }

        $ilacOnerisi = IlacOnerisi::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => IlacOnerisi::with(['hasta', 'hastalik', 'ilac'])->find($ilacOnerisi->oneri_id),
            'message' => 'İlaç önerisi başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\IlacOnerisi  $ilacOnerisi
     * @return \Illuminate\Http\Response
     */
    public function show(IlacOnerisi $ilacOnerisi)
    {
        $ilacOnerisi->load(['hasta', 'hastalik', 'ilac']);

        return response()->json([
            'status' => 'success',
            'data' => $ilacOnerisi,
            'message' => 'İlaç önerisi detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\IlacOnerisi  $ilacOnerisi
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, IlacOnerisi $ilacOnerisi)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'sometimes|required|exists:hastalar,hasta_id',
            'hastalik_id' => 'sometimes|required|exists:hastaliklar,hastalik_id',
            'ilac_id' => 'sometimes|required|exists:ilaclar,ilac_id',
            'oneri_puani' => 'sometimes|required|numeric|min:0|max:100',
            'oneri_sebebi' => 'nullable|string',
            'uygulanma_durumu' => 'boolean',
            'doktor_geribildirimi' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Hasta ve hastalık değiştirilmişse, hastanın hastalığa sahip olup olmadığını kontrol et
        if (($request->has('hasta_id') && $request->hasta_id != $ilacOnerisi->hasta_id) ||
            ($request->has('hastalik_id') && $request->hastalik_id != $ilacOnerisi->hastalik_id)) {

            $hastaId = $request->input('hasta_id', $ilacOnerisi->hasta_id);
            $hastalikId = $request->input('hastalik_id', $ilacOnerisi->hastalik_id);

            $hastaHastalik = HastaHastalik::where('hasta_id', $hastaId)
                ->where('hastalik_id', $hastalikId)
                ->exists();

            if (!$hastaHastalik) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Hasta belirtilen hastalığa sahip değil'
                ], 400);
            }
        }

        $ilacOnerisi->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => IlacOnerisi::with(['hasta', 'hastalik', 'ilac'])->find($ilacOnerisi->oneri_id),
            'message' => 'İlaç önerisi başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\IlacOnerisi  $ilacOnerisi
     * @return \Illuminate\Http\Response
     */
    public function destroy(IlacOnerisi $ilacOnerisi)
    {
        $ilacOnerisi->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'İlaç önerisi başarıyla silindi'
        ]);
    }

    /**
     * Get recommendations by patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function getByHasta(Request $request, Hasta $hasta)
    {
        $hastalikId = $request->input('hastalik_id');
        $uygulanma = $request->input('uygulanma_durumu');

        $query = IlacOnerisi::with(['hastalik', 'ilac'])
            ->where('hasta_id', $hasta->hasta_id);

        if ($hastalikId) {
            $query->where('hastalik_id', $hastalikId);
        }

        if ($uygulanma !== null) {
            $query->where('uygulanma_durumu', $uygulanma == 'true' || $uygulanma == 1);
        }

        $ilacOnerileri = $query->orderBy('oneri_puani', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $ilacOnerileri,
            'message' => 'Hasta için ilaç önerileri başarıyla listelendi'
        ]);
    }

    /**
     * Get recommendations by disease.
     *
     * @param  \App\Models\Hastalik  $hastalik
     * @return \Illuminate\Http\Response
     */
    public function getByHastalik(Request $request, Hastalik $hastalik)
    {
        $perPage = $request->input('per_page', 15);

        $ilacOnerileri = IlacOnerisi::with(['hasta', 'ilac'])
            ->where('hastalik_id', $hastalik->hastalik_id)
            ->orderBy('oneri_puani', 'desc')
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilacOnerileri,
            'message' => 'Hastalık için ilaç önerileri başarıyla listelendi'
        ]);
    }

    /**
     * Apply a recommendation (create a medicine usage record).
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\IlacOnerisi  $ilacOnerisi
     * @return \Illuminate\Http\Response
     */
    public function applyRecommendation(Request $request, IlacOnerisi $ilacOnerisi)
    {
        $validator = Validator::make($request->all(), [
            'baslangic_tarihi' => 'required|date',
            'bitis_tarihi' => 'nullable|date|after_or_equal:baslangic_tarihi',
            'dozaj' => 'nullable|string',
            'kullanim_talimatı' => 'nullable|string',
            'doktor_geribildirimi' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Öneri zaten uygulandı mı kontrol et
        if ($ilacOnerisi->uygulanma_durumu) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bu ilaç önerisi zaten uygulanmış'
            ], 400);
        }

        // Hastanın aktif hastalığını bul
        $hastaHastalik = HastaHastalik::where('hasta_id', $ilacOnerisi->hasta_id)
            ->where('hastalik_id', $ilacOnerisi->hastalik_id)
            ->where('aktif', true)
            ->first();

        if (!$hastaHastalik) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hastanın belirtilen hastalık için aktif kaydı bulunamadı'
            ], 400);
        }

        // İlaç kullanım kaydı oluştur
        $ilacKullanim = HastaIlacKullanim::create([
            'hasta_id' => $ilacOnerisi->hasta_id,
            'ilac_id' => $ilacOnerisi->ilac_id,
            'hasta_hastalik_id' => $hastaHastalik->hasta_hastalik_id,
            'baslangic_tarihi' => $request->baslangic_tarihi,
            'bitis_tarihi' => $request->bitis_tarihi,
            'dozaj' => $request->dozaj,
            'kullanim_talimatı' => $request->kullanim_talimatı,
            'aktif' => true
        ]);

        // Öneriyi güncelle
        $ilacOnerisi->update([
            'uygulanma_durumu' => true,
            'doktor_geribildirimi' => $request->doktor_geribildirimi
        ]);

        return response()->json([
            'status' => 'success',
            'data' => [
                'oneri' => $ilacOnerisi,
                'ilac_kullanim' => $ilacKullanim
            ],
            'message' => 'İlaç önerisi başarıyla uygulandı ve kullanım kaydı oluşturuldu'
        ]);
    }

    /**
     * Generate drug recommendations for a patient.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function generateRecommendations(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'required|exists:hastalar,hasta_id',
            'hastalik_id' => 'required|exists:hastaliklar,hastalik_id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $hastaId = $request->input('hasta_id');
        $hastalikId = $request->input('hastalik_id');

        // Hasta ve hastalık kayıtlarını al
        $hasta = Hasta::findOrFail($hastaId);
        $hastalik = Hastalik::findOrFail($hastalikId);

        // Hastanın hastalığa sahip olup olmadığını kontrol et
        $hastaHastalik = HastaHastalik::where('hasta_id', $hastaId)
            ->where('hastalik_id', $hastalikId)
            ->first();

        if (!$hastaHastalik) {
            return response()->json([
                'status' => 'error',
                'message' => 'Hasta belirtilen hastalığa sahip değil'
            ], 400);
        }

        // 1. Benzer hastaları bul (yaş, cinsiyet, vki gibi faktörlere göre)
        $benzerHastalar = Hasta::where('hasta_id', '!=', $hastaId)
            ->where(function($query) use ($hasta) {
                // Yaş aralığı (±5 yaş)
                $query->whereBetween('yas', [$hasta->yas - 5, $hasta->yas + 5]);

                // Cinsiyet (isteğe bağlı)
                if ($hasta->cinsiyet) {
                    $query->where('cinsiyet', $hasta->cinsiyet);
                }

                // VKI aralığı (±3 birim) (eğer varsa)
                if ($hasta->vki) {
                    $query->whereBetween('vki', [$hasta->vki - 3, $hasta->vki + 3]);
                }
            })
            ->pluck('hasta_id')
            ->toArray();

        // 2. Aynı hastalığa sahip benzer hastaların kullandığı ilaçları bul
        $ilacKullanimlari = HastaIlacKullanim::join('hasta_hastaliklar', function($join) use ($hastalikId) {
            $join->on('hasta_ilac_kullanim.hasta_id', '=', 'hasta_hastaliklar.hasta_id')
                ->where('hasta_hastaliklar.hastalik_id', '=', $hastalikId);
        })
            ->whereIn('hasta_ilac_kullanim.hasta_id', $benzerHastalar)
            ->select(
                'hasta_ilac_kullanim.ilac_id',
                DB::raw('COUNT(*) as kullanim_sayisi'),
                DB::raw('AVG(CASE WHEN etkinlik_degerlendirmesi = "Çok İyi" THEN 100
                         WHEN etkinlik_degerlendirmesi = "İyi" THEN 80
                         WHEN etkinlik_degerlendirmesi = "Orta" THEN 60
                         WHEN etkinlik_degerlendirmesi = "Düşük" THEN 40
                         WHEN etkinlik_degerlendirmesi = "Etkisiz" THEN 20
                         ELSE 50 END) as ortalama_etkinlik')
            )
            ->groupBy('hasta_ilac_kullanim.ilac_id')
            ->orderBy('kullanim_sayisi', 'desc')
            ->orderBy('ortalama_etkinlik', 'desc')
            ->limit(5)
            ->get();

        // 3. Önceden önerilmiş ve uygulanmış başarılı ilaçları listeden çıkar
        $denenmisilacIds = HastaIlacKullanim::where('hasta_id', $hastaId)
            ->pluck('ilac_id')
            ->toArray();

        // 4. Önerileri oluştur
        $oneriler = [];

        foreach ($ilacKullanimlari as $kullanim) {
            // Eğer ilaç daha önce denenmişse atla
            if (in_array($kullanim->ilac_id, $denenmisilacIds)) {
                continue;
            }

            $ilac = Ilac::find($kullanim->ilac_id);

            if (!$ilac) continue;

            // Etken madde kontrolü ve kontraendikasyon kontrolü buraya eklenebilir

            // Öneri puanı hesapla (kullanım sıklığı ve etkinlik ortalamasına göre)
            $oneriPuani = ($kullanim->kullanim_sayisi / max(1, count($benzerHastalar))) * 50 +
                ($kullanim->ortalama_etkinlik / 100) * 50;

            // Öneriyi oluştur
            $oneri = new IlacOnerisi([
                'hasta_id' => $hastaId,
                'hastalik_id' => $hastalikId,
                'ilac_id' => $kullanim->ilac_id,
                'oneri_puani' => min(100, round($oneriPuani, 2)),
                'oneri_sebebi' => "Benzer hasta profili için {$kullanim->kullanim_sayisi} kullanım ve {$kullanim->ortalama_etkinlik}% ortalama etkinlik",
                'uygulanma_durumu' => false
            ]);

            $oneri->save();
            $oneriler[] = $oneri;
        }

        // 5. Öneriler yetersizse, hastalık için en sık kullanılan ilaçları öner
        if (count($oneriler) < 3) {
            $enSikKullanilanIlaclar = HastaIlacKullanim::join('hasta_hastaliklar', function($join) use ($hastalikId) {
                $join->on('hasta_ilac_kullanim.hasta_id', '=', 'hasta_hastaliklar.hasta_id')
                    ->where('hasta_hastaliklar.hastalik_id', '=', $hastalikId);
            })
                ->whereNotIn('hasta_ilac_kullanim.ilac_id', array_merge(
                    collect($oneriler)->pluck('ilac_id')->toArray(),
                    $denenmisilacIds
                ))
                ->select(
                    'hasta_ilac_kullanim.ilac_id',
                    DB::raw('COUNT(*) as kullanim_sayisi'),
                    DB::raw('AVG(CASE WHEN etkinlik_degerlendirmesi = "Çok İyi" THEN 100
                             WHEN etkinlik_degerlendirmesi = "İyi" THEN 80
                             WHEN etkinlik_degerlendirmesi = "Orta" THEN 60
                             WHEN etkinlik_degerlendirmesi = "Düşük" THEN 40
                             WHEN etkinlik_degerlendirmesi = "Etkisiz" THEN 20
                             ELSE 50 END) as ortalama_etkinlik')
                )
                ->groupBy('hasta_ilac_kullanim.ilac_id')
                ->orderBy('kullanim_sayisi', 'desc')
                ->orderBy('ortalama_etkinlik', 'desc')
                ->limit(5 - count($oneriler))
                ->get();

            foreach ($enSikKullanilanIlaclar as $kullanim) {
                $ilac = Ilac::find($kullanim->ilac_id);

                if (!$ilac) continue;

                // Öneri puanı hesapla
                $oneriPuani = ($kullanim->ortalama_etkinlik / 100) * 70;

                // Öneriyi oluştur
                $oneri = new IlacOnerisi([
                    'hasta_id' => $hastaId,
                    'hastalik_id' => $hastalikId,
                    'ilac_id' => $kullanim->ilac_id,
                    'oneri_puani' => min(80, round($oneriPuani, 2)), // Benzer hasta verilerine göre daha düşük puanlı
                    'oneri_sebebi' => "Bu hastalıkta sık kullanılan ilaç, {$kullanim->ortalama_etkinlik}% ortalama etkinlik",
                    'uygulanma_durumu' => false
                ]);

                $oneri->save();
                $oneriler[] = $oneri;
            }
        }

        // 6. Oluşturulan önerileri döndür
        $sonuclar = IlacOnerisi::with(['ilac', 'hastalik'])
            ->whereIn('oneri_id', collect($oneriler)->pluck('oneri_id'))
            ->orderBy('oneri_puani', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $sonuclar,
            'message' => count($sonuclar) > 0
                ? 'İlaç önerileri başarıyla oluşturuldu'
                : 'Uygun ilaç önerisi bulunamadı'
        ]);
    }
}
