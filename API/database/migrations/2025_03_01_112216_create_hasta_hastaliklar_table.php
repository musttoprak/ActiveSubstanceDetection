<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHastaHastaliklarTable extends Migration
{
    public function up()
    {
        Schema::create('hasta_hastaliklar', function (Blueprint $table) {
            $table->id('hasta_hastalik_id');
            $table->unsignedBigInteger('hasta_id');
            $table->unsignedBigInteger('hastalik_id');
            $table->date('teshis_tarihi');
            $table->enum('siddet', ['Hafif', 'Orta', 'Şiddetli'])->nullable();
            $table->text('notlar')->nullable();
            $table->boolean('aktif')->default(true); // Hastalık aktif mi yoksa geçmiş mi
            $table->timestamps();

            $table->foreign('hasta_id')->references('hasta_id')->on('hastalar')->onDelete('cascade');
            $table->foreign('hastalik_id')->references('hastalik_id')->on('hastaliklar')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('hasta_hastaliklar');
    }
}
