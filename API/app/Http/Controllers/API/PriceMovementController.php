<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\PriceMovement;
use Illuminate\Http\Request;

class PriceMovementController extends Controller
{
    // Tüm fiyat hareketlerini listele
    public function index()
    {
        return response()->json(PriceMovement::all(), 200);
    }

    // Belirli bir ilaç için fiyat hareketlerini getir
    public function getByMedicine($medicineId)
    {
        $movements = PriceMovement::where('medicine_id', $medicineId)->get();

        if ($movements->isEmpty()) {
            return response()->json(['message' => 'No price movements found for this medicine'], 404);
        }

        return response()->json($movements, 200);
    }
}

