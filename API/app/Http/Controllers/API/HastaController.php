<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Hasta;
use App\Models\HastaTibbiGecmis;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HastaController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $hastalar = Hasta::paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastalar,
            'message' => 'Hastalar başarıyla listelendi'
        ]);
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ad' => 'required|string|max:255',
            'soyad' => 'required|string|max:255',
            'yas' => 'required|integer|min:0|max:150',
            'cinsiyet' => 'required|in:Erkek,Kadın,Diğer',
            'boy' => 'nullable|numeric|min:0|max:250',
            'kilo' => 'nullable|numeric|min:0|max:500',
            'dogum_tarihi' => 'nullable|date',
            'tc_kimlik' => 'nullable|string|size:11|unique:hastalar,tc_kimlik',
            'telefon' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:255|unique:hastalar,email',
            'adres' => 'nullable|string',

            // Tıbbi geçmiş bilgileri (aynı anda kaydetmek için)
            'tibbi_gecmis' => 'nullable|array',
            'tibbi_gecmis.kronik_hastaliklar' => 'nullable|string',
            'tibbi_gecmis.gecirilen_ameliyatlar' => 'nullable|string',
            'tibbi_gecmis.alerjiler' => 'nullable|string',
            'tibbi_gecmis.aile_hastaliklari' => 'nullable|string',
            'tibbi_gecmis.sigara_kullanimi' => 'nullable|string',
            'tibbi_gecmis.alkol_tuketimi' => 'nullable|string',
            'tibbi_gecmis.fiziksel_aktivite' => 'nullable|string',
            'tibbi_gecmis.beslenme_aliskanliklari' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Vücut kitle indeksi hesapla (varsa)
        if ($request->has('boy') && $request->has('kilo') && $request->boy > 0) {
            $boyMetre = $request->boy / 100; // cm'den metreye çevir
            $vki = $request->kilo / ($boyMetre * $boyMetre);
            $request->merge(['vki' => round($vki, 2)]);
        }

        // Hasta bilgilerini kaydet
        $hasta = Hasta::create($request->except('tibbi_gecmis'));

        // Tıbbi geçmiş bilgilerini kaydet (varsa)
        if ($request->has('tibbi_gecmis')) {
            $tibbiGecmisData = $request->tibbi_gecmis;
            $tibbiGecmisData['hasta_id'] = $hasta->hasta_id;

            HastaTibbiGecmis::create($tibbiGecmisData);
        }

        return response()->json([
            'status' => 'success',
            'data' => $hasta,
            'message' => 'Hasta başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Hasta $hasta)
    {
        // İlişkili tıbbi geçmiş bilgilerini de getir
        $hasta->load('tibbiGecmis');

        return response()->json([
            'status' => 'success',
            'data' => $hasta,
            'message' => 'Hasta detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Hasta $hasta)
    {
        $validator = Validator::make($request->all(), [
            'ad' => 'sometimes|required|string|max:255',
            'soyad' => 'sometimes|required|string|max:255',
            'yas' => 'sometimes|required|integer|min:0|max:150',
            'cinsiyet' => 'sometimes|required|in:Erkek,Kadın,Diğer',
            'boy' => 'nullable|numeric|min:0|max:250',
            'kilo' => 'nullable|numeric|min:0|max:500',
            'dogum_tarihi' => 'nullable|date',
            'tc_kimlik' => 'nullable|string|size:11|unique:hastalar,tc_kimlik,' . $hasta->hasta_id . ',hasta_id',
            'telefon' => 'nullable|string|max:20',
            'email' => 'nullable|email|max:255|unique:hastalar,email,' . $hasta->hasta_id . ',hasta_id',
            'adres' => 'nullable|string',

            // Tıbbi geçmiş bilgileri
            'tibbi_gecmis' => 'nullable|array',
            'tibbi_gecmis.kronik_hastaliklar' => 'nullable|string',
            'tibbi_gecmis.gecirilen_ameliyatlar' => 'nullable|string',
            'tibbi_gecmis.alerjiler' => 'nullable|string',
            'tibbi_gecmis.aile_hastaliklari' => 'nullable|string',
            'tibbi_gecmis.sigara_kullanimi' => 'nullable|string',
            'tibbi_gecmis.alkol_tuketimi' => 'nullable|string',
            'tibbi_gecmis.fiziksel_aktivite' => 'nullable|string',
            'tibbi_gecmis.beslenme_aliskanliklari' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Boy ve kilo güncellendiyse VKİ'yi yeniden hesapla
        if (($request->has('boy') || $request->has('kilo')) &&
            $request->input('boy', $hasta->boy) > 0) {

            $boyMetre = $request->input('boy', $hasta->boy) / 100;
            $kilo = $request->input('kilo', $hasta->kilo);

            $vki = $kilo / ($boyMetre * $boyMetre);
            $request->merge(['vki' => round($vki, 2)]);
        }

        // Hasta bilgilerini güncelle
        $hasta->update($request->except('tibbi_gecmis'));

        // Tıbbi geçmiş bilgilerini güncelle (varsa)
        if ($request->has('tibbi_gecmis')) {
            // Mevcut tıbbi geçmiş kaydını bul veya oluştur
            $tibbiGecmis = HastaTibbiGecmis::firstOrNew(['hasta_id' => $hasta->hasta_id]);

            // Gelen verileri güncelle
            $tibbiGecmis->fill($request->tibbi_gecmis);
            $tibbiGecmis->save();
        }

        // Güncel hasta bilgilerini tıbbi geçmişle birlikte getir
        $hasta->load('tibbiGecmis');

        return response()->json([
            'status' => 'success',
            'data' => $hasta,
            'message' => 'Hasta bilgileri başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Hasta $hasta)
    {
        $hasta->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Hasta başarıyla silindi'
        ]);
    }

    /**
     * Search patients by name, surname, tc_kimlik, etc.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function search(Request $request)
    {
        $request->validate([
            'query' => 'required|string|min:2',
            'per_page' => 'nullable|integer|min:1|max:100'
        ]);

        $query = $request->input('query');
        $perPage = $request->input('per_page', 15);

        $hastalar = Hasta::where('ad', 'like', "%{$query}%")
            ->orWhere('soyad', 'like', "%{$query}%")
            ->orWhere('tc_kimlik', 'like', "%{$query}%")
            ->orWhere('email', 'like', "%{$query}%")
            ->orWhere('telefon', 'like', "%{$query}%")
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastalar,
            'message' => 'Arama sonuçları başarıyla listelendi'
        ]);
    }

    /**
     * Get patient's medical history.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse
     */
    public function tibbiGecmis(Hasta $hasta)
    {
        $tibbiGecmis = $hasta->tibbiGecmis;

        if (!$tibbiGecmis) {
            return response()->json([
                'status' => 'success',
                'data' => null,
                'message' => 'Bu hastanın tıbbi geçmiş bilgisi bulunmamaktadır'
            ]);
        }

        return response()->json([
            'status' => 'success',
            'data' => $tibbiGecmis,
            'message' => 'Tıbbi geçmiş bilgileri başarıyla getirildi'
        ]);
    }

    /**
     * Get patient's diseases.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse|\Illuminate\Http\Response
     */
    public function hastaliklar(Hasta $hasta)
    {
        $hastaliklar = $hasta->hastaliklar;

        return response()->json([
            'status' => 'success',
            'data' => $hastaliklar,
            'message' => 'Hasta hastalıkları başarıyla listelendi'
        ]);
    }

    /**
     * Get patient's drug usage history.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse
     */
    public function ilacKullanim(Hasta $hasta)
    {
        $ilacKullanim = $hasta->ilacKullanim()->with('ilac')->get();

        return response()->json([
            'status' => 'success',
            'data' => $ilacKullanim,
            'message' => 'Hasta ilaç kullanım geçmişi başarıyla listelendi'
        ]);
    }

    /**
     * Get patient's laboratory results.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse
     */
    public function laboratuvarSonuclari(Hasta $hasta)
    {
        $laboratuvarSonuclari = $hasta->laboratuvarSonuclari()->orderBy('test_tarihi', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $laboratuvarSonuclari,
            'message' => 'Hasta laboratuvar sonuçları başarıyla listelendi'
        ]);
    }

    /**
     * Get drug recommendations for the patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\JsonResponse
     */
    public function ilacOnerileri(Hasta $hasta)
    {
        $ilacOnerileri = $hasta->ilacOnerileri()->with(['ilac', 'hastalik'])->get();

        return response()->json([
            'status' => 'success',
            'data' => $ilacOnerileri,
            'message' => 'Hasta ilaç önerileri başarıyla listelendi'
        ]);
    }
}
