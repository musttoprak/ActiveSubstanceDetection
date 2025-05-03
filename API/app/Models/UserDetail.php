<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'role',
        'profile_picture',
    ];

    // İlişkiler
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
