<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ReceteIlac extends Model
{
    use HasFactory;

    protected $table = 'recete_ilaclar';
    protected $primaryKey = 'recete_ilac_id';

    protected $fillable = [
        'recete_id',
        'ilac_id',
        'dozaj',
        'kullanim_talimati',
        'miktar'
    ];

    public function recete()
    {
        return $this->belongsTo(Recete::class, 'recete_id', 'recete_id');
    }

    public function ilac()
    {
        return $this->belongsTo(Ilac::class, 'ilac_id', 'ilac_id');
    }
}
