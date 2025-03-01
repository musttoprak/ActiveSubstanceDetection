<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreatePriceMovementsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('price_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('medicine_id')->constrained('medicines')->onDelete('cascade');
            $table->date('date')->nullable();
            $table->string('transaction_type')->nullable();
            $table->decimal('isf', 8, 2)->nullable();
            $table->decimal('dsf', 8, 2)->nullable();
            $table->decimal('psf', 8, 2)->nullable();
            $table->decimal('kf', 8, 2)->nullable();
            $table->decimal('ko', 8, 2)->nullable();
            $table->timestamps();
        });
    }


    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('price_movements');
    }
}
