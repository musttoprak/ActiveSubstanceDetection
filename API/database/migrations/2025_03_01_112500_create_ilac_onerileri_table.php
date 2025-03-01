<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateIlacOnerileriTable extends Migration
{
    public function up()
    {
        Schema::create('ilac_onerileri', function (Blueprint $table) {
            $table->id('oneri_id');
            $table->unsignedBigInteger('hasta_id');
            $table->unsignedBigInteger('hastalik_id');
            $table->unsignedBigInteger('ilac_id');
            $table->float('oneri_puani', 8, 2); // ML modeli tarafından belirlenen puan
            $table->string('oneri_sebebi')->nullable();
            $table->boolean('uygulanma_durumu')->default(false); // Doktor öneriyi uyguladı mı
            $table->text('doktor_geribildirimi')->nullable();
            $table->timestamps();

            $table->foreign('hasta_id')->references('hasta_id')->on('hastalar')->onDelete('cascade');
            $table->foreign('hastalik_id')->references('hastalik_id')->on('hastaliklar')->onDelete('cascade');
            $table->foreign('ilac_id')->references('ilac_id')->on('ilaclar')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('ilac_onerileri');
    }
}
