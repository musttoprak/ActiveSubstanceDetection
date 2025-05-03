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
}
