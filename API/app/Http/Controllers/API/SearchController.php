<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\EtkenMadde;
use App\Models\Hasta;
use App\Models\Ilac;
use App\Models\Recete;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function search(Request $request): \Illuminate\Http\JsonResponse
    {
        $query = $request->input('query');

        if (empty($query)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Arama terimi boş olamaz'
            ], 400);
        }

        // Tüm kategorilerde arama yap
        $medications = Ilac::where('ilac_adi', 'like', "%$query%")->with('etkenMaddeler:etken_madde_id,etken_madde_adi')
            ->orWhere('barkod', 'like', "%$query%")
            ->orWhere('uretici_firma', 'like', "%$query%")
            ->limit(3)
            ->get();

        $recetes = Recete::with(['hasta', 'hastalik', 'ilaclar.ilac.etkenMaddeler'])
            ->where('recete_no', 'like', "%$query%")
            ->limit(3)
            ->get();

        $activeIngredients = EtkenMadde::where('etken_madde_adi', 'like', "%$query%")->with(['ilaclar'])
            ->orWhere('etken_madde_kategorisi', 'like', "%$query%")
            ->orWhere('ingilizce_adi', 'like', "%$query%")
            ->orWhere('aciklama', 'like', "%$query%")
            ->limit(3)
            ->get();

        $patients = Hasta::where('ad', 'like', "%$query%")->with('hastaHastaliklar.hastalik')
            ->orWhere('soyad', 'like', "%$query%")
            ->orWhere('tc_kimlik', 'like', "%$query%")
            ->limit(3)
            ->get();

        return response()->json([
            'status' => 'success',
            'medications' => $medications,
            'recetes' => $recetes,
            'activeIngredients' => $activeIngredients,
            'patients' => $patients,
            'message' => 'Arama sonuçları başarıyla getirildi'
        ]);
    }

    public function getMedicineByBarcode($receteNo): \Illuminate\Http\JsonResponse
    {
        $recete = Recete::with(['hasta', 'hastalik', 'ilaclar.ilac.etkenMaddeler'])
            ->where('recete_no', $receteNo)
            ->first();

        if (!$recete) {
            return response()->json([
                'status' => 'error',
                'message' => 'Reçete bulunamadı'
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $recete,
            'message' => 'Reçete başarıyla getirildi'
        ]);
    }
}
