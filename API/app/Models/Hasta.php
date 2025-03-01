<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Hasta extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'hastalar';
    protected $primaryKey = 'hasta_id';

    protected $fillable = [
        'ad',
        'soyad',
        'yas',
        'cinsiyet',
        'boy',
        'kilo',
        'vki',
        'dogum_tarihi',
        'tc_kimlik',
        'telefon',
        'email',
        'adres'
    ];

    protected $casts = [
        'dogum_tarihi' => 'date',
        'vki' => 'float',
        'boy' => 'float',
        'kilo' => 'float',
        'deleted_at' => 'datetime'
    ];

    /**
     * Hasta-Tıbbi Geçmiş ilişkisi
     */
    public function tibbiGecmis()
    {
        return $this->hasOne(HastaTibbiGecmis::class, 'hasta_id', 'hasta_id');
    }

    /**
     * Hasta-Hastalık ilişkisi
     */
    public function hastaHastaliklar()
    {
        return $this->hasMany(HastaHastalik::class, 'hasta_id', 'hasta_id');
    }

    /**
     * Hasta-Hastalık ilişkisi (doğrudan hastalıkları getiren)
     */
    public function hastaliklar()
    {
        return $this->belongsToMany(Hastalik::class, 'hasta_hastaliklar',
            'hasta_id', 'hastalik_id')
            ->withPivot(['teshis_tarihi', 'siddet', 'notlar', 'aktif'])
            ->withTimestamps();
    }

    /**
     * Hasta-İlaç Kullanım ilişkisi
     */
    public function ilacKullanim()
    {
        return $this->hasMany(HastaIlacKullanim::class, 'hasta_id', 'hasta_id');
    }

    /**
     * Hasta-Laboratuvar Sonuçları ilişkisi
     */
    public function laboratuvarSonuclari()
    {
        return $this->hasMany(LaboratuvarSonucu::class, 'hasta_id', 'hasta_id');
    }

    /**
     * Hasta-İlaç Önerileri ilişkisi
     */
    public function ilacOnerileri()
    {
        return $this->hasMany(IlacOnerisi::class, 'hasta_id', 'hasta_id');
    }

    /**
     * Hastanın tam adını döndürür
     */
    public function getTamAdAttribute()
    {
        return "{$this->ad} {$this->soyad}";
    }

    /**
     * Ad ve soyada göre filtreleme scope'u
     */
    public function scopeFilter($query, $filter)
    {
        if (isset($filter['search']) && $filter['search']) {
            $search = $filter['search'];
            return $query->where(function($q) use ($search) {
                $q->where('ad', 'like', "%{$search}%")
                    ->orWhere('soyad', 'like', "%{$search}%")
                    ->orWhere('tc_kimlik', 'like', "%{$search}%")
                    ->orWhere('telefon', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        return $query;
    }
}
