<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HastaIlacKullanim extends Model
{
    use HasFactory;

    protected $table = 'hasta_ilac_kullanim';
    protected $primaryKey = 'kullanim_id';

    protected $fillable = [
        'hasta_id',
        'ilac_id',
        'hasta_hastalik_id',
        'baslangic_tarihi',
        'bitis_tarihi',
        'dozaj',
        'kullanim_talimatı',
        'etkinlik_degerlendirmesi',
        'yan_etki_raporlari',
        'aktif'
    ];

    protected $casts = [
        'baslangic_tarihi' => 'date',
        'bitis_tarihi' => 'date',
        'aktif' => 'boolean'
    ];

    /**
     * HastaIlacKullanim-Hasta ilişkisi
     */
    public function hasta()
    {
        return $this->belongsTo(Hasta::class, 'hasta_id', 'hasta_id');
    }

    /**
     * HastaIlacKullanim-Ilac ilişkisi
     */
    public function ilac()
    {
        return $this->belongsTo(Ilac::class, 'ilac_id', 'ilac_id');
    }

    /**
     * HastaIlacKullanim-HastaHastalik ilişkisi
     */
    public function hastaHastalik()
    {
        return $this->belongsTo(HastaHastalik::class, 'hasta_hastalik_id', 'hasta_hastalik_id');
    }

    /**
     * Aktif ilaç kullanımları scope'u
     */
    public function scopeAktif($query)
    {
        return $query->where('aktif', true);
    }

    /**
     * Etkinlik değerlendirmesine göre filtreleme scope'u
     */
    public function scopeEtkinlik($query, $etkinlik)
    {
        if ($etkinlik) {
            return $query->where('etkinlik_degerlendirmesi', $etkinlik);
        }

        return $query;
    }

    /**
     * Tarih aralığına göre filtreleme scope'u
     */
    public function scopeTarihAraligi($query, $baslangic, $bitis = null)
    {
        if ($baslangic && $bitis) {
            return $query->where(function($q) use ($baslangic, $bitis) {
                $q->whereBetween('baslangic_tarihi', [$baslangic, $bitis])
                    ->orWhereBetween('bitis_tarihi', [$baslangic, $bitis])
                    ->orWhere(function($subQ) use ($baslangic, $bitis) {
                        $subQ->where('baslangic_tarihi', '<=', $baslangic)
                            ->where(function($innerQ) use ($bitis) {
                                $innerQ->where('bitis_tarihi', '>=', $bitis)
                                    ->orWhereNull('bitis_tarihi');
                            });
                    });
            });
        } elseif ($baslangic) {
            return $query->where(function($q) use ($baslangic) {
                $q->where('baslangic_tarihi', '>=', $baslangic)
                    ->orWhere(function($subQ) use ($baslangic) {
                        $subQ->where('baslangic_tarihi', '<=', $baslangic)
                            ->where(function($innerQ) use ($baslangic) {
                                $innerQ->where('bitis_tarihi', '>=', $baslangic)
                                    ->orWhereNull('bitis_tarihi');
                            });
                    });
            });
        }

        return $query;
    }
}
