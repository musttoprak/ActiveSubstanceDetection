<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateHastaIlacKullanimTable extends Migration
{
    public function up()
    {
        Schema::create('hasta_ilac_kullanim', function (Blueprint $table) {
            $table->id('kullanim_id');
            $table->unsignedBigInteger('hasta_id');
            $table->unsignedBigInteger('ilac_id');
            $table->unsignedBigInteger('hasta_hastalik_id')->nullable(); // Hangi hastalık için reçete edildi
            $table->date('baslangic_tarihi');
            $table->date('bitis_tarihi')->nullable();
            $table->string('dozaj')->nullable(); // Örn. 2x1, günde 3 kez
            $table->text('kullanim_talimatı')->nullable();
            $table->enum('etkinlik_degerlendirmesi', ['Çok İyi', 'İyi', 'Orta', 'Düşük', 'Etkisiz'])->nullable();
            $table->text('yan_etki_raporlari')->nullable();
            $table->boolean('aktif')->default(true); // Halen kullanıyor mu
            $table->timestamps();

            $table->foreign('hasta_id')->references('hasta_id')->on('hastalar')->onDelete('cascade');
            $table->foreign('ilac_id')->references('ilac_id')->on('ilaclar')->onDelete('cascade');
            $table->foreign('hasta_hastalik_id')->references('hasta_hastalik_id')->on('hasta_hastaliklar')->onDelete('set null');
        });
    }

    public function down()
    {
        Schema::dropIfExists('hasta_ilac_kullanim');
    }
}
