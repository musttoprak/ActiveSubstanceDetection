<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHastaTibbiGecmisTable extends Migration
{
    public function up()
    {
        Schema::create('hasta_tibbi_gecmis', function (Blueprint $table) {
            $table->id('tibbi_gecmis_id');
            $table->unsignedBigInteger('hasta_id');
            $table->text('kronik_hastaliklar')->nullable();
            $table->text('gecirilen_ameliyatlar')->nullable();
            $table->text('alerjiler')->nullable();
            $table->text('aile_hastaliklari')->nullable();
            $table->text('sigara_kullanimi')->nullable();
            $table->text('alkol_tuketimi')->nullable();
            $table->text('fiziksel_aktivite')->nullable();
            $table->text('beslenme_aliskanliklari')->nullable();
            $table->timestamps();

            $table->foreign('hasta_id')->references('hasta_id')->on('hastalar')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('hasta_tibbi_gecmis');
    }
}

