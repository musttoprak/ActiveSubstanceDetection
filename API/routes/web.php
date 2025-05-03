<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\IlacImportController;
use App\Http\Controllers\Web\ReceteWebController;
/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});


Route::get('/ilac-import', [IlacImportController::class, 'showImportForm'])->name('ilac.import.form');
Route::post('/ilac-import', [IlacImportController::class, 'import'])->name('ilac.import');

// Reçete web sayfaları
Route::get('/receteler', [ReceteWebController::class, 'index'])->name('receteler.index');
Route::get('/receteler/create', [ReceteWebController::class, 'createForm'])->name('receteler.create');
Route::post('/receteler', [ReceteWebController::class, 'store'])->name('receteler.store');
Route::get('/receteler/qr/{receteNo}', [ReceteWebController::class, 'showByQR'])->name('receteler.qr');
Route::get('/receteler/{receteId}', [ReceteWebController::class, 'show'])->name('receteler.show');
Route::get('/receteler/{receteId}/oneriler', [ReceteWebController::class, 'getRecommendations'])->name('receteler.recommendations');
Route::post('/receteler/{receteId}/oneriler/{oneriId}/ekle', [ReceteWebController::class, 'addSuggestion'])->name('receteler.add-suggestion');
