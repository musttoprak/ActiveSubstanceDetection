<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class ChangeIlacKoduColumnType extends Migration
{
    public function up()
    {
        Schema::table('ilaclar', function (Blueprint $table) {
            // İlk olarak sütunu değiştir
            $table->string('ilac_kodu', 50)->nullable()->change();
        });
    }

    public function down()
    {
        Schema::table('ilaclar', function (Blueprint $table) {
            // Geri almak için tekrar unsignedInteger'a çevir
            $table->unsignedInteger('ilac_kodu')->nullable()->change();
        });
    }
}
