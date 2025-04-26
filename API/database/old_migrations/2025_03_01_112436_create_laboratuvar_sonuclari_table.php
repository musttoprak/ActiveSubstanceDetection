<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateLaboratuvarSonuclariTable extends Migration
{
    public function up()
    {
        Schema::create('laboratuvar_sonuclari', function (Blueprint $table) {
            $table->id('sonuc_id');
            $table->unsignedBigInteger('hasta_id');
            $table->string('test_turu');
            $table->string('test_kodu')->nullable();
            $table->string('deger');
            $table->string('birim')->nullable();
            $table->string('referans_aralik')->nullable();
            $table->boolean('normal_mi')->nullable();
            $table->date('test_tarihi');
            $table->text('notlar')->nullable();
            $table->timestamps();

            $table->foreign('hasta_id')->references('hasta_id')->on('hastalar')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('laboratuvar_sonuclari');
    }
}
