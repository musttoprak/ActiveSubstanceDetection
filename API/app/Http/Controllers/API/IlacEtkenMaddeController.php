<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Ilac;
use App\Models\EtkenMadde;
use App\Models\IlacEtkenMadde;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class IlacEtkenMaddeController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $ilacId = $request->input('ilac_id');
        $etkenMaddeId = $request->input('etken_madde_id');
        $dozajAra = $request->input('dozaj');

        $query = IlacEtkenMadde::with(['ilac', 'etkenMadde']);

        // Filtreleme
        if ($ilacId) {
            $query->where('ilac_id', $ilacId);
        }

        if ($etkenMaddeId) {
            $query->where('etken_madde_id', $etkenMaddeId);
        }

        if ($dozajAra) {
            $query->where('miktar', 'like', "%{$dozajAra}%");
        }

        $ilacEtkenMaddeler = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilacEtkenMaddeler,
            'message' => 'İlaç-etken madde ilişkileri başarıyla listelendi'
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
            'ilac_id' => 'required|exists:ilaclar,ilac_id',
            'etken_madde_id' => 'required|exists:etken_maddeler,etken_madde_id',
            'miktar' => 'nullable|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Aynı ilişki zaten var mı kontrol et
        $existingRelation = IlacEtkenMadde::where('ilac_id', $request->ilac_id)
            ->where('etken_madde_id', $request->etken_madde_id)
            ->first();

        if ($existingRelation) {
            return response()->json([
                'status' => 'error',
                'message' => 'Bu ilaç ve etken madde ilişkisi zaten mevcut'
            ], 400);
        }

        $ilacEtkenMadde = IlacEtkenMadde::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => IlacEtkenMadde::with(['ilac', 'etkenMadde'])->find($ilacEtkenMadde->ilac_etken_madde_id),
            'message' => 'İlaç-etken madde ilişkisi başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\IlacEtkenMadde  $ilacEtkenMadde
     * @return \Illuminate\Http\Response
     */
    public function show(IlacEtkenMadde $ilacEtkenMadde)
    {
        $ilacEtkenMadde->load(['ilac', 'etkenMadde']);

        return response()->json([
            'status' => 'success',
            'data' => $ilacEtkenMadde,
            'message' => 'İlaç-etken madde ilişkisi detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\IlacEtkenMadde  $ilacEtkenMadde
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, IlacEtkenMadde $ilacEtkenMadde)
    {
        $validator = Validator::make($request->all(), [
            'ilac_id' => 'sometimes|required|exists:ilaclar,ilac_id',
            'etken_madde_id' => 'sometimes|required|exists:etken_maddeler,etken_madde_id',
            'miktar' => 'nullable|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // İlac_id veya etken_madde_id değiştiriliyorsa, aynı ilişki zaten var mı kontrol et
        if (($request->has('ilac_id') && $request->ilac_id != $ilacEtkenMadde->ilac_id) ||
            ($request->has('etken_madde_id') && $request->etken_madde_id != $ilacEtkenMadde->etken_madde_id)) {

            $ilacId = $request->input('ilac_id', $ilacEtkenMadde->ilac_id);
            $etkenMaddeId = $request->input('etken_madde_id', $ilacEtkenMadde->etken_madde_id);

            $existingRelation = IlacEtkenMadde::where('ilac_id', $ilacId)
                ->where('etken_madde_id', $etkenMaddeId)
                ->where('ilac_etken_madde_id', '!=', $ilacEtkenMadde->ilac_etken_madde_id)
                ->first();

            if ($existingRelation) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Bu ilaç ve etken madde ilişkisi zaten mevcut'
                ], 400);
            }
        }

        $ilacEtkenMadde->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => IlacEtkenMadde::with(['ilac', 'etkenMadde'])->find($ilacEtkenMadde->ilac_etken_madde_id),
            'message' => 'İlaç-etken madde ilişkisi başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\IlacEtkenMadde  $ilacEtkenMadde
     * @return \Illuminate\Http\Response
     */
    public function destroy(IlacEtkenMadde $ilacEtkenMadde)
    {
        $ilacEtkenMadde->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'İlaç-etken madde ilişkisi başarıyla silindi'
        ]);
    }

    /**
     * Add multiple active substances to a medicine at once.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\Response
     */
    public function addMultipleToMedicine(Request $request, Ilac $ilac)
    {
        $validator = Validator::make($request->all(), [
            'etken_maddeler' => 'required|array',
            'etken_maddeler.*.etken_madde_id' => 'required|exists:etken_maddeler,etken_madde_id',
            'etken_maddeler.*.miktar' => 'nullable|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $eklenenIliskiler = [];
        $mevcutIliskiler = [];

        foreach ($request->etken_maddeler as $etkenMadde) {
            // Aynı ilişki zaten var mı kontrol et
            $existingRelation = IlacEtkenMadde::where('ilac_id', $ilac->ilac_id)
                ->where('etken_madde_id', $etkenMadde['etken_madde_id'])
                ->first();

            if ($existingRelation) {
                // İlişki zaten var, sadece miktar bilgisini güncelle
                $existingRelation->miktar = $etkenMadde['miktar'] ?? $existingRelation->miktar;
                $existingRelation->save();

                $mevcutIliskiler[] = IlacEtkenMadde::with(['ilac', 'etkenMadde'])
                    ->find($existingRelation->ilac_etken_madde_id);
            } else {
                // Yeni ilişki oluştur
                $yeniIliski = IlacEtkenMadde::create([
                    'ilac_id' => $ilac->ilac_id,
                    'etken_madde_id' => $etkenMadde['etken_madde_id'],
                    'miktar' => $etkenMadde['miktar'] ?? null
                ]);

                $eklenenIliskiler[] = IlacEtkenMadde::with(['ilac', 'etkenMadde'])
                    ->find($yeniIliski->ilac_etken_madde_id);
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'eklenen_iliskiler' => $eklenenIliskiler,
                'mevcut_iliskiler' => $mevcutIliskiler
            ],
            'message' => count($eklenenIliskiler) . ' yeni etken madde ilişkisi eklendi, ' .
                count($mevcutIliskiler) . ' mevcut ilişki güncellendi'
        ]);
    }

    /**
     * Get all medicines containing a specific active substance.
     *
     * @param  \App\Models\EtkenMadde  $etkenMadde
     * @return \Illuminate\Http\Response
     */
    public function getMedicinesByActiveSubstance(Request $request, EtkenMadde $etkenMadde)
    {
        $perPage = $request->input('per_page', 15);
        $dozajAra = $request->input('dozaj');

        $query = IlacEtkenMadde::with('ilac')
            ->where('etken_madde_id', $etkenMadde->etken_madde_id);

        if ($dozajAra) {
            $query->where('miktar', 'like', "%{$dozajAra}%");
        }

        $ilaclar = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $ilaclar,
            'message' => 'Etken maddeyi içeren ilaçlar başarıyla listelendi'
        ]);
    }

    /**
     * Get all active substances in a medicine.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\Response
     */
    public function getActiveSubstancesByMedicine(Ilac $ilac)
    {
        $etkenMaddeler = IlacEtkenMadde::with('etkenMadde')
            ->where('ilac_id', $ilac->ilac_id)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $etkenMaddeler,
            'message' => 'İlacın etken maddeleri başarıyla listelendi'
        ]);
    }

    /**
     * Find medicines with similar active substances.
     *
     * @param  \App\Models\Ilac  $ilac
     * @return \Illuminate\Http\Response
     */
    public function findSimilarMedicines(Ilac $ilac)
    {
        // İlacın etken maddelerini al
        $etkenMaddeIds = IlacEtkenMadde::where('ilac_id', $ilac->ilac_id)
            ->pluck('etken_madde_id')
            ->toArray();

        if (empty($etkenMaddeIds)) {
            return response()->json([
                'status' => 'success',
                'data' => [],
                'message' => 'Bu ilaç için etken madde kaydı bulunamadı'
            ]);
        }

        // Bu etken maddeleri içeren diğer ilaçları bul
        $similarIlacIds = IlacEtkenMadde::whereIn('etken_madde_id', $etkenMaddeIds)
            ->where('ilac_id', '!=', $ilac->ilac_id)
            ->pluck('ilac_id')
            ->unique()
            ->toArray();

        $similarIlaclar = Ilac::with(['etkenMaddeler'])
            ->whereIn('ilac_id', $similarIlacIds)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $similarIlaclar,
            'message' => 'Benzer etken maddelere sahip ilaçlar başarıyla listelendi'
        ]);
    }
}
