<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Medicine extends Model
{
    protected $fillable = [
        'name', 'image_src', 'weight', 'molecular_weight', 'formula',
        'related_atc_codes', 'cas', 'general_info', 'mechanism', 'pharmacokinetics',
    ];

    public function preparations()
    {
        return $this->hasMany(Preparation::class);
    }
}

