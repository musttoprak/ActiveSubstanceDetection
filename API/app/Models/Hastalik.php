<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Hastalik extends Model
{
    use HasFactory;

    protected $table = 'hastaliklar';
    protected $primaryKey = 'hastalik_id';

    protected $fillable = [
        'icd_kodu',
        'hastalik_adi',
        'hastalik_kategorisi',
        'aciklama'
    ];

    /**
     * Hastalık-Hasta ilişkisi
     */
    public function hastaHastaliklar()
    {
        return $this->hasMany(HastaHastalik::class, 'hastalik_id', 'hastalik_id');
    }

    /**
     * Hasta-Hastalık ilişkisi (doğrudan hastaları getiren)
     */
    public function hastalar()
    {
        return $this->belongsToMany(Hasta::class, 'hasta_hastaliklar',
            'hastalik_id', 'hasta_id')
            ->withPivot(['teshis_tarihi', 'siddet', 'notlar', 'aktif'])
            ->withTimestamps();
    }

    /**
     * Hastalık-İlaç Önerileri ilişkisi
     */
    public function ilacOnerileri()
    {
        return $this->hasMany(IlacOnerisi::class, 'hastalik_id', 'hastalik_id');
    }

    /**
     * Hastalık adına göre arama scope'u
     */
    public function scopeSearch($query, $search)
    {
        if ($search) {
            return $query->where('hastalik_adi', 'like', "%{$search}%")
                ->orWhere('icd_kodu', 'like', "%{$search}%")
                ->orWhere('hastalik_kategorisi', 'like', "%{$search}%");
        }

        return $query;
    }

    /**
     * Kategoriye göre filtreleme scope'u
     */
    public function scopeKategori($query, $kategori)
    {
        if ($kategori) {
            return $query->where('hastalik_kategorisi', $kategori);
        }

        return $query;
    }
}
