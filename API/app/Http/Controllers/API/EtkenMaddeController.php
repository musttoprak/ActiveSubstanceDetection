<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\EtkenMadde;
use Illuminate\Http\Request;

class EtkenMaddeController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $etkenMaddeler = EtkenMadde::paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $etkenMaddeler,
            'message' => 'Etken maddeler başarıyla listelendi'
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
        $request->validate([
            'etken_madde_adi' => 'required|string|max:255|unique:etken_maddeler,etken_madde_adi',
            'ingilizce_adi' => 'nullable|string|max:255',
            'net_kutle' => 'nullable|string|max:255',
            'molekul_agirligi' => 'nullable|string|max:255',
            'formul' => 'nullable|string|max:255',
            'atc_kodlari' => 'nullable|string|max:255',
            'genel_bilgi' => 'nullable|string',
            'etki_mekanizmasi' => 'nullable|string',
            'farmakokinetik' => 'nullable|string',
            'resim_url' => 'nullable|url|max:255',
            'mustahzarlar' => 'nullable|json'
        ]);

        $etkenMadde = EtkenMadde::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => $etkenMadde,
            'message' => 'Etken madde başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\EtkenMadde  $etkenMadde
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(EtkenMadde $etkenMadde)
    {
        return response()->json([
            'status' => 'success',
            'data' => $etkenMadde,
            'message' => 'Etken madde detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\EtkenMadde  $etkenMadde
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, EtkenMadde $etkenMadde)
    {
        $request->validate([
            'etken_madde_adi' => 'sometimes|required|string|max:255|unique:etken_maddeler,etken_madde_adi,' . $etkenMadde->etken_madde_id . ',etken_madde_id',
            'ingilizce_adi' => 'nullable|string|max:255',
            'net_kutle' => 'nullable|string|max:255',
            'molekul_agirligi' => 'nullable|string|max:255',
            'formul' => 'nullable|string|max:255',
            'atc_kodlari' => 'nullable|string|max:255',
            'genel_bilgi' => 'nullable|string',
            'etki_mekanizmasi' => 'nullable|string',
            'farmakokinetik' => 'nullable|string',
            'resim_url' => 'nullable|url|max:255',
            'mustahzarlar' => 'nullable|json'
        ]);

        $etkenMadde->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => $etkenMadde,
            'message' => 'Etken madde başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\EtkenMadde  $etkenMadde
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(EtkenMadde $etkenMadde)
    {
        // İlişkili ilaçları kontrol et
        $ilacCount = $etkenMadde->ilaclar()->count();

        if ($ilacCount > 0) {
            return response()->json([
                'status' => 'error',
                'message' => "Bu etken madde $ilacCount adet ilaçla ilişkili olduğu için silinemez"
            ], 400);
        }

        $etkenMadde->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Etken madde başarıyla silindi'
        ]);
    }

    /**
     * Search active substances by name, formula, or ATC code.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function search(Request $request)
    {
        $request->validate([
            'query' => 'required|string|min:3',
            'per_page' => 'nullable|integer|min:1|max:100'
        ]);

        $query = $request->input('query');
        $perPage = $request->input('per_page', 15);

        $etkenMaddeler = EtkenMadde::search($query)->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $etkenMaddeler,
            'message' => 'Arama sonuçları başarıyla listelendi'
        ]);
    }

    /**
     * Get medicines containing this active substance.
     *
     * @param  \App\Models\EtkenMadde  $etkenMadde
     * @return \Illuminate\Http\JsonResponse
     */
    public function ilaclar(Request $request, EtkenMadde $etkenMadde)
    {
        $perPage = $request->input('per_page', 15);
        $ilaclar = $etkenMadde->ilaclar()->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilaclar,
            'message' => 'Etken maddeyi içeren ilaçlar başarıyla listelendi'
        ]);
    }

    /**
     * Get related active substances based on ATC codes.
     *
     * @param  \App\Models\EtkenMadde  $etkenMadde
     * @return \Illuminate\Http\JsonResponse
     */
    public function relatedActiveSubstances(EtkenMadde $etkenMadde)
    {
        $relatedEtkenMaddeler = $etkenMadde->findRelatedActiveSubstances();

        return response()->json([
            'status' => 'success',
            'data' => $relatedEtkenMaddeler,
            'message' => 'İlişkili etken maddeler başarıyla listelendi'
        ]);
    }
}
