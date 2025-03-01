<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Hasta;
use App\Models\LaboratuvarSonucu;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class LaboratuvarSonucuController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $hastaId = $request->input('hasta_id');
        $testTuru = $request->input('test_turu');
        $normalMi = $request->input('normal_mi');
        $baslangicTarihi = $request->input('baslangic_tarihi');
        $bitisTarihi = $request->input('bitis_tarihi');

        $query = LaboratuvarSonucu::with('hasta');

        // Filtreleme
        if ($hastaId) {
            $query->where('hasta_id', $hastaId);
        }

        if ($testTuru) {
            $query->where('test_turu', $testTuru);
        }

        if ($normalMi !== null) {
            $query->where('normal_mi', $normalMi == 'true' || $normalMi == 1);
        }

        if ($baslangicTarihi && $bitisTarihi) {
            $query->whereBetween('test_tarihi', [$baslangicTarihi, $bitisTarihi]);
        } elseif ($baslangicTarihi) {
            $query->where('test_tarihi', '>=', $baslangicTarihi);
        } elseif ($bitisTarihi) {
            $query->where('test_tarihi', '<=', $bitisTarihi);
        }

        $laboratuvarSonuclari = $query->orderBy('test_tarihi', 'desc')->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $laboratuvarSonuclari,
            'message' => 'Laboratuvar sonuçları başarıyla listelendi'
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
            'hasta_id' => 'required|exists:hastalar,hasta_id',
            'test_turu' => 'required|string|max:255',
            'test_kodu' => 'nullable|string|max:255',
            'deger' => 'required|string',
            'birim' => 'nullable|string|max:255',
            'referans_aralik' => 'nullable|string|max:255',
            'normal_mi' => 'boolean',
            'test_tarihi' => 'required|date',
            'notlar' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $laboratuvarSonucu = LaboratuvarSonucu::create($request->all());

        return response()->json([
            'status' => 'success',
            'data' => LaboratuvarSonucu::with('hasta')->find($laboratuvarSonucu->sonuc_id),
            'message' => 'Laboratuvar sonucu başarıyla oluşturuldu'
        ], 201);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Models\LaboratuvarSonucu  $laboratuvarSonucu
     * @return \Illuminate\Http\Response
     */
    public function show(LaboratuvarSonucu $laboratuvarSonucu)
    {
        $laboratuvarSonucu->load('hasta');

        return response()->json([
            'status' => 'success',
            'data' => $laboratuvarSonucu,
            'message' => 'Laboratuvar sonucu detayları başarıyla getirildi'
        ]);
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Models\LaboratuvarSonucu  $laboratuvarSonucu
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, LaboratuvarSonucu $laboratuvarSonucu)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'sometimes|required|exists:hastalar,hasta_id',
            'test_turu' => 'sometimes|required|string|max:255',
            'test_kodu' => 'nullable|string|max:255',
            'deger' => 'sometimes|required|string',
            'birim' => 'nullable|string|max:255',
            'referans_aralik' => 'nullable|string|max:255',
            'normal_mi' => 'boolean',
            'test_tarihi' => 'sometimes|required|date',
            'notlar' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $laboratuvarSonucu->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => LaboratuvarSonucu::with('hasta')->find($laboratuvarSonucu->sonuc_id),
            'message' => 'Laboratuvar sonucu başarıyla güncellendi'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Models\LaboratuvarSonucu  $laboratuvarSonucu
     * @return \Illuminate\Http\Response
     */
    public function destroy(LaboratuvarSonucu $laboratuvarSonucu)
    {
        $laboratuvarSonucu->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Laboratuvar sonucu başarıyla silindi'
        ]);
    }

    /**
     * Get laboratory results for a patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function getByHasta(Request $request, Hasta $hasta)
    {
        $testTuru = $request->input('test_turu');
        $normalMi = $request->input('normal_mi');
        $baslangicTarihi = $request->input('baslangic_tarihi');
        $bitisTarihi = $request->input('bitis_tarihi');

        $query = LaboratuvarSonucu::where('hasta_id', $hasta->hasta_id);

        // Filtreleme
        if ($testTuru) {
            $query->where('test_turu', $testTuru);
        }

        if ($normalMi !== null) {
            $query->where('normal_mi', $normalMi == 'true' || $normalMi == 1);
        }

        if ($baslangicTarihi && $bitisTarihi) {
            $query->whereBetween('test_tarihi', [$baslangicTarihi, $bitisTarihi]);
        } elseif ($baslangicTarihi) {
            $query->where('test_tarihi', '>=', $baslangicTarihi);
        } elseif ($bitisTarihi) {
            $query->where('test_tarihi', '<=', $bitisTarihi);
        }

        $laboratuvarSonuclari = $query->orderBy('test_tarihi', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $laboratuvarSonuclari,
            'message' => 'Hasta laboratuvar sonuçları başarıyla listelendi'
        ]);
    }

    /**
     * Get the latest test results for a patient.
     *
     * @param  \App\Models\Hasta  $hasta
     * @return \Illuminate\Http\Response
     */
    public function getLatestByHasta(Hasta $hasta, Request $request)
    {
        $testTurleri = $request->input('test_turleri', []);
        $testTurleriArray = is_array($testTurleri) ? $testTurleri : explode(',', $testTurleri);

        $query = LaboratuvarSonucu::where('hasta_id', $hasta->hasta_id);

        if (!empty($testTurleriArray)) {
            $query->whereIn('test_turu', $testTurleriArray);
        }

        // Distinct test türleri için en son yapılan test sonuçlarını getir
        $latestResults = [];
        $distinctTestTypes = $query->select('test_turu')->distinct()->pluck('test_turu')->toArray();

        foreach ($distinctTestTypes as $testType) {
            $latestResult = LaboratuvarSonucu::where('hasta_id', $hasta->hasta_id)
                ->where('test_turu', $testType)
                ->orderBy('test_tarihi', 'desc')
                ->first();

            if ($latestResult) {
                $latestResults[] = $latestResult;
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => $latestResults,
            'message' => 'Hastanın en son test sonuçları başarıyla listelendi'
        ]);
    }

    /**
     * Get the test result history for a specific test type.
     *
     * @param  \App\Models\Hasta  $hasta
     * @param  string  $testTuru
     * @return \Illuminate\Http\Response
     */
    public function getTestHistory(Hasta $hasta, $testTuru)
    {
        $testHistory = LaboratuvarSonucu::where('hasta_id', $hasta->hasta_id)
            ->where('test_turu', $testTuru)
            ->orderBy('test_tarihi', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $testHistory,
            'message' => "Hastanın '$testTuru' test geçmişi başarıyla listelendi"
        ]);
    }

    /**
     * Get all available test types.
     *
     * @return \Illuminate\Http\Response
     */
    public function getTestTypes()
    {
        $testTypes = LaboratuvarSonucu::select('test_turu')
            ->distinct()
            ->orderBy('test_turu')
            ->pluck('test_turu');

        return response()->json([
            'status' => 'success',
            'data' => $testTypes,
            'message' => 'Test türleri başarıyla listelendi'
        ]);
    }
}
