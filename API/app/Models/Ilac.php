<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Ilac extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'ilaclar';
    protected $primaryKey = 'ilac_id';

    protected $fillable = [
        'ilac_adi', 'barkod', 'atc_kodu', 'uretici_firma',
        'ilac_kodu', 'ilac_kategori_id', 'ilac_adi_firma',
        'perakende_satis_fiyati', 'depocu_satis_fiyati_kdv_dahil',
        'depocu_satis_fiyati_kdv_haric', 'imalatci_satis_fiyati_kdv_haric',
        'fiyat_tarihi', 'sgk_durumu', 'recete_tipi',
        'etki_mekanizmasi', 'farmakokinetik', 'farmakodinamik',
        'endikasyonlar', 'kontrendikasyonlar', 'kullanim_yolu',
        'yan_etkiler', 'ilac_etkilesimleri', 'ozel_popülasyon_bilgileri',
        'uyarilar_ve_onlemler', 'formulasyon', 'ambalaj_bilgisi'
    ];

    protected $casts = [
        'fiyat_hareketleri' => 'array',
        'esdeger_ilaclar' => 'array',
        'fiyat_tarihi' => 'date'
    ];

    public function etkenMaddeler()
    {
        return $this->belongsToMany(EtkenMadde::class, 'ilac_etken_maddeler',
            'ilac_id', 'etken_madde_id')
            ->withPivot('miktar')
            ->withTimestamps();
    }

    public function hastaKullanimlari()
    {
        return $this->hasMany(HastaIlacKullanim::class, 'ilac_id', 'ilac_id');
    }

    public function onerileri()
    {
        return $this->hasMany(IlacOnerisi::class, 'ilac_id', 'ilac_id');
    }

    public function scopeSearch($query, $search)
    {
        return $query->where(function($q) use ($search) {
            $q->where('ilac_adi', 'LIKE', "%{$search}%")
                ->orWhere('barkod', 'LIKE', "%{$search}%")
                ->orWhere('ilac_adi_firma', 'LIKE', "%{$search}%")
                ->orWhere('uretici_firma', 'LIKE', "%{$search}%");
        });
    }

    public function getFiyatGecmisi()
    {
        if (!$this->fiyat_hareketleri) {
            return collect();
        }

        return collect($this->fiyat_hareketleri);
    }
}
