<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HastaTibbiGecmis extends Model
{
    use HasFactory;

    protected $table = 'hasta_tibbi_gecmis';
    protected $primaryKey = 'tibbi_gecmis_id';

    protected $fillable = [
        'hasta_id',
        'kronik_hastaliklar',
        'gecirilen_ameliyatlar',
        'alerjiler',
        'aile_hastaliklari',
        'sigara_kullanimi',
        'alkol_tuketimi',
        'fiziksel_aktivite',
        'beslenme_aliskanliklari'
    ];

    /**
     * Tıbbi Geçmiş-Hasta ilişkisi
     */
    public function hasta()
    {
        return $this->belongsTo(Hasta::class, 'hasta_id', 'hasta_id');
    }

    /**
     * Alerjileri dizi olarak döndürür
     */
    public function getAlerjilerArrayAttribute()
    {
        if (!$this->alerjiler) {
            return [];
        }

        return array_map('trim', explode(',', $this->alerjiler));
    }

    /**
     * Kronik hastalıkları dizi olarak döndürür
     */
    public function getKronikHastaliklarArrayAttribute()
    {
        if (!$this->kronik_hastaliklar) {
            return [];
        }

        return array_map('trim', explode(',', $this->kronik_hastaliklar));
    }

    /**
     * Ameliyatları dizi olarak döndürür
     */
    public function getGecirilenAmeliyatlarArrayAttribute()
    {
        if (!$this->gecirilen_ameliyatlar) {
            return [];
        }

        return array_map('trim', explode(',', $this->gecirilen_ameliyatlar));
    }

    /**
     * Aile hastalıklarını dizi olarak döndürür
     */
    public function getAileHastaliklariArrayAttribute()
    {
        if (!$this->aile_hastaliklari) {
            return [];
        }

        return array_map('trim', explode(',', $this->aile_hastaliklari));
    }
}
