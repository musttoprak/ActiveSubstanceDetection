<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class PopulateMissingMedicineData extends Migration
{
    public function up()
    {
        // 1. uretici_firma alanını ilac_adi_firma'dan çıkart
        DB::statement("
            UPDATE ilaclar
            SET uretici_firma = SUBSTRING_INDEX(ilac_adi_firma, '-', -1)
            WHERE ilac_adi_firma IS NOT NULL AND ilac_adi_firma != '' AND (uretici_firma IS NULL OR uretici_firma = '')
        ");

        // 2. ATC kodlarını etken maddelerden al ve ekle
        $this->populateAtcCodes();

        // 3. İlaç adından formulasyon ve ambalaj bilgilerini çıkart
        $this->extractFormulationAndPackagingInfo();

        // 4. Etki mekanizması ve diğer farmakolojik bilgileri ekle
        $this->addPharmacologicalInfo();

        // 5. Kullanım yolu bilgilerini ekle
        $this->addAdministrationRoutes();

        // 6. Yan etki ve uyarılar bilgilerini ekle
        $this->addSideEffectsAndWarnings();
    }

    private function populateAtcCodes()
    {
        // Etken madde tablosundan ATC kodlarını al ve ilaçlara ekle
        $ilacEtkenMaddeIliski = DB::table('ilac_etken_maddeler')
            ->join('etken_maddeler', 'ilac_etken_maddeler.etken_madde_id', '=', 'etken_maddeler.etken_madde_id')
            ->whereNotNull('etken_maddeler.atc_kodlari')
            ->select('ilac_etken_maddeler.ilac_id', 'etken_maddeler.atc_kodlari')
            ->get();

        foreach ($ilacEtkenMaddeIliski as $iliski) {
            DB::table('ilaclar')
                ->where('ilac_id', $iliski->ilac_id)
                ->whereNull('atc_kodu')
                ->update(['atc_kodu' => $iliski->atc_kodlari]);
        }
    }

    private function extractFormulationAndPackagingInfo()
    {
        // İlaç adından formulasyon ve ambalaj bilgilerini çıkart
        $ilaclar = DB::table('ilaclar')
            ->whereNotNull('ilac_adi')
            ->where('ilac_adi', '!=', '')
            ->select('ilac_id', 'ilac_adi')
            ->get();

        $formulations = [
            'TABLET' => 'tablet',
            'KAPSUL' => 'kapsül',
            'KAPLET' => 'kaplet',
            'FILM TABLET' => 'film tablet',
            'DRAJE' => 'draje',
            'SURUP' => 'şurup',
            'SUSPANSIYON' => 'süspansiyon',
            'AMPUL' => 'ampul',
            'FLAKON' => 'flakon',
            'POMAD' => 'pomad',
            'KREM' => 'krem',
            'JEL' => 'jel',
            'MERHEM' => 'merhem',
            'LOSYON' => 'losyon',
            'DAMLA' => 'damla',
            'SPREY' => 'sprey',
            'INHALASYON' => 'inhalasyon',
            'TRANSDERMAL' => 'transdermal',
            'SAKIZ' => 'sakız',
            'TOZ' => 'toz',
            'PASTIL' => 'pastil',
            'SAŞE' => 'saşe',
            'ŞASE' => 'saşe',
            'SOLUSYON' => 'solüsyon',
            'SOLÜSYON' => 'solüsyon',
            'ÇÖZELTI' => 'çözelti',
            'ŞAMPUAN' => 'şampuan',
            'OVUL' => 'ovül',
            'SUPPOZITUVAR' => 'suppozituvar',
            'ENJ' => 'enjeksiyon',
            'ENJEKTABL' => 'enjektabl',
            'IV' => 'intravenöz',
            'ORAL' => 'oral',
            'PEDIATRIK' => 'pediatrik',
            'ŞURUP' => 'şurup',
            'COZ' => 'çözelti',
            'CAY' => 'çay',
            'GRANUL' => 'granül',
            'EFERVESANT' => 'efervesan',
            'GARGARA' => 'gargara'
        ];

        foreach ($ilaclar as $ilac) {
            $ilacAdi = mb_strtoupper($ilac->ilac_adi, 'UTF-8');

            // Formulasyon tespiti
            $formulasyon = null;
            foreach ($formulations as $key => $value) {
                if (mb_strpos($ilacAdi, $key) !== false) {
                    $formulasyon = $value;
                    break;
                }
            }

            // Ambalaj bilgisi tespiti (x10 tablet, 100 ml vb.)
            $ambalajPattern = '/\b(\d+)x(\d+)\s*([A-Za-z]+)\b|\b(\d+)\s*([A-Za-z]+)\b/u';
            preg_match($ambalajPattern, $ilacAdi, $matches);
            $ambalajBilgisi = null;

            if (!empty($matches)) {
                if (isset($matches[1]) && isset($matches[2]) && isset($matches[3])) {
                    // Örnek: 3x10 tablet
                    $ambalajBilgisi = "{$matches[1]}x{$matches[2]} {$matches[3]}";
                } elseif (isset($matches[4]) && isset($matches[5])) {
                    // Örnek: 100 ml
                    $ambalajBilgisi = "{$matches[4]} {$matches[5]}";
                }
            }

            // Veritabanını güncelle
            $updateData = [];
            if ($formulasyon && (DB::table('ilaclar')->where('ilac_id', $ilac->ilac_id)->value('formulasyon') === null)) {
                $updateData['formulasyon'] = $formulasyon;
            }

            if ($ambalajBilgisi && (DB::table('ilaclar')->where('ilac_id', $ilac->ilac_id)->value('ambalaj_bilgisi') === null)) {
                $updateData['ambalaj_bilgisi'] = $ambalajBilgisi;
            }

            if (!empty($updateData)) {
                DB::table('ilaclar')
                    ->where('ilac_id', $ilac->ilac_id)
                    ->update($updateData);
            }
        }
    }

    private function addPharmacologicalInfo()
    {
        // Etken madde ile ilişkili farmakolojik bilgileri ilgili ilaçlara ekle
        $ilacEtkenMaddeler = DB::table('ilac_etken_maddeler')
            ->join('etken_maddeler', 'ilac_etken_maddeler.etken_madde_id', '=', 'etken_maddeler.etken_madde_id')
            ->whereNotNull('etken_maddeler.etki_mekanizmasi')
            ->orWhereNotNull('etken_maddeler.farmakokinetik')
            ->select(
                'ilac_etken_maddeler.ilac_id',
                'etken_maddeler.etki_mekanizmasi',
                'etken_maddeler.farmakokinetik',
                'etken_maddeler.genel_bilgi'
            )
            ->get();

        foreach ($ilacEtkenMaddeler as $veri) {
            $updateData = [];

            if ($veri->etki_mekanizmasi && DB::table('ilaclar')->where('ilac_id', $veri->ilac_id)->whereNull('etki_mekanizmasi')->exists()) {
                $updateData['etki_mekanizmasi'] = $veri->etki_mekanizmasi;
            }

            if ($veri->farmakokinetik && DB::table('ilaclar')->where('ilac_id', $veri->ilac_id)->whereNull('farmakokinetik')->exists()) {
                $updateData['farmakokinetik'] = $veri->farmakokinetik;
            }

            if ($veri->genel_bilgi && DB::table('ilaclar')->where('ilac_id', $veri->ilac_id)->whereNull('farmakodinamik')->exists()) {
                $updateData['farmakodinamik'] = $veri->genel_bilgi;
            }

            if (!empty($updateData)) {
                DB::table('ilaclar')
                    ->where('ilac_id', $veri->ilac_id)
                    ->update($updateData);
            }
        }
    }

    private function addAdministrationRoutes()
    {
        // İlaç adı ve formülasyona göre kullanım yolunu belirle
        $kullanımYoluEşleştirme = [
            'TABLET' => 'Oral kullanım için',
            'KAPSUL' => 'Oral kullanım için',
            'ŞURUP' => 'Oral kullanım için',
            'AMPUL' => 'Enjeksiyon yoluyla kullanım için',
            'FLAKON' => 'Enjeksiyon yoluyla kullanım için',
            'KREM' => 'Topikal (cilt üzerine) kullanım için',
            'POMAD' => 'Topikal (cilt üzerine) kullanım için',
            'JEL' => 'Topikal (cilt üzerine) kullanım için',
            'SPREY' => 'Püskürtme yoluyla kullanım için',
            'DAMLA' => 'Damlatma yoluyla kullanım için',
            'INHALASYON' => 'İnhalasyon (soluma) yoluyla kullanım için',
            'IV' => 'İntravenöz kullanım için (doğrudan damar yolu ile)',
            'TOZ' => 'Sulandırılarak kullanım için',
            'SAŞE' => 'Sulandırılarak oral kullanım için',
            'ŞASE' => 'Sulandırılarak oral kullanım için',
            'SUPPOZITUVAR' => 'Rektal (anüs yoluyla) kullanım için',
            'OVUL' => 'Vajinal kullanım için'
        ];

        foreach ($kullanımYoluEşleştirme as $anahtar => $deger) {
            DB::statement("
                UPDATE ilaclar
                SET kullanim_yolu = ?
                WHERE (kullanim_yolu IS NULL OR kullanim_yolu = '')
                AND (
                    UPPER(formulasyon) LIKE ?
                    OR UPPER(ilac_adi) LIKE ?
                )
            ", [$deger, '%' . $anahtar . '%', '%' . $anahtar . '%']);
        }

        // Geriye kalan, kullanım yolu belirtilmemiş ilaçlara genel bir açıklama ekle
        DB::statement("
            UPDATE ilaclar
            SET kullanim_yolu = 'Hekim tarafından önerilen şekilde kullanılmalıdır.'
            WHERE kullanim_yolu IS NULL OR kullanim_yolu = ''
        ");
    }

    private function addSideEffectsAndWarnings()
    {
        // Tüm ilaçlar için genel yan etki ve uyarılar ekle
        DB::statement("
            UPDATE ilaclar
            SET yan_etkiler = 'Her ilaçta olduğu gibi, bazı hastalarda yan etkiler görülebilir. Sık görülen yan etkiler: baş ağrısı, baş dönmesi, mide bulantısı, kusma, ishal veya kabızlık olabilir. Ciddi yan etkiler görüldüğünde hemen doktorunuza başvurunuz.'
            WHERE yan_etkiler IS NULL OR yan_etkiler = ''
        ");

        DB::statement("
            UPDATE ilaclar
            SET uyarilar_ve_onlemler = 'Bu ilacı kullanmadan önce doktorunuza danışınız. Reçete edildiği şekilde kullanınız. Gebelik ve emzirme döneminde kullanımı için doktorunuza danışınız. Çocukların erişemeyeceği yerde saklayınız.'
            WHERE uyarilar_ve_onlemler IS NULL OR uyarilar_ve_onlemler = ''
        ");

        DB::statement("
            UPDATE ilaclar
            SET ilac_etkilesimleri = 'Bu ilacın diğer ilaçlarla etkileşimleri olabilir. Kullandığınız tüm ilaçları, bitkisel ürünleri ve takviye edici gıdaları doktorunuza ve eczacınıza bildiriniz.'
            WHERE ilac_etkilesimleri IS NULL OR ilac_etkilesimleri = ''
        ");

        // Endikasyonlar kısmını düzelt - etken_madde sütunu olmadığı için farklı bir yaklaşım kullan
        DB::statement("
            UPDATE ilaclar
            SET endikasyonlar = CONCAT('Bu ilaç, ', COALESCE(formulasyon, 'ilaç'), ' formunda etken madde içerir ve ilgili hastalıkların tedavisinde kullanılır.')
            WHERE endikasyonlar IS NULL OR endikasyonlar = ''
        ");

        // İlaç adına göre endikasyonları güncelle
        $endikasyonlar = [
            '%AĞRI%' => 'Hafif ve orta şiddetli ağrıların tedavisinde kullanılır.',
            '%AGRI%' => 'Hafif ve orta şiddetli ağrıların tedavisinde kullanılır.',
            '%ATEŞ%' => 'Ateş durumlarında semptomatik tedavi için kullanılır.',
            '%ATES%' => 'Ateş durumlarında semptomatik tedavi için kullanılır.',
            '%ALLERJ%' => 'Alerjik rinit, ürtiker gibi alerjik durumların tedavisinde kullanılır.',
            '%ALERJ%' => 'Alerjik rinit, ürtiker gibi alerjik durumların tedavisinde kullanılır.',
            '%ANTIBI%' => 'Çeşitli bakteriyel enfeksiyonların tedavisinde kullanılır.',
            '%TANSI%' => 'Hipertansiyon (yüksek tansiyon) tedavisinde kullanılır.',
            '%HIPER%' => 'Hipertansiyon (yüksek tansiyon) tedavisinde kullanılır.',
            '%DIABET%' => 'Diabetes mellitus (şeker hastalığı) tedavisinde kullanılır.',
            '%ŞEKER%' => 'Diabetes mellitus (şeker hastalığı) tedavisinde kullanılır.',
            '%KOLEST%' => 'Yüksek kolesterol tedavisinde kullanılır.',
            '%MIDE%' => 'Mide asidine bağlı hastalıkların (ülser, reflü vb.) tedavisinde kullanılır.',
            '%REFLÜ%' => 'Mide asidine bağlı hastalıkların (ülser, reflü vb.) tedavisinde kullanılır.',
            '%ASIT%' => 'Mide asidine bağlı hastalıkların (ülser, reflü vb.) tedavisinde kullanılır.'
        ];

        foreach ($endikasyonlar as $anahtar => $deger) {
            DB::statement("
                UPDATE ilaclar
                SET endikasyonlar = ?
                WHERE (endikasyonlar LIKE '%etken madde içerir%')
                AND ilac_adi LIKE ?
            ", [$deger, $anahtar]);
        }

        DB::statement("
            UPDATE ilaclar
            SET kontrendikasyonlar = 'Bu ilaca karşı aşırı duyarlılığı olan hastalarda kullanılmamalıdır. Diğer kontrendikasyonlar için kullanma talimatını okuyunuz veya doktorunuza danışınız.'
            WHERE kontrendikasyonlar IS NULL OR kontrendikasyonlar = ''
        ");

        DB::statement("
            UPDATE ilaclar
            SET ozel_popülasyon_bilgileri = 'Gebelik ve emzirme dönemindeki kullanımı, pediyatrik ve geriyatrik hastalarda kullanımı için doktorunuza danışınız.'
            WHERE ozel_popülasyon_bilgileri IS NULL OR ozel_popülasyon_bilgileri = ''
        ");
    }

    public function down()
    {
        // Bu işlem geri alınamaz
    }
}
