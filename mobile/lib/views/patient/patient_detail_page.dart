// pages/patient_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/patient_detail_cubit.dart';
import 'package:mobile/models/response_models/hasta_hastalik_response_model.dart';
import 'package:mobile/models/response_models/lab_result_response_model.dart';
import 'package:mobile/models/response_models/medical_history_response_model.dart';
import 'package:mobile/models/response_models/medication_usage_response_model.dart,.dart';
import 'package:mobile/models/response_models/patient_response_model.dart';
import 'package:intl/intl.dart';

class PatientDetailPage extends StatefulWidget {
  final int hastaId;

  const PatientDetailPage({super.key, required this.hastaId});

  @override
  _PatientDetailPageState createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasta Detayları'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Genel Bilgiler'),
            Tab(text: 'Tıbbi Geçmiş'),
            Tab(text: 'Laboratuvar Sonuçları'),
            Tab(text: 'İlaç Kullanımı'),
            Tab(text: 'Hastalıklar'),
          ],
        ),
      ),
      body: BlocProvider(
        create: (context) => PatientDetailCubit(widget.hastaId),
        child: BlocBuilder<PatientDetailCubit, PatientDetailState>(
          builder: (context, state) {
            if (state is PatientDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PatientDetailError) {
              return Center(child: Text('Hata: ${state.message}'));
            } else if (state is PatientAllDataLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralInfoTab(state.patient),
                  _buildMedicalHistoryTab(state.medicalHistory),
                  _buildLabResultsTab(state.labResults),
                  _buildMedicationsTab(state.medications),
                  _buildDiseasesTab(state.diseases),
                ],
              );
            }
            return const Center(child: Text('Hasta bilgileri yükleniyor...'));
          },
        ),
      ),
    );
  }

  // Genel Bilgiler Tab
  Widget _buildGeneralInfoTab(PatientResponseModel patient) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Kişisel Bilgiler', [
            InfoItem('Ad Soyad', patient.tamAd),
            InfoItem('Yaş', '${patient.yas}'),
            InfoItem('Cinsiyet', patient.cinsiyet),
            InfoItem('TC Kimlik', patient.tcKimlik ?? '-'),
            InfoItem('Doğum Tarihi', patient.dogumTarihi != null ? DateFormat('dd.MM.yyyy').format(patient.dogumTarihi!) : '-'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('İletişim Bilgileri', [
            InfoItem('Telefon', patient.telefon ?? '-'),
            InfoItem('E-posta', patient.email ?? '-'),
            InfoItem('Adres', patient.adres ?? '-'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Fiziksel Bilgiler', [
            InfoItem('Boy', patient.boy != null ? '${patient.boy} cm' : '-'),
            InfoItem('Kilo', patient.kilo != null ? '${patient.kilo} kg' : '-'),
            InfoItem('Vücut Kitle İndeksi (VKİ)', patient.vki != null ? '${patient.vki}' : '-'),
          ]),
        ],
      ),
    );
  }

  // Tıbbi Geçmiş Tab
  Widget _buildMedicalHistoryTab(MedicalHistoryResponseModel? medicalHistory) {
    if (medicalHistory == null) {
      return const Center(child: Text('Tıbbi geçmiş bilgisi bulunamadı.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Kronik Hastalıklar', [
            InfoItem('', medicalHistory.kronikHastaliklar ?? 'Bilgi yok'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Geçirilen Ameliyatlar', [
            InfoItem('', medicalHistory.gecirilenAmeliyatlar ?? 'Bilgi yok'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Alerjiler', [
            InfoItem('', medicalHistory.alerjiler ?? 'Bilgi yok'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Aile Hastalıkları', [
            InfoItem('', medicalHistory.aileHastaliklari ?? 'Bilgi yok'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Yaşam Tarzı', [
            InfoItem('Sigara Kullanımı', medicalHistory.sigaraKullanimi ?? 'Bilgi yok'),
            InfoItem('Alkol Tüketimi', medicalHistory.alkolTuketimi ?? 'Bilgi yok'),
            InfoItem('Fiziksel Aktivite', medicalHistory.fizikselAktivite ?? 'Bilgi yok'),
            InfoItem('Beslenme Alışkanlıkları', medicalHistory.beslenmeAliskanliklari ?? 'Bilgi yok'),
          ]),
        ],
      ),
    );
  }

  // Laboratuvar Sonuçları Tab
  Widget _buildLabResultsTab(List<LabResultResponseModel> labResults) {
    if (labResults.isEmpty) {
      return const Center(child: Text('Laboratuvar sonucu bulunamadı.'));
    }

    // Tarihe göre sırala (en yeniden eskiye)
    labResults.sort((a, b) => b.testTarihi.compareTo(a.testTarihi));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Toplam ${labResults.length} laboratuvar sonucu',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: labResults.length,
            itemBuilder: (context, index) {
              final labResult = labResults[index];
              return Card(
                color: Color(0xFFF3F7FC),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(labResult.testTuru),
                  subtitle: Text(
                    '${DateFormat('dd.MM.yyyy').format(labResult.testTarihi)} - ${labResult.deger} ${labResult.birim ?? ''}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: labResult.normalMi ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      labResult.normalMi ? 'Normal' : 'Anormal',
                      style: TextStyle(
                        color: labResult.normalMi ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ),
                  onTap: () {
                    _showLabResultDetail(context, labResult);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // İlaç Kullanımı Tab
  Widget _buildMedicationsTab(List<MedicationUsageResponseModel> medications) {
    if (medications.isEmpty) {
      return const Center(child: Text('İlaç kullanım bilgisi bulunamadı.'));
    }

    // Aktif ilaçları üstte göster
    medications.sort((a, b) {
      if (a.aktif && !b.aktif) return -1;
      if (!a.aktif && b.aktif) return 1;
      return b.baslangicTarihi.compareTo(a.baslangicTarihi);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Toplam ${medications.length} ilaç kullanımı (${medications.where((m) => m.aktif).length} aktif)',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final medication = medications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: medication.aktif ? Colors.white : Colors.grey.shade100,
                child: ListTile(
                  title: Text(medication.ilac?.ilacAdi ?? 'Bilinmeyen İlaç'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(medication.dozaj != null ? 'Dozaj: ${medication.dozaj}' : ''),
                      Text('Başlangıç: ${DateFormat('dd.MM.yyyy').format(medication.baslangicTarihi)}'),
                      if (medication.bitisTarihi != null)
                        Text('Bitiş: ${DateFormat('dd.MM.yyyy').format(medication.bitisTarihi!)}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: medication.aktif ? Colors.blue.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      medication.aktif ? 'Aktif' : 'Pasif',
                      style: TextStyle(
                        color: medication.aktif ? Colors.blue.shade800 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  onTap: () {
                    _showMedicationDetail(context, medication);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Hastalıklar Tab
  Widget _buildDiseasesTab(List<HastaHastalikResponseModel> diseases) {
    if (diseases.isEmpty) {
      return const Center(child: Text('Hastalık bilgisi bulunamadı.'));
    }

    // Aktif hastalıkları üstte göster
    diseases.sort((a, b) {
      if (a.aktif && !b.aktif) return -1;
      if (!a.aktif && b.aktif) return 1;
      return b.teshisTarihi.compareTo(a.teshisTarihi);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Toplam ${diseases.length} hastalık (${diseases.where((d) => d.aktif).length} aktif)',
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: diseases.length,
            itemBuilder: (context, index) {
              final disease = diseases[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: disease.aktif ? Colors.white : Colors.grey.shade100,
                child: ListTile(
                  title: Text(disease.hastalik?.hastalikAdi ?? 'Bilinmeyen Hastalık'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ICD: ${disease.hastalik?.icdKodu ?? '-'}'),
                      Text('Teşhis Tarihi: ${DateFormat('dd.MM.yyyy').format(disease.teshisTarihi)}'),
                      if (disease.siddet != null)
                        Text('Şiddet: ${disease.siddet}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: disease.aktif ? Colors.orange.shade100 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      disease.aktif ? 'Aktif' : 'İyileşti',
                      style: TextStyle(
                        color: disease.aktif ? Colors.orange.shade800 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  onTap: () {
                    _showDiseaseDetail(context, disease);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Bilgi kartı widget'ı
  Widget _buildInfoCard(String title, List<InfoItem> items) {
    return Card(
      color: Color(0xFFF3F7FC),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: item.label.isNotEmpty
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      '${item.label}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(item.value),
                  ),
                ],
              )
                  : Text(item.value),
            )),
          ],
        ),
      ),
    );
  }

  // Laboratuvar sonucu detay diyaloğu
  void _showLabResultDetail(BuildContext context, LabResultResponseModel labResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(labResult.testTuru),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoRow('Test Kodu', labResult.testKodu ?? '-'),
              InfoRow('Değer', '${labResult.deger} ${labResult.birim ?? ''}'),
              InfoRow('Referans Aralık', labResult.referansAralik ?? '-'),
              InfoRow('Durum', labResult.normalMi ? 'Normal' : 'Anormal'),
              InfoRow('Test Tarihi', DateFormat('dd.MM.yyyy').format(labResult.testTarihi)),
              if (labResult.notlar != null && labResult.notlar!.isNotEmpty)
                InfoRow('Notlar', labResult.notlar!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // İlaç kullanım detay diyaloğu
  void _showMedicationDetail(BuildContext context, MedicationUsageResponseModel medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medication.ilac?.ilacAdi ?? 'İlaç Detayları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (medication.ilac?.ureticiFirma != null)
                InfoRow('Üretici Firma', medication.ilac!.ureticiFirma!),
              InfoRow('Dozaj', medication.dozaj ?? '-'),
              InfoRow('Kullanım Talimatı', medication.kullanimTalimati ?? '-'),
              InfoRow('Başlangıç Tarihi', DateFormat('dd.MM.yyyy').format(medication.baslangicTarihi)),
              if (medication.bitisTarihi != null)
                InfoRow('Bitiş Tarihi', DateFormat('dd.MM.yyyy').format(medication.bitisTarihi!)),
              InfoRow('Durum', medication.aktif ? 'Aktif' : 'Sonlandırıldı'),
              if (medication.etkinlikDegerlendirmesi != null)
                InfoRow('Etkinlik Değerlendirmesi', medication.etkinlikDegerlendirmesi!),
              if (medication.yanEtkiRaporlari != null)
                InfoRow('Yan Etki Raporları', medication.yanEtkiRaporlari!),
              if (medication.hastalik != null)
                InfoRow('Tedavi Edilen Hastalık', medication.hastalik!.hastalikAdi),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  // Hastalık detay diyaloğu
  void _showDiseaseDetail(BuildContext context, HastaHastalikResponseModel disease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(disease.hastalik?.hastalikAdi ?? 'Hastalık Detayları'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              InfoRow('ICD Kodu', disease.hastalik?.icdKodu ?? '-'),
              InfoRow('Kategori', disease.hastalik?.hastalikKategorisi ?? '-'),
              InfoRow('Teşhis Tarihi', DateFormat('dd.MM.yyyy').format(disease.teshisTarihi)),
              InfoRow('Şiddet', disease.siddet ?? '-'),
              InfoRow('Durum', disease.aktif ? 'Aktif' : 'İyileşti'),
              if (disease.notlar != null && disease.notlar!.isNotEmpty)
                InfoRow('Notlar', disease.notlar!),
              if (disease.hastalik?.aciklama != null)
                InfoRow('Açıklama', disease.hastalik!.aciklama!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

// Bilgi satırı widget'ı (diyaloglar için)
class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// Bilgi öğesi sınıfı (kartlar için)
class InfoItem {
  final String label;
  final String value;

  InfoItem(this.label, this.value);
}