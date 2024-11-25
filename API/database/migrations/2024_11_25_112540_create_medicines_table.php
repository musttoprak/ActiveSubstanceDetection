<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateMedicinesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('medicines', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('image_src')->nullable();
            $table->string('weight')->nullable();
            $table->string('molecular_weight')->nullable();
            $table->string('formula')->nullable();
            $table->string('related_atc_codes')->nullable();
            $table->string('cas')->nullable();
            $table->text('general_info')->nullable();
            $table->text('mechanism')->nullable();
            $table->text('pharmacokinetics')->nullable();
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
        Schema::dropIfExists('medicines');
    }
}
