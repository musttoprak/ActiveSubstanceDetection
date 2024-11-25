<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Preparation extends Model
{
    protected $fillable = ['medicine_id', 'name', 'company', 'sgk_status', 'link'];

    public function medicine()
    {
        return $this->belongsTo(Medicine::class);
    }
}

