<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PriceMovement extends Model
{
    protected $fillable = [
        'medicine_id',
        'date',
        'transaction_type',
        'isf',
        'dsf',
        'psf',
        'kf',
        'ko',
    ];
}

