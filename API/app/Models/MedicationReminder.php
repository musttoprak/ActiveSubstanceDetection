<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MedicationReminder extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'patient_id',
        'patient_name',
        'medication_name',
        'dose',
        'reminder_time',
        'reminder_date',
        'notes',
        'is_complete',
    ];

    protected $casts = [
        'reminder_date' => 'date',
        'reminder_time' => 'datetime:H:i',
        'is_complete' => 'boolean',
    ];

    // İlişkiler
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
