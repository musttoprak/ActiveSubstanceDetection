<?php

use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\HastaController;
use App\Http\Controllers\API\HastaTibbiGecmisController;
use App\Http\Controllers\API\HastalikController;
use App\Http\Controllers\API\HastaHastalikController;
use App\Http\Controllers\API\IlacController;
use App\Http\Controllers\API\EtkenMaddeController;
use App\Http\Controllers\API\IlacEtkenMaddeController;
use App\Http\Controllers\API\HastaIlacKullanimController;
use App\Http\Controllers\API\LaboratuvarSonucuController;
use App\Http\Controllers\API\IlacOnerisiController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// Auth Routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::middleware('auth:sanctum')->post('/logout', [AuthController::class, 'logout']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {

    // Hasta (Patient) Routes
    Route::apiResource('hastalar', HastaController::class);
    Route::get('/hastalar/search', [HastaController::class, 'search']);
    Route::get('/hastalar/{hasta}/tibbi-gecmis', [HastaController::class, 'tibbiGecmis']);
    Route::get('/hastalar/{hasta}/hastaliklar', [HastaController::class, 'hastaliklar']);
    Route::get('/hastalar/{hasta}/ilac-kullanim', [HastaController::class, 'ilacKullanim']);
    Route::get('/hastalar/{hasta}/laboratuvar-sonuclari', [HastaController::class, 'laboratuvarSonuclari']);
    Route::get('/hastalar/{hasta}/ilac-onerileri', [HastaController::class, 'ilacOnerileri']);

    // Hasta Tıbbi Geçmiş (Patient Medical History) Routes
    Route::apiResource('hasta-tibbi-gecmis', HastaTibbiGecmisController::class);
    Route::get('/hasta-tibbi-gecmis/hasta/{hasta}', [HastaTibbiGecmisController::class, 'getOrCreateForHasta']);
    Route::post('/hasta-tibbi-gecmis/hasta/{hasta}/alerjiler', [HastaTibbiGecmisController::class, 'updateAlerjiler']);
    Route::post('/hasta-tibbi-gecmis/hasta/{hasta}/kronik-hastaliklar', [HastaTibbiGecmisController::class, 'updateKronikHastaliklar']);

    // Hastalık (Disease) Routes
    Route::apiResource('hastaliklar', HastalikController::class);
    Route::get('/hastaliklar/search', [HastalikController::class, 'search']);
    Route::get('/hastaliklar/{hastalik}/hastalar', [HastalikController::class, 'hastalar']);
    Route::get('/hastaliklar/kategoriler', [HastalikController::class, 'kategoriler']);

    // Hasta Hastalık (Patient Disease) Routes
    Route::apiResource('hasta-hastaliklar', HastaHastalikController::class);
    Route::get('/hasta-hastaliklar/hasta/{hasta}/aktif', [HastaHastalikController::class, 'getActiveDiseasesForPatient']);
    Route::post('/hasta-hastaliklar/{hastaHastalik}/iyilestir', [HastaHastalikController::class, 'setCured']);

    // Laboratuvar Sonuçları (Laboratory Results) Routes
    Route::apiResource('laboratuvar-sonuclari', LaboratuvarSonucuController::class);
    Route::get('/laboratuvar-sonuclari/hasta/{hasta}', [LaboratuvarSonucuController::class, 'getByHasta']);
    Route::get('/laboratuvar-sonuclari/hasta/{hasta}/son', [LaboratuvarSonucuController::class, 'getLatestByHasta']);
    Route::get('/laboratuvar-sonuclari/hasta/{hasta}/test/{testTuru}', [LaboratuvarSonucuController::class, 'getTestHistory']);
    Route::get('/laboratuvar-sonuclari/test-turleri', [LaboratuvarSonucuController::class, 'getTestTypes']);

    // Hasta İlaç Kullanım (Patient Drug Usage) Routes
    Route::apiResource('hasta-ilac-kullanim', HastaIlacKullanimController::class);
    Route::get('/hasta-ilac-kullanim/hasta/{hasta}', [HastaIlacKullanimController::class, 'getByHasta']);
    Route::get('/hasta-ilac-kullanim/hasta/{hasta}/aktif', [HastaIlacKullanimController::class, 'getActiveByHasta']);
    Route::get('/hasta-ilac-kullanim/ilac/{ilac}', [HastaIlacKullanimController::class, 'getByIlac']);
    Route::post('/hasta-ilac-kullanim/{hastaIlacKullanim}/sonlandir', [HastaIlacKullanimController::class, 'endMedication']);

    // İlaç Önerileri (Drug Recommendations) Routes
    Route::apiResource('ilac-onerileri', IlacOnerisiController::class);
    Route::get('/ilac-onerileri/hasta/{hasta}', [IlacOnerisiController::class, 'getByHasta']);
    Route::get('/ilac-onerileri/hastalik/{hastalik}', [IlacOnerisiController::class, 'getByHastalik']);
    Route::post('/ilac-onerileri/generate', [IlacOnerisiController::class, 'generateRecommendations']);
    Route::post('/ilac-onerileri/{ilacOnerisi}/uygula', [IlacOnerisiController::class, 'applyRecommendation']);

    // İlaç Etken Madde İşlemleri (Korumalı)
    Route::post('/ilaclar/{ilac}/etken-maddeler/ekle', [IlacEtkenMaddeController::class, 'addMultipleToMedicine']);
});

// Public Routes

// İlaç (Medicine) Routes
Route::apiResource('ilaclar', IlacController::class)->only(['index', 'show']);
Route::get('/ilaclar/search', [IlacController::class, 'search']);
Route::get('/ilaclar/{ilac}/etken-maddeler', [IlacController::class, 'etkenMaddeler']);
Route::get('/ilaclar/{ilac}/fiyat-hareketleri', [IlacController::class, 'fiyatHareketleri']);
Route::get('/ilaclar/{ilac}/esdeger-ilaclar', [IlacController::class, 'esdegerIlaclar']);
Route::get('/ilaclar/{ilac}/benzer-ilaclar', [IlacEtkenMaddeController::class, 'findSimilarMedicines']);

// Etken Madde (Active Substance) Routes
Route::apiResource('etken-maddeler', EtkenMaddeController::class)->only(['index', 'show']);
Route::get('/etken-maddeler/search', [EtkenMaddeController::class, 'search']);
Route::get('/etken-maddeler/{etkenMadde}/ilaclar', [EtkenMaddeController::class, 'ilaclar']);
Route::get('/etken-maddeler/{etkenMadde}/benzer-etken-maddeler', [EtkenMaddeController::class, 'relatedActiveSubstances']);

// İlaç Etken Madde İlişki (Drug Active Substance Relationship) Routes
Route::apiResource('ilac-etken-maddeler', IlacEtkenMaddeController::class)->only(['index', 'show']);
Route::get('/ilac-etken-maddeler/etken-madde/{etkenMadde}/ilaclar', [IlacEtkenMaddeController::class, 'getMedicinesByActiveSubstance']);
Route::get('/ilac-etken-maddeler/ilac/{ilac}/etken-maddeler', [IlacEtkenMaddeController::class, 'getActiveSubstancesByMedicine']);
