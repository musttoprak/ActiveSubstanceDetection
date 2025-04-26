<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateIlaclarTable extends Migration
{
    public function up()
    {
        Schema::create('ilaclar', function (Blueprint $table) {
            $table->id('ilac_id');
            $table->string('ilac_adi');
            $table->string('barkod')->unique()->nullable();
            $table->string('atc_kodu')->nullable(); // Anatomik Terapötik Kimyasal sınıflandırma
            $table->string('uretici_firma')->nullable();
            $table->text('etki_mekanizmasi')->nullable();
            $table->text('farmakokinetik')->nullable(); // Emilim, dağılım, metabolizma, atılım
            $table->text('farmakodinamik')->nullable();
            $table->text('endikasyonlar')->nullable(); // Hangi hastalıklarda kullanıldığı
            $table->text('kontrendikasyonlar')->nullable(); // Hangi durumlarda kullanılmaması gerektiği
            $table->text('kullanim_yolu')->nullable(); // Oral, parenteral, topikal vb.
            $table->text('yan_etkiler')->nullable();
            $table->text('ilac_etkilesimleri')->nullable();
            $table->text('ozel_popülasyon_bilgileri')->nullable(); // Hamilelik, pediatrik, geriatrik
            $table->text('uyarilar_ve_onlemler')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down()
    {
        Schema::dropIfExists('ilaclar');
    }
}
