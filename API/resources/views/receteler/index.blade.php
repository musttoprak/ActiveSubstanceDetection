@extends('layouts.app')

@section('title', 'Reçete Listesi')

@section('content')
    <div class="card">
        <div class="card-header bg-white d-flex justify-content-between align-items-center">
            <h4 class="my-2">Reçete Listesi</h4>
            <a href="{{ route('receteler.create') }}" class="btn btn-primary">
                <i class="bi bi-plus-circle"></i> Yeni Reçete
            </a>
        </div>
        <div class="card-body">
            @if($receteler->isEmpty())
                <div class="alert alert-info">
                    Henüz reçete bulunmuyor. Yeni bir reçete oluşturmak için "Yeni Reçete" butonunu kullanabilirsiniz.
                </div>
            @else
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                        <tr>
                            <th>Reçete No</th>
                            <th>Hasta</th>
                            <th>Hastalık</th>
                            <th>Tarih</th>
                            <th>Durum</th>
                            <th>İşlemler</th>
                        </tr>
                        </thead>
                        <tbody>
                        @foreach($receteler as $recete)
                            <tr>
                                <td>{{ $recete->recete_no }}</td>
                                <td>{{ $recete->hasta->ad }} {{ $recete->hasta->soyad }}</td>
                                <td>{{ $recete->hastalik->hastalik_adi }}</td>
                                <td>{{ date('d.m.Y', strtotime($recete->tarih)) }}</td>
                                <td>
                                    <span
                                        class="badge bg-{{ $recete->durum == 'Onaylandı' ? 'success' : ($recete->durum == 'İptal Edildi' ? 'danger' : 'warning') }}">
                                        {{ $recete->durum }}
                                    </span>
                                </td>
                                <td>
                                    <a href="{{ route('receteler.show', ['receteId' => $recete->recete_id]) }}"
                                       class="btn btn-sm btn-outline-primary me-1" title="Detay">
                                        <i class="bi bi-list-ul"></i>
                                    </a>
                                    <a href="{{ route('receteler.qr', ['receteNo' => $recete->recete_no]) }}"
                                       class="btn btn-sm btn-outline-success me-1" title="QR Görüntüle">
                                        <i class="bi bi-qr-code"></i>
                                    </a>
                                    <button type="button" class="btn btn-sm btn-outline-secondary btn-print-qr"
                                            data-recete-no="{{ $recete->recete_no }}"
                                            data-hasta="{{ $recete->hasta->ad }} {{ $recete->hasta->soyad }}"
                                            data-tarih="{{ date('d.m.Y', strtotime($recete->tarih)) }}"
                                            title="QR Yazdır">
                                        <i class="bi bi-printer"></i>
                                    </button>
                                </td>
                            </tr>
                        @endforeach
                        </tbody>
                    </table>
                </div>

                <div class="mt-4 d-flex justify-content-center">
                    {{ $receteler->links() }}
                </div>
            @endif
        </div>
    </div>

    <!-- QR Yazdırma için Modal -->
    <div class="modal fade" id="qrModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">QR Kodu Yazdır</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Kapat"></button>
                </div>
                <div class="modal-body text-center">
                    <div id="qrCodeContainer"></div>
                    <p class="mt-3">Bu QR kodu tarayarak reçeteye erişebilirsiniz.</p>
                    <p id="receteDetails" class="text-muted"></p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button>
                    <button type="button" class="btn btn-primary" id="printQrBtn">Yazdır</button>
                </div>
            </div>
        </div>
    </div>
@endsection

@section('scripts')
    <script src="https://cdn.jsdelivr.net/npm/qrious@4.0.2/dist/qrious.min.js"></script>
    <script>
        $(document).ready(function () {
            let modal = new bootstrap.Modal(document.getElementById('qrModal'));
            let qrCode;

            $('.btn-print-qr').click(function () {
                let receteNo = $(this).data('recete-no');
                let hasta = $(this).data('hasta');
                let tarih = $(this).data('tarih');
                let qrUrl = receteNo;

                // QR container'ı temizle
                $('#qrCodeContainer').empty();

                // Yeni canvas oluştur
                let canvas = document.createElement('canvas');
                canvas.id = 'qrCanvas';
                $('#qrCodeContainer').append(canvas);

                // QR kodu oluştur
                qrCode = new QRious({
                    element: document.getElementById('qrCanvas'),
                    value: qrUrl,
                    size: 250
                });

                // Reçete detaylarını göster
                $('#receteDetails').text(hasta + ' - ' + tarih);

                // Modal'ı göster
                modal.show();
            });

            // QR kodunu yazdır
            $('#printQrBtn').click(function () {
                let printWindow = window.open('', '_blank');
                let receteDetails = $('#receteDetails').text();

                printWindow.document.write('<html><head><title>Reçete QR Kodu</title>');
                printWindow.document.write('<style>body { text-align: center; padding: 50px; }</style>');
                printWindow.document.write('</head><body>');
                printWindow.document.write('<h2>Reçete QR Kodu</h2>');
                printWindow.document.write('<div style="margin: 30px auto;">');
                printWindow.document.write('<img src="' + qrCode.toDataURL() + '" />');
                printWindow.document.write('</div>');
                printWindow.document.write('<p>' + receteDetails + '</p>');
                printWindow.document.write('</body></html>');
                printWindow.document.close();
                printWindow.print();
            });
        });
    </script>
@endsection

@section('styles')
    <style>
        /* Pagination stilleri */
        .pagination {
            display: flex;
            padding-left: 0;
            list-style: none;
            margin: 1rem 0;
        }

        .pagination .page-item {
            margin: 0 2px;
        }

        .pagination .page-item .page-link {
            padding: 8px 16px;
            color: #4361ee;
            background-color: #fff;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            transition: all 0.2s ease;
        }

        .pagination .page-item.active .page-link {
            background-color: #4361ee;
            border-color: #4361ee;
            color: white;
        }

        .pagination .page-item .page-link:hover {
            background-color: #e9ecef;
            border-color: #dee2e6;
            color: #0056b3;
        }

        .pagination .page-item.disabled .page-link {
            color: #6c757d;
            pointer-events: none;
            background-color: #fff;
            border-color: #dee2e6;
        }
    </style>
@endsection
