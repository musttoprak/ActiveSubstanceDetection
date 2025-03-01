<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IlacOnerisi extends Model
{
    use HasFactory;

    protected $table = 'ilac_onerileri';
    protected $primaryKey = 'oneri_id';

    protected $fillable = [
        'hasta_id',
        'hastalik_id',
        'ilac_id',
        'oneri_puani',
        'oneri_sebebi',
        'uygulanma_durumu',
        'doktor_geribildirimi'
    ];

    protected $casts = [
        'oneri_puani' => 'float',
        'uygulanma_durumu' => 'boolean'
    ];

    /**
     * IlacOnerisi-Hasta ilişkisi
     */
    public function hasta()
    {
        return $this->belongsTo(Hasta::class, 'hasta_id', 'hasta_id');
    }

    /**
     * IlacOnerisi-Hastalik ilişkisi
     */
    public function hastalik()
    {
        return $this->belongsTo(Hastalik::class, 'hastalik_id', 'hastalik_id');
    }

    /**
     * IlacOnerisi-Ilac ilişkisi
     */
    public function ilac()
    {
        return $this->belongsTo(Ilac::class, 'ilac_id', 'ilac_id');
    }

    /**
     * Puan aralığına göre filtreleme scope'u
     */
    public function scopePuanAraligi($query, $minPuan, $maxPuan = null)
    {
        if ($minPuan !== null && $maxPuan !== null) {
            return $query->whereBetween('oneri_puani', [$minPuan, $maxPuan]);
        } elseif ($minPuan !== null) {
            return $query->where('oneri_puani', '>=', $minPuan);
        } elseif ($maxPuan !== null) {
            return $query->where('oneri_puani', '<=', $maxPuan);
        }

        return $query;
    }

    /**
     * Uygulanma durumuna göre filtreleme scope'u
     */
    public function scopeUygulanma($query, $uygulanmaDurumu)
    {
        if ($uygulanmaDurumu !== null) {
            return $query->where('uygulanma_durumu', $uygulanmaDurumu);
        }

        return $query;
    }

    /**
     * Hasta ID'sine göre filtreleme scope'u
     */
    public function scopeHastaId($query, $hastaId)
    {
        if ($hastaId) {
            return $query->where('hasta_id', $hastaId);
        }

        return $query;
    }

    /**
     * Hastalık ID'sine göre filtreleme scope'u
     */
    public function scopeHastalikId($query, $hastalikId)
    {
        if ($hastalikId) {
            return $query->where('hastalik_id', $hastalikId);
        }

        return $query;
    }

    /**
     * İlaç ID'sine göre filtreleme scope'u
     */
    public function scopeIlacId($query, $ilacId)
    {
        if ($ilacId) {
            return $query->where('ilac_id', $ilacId);
        }

        return $query;
    }
}
