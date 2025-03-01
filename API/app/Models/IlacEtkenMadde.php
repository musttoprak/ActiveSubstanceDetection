<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class IlacEtkenMadde extends Model
{
    use HasFactory;

    protected $table = 'ilac_etken_maddeler';
    protected $primaryKey = 'ilac_etken_madde_id';

    protected $fillable = [
        'ilac_id',
        'etken_madde_id',
        'miktar'
    ];

    /**
     * IlacEtkenMadde-Ilac ilişkisi
     */
    public function ilac()
    {
        return $this->belongsTo(Ilac::class, 'ilac_id', 'ilac_id');
    }

    /**
     * IlacEtkenMadde-EtkenMadde ilişkisi
     */
    public function etkenMadde()
    {
        return $this->belongsTo(EtkenMadde::class, 'etken_madde_id', 'etken_madde_id');
    }

    /**
     * Miktara göre filtreleme scope'u
     */
    public function scopeDozajAra($query, $search)
    {
        if ($search) {
            return $query->where('miktar', 'like', "%{$search}%");
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

    /**
     * Etken madde ID'sine göre filtreleme scope'u
     */
    public function scopeEtkenMaddeId($query, $etkenMaddeId)
    {
        if ($etkenMaddeId) {
            return $query->where('etken_madde_id', $etkenMaddeId);
        }

        return $query;
    }
}
