<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddColumnsToIlaclarTable extends Migration
{
    public function up()
    {
        Schema::table('ilaclar', function (Blueprint $table) {
            // İlaç dosya adından kod bilgisi
            $table->unsignedInteger('ilac_kodu')->nullable();
            $table->unsignedInteger('ilac_kategori_id')->nullable();

            // ÖZET alanı için
            $table->string('ilac_adi_firma')->nullable();
            $table->decimal('perakende_satis_fiyati', 10, 2)->nullable();
            $table->decimal('depocu_satis_fiyati_kdv_dahil', 10, 2)->nullable();
            $table->decimal('depocu_satis_fiyati_kdv_haric', 10, 2)->nullable();
            $table->decimal('imalatci_satis_fiyati_kdv_haric', 10, 2)->nullable();
            $table->date('fiyat_tarihi')->nullable();

            // SUT ÖZET alanı için
            $table->string('sgk_durumu')->nullable();

            // Diğer bilgiler
            $table->json('fiyat_hareketleri')->nullable();
            $table->json('esdeger_ilaclar')->nullable();

            // İlacın formülasyonu ve diğer bilgiler
            $table->string('formulasyon')->nullable(); // örn: "tablet", "şurup", "ampul" vs.
            $table->string('ambalaj_bilgisi')->nullable(); // örn: "30 tablet", "100 ml şişe" vs.
            $table->string('recete_tipi')->nullable();
        });
    }

    public function down()
    {
        Schema::table('ilaclar', function (Blueprint $table) {
            $table->dropColumn([
                'ilac_kodu',
                'ilac_kategori_id',
                'ilac_adi_firma',
                'perakende_satis_fiyati',
                'depocu_satis_fiyati_kdv_dahil',
                'depocu_satis_fiyati_kdv_haric',
                'imalatci_satis_fiyati_kdv_haric',
                'fiyat_tarihi',
                'sgk_durumu',
                'fiyat_hareketleri',
                'esdeger_ilaclar',
                'formulasyon',
                'ambalaj_bilgisi',
                'recete_tipi'
            ]);
        });
    }
}
