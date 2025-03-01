<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHastaliklarTable extends Migration
{
    public function up()
    {
        Schema::create('hastaliklar', function (Blueprint $table) {
            $table->id('hastalik_id');
            $table->string('icd_kodu')->unique();
            $table->string('hastalik_adi');
            $table->string('hastalik_kategorisi')->nullable();
            $table->text('aciklama')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('hastaliklar');
    }
}
