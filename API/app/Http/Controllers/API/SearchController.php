<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\EtkenMadde;
use App\Models\Hasta;
use App\Models\Ilac;
use App\Models\Medicine;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    public function search(Request $request)
    {
        $query = $request->input('query');
        $category = $request->input('category');

        switch ($category) {
            case 'İlaçlar':
                $results = Medicine::where('ilac_adi', 'like', "%$query%")->get();
                break;
            case 'Etken Maddeler':
                $results = EtkenMadde::where('etken_madde_adi', 'like', "%$query%")->get();
                break;
            case 'Hastalar':
                $results = Hasta::where('hasta_adi', 'like', "%$query%")->get();
                break;
            default:
                $results = [];
                break;
        }

        return response()->json(['results' => $results]);
    }

    public function getMedicineByBarcode($barcode): \Illuminate\Http\JsonResponse
    {
        $medicine = Medicine::where('barcode', $barcode)->first();

        if ($medicine) {
            return response()->json(['medicine' => $medicine]);
        } else {
            return response()->json(['message' => 'İlaç bulunamadı'], 404);
        }
    }
}
