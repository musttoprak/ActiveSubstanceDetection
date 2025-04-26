<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddColumnsToEtkenMaddelerTable extends Migration
{
    public function up()
    {
        Schema::table('etken_maddeler', function (Blueprint $table) {
            // Etken madde için ek bilgiler
            $table->string('ingilizce_adi')->nullable();
            $table->string('net_kutle')->nullable();
            $table->string('molekul_agirligi')->nullable();
            $table->string('formul')->nullable();
            $table->string('atc_kodlari')->nullable();
            $table->text('genel_bilgi')->nullable();
            $table->text('etki_mekanizmasi')->nullable();
            $table->text('farmakokinetik')->nullable();
            $table->string('resim_url')->nullable();
            $table->json('mustahzarlar')->nullable(); // İçeren ilaçların JSON listesi
        });
    }

    public function down()
    {
        Schema::table('etken_maddeler', function (Blueprint $table) {
            $table->dropColumn([
                'ingilizce_adi',
                'net_kutle',
                'molekul_agirligi',
                'formul',
                'atc_kodlari',
                'genel_bilgi',
                'etki_mekanizmasi',
                'farmakokinetik',
                'resim_url',
                'mustahzarlar'
            ]);
        });
    }
}
