<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateIlacEtkenMaddelerTable extends Migration
{
    public function up()
    {
        Schema::create('ilac_etken_maddeler', function (Blueprint $table) {
            $table->id('ilac_etken_madde_id');
            $table->unsignedBigInteger('ilac_id');
            $table->unsignedBigInteger('etken_madde_id');
            $table->string('miktar')->nullable(); // Örn. 500 mg
            $table->timestamps();

            $table->foreign('ilac_id')->references('ilac_id')->on('ilaclar')->onDelete('cascade');
            $table->foreign('etken_madde_id')->references('etken_madde_id')->on('etken_maddeler')->onDelete('cascade');
        });
    }

    public function down()
    {
        Schema::dropIfExists('ilac_etken_maddeler');
    }
}
