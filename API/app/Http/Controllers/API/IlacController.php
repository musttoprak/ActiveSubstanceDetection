<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Ilac;
use Illuminate\Http\Request;

class IlacController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $ilaclar = Ilac::with('etkenMaddeler:etken_madde_id,etken_madde_adi')
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilaclar,
            'message' => 'İlaçlar başarıyla listelendi'
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
            'ilac_adi' => 'required|string|max:255',
            'barkod' => 'nullable|string|max:255|unique:ilaclar,barkod',
            'atc_kodu' => 'nullable|string|max:255',
            'uretici_firma' => 'nullable|string|max:255',
            'ilac_adi_firma' => 'nullable|string|max:255',
            'recete_tipi' => 'nullable|string|max:255',
            'perakende_satis_fiyati' => 'nullable|numeric',
            'sgk_durumu' => 'nullable|string|max:255',
            'etken_maddeler' => 'nullable|array',
            'etken_maddeler.*.etken_madde_id' => 'required|exists:etken_maddeler,etken_madde_id',
            'etken_maddeler.*.miktar' => 'nullable|string'
        ]);

        $ilac = Ilac::create($request->except('etken_maddeler'));

        // Etken maddeler ilişkisini ekle
        if ($request->has('etken_maddeler')) {
            foreach ($request->etken_maddeler as $etkenMadde) {
                $ilac->etkenMaddeler()->attach($etkenMadde['etken_madde_id'], [
                    'miktar' => $etkenMadde['miktar'] ?? null,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => Ilac::with('etkenMaddeler')->find($ilac->ilac_id),
            'message' => 'İlaç başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\JsonResponse
     */
    public function show(Ilac $ilac)
    {
        $ilac->load('etkenMaddeler');

        return response()->json([
            'status' => 'success',
            'data' => $ilac,
            'message' => 'İlaç detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\JsonResponse
     */
    public function update(Request $request, Ilac $ilac)
    {
        $request->validate([
            'ilac_adi' => 'sometimes|required|string|max:255',
            'barkod' => 'nullable|string|max:255|unique:ilaclar,barkod,' . $ilac->ilac_id . ',ilac_id',
            'atc_kodu' => 'nullable|string|max:255',
            'uretici_firma' => 'nullable|string|max:255',
            'ilac_adi_firma' => 'nullable|string|max:255',
            'recete_tipi' => 'nullable|string|max:255',
            'perakende_satis_fiyati' => 'nullable|numeric',
            'sgk_durumu' => 'nullable|string|max:255',
            'etken_maddeler' => 'nullable|array',
            'etken_maddeler.*.etken_madde_id' => 'required|exists:etken_maddeler,etken_madde_id',
            'etken_maddeler.*.miktar' => 'nullable|string'
        ]);

        $ilac->update($request->except('etken_maddeler'));

        // Etken maddeler ilişkisini güncelle
        if ($request->has('etken_maddeler')) {
            $ilac->etkenMaddeler()->detach(); // Önceki ilişkileri sil

            foreach ($request->etken_maddeler as $etkenMadde) {
                $ilac->etkenMaddeler()->attach($etkenMadde['etken_madde_id'], [
                    'miktar' => $etkenMadde['miktar'] ?? null,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => Ilac::with('etkenMaddeler')->find($ilac->ilac_id),
            'message' => 'İlaç başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\JsonResponse
     */
    public function destroy(Ilac $ilac)
    {
        $ilac->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'İlaç başarıyla silindi'
        ]);
    }

    /**
     * Search medicines by name, barcode, or manufacturer.
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

        $ilaclar = Ilac::search($query)
            ->with('etkenMaddeler:etken_madde_id,etken_madde_adi')
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilaclar,
            'message' => 'Arama sonuçları başarıyla listelendi'
        ]);
    }

    /**
     * Get active substances of the medicine.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\JsonResponse
     */
    public function etkenMaddeler(Ilac $ilac)
    {
        $etkenMaddeler = $ilac->etkenMaddeler;

        return response()->json([
            'status' => 'success',
            'data' => $etkenMaddeler,
            'message' => 'İlacın etken maddeleri başarıyla listelendi'
        ]);
    }

    /**
     * Get price history of the medicine.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\JsonResponse
     */
    public function fiyatHareketleri(Ilac $ilac)
    {
        $fiyatHareketleri = $ilac->getFiyatGecmisi();

        return response()->json([
            'status' => 'success',
            'data' => $fiyatHareketleri,
            'message' => 'İlacın fiyat hareketleri başarıyla listelendi'
        ]);
    }

    /**
     * Get equivalent medicines.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\JsonResponse
     */
    public function esdegerIlaclar(Ilac $ilac)
    {
        // Aynı etken maddeye sahip diğer ilaçları getir
        $etkenMaddeIds = $ilac->etkenMaddeler->pluck('etken_madde_id');

        if ($etkenMaddeIds->isEmpty()) {
            return response()->json([
                'status' => 'success',
                'data' => [],
                'message' => 'Bu ilaç için eşdeğer ilaçlar bulunamadı'
            ]);
        }

        $esdegerIlaclar = Ilac::whereHas('etkenMaddeler', function($query) use ($etkenMaddeIds) {
            $query->whereIn('etken_madde_id', $etkenMaddeIds);
        })
            ->where('ilac_id', '!=', $ilac->ilac_id)
            ->with('etkenMaddeler:etken_madde_id,etken_madde_adi')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $esdegerIlaclar,
            'message' => 'Eşdeğer ilaçlar başarıyla listelendi'
        ]);
    }
}
