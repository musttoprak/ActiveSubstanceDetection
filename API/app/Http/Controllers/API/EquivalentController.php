<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Equivalent;
use Illuminate\Http\Request;

class EquivalentController extends Controller
{
    // Tüm eşdeğer ilaçları listele
    public function index()
    {
        return response()->json(Equivalent::all(), 200);
    }

    // Belirli bir ilaca ait eşdeğer ilaçları getir
    public function getByMedicine($medicineId)
    {
        $equivalents = Equivalent::where('medicine_id', $medicineId)->get();

        if ($equivalents->isEmpty()) {
            return response()->json(['message' => 'No equivalents found for this medicine'], 404);
        }

        return response()->json($equivalents, 200);
    }
}
