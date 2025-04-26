// database/migrations/2025_04_22_create_receteler_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('receteler', function (Blueprint $table) {
            $table->id('recete_id');
            $table->foreignId('hasta_id')->constrained('hastalar', 'hasta_id');
            $table->foreignId('hastalik_id')->constrained('hastaliklar', 'hastalik_id');
            $table->string('recete_no')->unique();
            $table->date('tarih');
            $table->text('notlar')->nullable();
            $table->enum('durum', ['Onaylandı', 'Beklemede', 'İptal Edildi'])->default('Beklemede');
            $table->boolean('aktif')->default(true);
            $table->timestamps();
        });

        Schema::create('recete_ilaclar', function (Blueprint $table) {
            $table->id('recete_ilac_id');
            $table->foreignId('recete_id')->constrained('receteler', 'recete_id')->onDelete('cascade');
            $table->foreignId('ilac_id')->constrained('ilaclar', 'ilac_id');
            $table->string('dozaj')->nullable();
            $table->string('kullanim_talimati')->nullable();
            $table->integer('miktar')->default(1);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('recete_ilaclar');
        Schema::dropIfExists('receteler');
    }
};
