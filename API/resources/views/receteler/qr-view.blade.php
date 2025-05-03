@extends('layouts.app')

@section('title', 'QR ile Reçete Görüntüleme')

@section('content')
    <div class="card">
        <div class="card-header bg-white">
            <h4 class="my-2">Reçete #{{ $recete->recete_no }}</h4>
        </div>
        <div class="card-body">
            <div class="alert alert-info">
                <i class="bi bi-info-circle"></i> Bu reçete QR kod ile görüntülenmektedir.
            </div>

            <div class="row mb-4">
                <div class="col-md-6">
                    <h5 class="text-muted mb-3">Hasta Bilgileri</h5>
                    <p><strong>Ad Soyad:</strong> {{ $recete->hasta->ad }} {{ $recete->hasta->soyad }}</p>
                    <p><strong>T.C. Kimlik:</strong> {{ $recete->hasta->tc_kimlik ?? 'Belirtilmemiş' }}</p>
                </div>
                <div class="col-md-6">
                    <h5 class="text-muted mb-3">Reçete Bilgileri</h5>
                    <p><strong>Hastalık:</strong> {{ $recete->hastalik->hastalik_adi }}</p>
                    <p><strong>Tarih:</strong> {{ date('d.m.Y', strtotime($recete->tarih)) }}</p>
                    <p><strong>Durum:</strong>
                        <span class="badge bg-{{ $recete->durum == 'Onaylandı' ? 'success' : ($recete->durum == 'İptal Edildi' ? 'danger' : 'warning') }}">
                        {{ $recete->durum }}
                    </span>
                    </p>
                </div>
            </div>

            @if($recete->notlar)
                <div class="mb-4">
                    <h5 class="text-muted mb-2">Notlar</h5>
                    <div class="p-3 bg-light rounded">{{ $recete->notlar }}</div>
                </div>
            @endif

            <h5 class="text-muted mb-3">İlaçlar</h5>
            <div class="table-responsive">
                <table class="table table-striped">
                    <thead>
                    <tr>
                        <th>İlaç Adı</th>
                        <th>Dozaj</th>
                        <th>Kullanım Talimatı</th>
                        <th>Miktar</th>
                    </tr>
                    </thead>
                    <tbody>
                    @foreach($recete->ilaclar as $receteIlac)
                        <tr>
                            <td>{{ $receteIlac->ilac->ilac_adi }}</td>
                            <td>{{ $receteIlac->dozaj ?? 'Belirtilmemiş' }}</td>
                            <td>{{ $receteIlac->kullanim_talimati ?? 'Belirtilmemiş' }}</td>
                            <td>{{ $receteIlac->miktar }}</td>
                        </tr>
                    @endforeach
                    </tbody>
                </table>
            </div>

            <div class="mt-4">
                <h5 class="text-muted mb-3">Etken Maddeler</h5>
                <div class="row">
                    @php $etkenMaddeler = []; @endphp
                    @foreach($recete->ilaclar as $receteIlac)
                        @if($receteIlac->ilac->etkenMaddeler)
                            @foreach($receteIlac->ilac->etkenMaddeler as $etkenMadde)
                                @php
                                    if (!in_array($etkenMadde->etken_madde_id, array_column($etkenMaddeler, 'id'))) {
                                        $etkenMaddeler[] = [
                                            'id' => $etkenMadde->etken_madde_id,
                                            'adi' => $etkenMadde->etken_madde_adi
                                        ];
                                    }
                                @endphp
                            @endforeach
                        @endif
                    @endforeach

                    @if(count($etkenMaddeler) > 0)
                        @foreach($etkenMaddeler as $etkenMadde)
                            <div class="col-md-4 mb-2">
                                <span class="badge bg-light text-dark p-2">{{ $etkenMadde['adi'] }}</span>
                            </div>
                        @endforeach
                    @else
                        <div class="col-12">
                            <p class="text-muted">Etken madde bilgisi bulunamadı.</p>
                        </div>
                    @endif
                </div>
            </div>

            <div class="mt-4 text-end">
                <button onclick="window.print()" class="btn btn-primary">
                    <i class="bi bi-printer"></i> Yazdır
                </button>
            </div>
        </div>
    </div>
@endsection

@section('styles')
    <style>
        @media print {
            .navbar, .text-end, .alert {
                display: none;
            }
            .card {
                border: none;
                box-shadow: none;
            }
        }
    </style>
@endsection
