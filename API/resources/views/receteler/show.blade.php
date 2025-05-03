@extends('layouts.app')

@section('title', 'Reçete Detayı')

@section('content')
    <div class="row">
        <div class="col-md-8">
            <div class="card mb-4">
                <div class="card-header bg-white d-flex justify-content-between align-items-center">
                    <h4 class="my-2">Reçete #{{ $recete->recete_no }}</h4>
                    <span class="badge bg-{{ $recete->durum == 'Onaylandı' ? 'success' : ($recete->durum == 'İptal Edildi' ? 'danger' : 'warning') }}">
                    {{ $recete->durum }}
                </span>
                </div>
                <div class="card-body">
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <h5 class="text-muted mb-3">Hasta Bilgileri</h5>
                            <p><strong>Ad Soyad:</strong> {{ $recete->hasta->ad }} {{ $recete->hasta->soyad }}</p>
                            <p><strong>T.C. Kimlik:</strong> {{ $recete->hasta->tc_kimlik ?? 'Belirtilmemiş' }}</p>
                            <p><strong>Telefon:</strong> {{ $recete->hasta->telefon ?? 'Belirtilmemiş' }}</p>
                        </div>
                        <div class="col-md-6">
                            <h5 class="text-muted mb-3">Reçete Bilgileri</h5>
                            <p><strong>Hastalık:</strong> {{ $recete->hastalik->hastalik_adi }}</p>
                            <p><strong>Tarih:</strong> {{ date('d.m.Y', strtotime($recete->tarih)) }}</p>
                            <p><strong>Doktor:</strong> {{ $recete->doktor->ad ?? 'Belirtilmemiş' }} {{ $recete->doktor->soyad ?? '' }}</p>
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

                    <div class="mt-4 text-end">
                        <a href="{{ route('receteler.index') }}" class="btn btn-secondary">Reçete Listesine Dön</a>
                        <a href="{{ route('receteler.create') }}" class="btn btn-primary">Yeni Reçete Oluştur</a>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-md-4">
            <div class="card">
                <div class="card-header bg-white">
                    <h5 class="my-2">QR Kod</h5>
                </div>
                <div class="card-body text-center">
                    <div class="my-3">
                        {!! $qrCode !!}
                    </div>
                    <p class="text-muted">Bu QR kodu tarayarak reçeteye erişebilirsiniz.</p>
                    <div class="d-grid gap-2">
                        <button class="btn btn-outline-primary" id="printQr">QR Kodu Yazdır</button>
                        <a href="{{ route('receteler.qr', ['receteNo' => $recete->recete_no]) }}" class="btn btn-outline-secondary" target="_blank">
                            QR Sayfasını Aç
                        </a>
                    </div>
                </div>
            </div>
        </div>

        <!-- Hasta-Hastalık-İlaç İlişkisi Analizi -->
        <div class="card mt-4">
            <div class="card-header bg-white">
                <h4 class="my-2">Demografik ve Hastalık Tabanlı Analiz</h4>
            </div>
            <div class="card-body">
                <!-- Hasta Demografik Bilgileri -->
                <div class="row mb-4">
                    <div class="col-md-6">
                        <h5 class="text-muted mb-3">Hasta Demografik Bilgileri</h5>
                        <div class="table-responsive">
                            <table class="table table-bordered">
                                <tr>
                                    <th class="bg-light">Ad Soyad</th>
                                    <td>{{ $recete->hasta->ad }} {{ $recete->hasta->soyad }}</td>
                                </tr>
                                <tr>
                                    <th class="bg-light">Yaş</th>
                                    <td>{{ $recete->hasta->yas ?? 'Belirtilmemiş' }}</td>
                                </tr>
                                <tr>
                                    <th class="bg-light">Cinsiyet</th>
                                    <td>{{ $recete->hasta->cinsiyet ?? 'Belirtilmemiş' }}</td>
                                </tr>
                                @if(isset($recete->hasta->boy) && isset($recete->hasta->kilo))
                                    <tr>
                                        <th class="bg-light">Boy / Kilo</th>
                                        <td>{{ $recete->hasta->boy }} cm / {{ $recete->hasta->kilo }} kg</td>
                                    </tr>
                                @endif
                                @if(isset($recete->hasta->vki))
                                    <tr>
                                        <th class="bg-light">VKİ</th>
                                        <td>{{ number_format($recete->hasta->vki, 1) }} kg/m²</td>
                                    </tr>
                                @endif
                            </table>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <h5 class="text-muted mb-3">Hastalık Bilgileri</h5>
                        <div class="table-responsive">
                            <table class="table table-bordered">
                                <tr>
                                    <th class="bg-light">Hastalık</th>
                                    <td>{{ $recete->hastalik->hastalik_adi }}</td>
                                </tr>
                                @if(isset($recete->hastalik->hastalik_kategorisi))
                                    <tr>
                                        <th class="bg-light">Kategori</th>
                                        <td>{{ $recete->hastalik->hastalik_kategorisi }}</td>
                                    </tr>
                                @endif
                                @if(isset($recete->hastalik->onem_derecesi))
                                    <tr>
                                        <th class="bg-light">Önem Derecesi</th>
                                        <td>{{ $recete->hastalik->onem_derecesi }}</td>
                                    </tr>
                                @endif
                                <tr>
                                    <th class="bg-light">Reçete Tarihi</th>
                                    <td>{{ date('d.m.Y', strtotime($recete->tarih)) }}</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Mevcut İlaçlar ve Etken Madde Eşleşmeleri -->
        <div class="card mt-4">
            <div class="card-header bg-white">
                <h4 class="my-2">Mevcut İlaçlar ve Etken Madde Analizi</h4>
            </div>
            <div class="card-body">
                <div class="card-header bg-white">
                    <h5 class="my-2">Reçetedeki İlaçların Etken Maddeleri</h5>
                </div>
                <div class="table-responsive">
                    <table class="table table-bordered">
                        <thead>
                        <tr>
                            <th>İlaç</th>
                            @foreach($etkenMaddeler as $etkenMadde)
                                <th class="text-center">{{ $etkenMadde['adi'] }}</th>
                            @endforeach
                        </tr>
                        </thead>
                        <tbody>
                        @foreach($recete->ilaclar as $receteIlac)
                            <tr>
                                <td>{{ $receteIlac->ilac->ilac_adi }}</td>
                                @foreach($etkenMaddeler as $etkenMadde)
                                    @php
                                        $ilacEtkenMaddeleri = $receteIlac->ilac->etkenMaddeler->pluck('etken_madde_id')->toArray();
                                        $match = in_array($etkenMadde['id'], $ilacEtkenMaddeleri);
                                    @endphp
                                    <td class="text-center">
                                        @if($match)
                                            <span class="badge bg-primary">✓</span>
                                        @else
                                            <span class="badge bg-light text-dark">-</span>
                                        @endif
                                    </td>
                                @endforeach
                            </tr>
                        @endforeach
                        </tbody>
                    </table>
                </div>

                <!-- Etken Madde Eşleşme Analizi -->
                <div class="card-header bg-white">
                    <h5 class="my-2">Etken Madde Eşleşme Analizi</h5>
                </div>
                <div class="card-body">
                    <div class="alert alert-info">
                        <i class="bi bi-info-circle me-2"></i> Bu bölüm, önerilen ilaçların etken maddelerinin mevcut reçetedeki ilaçların etken maddeleriyle nasıl eşleştiğini gösterir.
                    </div>

                    <div class="table-responsive">
                        <table class="table table-bordered">
                            <thead>
                            <tr>
                                <th>Önerilen İlaç</th>
                                <th>Etken Maddeler</th>
                                <th>Mevcut Reçetede Eşleşen Etken Maddeler</th>
                                <th>Eşleşme Oranı</th>
                            </tr>
                            </thead>
                            <tbody>
                            @foreach($oneriler as $oneri)
                                @php
                                    // Önerilen ilacın etken maddeleri
                                    $oneriEtkenMaddeler = $oneri->ilac->etkenMaddeler->pluck('etken_madde_id')->toArray();
                                    $oneriEtkenMaddeAdlari = [];
                                    foreach($oneri->ilac->etkenMaddeler as $etkenMadde) {
                                        $oneriEtkenMaddeAdlari[] = $etkenMadde->etken_madde_adi;
                                    }

                                    // Mevcut reçetedeki etken maddeler
                                    $receteEtkenMaddeler = [];
                                    $receteEtkenMaddeAdlari = [];
                                    foreach($recete->ilaclar as $receteIlac) {
                                        if ($receteIlac->ilac && $receteIlac->ilac->etkenMaddeler) {
                                            foreach($receteIlac->ilac->etkenMaddeler as $etkenMadde) {
                                                $receteEtkenMaddeler[] = $etkenMadde->etken_madde_id;
                                                $receteEtkenMaddeAdlari[$etkenMadde->etken_madde_id] = $etkenMadde->etken_madde_adi;
                                            }
                                        }
                                    }

                                    // Benzersiz değerleri al
                                    $receteEtkenMaddeler = array_unique($receteEtkenMaddeler);

                                    // Eşleşenleri bul
                                    $kesisim = array_intersect($oneriEtkenMaddeler, $receteEtkenMaddeler);
                                    $birlesim = array_unique(array_merge($oneriEtkenMaddeler, $receteEtkenMaddeler));

                                    // Eşleşme oranı (Jaccard benzerliği)
                                    $eslesmeOrani = count($birlesim) > 0 ? (count($kesisim) / count($birlesim)) * 100 : 0;

                                    // Eşleşen etken madde adları
                                    $eslesenEtkenMaddeAdlari = [];
                                    foreach($kesisim as $etkenMaddeId) {
                                        $eslesenEtkenMaddeAdlari[] = $receteEtkenMaddeAdlari[$etkenMaddeId] ?? "Etken Madde #$etkenMaddeId";
                                    }
                                @endphp

                                <tr>
                                    <td>{{ $oneri->ilac->ilac_adi }}</td>
                                    <td>
                                        @if(count($oneriEtkenMaddeAdlari) > 0)
                                            @foreach($oneriEtkenMaddeAdlari as $adi)
                                                <span class="badge bg-secondary me-1 mb-1">{{ $adi }}</span>
                                            @endforeach
                                        @else
                                            <em class="text-muted">Etken madde bilgisi bulunamadı</em>
                                        @endif
                                    </td>
                                    <td>
                                        @if(count($eslesenEtkenMaddeAdlari) > 0)
                                            @foreach($eslesenEtkenMaddeAdlari as $adi)
                                                <span class="badge bg-success me-1 mb-1">{{ $adi }}</span>
                                            @endforeach
                                        @else
                                            <em class="text-muted">Eşleşme yok</em>
                                        @endif
                                    </td>
                                    <td class="text-center">
                                        <h5 class="{{ $eslesmeOrani > 0 ? ($eslesmeOrani >= 50 ? 'text-success' : 'text-warning') : 'text-danger' }}">
                                            {{ number_format($eslesmeOrani, 1) }}%
                                        </h5>
                                        @if($eslesmeOrani == 0)
                                            <small class="text-danger">Etken madde eşleşmesi yok!</small>
                                        @endif
                                    </td>
                                </tr>
                            @endforeach
                            </tbody>
                        </table>
                    </div>

                    <!-- Etken madde eşleşmesi yoksa uyarı -->
                    @if(count($oneriler) > 0)
                        @php
                            $tumEslesmeleriSifir = true;
                            foreach($oneriler as $oneri) {
                                $oneriEtkenMaddeler = $oneri->ilac->etkenMaddeler->pluck('etken_madde_id')->toArray();
                                $receteEtkenMaddeler = [];
                                foreach($recete->ilaclar as $receteIlac) {
                                    if ($receteIlac->ilac && $receteIlac->ilac->etkenMaddeler) {
                                        foreach($receteIlac->ilac->etkenMaddeler as $etkenMadde) {
                                            $receteEtkenMaddeler[] = $etkenMadde->etken_madde_id;
                                        }
                                    }
                                }
                                $receteEtkenMaddeler = array_unique($receteEtkenMaddeler);
                                $kesisim = array_intersect($oneriEtkenMaddeler, $receteEtkenMaddeler);
                                if(count($kesisim) > 0) {
                                    $tumEslesmeleriSifir = false;
                                    break;
                                }
                            }
                        @endphp

                        @if($tumEslesmeleriSifir)
                            <div class="alert alert-warning mt-3">
                                <i class="bi bi-exclamation-triangle me-2"></i>
                                <strong>Dikkat:</strong> Önerilen ilaçların hiçbiri mevcut reçetedeki ilaçların etken maddeleriyle eşleşmiyor!
                                <div class="mt-2">
                                    Bu durum aşağıdaki nedenlerden kaynaklanabilir:
                                    <ul class="mb-0 mt-1">
                                        <li>Farklı tedavi yaklaşımı öneriliyor olabilir</li>
                                        <li>Öneriler hastalık-ilaç ilişkisine veya hasta demografik özelliklerine göre yapılmış olabilir</li>
                                        <li>Veritabanında etken madde bilgileri eksik olabilir</li>
                                    </ul>
                                </div>
                            </div>
                        @endif
                    @endif
                </div>

                <!-- Uyumluluk Tablosu -->
                <div class="card-header bg-white">
                    <h5 class="my-2">Etken Madde Uyumluluğu</h5>
                </div>
                <div class="table-responsive mb-4">
                    <table class="table table-bordered">
                        <thead>
                        <tr>
                            <th>İlaç</th>
                            @foreach($etkenMaddeler as $etkenMadde)
                                <th class="text-center">{{ $etkenMadde['adi'] }}</th>
                            @endforeach
                            <th class="text-center">Uyumluluk Puanı</th>
                            <th></th>
                        </tr>
                        </thead>
                        <tbody>
                        @foreach($oneriler as $oneri)
                            <tr>
                                <td>{{ $oneri->ilac->ilac_adi }}</td>
                                @foreach($etkenMaddeler as $etkenMadde)
                                    @php
                                        $ilacEtkenMaddeleri = $oneri->ilac->etkenMaddeler->pluck('etken_madde_id')->toArray();
                                        $match = in_array($etkenMadde['id'], $ilacEtkenMaddeleri);
                                    @endphp
                                    <td class="text-center">
                                        @if($match)
                                            <span class="badge bg-success">✓</span>
                                        @else
                                            <span class="badge bg-light text-dark">-</span>
                                        @endif
                                    </td>
                                @endforeach
                                <td class="text-center">
                                    <div class="d-flex align-items-center">
                                        <div class="progress flex-grow-1" style="height: 10px;">
                                            <div class="progress-bar bg-{{ $oneri->oneri_puani >= 70 ? 'success' : ($oneri->oneri_puani >= 40 ? 'warning' : 'danger') }}"
                                                 role="progressbar"
                                                 style="width: {{ min($oneri->oneri_puani, 100) }}%;">
                                            </div>
                                        </div>
                                        <span class="ms-2">{{ number_format($oneri->oneri_puani, 1) }}%</span>
                                    </div>
                                </td>
                                <td class="text-center">
                                    <form action="{{ route('receteler.add-suggestion', ['receteId' => $recete->recete_id, 'oneriId' => $oneri->oneri_id]) }}" method="POST">
                                        @csrf
                                        <input type="hidden" name="dozaj" value="">
                                        <input type="hidden" name="kullanim_talimati" value="">
                                        <input type="hidden" name="miktar" value="1">
                                        <button type="submit" class="btn btn-sm {{ $oneri->uygulanma_durumu ? 'btn-success disabled' : 'btn-outline-primary' }}">
                                            {{ $oneri->uygulanma_durumu ? 'Eklendi' : 'Reçeteye Ekle' }}
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        @endforeach
                        </tbody>
                    </table>
                </div>

                <!-- Veri Kalitesi Kontrolü -->
                @php
                    $etkenMaddeVerisiEksik = true;
                    foreach($recete->ilaclar as $receteIlac) {
                        if ($receteIlac->ilac && $receteIlac->ilac->etkenMaddeler && $receteIlac->ilac->etkenMaddeler->count() > 0) {
                            $etkenMaddeVerisiEksik = false;
                            break;
                        }
                    }
                @endphp

                @if($etkenMaddeVerisiEksik)
                    <div class="alert alert-danger mt-4">
                        <i class="bi bi-exclamation-triangle-fill me-2"></i>
                        <strong>Veri Eksikliği Uyarısı:</strong> Reçetedeki ilaçların etken madde bilgileri eksik veya bulunamıyor!
                        <div class="mt-2">
                            <p class="mb-1">Bu durum, ML modelinin etken madde analizi yapamamasına ve önerilerin sadece hastalık-ilaç ilişkisi ve demografik özelliklere dayanmasına neden olacaktır.</p>
                            <p class="mb-0">Daha doğru öneriler için, lütfen ilaç veritabanındaki etken madde bilgilerini güncelleyin.</p>
                        </div>
                    </div>
                @endif


                <!-- İlaç-Hastalık Uyumluluk Açıklaması -->
                <div class="card-header bg-white">
                    <h5 class="my-2">Öneri Detayları</h5>
                </div>
                <div class="row">
                    @foreach($oneriler as $oneri)
                        <div class="col-md-6 mb-3">
                            <div class="card h-100">
                                <div class="card-body">
                                    <h6 class="card-title">
                                        {{ $oneri->ilac->ilac_adi }}
                                        <span class="float-end badge bg-{{ $oneri->oneri_puani >= 70 ? 'success' : ($oneri->oneri_puani >= 40 ? 'warning' : 'danger') }}">
                                                {{ number_format($oneri->oneri_puani, 1) }}%
                                            </span>
                                    </h6>
                                    <div class="small text-muted mb-2">
                                        <strong>Öneri nedeni:</strong>
                                        @if($oneri->oneri_puani >= 80)
                                            Bu ilaç, hastalık ve etken madde uyumluluğu açısından yüksek puan almıştır.
                                        @elseif($oneri->oneri_puani >= 60)
                                            Bu ilaç, benzer etken maddelere sahip olduğu için önerilmiştir.
                                        @else
                                            Bu ilaç, alternatif tedavi seçeneği olarak önerilmiştir.
                                        @endif
                                    </div>
                                    <div>
                                        <strong>Etken Maddeler:</strong>
                                        @if($oneri->ilac->etkenMaddeler->count() > 0)
                                            @foreach($oneri->ilac->etkenMaddeler as $etkenMadde)
                                                <span class="badge bg-light text-dark me-1">{{ $etkenMadde->etken_madde_adi }}</span>
                                            @endforeach
                                        @else
                                            <span class="text-muted">Bilgi yok</span>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        </div>
                    @endforeach
                </div>

            </div>
        </div>

        <!-- Öneri Modeli Açıklaması -->
        <div class="card mt-4">
            <div class="card-header bg-white">
                <h5 class="my-2">ML Modeli Öneri Faktörleri</h5>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-lg-4">
                        <div class="card h-100">
                            <div class="card-body text-center">
                                <div class="display-4 text-primary mb-2">50%</div>
                                <h5 class="card-title">Etken Madde Analizi</h5>
                                <p class="card-text">Reçetedeki mevcut ilaçların etken maddeleriyle benzerlik değerlendirilir.</p>
                                <div class="text-center mt-3">
                                    <i class="bi bi-capsule fs-1 text-primary"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="card h-100">
                            <div class="card-body text-center">
                                <div class="display-4 text-success mb-2">30%</div>
                                <h5 class="card-title">Hastalık-İlaç İlişkisi</h5>
                                <p class="card-text">Belirli hastalıklar için ilaç kullanım sıklıkları göz önünde bulundurulur.</p>
                                <div class="text-center mt-3">
                                    <i class="bi bi-clipboard2-pulse fs-1 text-success"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-4">
                        <div class="card h-100">
                            <div class="card-body text-center">
                                <div class="display-4 text-info mb-2">20%</div>
                                <h5 class="card-title">Hasta Demografik Özellikleri</h5>
                                <p class="card-text">Hastanın yaşı, cinsiyeti ve vücut kitle indeksi gibi faktörler değerlendirilir.</p>
                                <div class="text-center mt-3">
                                    <i class="bi bi-person-vcard fs-1 text-info"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="alert alert-light border mt-4">
                    <h6 class="mb-3">ML Modeli Nasıl Çalışır?</h6>
                    <p>Hibrit öneri sistemi, üç farklı faktörü ağırlıklı olarak değerlendirir ve bu faktörlerin ağırlıklı ortalamasını alarak nihai öneri puanını hesaplar.</p>

                    <ol>
                        <li class="mb-2">
                            <strong>Etken Madde Analizi (%50):</strong>
                            <ul>
                                <li>Önerilen ilacın etken maddeleri ile mevcut reçetedeki ilaçların etken maddeleri karşılaştırılır</li>
                                <li>Jaccard benzerlik metriği kullanılarak etken madde eşleşme oranı hesaplanır</li>
                                <li>Formül: (Kesişim Etken Madde Sayısı / Birleşim Etken Madde Sayısı) * 100</li>
                            </ul>
                        </li>
                        <li class="mb-2">
                            <strong>Hastalık-İlaç İlişkisi (%30):</strong>
                            <ul>
                                <li>Belirli bir hastalık için hangi ilaçların ne sıklıkla reçete edildiği analiz edilir</li>
                                <li>Geçmiş reçete verileri kullanılarak hastalık-ilaç ilişki matrisi oluşturulur</li>
                                <li>Bu ilişki matrisi kullanılarak hastalığa uygun ilaçlar belirlenir</li>
                            </ul>
                        </li>
                        <li class="mb-2">
                            <strong>Hasta Demografik Özellikleri (%20):</strong>
                            <ul>
                                <li>Hastanın yaş, cinsiyet, VKİ gibi demografik özellikleri dikkate alınır</li>
                                <li>Benzer demografik özelliklere sahip hastalara hangi ilaçların daha uygun olduğu belirlenir</li>
                                <li>Yaş grupları ve cinsiyete göre ilaç uyumluluğu değerlendirilir</li>
                            </ul>
                        </li>
                    </ol>

                    <div class="bg-light p-3 rounded">
                        <strong>Nihai Öneri Puanı Hesaplaması:</strong>
                        <p class="mb-0">Öneri Puanı = (Etken Madde Skoru * 0.5) + (Hastalık-İlaç Skoru * 0.3) + (Demografik Uyum Skoru * 0.2)</p>
                    </div>
                </div>
            </div>

            <div class="card-header bg-white">
                <h5 class="my-2">Öneri Sistemi Nasıl Çalışır?</h5>
            </div>
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col-md-4 text-center">
                        <div style="max-width: 200px; margin: 0 auto;">
                            <svg width="100%" height="100%" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
                                <circle cx="100" cy="100" r="80" fill="#f8f9fa" stroke="#dee2e6" stroke-width="2"/>
                                <path d="M100,20 A80,80 0 0,1 169.3,130" fill="none" stroke="#4361ee" stroke-width="40" stroke-dasharray="208" stroke-dashoffset="0"/>
                                <path d="M169.3,130 A80,80 0 0,1 30.7,130" fill="none" stroke="#2ecc71" stroke-width="40" stroke-dasharray="208" stroke-dashoffset="0"/>
                                <path d="M30.7,130 A80,80 0 0,1 100,20" fill="none" stroke="#3498db" stroke-width="40" stroke-dasharray="208" stroke-dashoffset="0"/>
                                <circle cx="100" cy="100" r="40" fill="white"/>
                                <text x="100" y="105" font-family="Arial" font-size="12" text-anchor="middle">ML Model</text>
                            </svg>
                        </div>
                    </div>
                    <div class="col-md-8">
                        <h6>Hibrit Öneri Sistemi</h6>
                        <p>Öneriler, üç farklı faktörü dikkate alan gelişmiş bir hibrit model tarafından oluşturulur:</p>

                        <div class="mb-2">
                            <strong>1. Etken Madde Analizi (Ağırlık: %50)</strong>
                            <div class="progress mb-1" style="height: 8px;">
                                <div class="progress-bar bg-primary" role="progressbar" style="width: 50%"></div>
                            </div>
                            <small class="text-muted">Reçetedeki mevcut ilaçların etken maddeleriyle benzerlik</small>
                        </div>

                        <div class="mb-2">
                            <strong>2. Hastalık-İlaç İlişkisi (Ağırlık: %30)</strong>
                            <div class="progress mb-1" style="height: 8px;">
                                <div class="progress-bar bg-success" role="progressbar" style="width: 30%"></div>
                            </div>
                            <small class="text-muted">Belirli hastalıklar için ilaç kullanım sıklıkları</small>
                        </div>

                        <div class="mb-2">
                            <strong>3. Hasta Demografik Özellikleri (Ağırlık: %20)</strong>
                            <div class="progress mb-1" style="height: 8px;">
                                <div class="progress-bar bg-info" role="progressbar" style="width: 20%"></div>
                            </div>
                            <small class="text-muted">Hastanın yaşı, cinsiyeti ve vücut kitle indeksi dikkate alınır</small>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
@endsection

@section('scripts')
    <script>
        // QR kodu yazdırma
        document.getElementById('printQr').addEventListener('click', function() {
            let printWindow = window.open('', '_blank');
            printWindow.document.write('<html><head><title>Reçete QR Kodu</title>');
            printWindow.document.write('<style>body { text-align: center; padding: 50px; }</style>');
            printWindow.document.write('</head><body>');
            printWindow.document.write('<h2>Reçete #{{ $recete->recete_no }}</h2>');
            printWindow.document.write('<div style="margin: 30px auto;">');
            printWindow.document.write('{!! $qrCode !!}');
            printWindow.document.write('</div>');
            printWindow.document.write('<p>{{ $recete->hasta->ad }} {{ $recete->hasta->soyad }} - {{ date("d.m.Y", strtotime($recete->tarih)) }}</p>');
            printWindow.document.write('</body></html>');
            printWindow.document.close();
            printWindow.print();
        });
    </script>
@endsection
