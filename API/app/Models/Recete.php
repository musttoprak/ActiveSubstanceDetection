<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Recete extends Model
{
    use HasFactory;

    protected $table = 'receteler';
    protected $primaryKey = 'recete_id';

    protected $fillable = [
        'hasta_id',
        'hastalik_id',
        'recete_no',
        'tarih',
        'notlar',
        'durum',
        'aktif'
    ];

    public function hasta()
    {
        return $this->belongsTo(Hasta::class, 'hasta_id', 'hasta_id');
    }

    public function hastalik()
    {
        return $this->belongsTo(Hastalik::class, 'hastalik_id', 'hastalik_id');
    }
    public function ilaclar()
    {
        return $this->hasMany(ReceteIlac::class, 'recete_id', 'recete_id');
    }
}
