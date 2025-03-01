<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Hastalik;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class HastalikController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $kategori = $request->input('kategori');
        $search = $request->input('search');

        $query = Hastalik::query();

        // Kategori filtresi
        if ($kategori) {
            $query->where('hastalik_kategorisi', $kategori);
        }

        // Arama filtresi
        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('hastalik_adi', 'like', "%{$search}%")
                    ->orWhere('icd_kodu', 'like', "%{$search}%");
            });
        }

        $hastaliklar = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastaliklar,
            'message' => 'Hastalıklar başarıyla listelendi'
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
            'icd_kodu' => 'required|string|max:255|unique:hastaliklar,icd_kodu',
            'hastalik_adi' => 'required|string|max:255',
            'hastalik_kategorisi' => 'nullable|string|max:255',
            'aciklama' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $hastalik = Hastalik::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => $hastalik,
            'message' => 'Hastalık başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\Hastalik  $hastalik
     * @return \Illuminate\Http\Response
     */
    public function show(Hastalik $hastalik)
    {
        return response()->json([
            'status' => 'success',
            'data' => $hastalik,
            'message' => 'Hastalık detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\Hastalik  $hastalik
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Hastalik $hastalik)
    {
        $validator = Validator::make($request->all(), [
            'icd_kodu' => 'sometimes|required|string|max:255|unique:hastaliklar,icd_kodu,' . $hastalik->hastalik_id . ',hastalik_id',
            'hastalik_adi' => 'sometimes|required|string|max:255',
            'hastalik_kategorisi' => 'nullable|string|max:255',
            'aciklama' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $hastalik->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => $hastalik,
            'message' => 'Hastalık başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\Hastalik  $hastalik
     * @return \Illuminate\Http\Response
     */
    public function destroy(Hastalik $hastalik)
    {
        // İlişkili hasta kayıtları var mı kontrol et
        $hastaCount = $hastalik->hastalar()->count();

        if ($hastaCount > 0) {
            return response()->json([
                'status' => 'error',
                'message' => "Bu hastalık $hastaCount hasta kaydı ile ilişkili olduğu için silinemez"
            ], 400);
        }

        $hastalik->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Hastalık başarıyla silindi'
        ]);
    }

    /**
     * Search diseases by name or ICD code.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function search(Request $request)
    {
        $request->validate([
            'query' => 'required|string|min:2',
            'per_page' => 'nullable|integer|min:1|max:100'
        ]);

        $query = $request->input('query');
        $perPage = $request->input('per_page', 15);

        $hastaliklar = Hastalik::where('hastalik_adi', 'like', "%{$query}%")
            ->orWhere('icd_kodu', 'like', "%{$query}%")
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastaliklar,
            'message' => 'Arama sonuçları başarıyla listelendi'
        ]);
    }

    /**
     * Get patients who have a specific disease.
     *
     * @param  \App\Models\Hastalik  $hastalik
     * @return \Illuminate\Http\Response
     */
    public function hastalar(Request $request, Hastalik $hastalik)
    {
        $perPage = $request->input('per_page', 15);
        $aktif = $request->input('aktif');

        $query = $hastalik->hastalar();

        if ($aktif !== null) {
            $query->wherePivot('aktif', $aktif == 'true' || $aktif == 1);
        }

        $hastalar = $query->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $hastalar,
            'message' => 'Hastalığa sahip hastalar başarıyla listelendi'
        ]);
    }

    /**
     * Get disease categories.
     *
     * @return \Illuminate\Http\Response
     */
    public function kategoriler()
    {
        $kategoriler = Hastalik::select('hastalik_kategorisi')
            ->distinct()
            ->whereNotNull('hastalik_kategorisi')
            ->orderBy('hastalik_kategorisi')
            ->pluck('hastalik_kategorisi');

        return response()->json([
            'status' => 'success',
            'data' => $kategoriler,
            'message' => 'Hastalık kategorileri başarıyla listelendi'
        ]);
    }
}
