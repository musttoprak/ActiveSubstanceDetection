<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Medicine;
use Illuminate\Http\Request;

class MedicineController extends Controller
{
    // Tüm ilaçları listele
    public function index()
    {
        return response()->json(Medicine::all(), 200);
    }

    // Belirli bir ilacı getir
    public function show($id)
    {
        $medicine = Medicine::find($id);

        if (!$medicine) {
            return response()->json(['message' => 'Medicine not found'], 404);
        }

        return response()->json($medicine, 200);
    }
}
