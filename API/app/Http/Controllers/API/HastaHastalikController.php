<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Hasta;
use App\Models\Hastalik;
use App\Models\HastaHastalik;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HastaHastalikController extends Controller
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
        $hastalikId = $request->input('hastalik_id');
        $aktif = $request->input('aktif');
        $siddet = $request->input('siddet');

        $query = HastaHastalik::with(['hasta', 'hastalik']);

        // Filtreleme
        if ($hastaId) {
            $query->where('hasta_id', $hastaId);
        }

        if ($hastalikId) {
            $query->where('hastalik_id', $hastalikId);
        }

        if ($aktif !== null) {
            $query->where('aktif', $aktif == 'true' || $aktif == 1);
        }

        if ($siddet) {
            $query->where('siddet', $siddet);
        }

        $hastaHastaliklar = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastaHastaliklar,
            'message' => 'Hasta hastalıkları başarıyla listelendi'
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
            'teshis_tarihi' => 'required|date',
            'siddet' => 'nullable|in:Hafif,Orta,Şiddetli',
            'notlar' => 'nullable|string',
            'aktif' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Aynı hastalık zaten aktif mi kontrol et
        $existingActiveDisease = HastaHastalik::where('hasta_id', $request->hasta_id)
            ->where('hastalik_id', $request->hastalik_id)
            ->where('aktif', true)
            ->first();

        if ($existingActiveDisease && $request->input('aktif', true)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bu hastalık bu hasta için zaten aktif durumda'
            ], 400);
        }

        $hastaHastalik = HastaHastalik::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => HastaHastalik::with(['hasta', 'hastalik'])->find($hastaHastalik->hasta_hastalik_id),
            'message' => 'Hasta hastalığı başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\HastaHastalik  $hastaHastalik
     * @return \Illuminate\Http\Response
     */
    public function show(HastaHastalik $hastaHastalik)
    {
        $hastaHastalik->load(['hasta', 'hastalik']);

        return response()->json([
            'status' => 'success',
            'data' => $hastaHastalik,
            'message' => 'Hasta hastalığı detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\HastaHastalik  $hastaHastalik
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, HastaHastalik $hastaHastalik)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'sometimes|required|exists:hastalar,hasta_id',
            'hastalik_id' => 'sometimes|required|exists:hastaliklar,hastalik_id',
            'teshis_tarihi' => 'sometimes|required|date',
            'siddet' => 'nullable|in:Hafif,Orta,Şiddetli',
            'notlar' => 'nullable|string',
            'aktif' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Eğer aktiflik durumu değişiyorsa ve aktif ediliyorsa, aynı hastalık zaten aktif mi kontrol et
        if ($request->has('aktif') && $request->aktif && !$hastaHastalik->aktif) {
            $existingActiveDisease = HastaHastalik::where('hasta_id', $hastaHastalik->hasta_id)
                ->where('hastalik_id', $hastaHastalik->hastalik_id)
                ->where('aktif', true)
                ->where('hasta_hastalik_id', '!=', $hastaHastalik->hasta_hastalik_id)
                ->first();

            if ($existingActiveDisease) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu hastalık bu hasta için zaten aktif durumda'
                ], 400);
            }
        }

        $hastaHastalik->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => HastaHastalik::with(['hasta', 'hastalik'])->find($hastaHastalik->hasta_hastalik_id),
            'message' => 'Hasta hastalığı başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\HastaHastalik  $hastaHastalik
     * @return \Illuminate\Http\Response
     */
    public function destroy(HastaHastalik $hastaHastalik)
    {
        // İlişkili ilaç kullanımları vs. varsa kontrol et
        $hastaHastalik->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Hasta hastalığı başarıyla silindi'
        ]);
    }

    /**
     * Get active diseases for a patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function getActiveDiseasesForPatient(Hasta $hasta)
    {
        $activeHastaliklar = HastaHastalik::with('hastalik')
            ->where('hasta_id', $hasta->hasta_id)
            ->where('aktif', true)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $activeHastaliklar,
            'message' => 'Hastanın aktif hastalıkları başarıyla listelendi'
        ]);
    }

    /**
     * Set a disease as inactive (cured).
     *
     * @param  \App\Models\HastaHastalik  $hastaHastalik
     * @return \Illuminate\Http\Response
     */
    public function setCured(HastaHastalik $hastaHastalik)
    {
        $hastaHastalik->update([
            'aktif' => false,
            'notlar' => $hastaHastalik->notlar . "\n" . now()->format('Y-m-d') . ": Hastalık iyileştirildi."
        ]);

        return response()->json([
            'status' => 'success',
            'data' => $hastaHastalik,
            'message' => 'Hastalık iyileştirildi olarak işaretlendi'
        ]);
    }
}
