<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Hasta;
use App\Models\Ilac;
use App\Models\HastaIlacKullanim;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HastaIlacKullanimController extends Controller
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
        $ilacId = $request->input('ilac_id');
        $aktif = $request->input('aktif');
        $etkinlik = $request->input('etkinlik');

        $query = HastaIlacKullanim::with(['hasta', 'ilac', 'hastaHastalik.hastalik']);

        // Filtreleme
        if ($hastaId) {
            $query->where('hasta_id', $hastaId);
        }

        if ($ilacId) {
            $query->where('ilac_id', $ilacId);
        }

        if ($aktif !== null) {
            $query->where('aktif', $aktif == 'true' || $aktif == 1);
        }

        if ($etkinlik) {
            $query->where('etkinlik_degerlendirmesi', $etkinlik);
        }

        $hastaIlacKullanimlar = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastaIlacKullanimlar,
            'message' => 'İlaç kullanımları başarıyla listelendi'
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
            'ilac_id' => 'required|exists:ilaclar,ilac_id',
            'hasta_hastalik_id' => 'nullable|exists:hasta_hastaliklar,hasta_hastalik_id',
            'baslangic_tarihi' => 'required|date',
            'bitis_tarihi' => 'nullable|date|after_or_equal:baslangic_tarihi',
            'dozaj' => 'nullable|string',
            'kullanim_talimatı' => 'nullable|string',
            'etkinlik_degerlendirmesi' => 'nullable|in:Çok İyi,İyi,Orta,Düşük,Etkisiz',
            'yan_etki_raporlari' => 'nullable|string',
            'aktif' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Eğer hasta_hastalik_id verilmişse, ilişkili hastalığın hastaya ait olup olmadığını kontrol et
        if ($request->has('hasta_hastalik_id') && $request->hasta_hastalik_id) {
            $hastaHastalik = \App\Models\HastaHastalik::find($request->hasta_hastalik_id);

            if (!$hastaHastalik || $hastaHastalik->hasta_id != $request->hasta_id) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Belirtilen hastalık bu hastaya ait değil'
                ], 400);
            }
        }

        $hastaIlacKullanim = HastaIlacKullanim::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => HastaIlacKullanim::with(['hasta', 'ilac', 'hastaHastalik.hastalik'])
                ->find($hastaIlacKullanim->kullanim_id),
            'message' => 'İlaç kullanımı başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\HastaIlacKullanim  $hastaIlacKullanim
     * @return \Illuminate\Http\Response
     */
    public function show(HastaIlacKullanim $hastaIlacKullanim)
    {
        $hastaIlacKullanim->load(['hasta', 'ilac', 'hastaHastalik.hastalik']);

        return response()->json([
            'status' => 'success',
            'data' => $hastaIlacKullanim,
            'message' => 'İlaç kullanımı detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\HastaIlacKullanim  $hastaIlacKullanim
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, HastaIlacKullanim $hastaIlacKullanim)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'sometimes|required|exists:hastalar,hasta_id',
            'ilac_id' => 'sometimes|required|exists:ilaclar,ilac_id',
            'hasta_hastalik_id' => 'nullable|exists:hasta_hastaliklar,hasta_hastalik_id',
            'baslangic_tarihi' => 'sometimes|required|date',
            'bitis_tarihi' => 'nullable|date|after_or_equal:baslangic_tarihi',
            'dozaj' => 'nullable|string',
            'kullanim_talimatı' => 'nullable|string',
            'etkinlik_degerlendirmesi' => 'nullable|in:Çok İyi,İyi,Orta,Düşük,Etkisiz',
            'yan_etki_raporlari' => 'nullable|string',
            'aktif' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Eğer hasta_hastalik_id değiştiriliyorsa, ilişkili hastalığın hastaya ait olup olmadığını kontrol et
        if ($request->has('hasta_hastalik_id') && $request->hasta_hastalik_id) {
            $hastaHastalik = \App\Models\HastaHastalik::find($request->hasta_hastalik_id);
            $hastaId = $request->input('hasta_id', $hastaIlacKullanim->hasta_id);

            if (!$hastaHastalik || $hastaHastalik->hasta_id != $hastaId) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Belirtilen hastalık bu hastaya ait değil'
                ], 400);
            }
        }

        $hastaIlacKullanim->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => HastaIlacKullanim::with(['hasta', 'ilac', 'hastaHastalik.hastalik'])
                ->find($hastaIlacKullanim->kullanim_id),
            'message' => 'İlaç kullanımı başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\HastaIlacKullanim  $hastaIlacKullanim
     * @return \Illuminate\Http\Response
     */
    public function destroy(HastaIlacKullanim $hastaIlacKullanim)
    {
        $hastaIlacKullanim->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'İlaç kullanımı başarıyla silindi'
        ]);
    }

    /**
     * Get drug usage history for a patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function getByHasta(Hasta $hasta)
    {
        $ilacKullanimlari = HastaIlacKullanim::with(['ilac', 'hastaHastalik.hastalik'])
            ->where('hasta_id', $hasta->hasta_id)
            ->orderBy('baslangic_tarihi', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $ilacKullanimlari,
            'message' => 'Hasta ilaç kullanım geçmişi başarıyla listelendi'
        ]);
    }

    /**
     * Get active medication for a patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function getActiveByHasta(Hasta $hasta)
    {
        $aktifIlaclar = HastaIlacKullanim::with(['ilac', 'hastaHastalik.hastalik'])
            ->where('hasta_id', $hasta->hasta_id)
            ->where('aktif', true)
            ->orderBy('baslangic_tarihi', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $aktifIlaclar,
            'message' => 'Hastanın aktif ilaçları başarıyla listelendi'
        ]);
    }

    /**
     * Get patients using a specific drug.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\Response
     */
    public function getByIlac(Request $request, Ilac $ilac)
    {
        $perPage = $request->input('per_page', 15);
        $aktif = $request->input('aktif');

        $query = HastaIlacKullanim::with(['hasta', 'hastaHastalik.hastalik'])
            ->where('ilac_id', $ilac->ilac_id);

        if ($aktif !== null) {
            $query->where('aktif', $aktif == 'true' || $aktif == 1);
        }

        $ilacKullanimlari = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilacKullanimlari,
            'message' => 'İlacı kullanan hastalar başarıyla listelendi'
        ]);
    }

    /**
     * End active medication.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\HastaIlacKullanim  $hastaIlacKullanim
     * @return \Illuminate\Http\Response
     */
    public function endMedication(Request $request, HastaIlacKullanim $hastaIlacKullanim)
    {
        $validator = Validator::make($request->all(), [
            'bitis_tarihi' => 'required|date|after_or_equal:baslangic_tarihi',
            'etkinlik_degerlendirmesi' => 'required|in:Çok İyi,İyi,Orta,Düşük,Etkisiz',
            'yan_etki_raporlari' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $hastaIlacKullanim->update([
            'bitis_tarihi' => $request->bitis_tarihi,
            'etkinlik_degerlendirmesi' => $request->etkinlik_degerlendirmesi,
            'yan_etki_raporlari' => $request->yan_etki_raporlari,
            'aktif' => false
        ]);

        return response()->json([
            'status' => 'success',
            'data' => $hastaIlacKullanim,
            'message' => 'İlaç kullanımı sonlandırıldı'
        ]);
    }
}
