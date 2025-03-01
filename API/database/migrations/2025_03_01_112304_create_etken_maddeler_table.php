<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateEtkenMaddelerTable extends Migration
{
    public function up()
    {
        Schema::create('etken_maddeler', function (Blueprint $table) {
            $table->id('etken_madde_id');
            $table->string('etken_madde_adi')->unique();
            $table->string('etken_madde_kategorisi')->nullable();
            $table->text('aciklama')->nullable();
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('etken_maddeler');
    }
}
