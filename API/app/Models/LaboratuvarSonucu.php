<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LaboratuvarSonucu extends Model
{
    use HasFactory;

    protected $table = 'laboratuvar_sonuclari';
    protected $primaryKey = 'sonuc_id';

    protected $fillable = [
        'hasta_id',
        'test_turu',
        'test_kodu',
        'deger',
        'birim',
        'referans_aralik',
        'normal_mi',
        'test_tarihi',
        'notlar'
    ];

    protected $casts = [
        'test_tarihi' => 'date',
        'normal_mi' => 'boolean'
    ];

    /**
     * LaboratuvarSonucu-Hasta ilişkisi
     */
    public function hasta()
    {
        return $this->belongsTo(Hasta::class, 'hasta_id', 'hasta_id');
    }

    /**
     * Test türüne göre filtreleme scope'u
     */
    public function scopeTestTuru($query, $testTuru)
    {
        if ($testTuru) {
            return $query->where('test_turu', $testTuru);
        }

        return $query;
    }

    /**
     * Normal değer durumuna göre filtreleme scope'u
     */
    public function scopeNormalMi($query, $normalMi)
    {
        if ($normalMi !== null) {
            return $query->where('normal_mi', $normalMi);
        }

        return $query;
    }

    /**
     * Tarih aralığına göre filtreleme scope'u
     */
    public function scopeTarihAraligi($query, $baslangic, $bitis = null)
    {
        if ($baslangic && $bitis) {
            return $query->whereBetween('test_tarihi', [$baslangic, $bitis]);
        } elseif ($baslangic) {
            return $query->where('test_tarihi', '>=', $baslangic);
        } elseif ($bitis) {
            return $query->where('test_tarihi', '<=', $bitis);
        }

        return $query;
    }

    /**
     * Belirtilen test türlerinin son sonuçlarını almak için scope
     */
    public function scopeSonSonuclar($query, $hastaId, $testTurleri = [])
    {
        $query->where('hasta_id', $hastaId);

        if (!empty($testTurleri)) {
            $query->whereIn('test_turu', $testTurleri);
        }

        return $query->latest('test_tarihi');
    }

    /**
     * Test adına göre arama scope'u
     */
    public function scopeSearch($query, $search)
    {
        if ($search) {
            return $query->where('test_turu', 'like', "%{$search}%")
                ->orWhere('test_kodu', 'like', "%{$search}%");
        }

        return $query;
    }
}
