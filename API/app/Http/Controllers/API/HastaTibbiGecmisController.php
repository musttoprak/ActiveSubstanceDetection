<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Hasta;
use App\Models\HastaTibbiGecmis;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HastaTibbiGecmisController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $hastaId = $request->input('hasta_id');

        $query = HastaTibbiGecmis::with('hasta');

        // Hasta ID'sine göre filtreleme
        if ($hastaId) {
            $query->where('hasta_id', $hastaId);
        }

        $hastaTibbiGecmisler = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastaTibbiGecmisler,
            'message' => 'Tıbbi geçmiş kayıtları başarıyla listelendi'
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
            'kronik_hastaliklar' => 'nullable|string',
            'gecirilen_ameliyatlar' => 'nullable|string',
            'alerjiler' => 'nullable|string',
            'aile_hastaliklari' => 'nullable|string',
            'sigara_kullanimi' => 'nullable|string',
            'alkol_tuketimi' => 'nullable|string',
            'fiziksel_aktivite' => 'nullable|string',
            'beslenme_aliskanliklari' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Mevcut bir tıbbi geçmiş kaydı var mı kontrol et
        $existingRecord = HastaTibbiGecmis::where('hasta_id', $request->hasta_id)->first();

        if ($existingRecord) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bu hasta için zaten bir tıbbi geçmiş kaydı mevcut. Güncelleme yapın.'
            ], 400);
        }

        $hastaTibbiGecmis = HastaTibbiGecmis::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => HastaTibbiGecmis::with('hasta')->find($hastaTibbiGecmis->tibbi_gecmis_id),
            'message' => 'Tıbbi geçmiş başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\HastaTibbiGecmis  $hastaTibbiGecmis
     * @return \Illuminate\Http\Response
     */
    public function show(HastaTibbiGecmis $hastaTibbiGecmis)
    {
        $hastaTibbiGecmis->load('hasta');

        return response()->json([
            'status' => 'success',
            'data' => $hastaTibbiGecmis,
            'message' => 'Tıbbi geçmiş detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\HastaTibbiGecmis  $hastaTibbiGecmis
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, HastaTibbiGecmis $hastaTibbiGecmis)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'sometimes|required|exists:hastalar,hasta_id',
            'kronik_hastaliklar' => 'nullable|string',
            'gecirilen_ameliyatlar' => 'nullable|string',
            'alerjiler' => 'nullable|string',
            'aile_hastaliklari' => 'nullable|string',
            'sigara_kullanimi' => 'nullable|string',
            'alkol_tuketimi' => 'nullable|string',
            'fiziksel_aktivite' => 'nullable|string',
            'beslenme_aliskanliklari' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $hastaTibbiGecmis->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => HastaTibbiGecmis::with('hasta')->find($hastaTibbiGecmis->tibbi_gecmis_id),
            'message' => 'Tıbbi geçmiş başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\HastaTibbiGecmis  $hastaTibbiGecmis
     * @return \Illuminate\Http\Response
     */
    public function destroy(HastaTibbiGecmis $hastaTibbiGecmis)
    {
        $hastaTibbiGecmis->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Tıbbi geçmiş başarıyla silindi'
        ]);
    }

    /**
     * Get or create medical history for a patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function getOrCreateForHasta(Hasta $hasta)
    {
        $tibbiGecmis = HastaTibbiGecmis::firstOrCreate(['hasta_id' => $hasta->hasta_id]);

        return response()->json([
            'status' => 'success',
            'data' => $tibbiGecmis,
            'message' => 'Hasta tıbbi geçmişi başarıyla getirildi'
        ]);
    }

    /**
     * Update or add allergies for a patient.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function updateAlerjiler(Request $request, Hasta $hasta)
    {
        $validator = Validator::make($request->all(), [
            'alerjiler' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $tibbiGecmis = HastaTibbiGecmis::firstOrCreate(['hasta_id' => $hasta->hasta_id]);

        // Mevcut alerjileri al
        $mevcutAlerjiler = $tibbiGecmis->alerjiler;
        $yeniAlerjiler = $request->alerjiler;

        // Eğer mevcut alerjiler varsa, yeni alerjileri ekle (tekrarsız)
        if ($mevcutAlerjiler) {
            $mevcutAlerjilerArray = array_map('trim', explode(',', $mevcutAlerjiler));
            $yeniAlerjilerArray = array_map('trim', explode(',', $yeniAlerjiler));

            // Dizileri birleştir ve tekrarsız hale getir
            $birlesikAlerjiler = array_unique(array_merge($mevcutAlerjilerArray, $yeniAlerjilerArray));

            // Virgülle ayrılmış string'e çevir
            $guncelAlerjiler = implode(', ', $birlesikAlerjiler);

            $tibbiGecmis->alerjiler = $guncelAlerjiler;
        } else {
            $tibbiGecmis->alerjiler = $yeniAlerjiler;
        }

        $tibbiGecmis->save();

        return response()->json([
            'status' => 'success',
            'data' => $tibbiGecmis,
            'message' => 'Hasta alerjileri başarıyla güncellendi'
        ]);
    }

    /**
     * Update chronic diseases for a patient.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function updateKronikHastaliklar(Request $request, Hasta $hasta)
    {
        $validator = Validator::make($request->all(), [
            'kronik_hastaliklar' => 'required|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $tibbiGecmis = HastaTibbiGecmis::firstOrCreate(['hasta_id' => $hasta->hasta_id]);
        $tibbiGecmis->kronik_hastaliklar = $request->kronik_hastaliklar;
        $tibbiGecmis->save();

        return response()->json([
            'status' => 'success',
            'data' => $tibbiGecmis,
            'message' => 'Hasta kronik hastalıkları başarıyla güncellendi'
        ]);
    }
}
