<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class UpdateMedicinesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('medicines', function (Blueprint $table) {
            $table->string('company')->nullable();
            $table->string('barcode')->nullable();
            $table->string('prescription_type')->nullable();
            $table->decimal('retail_price', 8, 2)->nullable();
            $table->decimal('depot_price_with_vat', 8, 2)->nullable();
            $table->decimal('depot_price_without_vat', 8, 2)->nullable();
            $table->decimal('manufacturer_price_without_vat', 8, 2)->nullable();
            $table->string('vat_info')->nullable();
            $table->string('price_date')->nullable();
            $table->string('active_substance')->nullable();
            $table->string('dosage')->nullable();
            $table->string('sgk_status')->nullable();
        });
    }
    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        //
    }
}
