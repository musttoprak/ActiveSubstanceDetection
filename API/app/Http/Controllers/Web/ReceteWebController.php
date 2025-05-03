<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Jobs\IlacOnerisiJob;
use App\Models\Hasta;
use App\Models\Hastalik;
use App\Models\Ilac;
use App\Models\IlacOnerisi;
use App\Models\Recete;
use App\Models\ReceteIlac;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class ReceteWebController extends Controller
{
    /**
     * Reçete oluşturma formunu göster
     */
    public function createForm()
    {
        $hastalar = Hasta::all();
        $hastaliklar = Hastalik::all();
        $ilaclar = Ilac::all();

        return view('receteler.create', compact('hastalar', 'hastaliklar', 'ilaclar'));
    }

    /**
     * Reçete oluştur
     */
    public function store(Request $request)
    {
        $request->validate([
            'hasta_id' => 'required|exists:hastalar,hasta_id',
            'hastalik_id' => 'required|exists:hastaliklar,hastalik_id',
            'tarih' => 'required|date',
            'notlar' => 'nullable|string',
            'ilaclar' => 'required|array',
            'ilaclar.*.ilac_id' => 'required|exists:ilaclar,ilac_id',
            'ilaclar.*.dozaj' => 'nullable|string',
            'ilaclar.*.kullanim_talimati' => 'nullable|string',
            'ilaclar.*.miktar' => 'required|integer|min:1'
        ]);

        // Reçete numarası oluştur
        $receteNo = 'RX-' . date('Ymd') . '-' . Str::upper(Str::random(6));

        // Reçete oluştur
        $recete = Recete::create([
            'hasta_id' => $request->hasta_id,
            'hastalik_id' => $request->hastalik_id,
            'recete_no' => $receteNo,
            'tarih' => $request->tarih,
            'notlar' => $request->notlar,
            'durum' => 'Beklemede',
            'aktif' => true
        ]);

        // İlaçları ekle
        foreach ($request->ilaclar as $ilac) {
            $recete->ilaclar()->create([
                'ilac_id' => $ilac['ilac_id'],
                'dozaj' => $ilac['dozaj'] ?? null,
                'kullanim_talimati' => $ilac['kullanim_talimati'] ?? null,
                'miktar' => $ilac['miktar'] ?? 1
            ]);
        }

        // Reçete detaylarını yükle
        $recete->load(['hasta', 'hastalik', 'ilaclar.ilac']);

        // QR kodu oluştur
        $qrCode = QrCode::size(250)->generate($receteNo);

        return view('receteler.show', compact('recete', 'qrCode'));
    }

    /**
     * QR kodu ile reçeteyi göster
     */
    public function showByQR($receteNo)
    {
        $recete = Recete::with(['hasta', 'hastalik', 'ilaclar.ilac.etkenMaddeler'])
            ->where('recete_no', $receteNo)
            ->firstOrFail();

        return view('receteler.qr-view', compact('recete'));
    }

    /**
     * Reçete detaylarını ve önerileri göster
     */
    public function show($receteId)
    {
        $recete = Recete::with(['hasta', 'hastalik', 'ilaclar.ilac.etkenMaddeler'])
            ->findOrFail($receteId);

        // Reçetedeki ilaçların etken maddelerini topla
        $etkenMaddeIds = [];
        $etkenMaddeler = [];

        foreach ($recete->ilaclar as $receteIlac) {
            if ($receteIlac->ilac && $receteIlac->ilac->etkenMaddeler) {
                foreach ($receteIlac->ilac->etkenMaddeler as $etkenMadde) {
                    $etkenMaddeIds[] = $etkenMadde->etken_madde_id;

                    // Etken madde bilgilerini sakla
                    if (!isset($etkenMaddeler[$etkenMadde->etken_madde_id])) {
                        $etkenMaddeler[$etkenMadde->etken_madde_id] = [
                            'id' => $etkenMadde->etken_madde_id,
                            'adi' => $etkenMadde->etken_madde_adi
                        ];
                    }
                }
            }
        }

        // Benzersiz etken maddeleri al
        $uniqueEtkenMaddeIds = array_unique($etkenMaddeIds);
        $etkenMaddeler = array_values($etkenMaddeler);

        // Mevcut ilaçların ID'lerini al
        $excludeIlacIds = $recete->ilaclar->pluck('ilac_id')->toArray();

        // İlaç önerilerini al
        $oneriler = IlacOnerisi::with(['ilac.etkenMaddeler'])
            ->where('hasta_id', $recete->hasta_id)
            ->where('hastalik_id', $recete->hastalik_id)
            ->orderBy('oneri_puani', 'desc')
            ->limit(5)
            ->get();

        // QR kodu oluştur
        $qrCode = QrCode::size(250)->generate($recete->recete_no);

        return view('receteler.show', compact(
            'recete',
            'qrCode',
            'oneriler',
            'etkenMaddeler',
            'uniqueEtkenMaddeIds',
            'excludeIlacIds'
        ));
    }

    /**
     * Tüm reçeteleri listele
     */
    public function index()
    {
        $receteler = Recete::with(['hasta', 'hastalik'])
            ->orderBy('created_at', 'desc')
            ->paginate(10);

        return view('receteler.index', compact('receteler'));
    }

    /**
     * Reçete için ilaç önerisi al
     */
    public function getRecommendations($receteId)
    {
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

        // İlaç önerisi işini başlat
        $job = new IlacOnerisiJob(
            $recete->hasta_id,
            $recete->hastalik_id,
            $uniqueEtkenMaddeIds,
            $excludeIlacIds
        );

        // İşi hemen çalıştır
        $result = $job->handle();

        if (isset($result['success']) && $result['success']) {
            return redirect()->route('receteler.show', $receteId)
                ->with('success', 'İlaç önerileri başarıyla oluşturuldu.');
        } else {
            return redirect()->route('receteler.show', $receteId)
                ->with('error', $result['message'] ?? 'İlaç önerisi işlemi başarısız.');
        }
    }

    /**
     * Önerilen ilacı reçeteye ekle
     */
    public function addSuggestion(Request $request, $receteId, $oneriId)
    {
        $recete = Recete::findOrFail($receteId);
        $oneri = IlacOnerisi::findOrFail($oneriId);

        // Reçete ve öneri aynı hasta ve hastalık için olmalı
        if ($recete->hasta_id != $oneri->hasta_id || $recete->hastalik_id != $oneri->hastalik_id) {
            return redirect()->route('receteler.show', $receteId)
                ->with('error', 'Reçete ve öneri aynı hasta ve hastalık için olmalıdır.');
        }

        // İlacı reçeteye ekle
        $receteIlac = ReceteIlac::create([
            'recete_id' => $receteId,
            'ilac_id' => $oneri->ilac_id,
            'dozaj' => $request->dozaj,
            'kullanim_talimati' => $request->kullanim_talimati,
            'miktar' => $request->miktar ?? 1
        ]);

        // Öneriyi uygulandı olarak işaretle
        $oneri->update(['uygulanma_durumu' => true]);

        return redirect()->route('receteler.show', $receteId)
            ->with('success', 'Önerilen ilaç reçeteye başarıyla eklendi.');
    }
}
