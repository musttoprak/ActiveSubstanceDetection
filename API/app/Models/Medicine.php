<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Medicine extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'id',
        'name',
        'image_src',
        'weight',
        'molecular_weight',
        'formula',
        'related_atc_codes',
        'cas',
        'general_info',
        'mechanism',
        'pharmacokinetics',
        'company',
        'barcode',
        'prescription_type',
        'retail_price',
        'depot_price_with_vat',
        'depot_price_without_vat',
        'manufacturer_price_without_vat',
        'vat_info',
        'price_date',
        'active_substance',
        'dosage',
        'sgk_status',
        'created_at',
        'updated_at'
    ];

    public function preparations()
    {
        return $this->hasMany(Preparation::class);
    }
}

