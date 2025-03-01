<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EtkenMadde extends Model
{
    use HasFactory;

    protected $table = 'etken_maddeler';
    protected $primaryKey = 'etken_madde_id';

    protected $fillable = [
        'etken_madde_adi', 'etken_madde_kategorisi', 'aciklama',
        'ingilizce_adi', 'net_kutle', 'molekul_agirligi',
        'formul', 'atc_kodlari', 'genel_bilgi',
        'etki_mekanizmasi', 'farmakokinetik', 'resim_url'
    ];

    protected $casts = [
        'mustahzarlar' => 'array'
    ];

    public function ilaclar()
    {
        return $this->belongsToMany(Ilac::class, 'ilac_etken_maddeler',
            'etken_madde_id', 'ilac_id')
            ->withPivot('miktar')
            ->withTimestamps();
    }

    public function scopeSearch($query, $search)
    {
        return $query->where(function($q) use ($search) {
            $q->where('etken_madde_adi', 'LIKE', "%{$search}%")
                ->orWhere('ingilizce_adi', 'LIKE', "%{$search}%")
                ->orWhere('formul', 'LIKE', "%{$search}%")
                ->orWhere('atc_kodlari', 'LIKE', "%{$search}%");
        });
    }
}
