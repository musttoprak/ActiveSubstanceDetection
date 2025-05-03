@extends('layouts.app')

@section('title', 'Yeni Reçete Oluştur')

@section('styles')
    <style>
        .ilac-item {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 15px;
            position: relative;
        }
        .remove-ilac {
            position: absolute;
            right: 10px;
            top: 10px;
            color: #dc3545;
            cursor: pointer;
        }
    </style>
@endsection

@section('content')
    <div class="card mb-4">
        <div class="card-header bg-white">
            <h4 class="my-2">Yeni Reçete Oluştur</h4>
        </div>
        <div class="card-body">
            <form action="{{ route('receteler.store') }}" method="POST" id="receteForm">
                @csrf

                <div class="row mb-3">
                    <div class="col-md-6">
                        <label for="hasta_id" class="form-label">Hasta</label>
                        <select name="hasta_id" id="hasta_id" class="form-select @error('hasta_id') is-invalid @enderror" required>
                            <option value="">Hasta Seçin</option>
                            @foreach($hastalar as $hasta)
                                <option value="{{ $hasta->hasta_id }}">{{ $hasta->ad }} {{ $hasta->soyad }} ({{ $hasta->tc_kimlik ?? 'TC Kimlik Yok' }})</option>
                            @endforeach
                        </select>
                        @error('hasta_id')
                        <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="col-md-6">
                        <label for="hastalik_id" class="form-label">Hastalık</label>
                        <select name="hastalik_id" id="hastalik_id" class="form-select @error('hastalik_id') is-invalid @enderror" required>
                            <option value="">Hastalık Seçin</option>
                            @foreach($hastaliklar as $hastalik)
                                <option value="{{ $hastalik->hastalik_id }}">{{ $hastalik->hastalik_adi }}</option>
                            @endforeach
                        </select>
                        @error('hastalik_id')
                        <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>
                </div>

                <div class="row mb-3">
                    <div class="col-md-6">
                        <label for="tarih" class="form-label">Tarih</label>
                        <input type="date" name="tarih" id="tarih" class="form-control @error('tarih') is-invalid @enderror" value="{{ date('Y-m-d') }}" required>
                        @error('tarih')
                        <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>
                </div>

                <div class="mb-3">
                    <label for="notlar" class="form-label">Notlar</label>
                    <textarea name="notlar" id="notlar" rows="3" class="form-control @error('notlar') is-invalid @enderror">{{ old('notlar') }}</textarea>
                    @error('notlar')
                    <div class="invalid-feedback">{{ $message }}</div>
                    @enderror
                </div>

                <h5 class="mt-4 mb-3">İlaçlar</h5>

                <div id="ilaclar-container">
                    <!-- İlaç öğeleri buraya eklenecek -->
                </div>

                <button type="button" id="add-ilac" class="btn btn-outline-primary mb-4">
                    <i class="bi bi-plus-circle"></i> İlaç Ekle
                </button>

                <div class="text-end">
                    <button type="submit" class="btn btn-primary px-4">Reçete Oluştur</button>
                </div>
            </form>
        </div>
    </div>

    <!-- İlaç şablonu (gizli) -->
    <div id="ilac-template" style="display: none;">
        <div class="ilac-item">
            <span class="remove-ilac">&times;</span>
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">İlaç</label>
                    <select name="ilaclar[INDEX][ilac_id]" class="form-select ilac-select" required>
                        <option value="">İlaç Seçin</option>
                        @foreach($ilaclar as $ilac)
                            <option value="{{ $ilac->ilac_id }}">{{ $ilac->ilac_adi }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Miktar</label>
                    <input type="number" name="ilaclar[INDEX][miktar]" class="form-control" value="1" min="1" required>
                </div>
            </div>
            <div class="row">
                <div class="col-md-6 mb-3">
                    <label class="form-label">Dozaj</label>
                    <input type="text" name="ilaclar[INDEX][dozaj]" class="form-control" placeholder="Örn: Günde 2 kez 1 tablet">
                </div>
                <div class="col-md-6 mb-3">
                    <label class="form-label">Kullanım Talimatı</label>
                    <input type="text" name="ilaclar[INDEX][kullanim_talimati]" class="form-control" placeholder="Örn: Yemeklerden sonra">
                </div>
            </div>
        </div>
    </div>
@endsection

@section('scripts')
    <script>
        $(document).ready(function() {
            // İlaç ekleme fonksiyonu
            let ilacIndex = 0;

            function addIlac() {
                let template = $('#ilac-template').html();
                template = template.replace(/INDEX/g, ilacIndex);

                $('#ilaclar-container').append(template);
                ilacIndex++;
            }

            // İlk ilaç öğesini ekle
            addIlac();

            // "İlaç Ekle" butonuna tıklandığında yeni ilaç öğesi ekle
            $('#add-ilac').click(function() {
                addIlac();
            });

            // İlaç silme işlemi (delegasyon ile)
            $('#ilaclar-container').on('click', '.remove-ilac', function() {
                // En az bir ilaç öğesi kalmalı
                if ($('.ilac-item').length > 1) {
                    $(this).closest('.ilac-item').remove();
                } else {
                    alert('En az bir ilaç eklemelisiniz.');
                }
            });

            // Form gönderimi öncesi kontrol
            $('#receteForm').submit(function(e) {
                if ($('.ilac-item').length === 0) {
                    e.preventDefault();
                    alert('En az bir ilaç eklemelisiniz.');
                }
            });
        });
    </script>
@endsection
