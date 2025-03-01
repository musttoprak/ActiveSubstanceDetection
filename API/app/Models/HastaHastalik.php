<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HastaHastalik extends Model
{
    use HasFactory;

    protected $table = 'hasta_hastaliklar';
    protected $primaryKey = 'hasta_hastalik_id';

    protected $fillable = [
        'hasta_id',
        'hastalik_id',
        'teshis_tarihi',
        'siddet',
        'notlar',
        'aktif'
    ];

    protected $casts = [
        'teshis_tarihi' => 'date',
        'aktif' => 'boolean'
    ];

    /**
     * HastaHastalık-Hasta ilişkisi
     */
    public function hasta()
    {
        return $this->belongsTo(Hasta::class, 'hasta_id', 'hasta_id');
    }

    /**
     * HastaHastalık-Hastalık ilişkisi
     */
    public function hastalik()
    {
        return $this->belongsTo(Hastalik::class, 'hastalik_id', 'hastalik_id');
    }

    /**
     * Aktif hastalıklar scope'u
     */
    public function scopeAktif($query)
    {
        return $query->where('aktif', true);
    }

    /**
     * Belirli bir şiddetteki hastalıklar scope'u
     */
    public function scopeSiddet($query, $siddet)
    {
        if ($siddet) {
            return $query->where('siddet', $siddet);
        }

        return $query;
    }

    /**
     * Tarih aralığına göre filtreleme scope'u
     */
    public function scopeTarihAraligi($query, $baslangic, $bitis = null)
    {
        if ($baslangic && $bitis) {
            return $query->whereBetween('teshis_tarihi', [$baslangic, $bitis]);
        } elseif ($baslangic) {
            return $query->where('teshis_tarihi', '>=', $baslangic);
        }

        return $query;
    }
}
