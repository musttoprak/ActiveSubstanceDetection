<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Jobs\IlacOnerisiJob;
use App\Models\Hasta;
use App\Models\Hastalik;
use App\Models\IlacOnerisi;
use App\Models\Recete;
use App\Models\ReceteIlac;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class ReceteController extends Controller
{
    // Tüm reçeteleri listele
    public function index(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $receteler = Recete::with(['hasta', 'hastalik', 'doktor', 'ilaclar.ilac'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return response()->json([
            'status' => 'success',
            'data' => $receteler,
            'message' => 'Reçeteler başarıyla listelendi'
        ]);
    }

    // Reçete detayını getir
    public function show($id)
    {
        $recete = Recete::with(['hasta', 'hastalik', 'doktor', 'ilaclar.ilac'])
            ->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'data' => $recete,
            'message' => 'Reçete detayları başarıyla getirildi'
        ]);
    }

    // Reçete oluştur
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'required|exists:hastalar,hasta_id',
            'hastalik_id' => 'required|exists:hastaliklar,hastalik_id',
            'doktor_id' => 'nullable|exists:kullanicilar,id',
            'tarih' => 'required|date',
            'notlar' => 'nullable|string',
            'ilaclar' => 'array',
            'ilaclar.*.ilac_id' => 'required|exists:ilaclar,ilac_id',
            'ilaclar.*.dozaj' => 'nullable|string',
            'ilaclar.*.kullanim_talimati' => 'nullable|string',
            'ilaclar.*.miktar' => 'integer|min:1'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        // Reçete numarası oluştur
        $receteNo = 'RX-' . date('Ymd') . '-' . Str::upper(Str::random(6));

        // Reçete oluştur
        $recete = Recete::create([
            'hasta_id' => $request->hasta_id,
            'hastalik_id' => $request->hastalik_id,
            'doktor_id' => $request->doktor_id,
            'recete_no' => $receteNo,
            'tarih' => $request->tarih,
            'notlar' => $request->notlar,
            'durum' => 'Beklemede',
            'aktif' => true
        ]);

        // İlaçları ekle
        if ($request->has('ilaclar') && is_array($request->ilaclar)) {
            foreach ($request->ilaclar as $ilac) {
                ReceteIlac::create([
                    'recete_id' => $recete->recete_id,
                    'ilac_id' => $ilac['ilac_id'],
                    'dozaj' => $ilac['dozaj'] ?? null,
                    'kullanim_talimati' => $ilac['kullanim_talimati'] ?? null,
                    'miktar' => $ilac['miktar'] ?? 1
                ]);
            }
        }

        // Reçete oluşturulduktan sonra detaylı bilgileri yükle
        $recete->load(['hasta', 'hastalik', 'doktor', 'ilaclar.ilac']);

        return response()->json([
            'status' => 'success',
            'data' => $recete,
            'message' => 'Reçete başarıyla oluşturuldu'
        ], 201);
    }

    // Reçete güncelle
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'hasta_id' => 'sometimes|required|exists:hastalar,hasta_id',
            'hastalik_id' => 'sometimes|required|exists:hastaliklar,hastalik_id',
            'doktor_id' => 'nullable|exists:kullanicilar,id',
            'tarih' => 'sometimes|required|date',
            'notlar' => 'nullable|string',
            'durum' => 'sometimes|in:Onaylandı,Beklemede,İptal Edildi',
            'aktif' => 'sometimes|boolean',
            'ilaclar' => 'array',
            'ilaclar.*.ilac_id' => 'required|exists:ilaclar,ilac_id',
            'ilaclar.*.dozaj' => 'nullable|string',
            'ilaclar.*.kullanim_talimati' => 'nullable|string',
            'ilaclar.*.miktar' => 'integer|min:1'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $recete = Recete::findOrFail($id);
        $recete->update($request->except('ilaclar'));

        // İlaçları güncelle
        if ($request->has('ilaclar') && is_array($request->ilaclar)) {
            // Mevcut ilaçları temizle
            ReceteIlac::where('recete_id', $recete->recete_id)->delete();

            // Yeni ilaçları ekle
            foreach ($request->ilaclar as $ilac) {
                ReceteIlac::create([
                    'recete_id' => $recete->recete_id,
                    'ilac_id' => $ilac['ilac_id'],
                    'dozaj' => $ilac['dozaj'] ?? null,
                    'kullanim_talimati' => $ilac['kullanim_talimati'] ?? null,
                    'miktar' => $ilac['miktar'] ?? 1
                ]);
            }
        }

        // Güncellenen reçete detaylarını yükle
        $recete->load(['hasta', 'hastalik', 'doktor', 'ilaclar.ilac']);

        return response()->json([
            'status' => 'success',
            'data' => $recete,
            'message' => 'Reçete başarıyla güncellendi'
        ]);
    }

    // Reçete sil
    public function destroy($id)
    {
        $recete = Recete::findOrFail($id);

        // İlgili ilaçlar cascade ile silinecek
        $recete->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Reçete başarıyla silindi'
        ]);
    }

    // Hasta reçetelerini getir
    public function getPatientPrescriptions($hastaId)
    {
        $receteler = Recete::with(['hastalik', 'doktor', 'ilaclar.ilac'])
            ->where('hasta_id', $hastaId)
            ->orderBy('tarih', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $receteler,
            'message' => 'Hasta reçeteleri başarıyla listelendi'
        ]);
    }

    // QR kod ile reçete getir
    public function getPrescriptionByQR($receteNo)
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

    // ReceteController.php içinde güncelleme
    /**
     * Reçete için ilaç önerisi al
     */
    public function getPrescriptionRecommendations($receteId)
    {
        try {
            $recete = Recete::with(['ilaclar.ilac.etkenMaddeler'])->findOrFail($receteId);

            // Reçetedeki ilaçların etken maddelerini topla
            $etkenMaddeIds = [];
            foreach ($recete->ilaclar as $receteIlac) {
                if ($receteIlac->ilac && $receteIlac->ilac->etkenMaddeler) {
                    foreach ($receteIlac->ilac->etkenMaddeler as $etkenMadde) {
                        $etkenMaddeIds[] = $etkenMadde->etken_madde_id;
                    }
                }
            }

            // Benzersiz etken madde ID'lerini al
            $uniqueEtkenMaddeIds = array_unique($etkenMaddeIds);

            // Reçetedeki ilaçların ID'lerini hariç tutma listesine ekle
            $excludeIlacIds = $recete->ilaclar->pluck('ilac_id')->toArray();

            // İlaç önerisi isteği için veriyi hazırla
            $requestData = [
                'hasta_id' => $recete->hasta_id,
                'hastalik_id' => $recete->hastalik_id,
                'etken_madde_ids' => $uniqueEtkenMaddeIds,
                'exclude_ilac_ids' => $excludeIlacIds
            ];

            // Debug log ekle
            Log::info("İlaç önerisi isteniyor", $requestData);

            // İlaç önerisi isteğini oluştur ve hemen işle (sync)
            $job = new IlacOnerisiJob(
                $recete->hasta_id,
                $recete->hastalik_id,
                $uniqueEtkenMaddeIds,
                $excludeIlacIds
            );

            // İşi hemen çalıştır
            $result = $job->handle();

            // Debug log ekle
            Log::info("İlaç önerisi sonucu", ['result' => $result]);

            if (isset($result['success']) && $result['success']) {
                return response()->json([
                    'status' => 'success',
                    'message' => 'İlaç önerileri başarıyla oluşturuldu',
                    'data' => $result
                ]);
            } else {
                return response()->json([
                    'status' => 'error',
                    'message' => $result['message'] ?? 'İlaç önerisi işlemi başarısız',
                    'data' => $result
                ], 500);
            }
        } catch (\Exception $e) {
            Log::error("İlaç önerisi isteği sırasında hata: " . $e->getMessage());
            Log::error("Hata izleme: " . $e->getTraceAsString());

            return response()->json([
                'status' => 'error',
                'message' => 'İlaç önerisi talebi sırasında hata: ' . $e->getMessage()
            ], 500);
        }
    }

    // Reçeteye önerilen ilaçları getir
    public function getPrescriptionSuggestions($receteId)
    {
        $recete = Recete::findOrFail($receteId);

        $oneriler = IlacOnerisi::with(['ilac'])
            ->where('hasta_id', $recete->hasta_id)
            ->where('hastalik_id', $recete->hastalik_id)
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $oneriler,
            'message' => 'Reçete için ilaç önerileri başarıyla listelendi'
        ]);
    }

    // Önerilen ilacı reçeteye ekle
    public function addSuggestionToPrescription(Request $request, $receteId, $oneriId)
    {
        $validator = Validator::make($request->all(), [
            'dozaj' => 'nullable|string',
            'kullanim_talimati' => 'nullable|string',
            'miktar' => 'integer|min:1'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'errors' => $validator->errors(),
                'message' => 'Validasyon hatası'
            ], 422);
        }

        $recete = Recete::findOrFail($receteId);
        $oneri = IlacOnerisi::findOrFail($oneriId);

        // Reçete ve öneri aynı hasta ve hastalık için olmalı
        if ($recete->hasta_id != $oneri->hasta_id || $recete->hastalik_id != $oneri->hastalik_id) {
            return response()->json([
                'status' => 'error',
                'message' => 'Reçete ve öneri aynı hasta ve hastalık için olmalıdır'
            ], 400);
        }

        // İlacı reçeteye ekle
        $receteIlac = ReceteIlac::create([
            'recete_id' => $receteId,
            'ilac_id' => $oneri->ilac_id,
            'dozaj' => $request->dozaj ?? null,
            'kullanim_talimati' => $request->kullanim_talimati ?? null,
            'miktar' => $request->miktar ?? 1
        ]);

        // Öneriyi uygulandı olarak işaretle
        $oneri->update(['uygulanma_durumu' => true]);

        // Eklenen ilaç bilgisini yükle
        $receteIlac->load('ilac');

        return response()->json([
            'status' => 'success',
            'data' => $receteIlac,
            'message' => 'Önerilen ilaç reçeteye başarıyla eklendi'
        ]);
    }
}
