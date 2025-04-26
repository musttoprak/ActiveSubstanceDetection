<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHastalarTable extends Migration
{
    public function up()
    {
        Schema::create('hastalar', function (Blueprint $table) {
            $table->id('hasta_id');
            $table->string('ad');
            $table->string('soyad');
            $table->integer('yas');
            $table->enum('cinsiyet', ['Erkek', 'Kadın', 'Diğer']);
            $table->decimal('boy', 5, 2)->nullable(); // cm cinsinden
            $table->decimal('kilo', 5, 2)->nullable(); // kg cinsinden
            $table->decimal('vki', 5, 2)->nullable(); // BMI - Vücut Kitle İndeksi
            $table->date('dogum_tarihi');
            $table->string('tc_kimlik', 11)->unique()->nullable();
            $table->string('telefon')->nullable();
            $table->string('email')->unique()->nullable();
            $table->text('adres')->nullable();
            $table->timestamps();
            $table->softDeletes(); // Silinen hastaları takip etmek için
        });
    }

    public function down()
    {
        Schema::dropIfExists('hastalar');
    }
}
