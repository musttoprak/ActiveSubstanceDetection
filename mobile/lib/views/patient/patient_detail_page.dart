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

class _PatientDetailPageState extends State<PatientDetailPage>
    with SingleTickerProviderStateMixin {
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
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        centerTitle: true,
        elevation: 0,
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
          labelStyle:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          dividerHeight: 0,
        ),
      ),
      body: BlocProvider(
        create: (context) => PatientDetailCubit(widget.hastaId),
        child: BlocBuilder<PatientDetailCubit, PatientDetailState>(
          builder: (context, state) {
            if (state is PatientDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is PatientDetailError) {
              print(state.message);
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
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  radius: 25,
                  child: Text(
                    _getInitials(patient.tamAd),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.tamAd,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${patient.yas} yaşında, ${patient.cinsiyet}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildInfoCardNew(
            'Kişisel Bilgiler',
            Icons.person,
            Colors.indigo,
            [
              InfoItemNew('Ad Soyad', patient.tamAd, Icons.badge),
              InfoItemNew('Yaş', '${patient.yas}', Icons.cake),
              InfoItemNew(
                  'Cinsiyet',
                  patient.cinsiyet,
                  patient.cinsiyet.toLowerCase() == 'erkek'
                      ? Icons.male
                      : patient.cinsiyet.toLowerCase() == 'kadın'
                          ? Icons.female
                          : Icons.person),
              InfoItemNew(
                  'TC Kimlik', patient.tcKimlik ?? '-', Icons.credit_card),
              InfoItemNew(
                  'Doğum Tarihi',
                  patient.dogumTarihi != null
                      ? DateFormat('dd.MM.yyyy').format(patient.dogumTarihi!)
                      : '-',
                  Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCardNew(
            'İletişim Bilgileri',
            Icons.contact_phone,
            Colors.teal,
            [
              InfoItemNew('Telefon', patient.telefon ?? '-', Icons.phone),
              InfoItemNew('E-posta', patient.email ?? '-', Icons.email),
              InfoItemNew('Adres', patient.adres ?? '-', Icons.home),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCardNew(
            'Fiziksel Bilgiler',
            Icons.accessibility_new,
            Colors.amber,
            [
              InfoItemNew(
                  'Boy',
                  patient.boy != null ? '${patient.boy} cm' : '-',
                  Icons.height),
              InfoItemNew(
                  'Kilo',
                  patient.kilo != null ? '${patient.kilo} kg' : '-',
                  Icons.monitor_weight),
              InfoItemNew(
                  'Vücut Kitle İndeksi (VKİ)',
                  patient.vki != null ? '${patient.vki}' : '-',
                  Icons.insert_chart),
            ],
            extraWidget:
                patient.vki != null ? _buildBMIIndicator(patient.vki!) : null,
          ),
        ],
      ),
    );
  }

  // İsmin baş harflerini alma
  String _getInitials(String fullName) {
    List<String> nameParts = fullName.split(' ');
    String initials = '';
    for (var part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0];
      }
    }
    return initials.length > 2
        ? initials.substring(0, 2).toUpperCase()
        : initials.toUpperCase();
  }

  // VKİ göstergesi
  Widget _buildBMIIndicator(double vki) {
    String category;
    Color color;

    if (vki < 18.5) {
      category = 'Zayıf';
      color = Colors.blue;
    } else if (vki < 25) {
      category = 'Normal';
      color = Colors.green;
    } else if (vki < 30) {
      category = 'Fazla Kilolu';
      color = Colors.orange;
    } else {
      category = 'Obez';
      color = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'VKİ Kategorisi: $category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey.shade200,
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              Flexible(
                flex: 185, // 18.5 * 10
                child: Container(color: Colors.blue),
              ),
              Flexible(
                flex: 65, // (25 - 18.5) * 10
                child: Container(color: Colors.green),
              ),
              Flexible(
                flex: 50, // (30 - 25) * 10
                child: Container(color: Colors.orange),
              ),
              Flexible(
                flex: 100, // Rest
                child: Container(color: Colors.red),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          alignment: Alignment.lerp(
            Alignment.centerLeft,
            Alignment.centerRight,
            vki > 40 ? 1.0 : vki / 40,
          ),
          child: Icon(
            Icons.arrow_drop_up,
            color: color,
            size: 34,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              flex: 185, // 0-18.5
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  SizedBox(), // Boş alan
                ],
              ),
            ),
            Flexible(
              flex: 65, // 18.5-25
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('18.5',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  SizedBox(), // Boş alan
                ],
              ),
            ),
            Flexible(
              flex: 50, // 25-30
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('25',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  SizedBox(), // Boş alan
                ],
              ),
            ),
            Flexible(
              flex: 100, // 30-40+
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('30',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  Text('40+',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Modern bilgi kartı
  Widget _buildInfoCardNew(String title, IconData titleIcon,
      MaterialColor color, List<InfoItemNew> items,
      {Widget? extraWidget}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  titleIcon,
                  color: color.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) => _buildInfoItemRow(item)).toList(),
                if (extraWidget != null) extraWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bilgi satırı
  Widget _buildInfoItemRow(InfoItemNew item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tıbbi Geçmiş Tab
  Widget _buildMedicalHistoryTab(MedicalHistoryResponseModel? medicalHistory) {
    if (medicalHistory == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_edu_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tıbbi geçmiş bilgisi bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.history_edu, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Tıbbi Geçmiş Özeti',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          _buildMedicalHistoryCard(
            'Kronik Hastalıklar',
            Icons.medical_services,
            Colors.red,
            medicalHistory.kronikHastaliklar ?? 'Bilgi yok',
          ),
          const SizedBox(height: 16),
          _buildMedicalHistoryCard(
            'Geçirilen Ameliyatlar',
            Icons.local_hospital,
            Colors.purple,
            medicalHistory.gecirilenAmeliyatlar ?? 'Bilgi yok',
          ),
          const SizedBox(height: 16),
          _buildMedicalHistoryCard(
            'Alerjiler',
            Icons.coronavirus,
            Colors.orange,
            medicalHistory.alerjiler ?? 'Bilgi yok',
          ),
          const SizedBox(height: 16),
          _buildMedicalHistoryCard(
            'Aile Hastalıkları',
            Icons.family_restroom,
            Colors.blue,
            medicalHistory.aileHastaliklari ?? 'Bilgi yok',
          ),
          const SizedBox(height: 16),
          _buildLifestyleCard(medicalHistory),
        ],
      ),
    );
  }

  // Tıbbi geçmiş kartı
  Widget _buildMedicalHistoryCard(
    String title,
    IconData titleIcon,
    MaterialColor color,
    String content,
  ) {
    final isEmpty = content == 'Bilgi yok';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  titleIcon,
                  color: color.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bilgi yok',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  )
                : Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Yaşam tarzı kartı
  Widget _buildLifestyleCard(MedicalHistoryResponseModel medicalHistory) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Yaşam Tarzı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLifestyleItem(
                  'Sigara Kullanımı',
                  medicalHistory.sigaraKullanimi ?? 'Bilgi yok',
                  Icons.smoking_rooms,
                ),
                const Divider(),
                _buildLifestyleItem(
                  'Alkol Tüketimi',
                  medicalHistory.alkolTuketimi ?? 'Bilgi yok',
                  Icons.local_bar,
                ),
                const Divider(),
                _buildLifestyleItem(
                  'Fiziksel Aktivite',
                  medicalHistory.fizikselAktivite ?? 'Bilgi yok',
                  Icons.directions_run,
                ),
                const Divider(),
                _buildLifestyleItem(
                  'Beslenme Alışkanlıkları',
                  medicalHistory.beslenmeAliskanliklari ?? 'Bilgi yok',
                  Icons.restaurant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Yaşam tarzı öğesi
  Widget _buildLifestyleItem(String label, String value, IconData icon) {
    final isEmpty = value == 'Bilgi yok';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                isEmpty
                    ? Text(
                        'Bilgi yok',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500],
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Laboratuvar Sonuçları Tab
  Widget _buildLabResultsTab(List<LabResultResponseModel> labResults) {
    if (labResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Laboratuvar sonucu bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Tarihe göre sırala (en yeniden eskiye)
    labResults.sort((a, b) => b.testTarihi.compareTo(a.testTarihi));

    // Tarih gruplarına ayır
    final groupedResults = <String, List<LabResultResponseModel>>{};
    for (var result in labResults) {
      final dateKey = DateFormat('dd.MM.yyyy').format(result.testTarihi);
      if (!groupedResults.containsKey(dateKey)) {
        groupedResults[dateKey] = [];
      }
      groupedResults[dateKey]!.add(result);
    }

    final sortedDates = groupedResults.keys.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('dd.MM.yyyy').parse(a);
          final dateB = DateFormat('dd.MM.yyyy').parse(b);
          return dateB.compareTo(dateA); // En yeniden eskiye
        } catch (e) {
          return 0;
        }
      });

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.science, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                'Toplam ${labResults.length} laboratuvar sonucu',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: sortedDates.length,
            itemBuilder: (context, dateIndex) {
              final dateKey = sortedDates[dateIndex];
              final dateResults = groupedResults[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateKey,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...dateResults.map((labResult) {
                    final isAbnormal = !labResult.normalMi;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isAbnormal
                              ? Colors.red.withOpacity(0.3)
                              : Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showLabResultDetail(context, labResult);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      labResult.testTuru,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: labResult.normalMi
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: labResult.normalMi
                                            ? Colors.green.shade300
                                            : Colors.red.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          labResult.normalMi
                                              ? Icons.check_circle
                                              : Icons.warning,
                                          size: 16,
                                          color: labResult.normalMi
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          labResult.normalMi
                                              ? 'Normal'
                                              : 'Anormal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: labResult.normalMi
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.straighten,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${labResult.deger} ${labResult.birim ?? ''}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isAbnormal
                                                    ? Colors.red.shade700
                                                    : Colors.grey[800],
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (labResult.referansAralik !=
                                            null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.difference,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Ref: ${labResult.referansAralik}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'İlaç kullanım bilgisi bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Aktif ilaçları üstte göster
    medications.sort((a, b) {
      if (a.aktif && !b.aktif) return -1;
      if (!a.aktif && b.aktif) return 1;
      return b.baslangicTarihi.compareTo(a.baslangicTarihi);
    });

    // Aktif ve pasif ilaçlar için ayrı listeler
    final activemedications = medications.where((m) => m.aktif).toList();
    final inactivemedications = medications.where((m) => !m.aktif).toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.medication, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                'Toplam ${medications.length} ilaç (${activemedications.length} aktif)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              if (activemedications.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "AKTİF İLAÇLAR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                ...activemedications.map(
                    (medication) => _buildMedicationCard(medication, context)),
              ],
              if (inactivemedications.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "GEÇMİŞ İLAÇLAR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                ...inactivemedications.map(
                    (medication) => _buildMedicationCard(medication, context)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // İlaç kartı widget'ı
  Widget _buildMedicationCard(
      MedicationUsageResponseModel medication, BuildContext context) {
    final isActive = medication.aktif;

    return Card(
      elevation: isActive ? 2 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.blue.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isActive ? 1 : 0.5,
        ),
      ),
      color: isActive ? Colors.white : Colors.grey.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showMedicationDetail(context, medication);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medication,
                    color: isActive ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      medication.ilac?.ilacAdi ?? 'Bilinmeyen İlaç',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isActive ? Colors.black : Colors.grey[700],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isActive ? Colors.blue.shade50 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? Colors.blue.shade300
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.check_circle : Icons.history,
                          size: 14,
                          color: isActive
                              ? Colors.blue.shade700
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (medication.dozaj != null && medication.dozaj!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      medication.dozaj!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Başlangıç: ${DateFormat('dd.MM.yyyy').format(medication.baslangicTarihi)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              if (medication.bitisTarihi != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Bitiş: ${DateFormat('dd.MM.yyyy').format(medication.bitisTarihi!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Hastalıklar Tab
  Widget _buildDiseasesTab(List<HastaHastalikResponseModel> diseases) {
    if (diseases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Hastalık bilgisi bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Aktif hastalıkları üstte göster
    diseases.sort((a, b) {
      if (a.aktif && !b.aktif) return -1;
      if (!a.aktif && b.aktif) return 1;
      return b.teshisTarihi.compareTo(a.teshisTarihi);
    });

    // Aktif ve pasif hastalıklar için ayrı listeler
    final activeDiseases = diseases.where((d) => d.aktif).toList();
    final inactiveDiseases = diseases.where((d) => !d.aktif).toList();

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.healing, color: Colors.orange.shade800),
              const SizedBox(width: 12),
              Text(
                'Toplam ${diseases.length} hastalık (${activeDiseases.length} aktif)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              if (activeDiseases.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        size: 16,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "AKTİF HASTALIKLAR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                ...activeDiseases
                    .map((disease) => _buildDiseaseCard(disease, context)),
              ],
              if (inactiveDiseases.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "GEÇMİŞ HASTALIKLAR",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                ...inactiveDiseases
                    .map((disease) => _buildDiseaseCard(disease, context)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Hastalık kartı widget'ı
  Widget _buildDiseaseCard(
      HastaHastalikResponseModel disease, BuildContext context) {
    final isActive = disease.aktif;

    return Card(
      elevation: isActive ? 2 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.orange.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: isActive ? 1 : 0.5,
        ),
      ),
      color: isActive ? Colors.white : Colors.grey.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showDiseaseDetail(context, disease);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_hospital,
                    color: isActive ? Colors.orange.shade800 : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      disease.hastalik?.hastalikAdi ?? 'Bilinmeyen Hastalık',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isActive ? Colors.black : Colors.grey[700],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? Colors.orange.shade300
                            : Colors.green.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? Icons.warning : Icons.check_circle,
                          size: 14,
                          color: isActive
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isActive ? 'Aktif' : 'İyileşti',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.code,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ICD: ${disease.hastalik?.icdKodu ?? '-'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (disease.siddet != null && disease.siddet!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Şiddet: ${disease.siddet}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event_note,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Teşhis: ${DateFormat('dd.MM.yyyy').format(disease.teshisTarihi)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Laboratuvar sonucu detay diyaloğu
  void _showLabResultDetail(
      BuildContext context, LabResultResponseModel labResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: labResult.normalMi
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: labResult.normalMi
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      child: Icon(
                        labResult.normalMi ? Icons.check : Icons.warning,
                        color: labResult.normalMi ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labResult.testTuru,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMMM yyyy', 'tr_TR')
                                .format(labResult.testTarihi),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: labResult.normalMi
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        labResult.normalMi ? 'Normal' : 'Anormal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: labResult.normalMi
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InfoRow(
                        'Test Kodu',
                        labResult.testKodu ?? '-',
                        icon: Icons.qr_code,
                      ),
                      InfoRow(
                        'Değer',
                        '${labResult.deger} ${labResult.birim ?? ''}',
                        icon: Icons.straighten,
                        isHighlighted: true,
                      ),
                      InfoRow(
                        'Referans Aralık',
                        labResult.referansAralik ?? '-',
                        icon: Icons.call_split,
                      ),
                      InfoRow(
                        'Test Tarihi',
                        DateFormat('dd.MM.yyyy').format(labResult.testTarihi),
                        icon: Icons.calendar_today,
                      ),
                      if (labResult.notlar != null &&
                          labResult.notlar!.isNotEmpty)
                        InfoRow(
                          'Notlar',
                          labResult.notlar!,
                          icon: Icons.note,
                        ),
                    ],
                  ),
                ),
              ),
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
  void _showMedicationDetail(
      BuildContext context, MedicationUsageResponseModel medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: medication.aktif
                      ? Colors.blue.shade50
                      : Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: medication.aktif
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      child: Icon(
                        Icons.medication,
                        color: medication.aktif ? Colors.blue : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.ilac?.ilacAdi ?? 'İlaç Detayları',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Başlangıç: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(medication.baslangicTarihi)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: medication.aktif
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        medication.aktif ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: medication.aktif
                              ? Colors.blue[700]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (medication.ilac?.ureticiFirma != null)
                        InfoRow(
                          'Üretici Firma',
                          medication.ilac!.ureticiFirma!,
                          icon: Icons.business,
                        ),
                      InfoRow(
                        'Dozaj',
                        medication.dozaj ?? '-',
                        icon: Icons.timer,
                        isHighlighted: true,
                      ),
                      InfoRow(
                        'Kullanım Talimatı',
                        medication.kullanimTalimati ?? '-',
                        icon: Icons.description,
                      ),
                      InfoRow(
                        'Başlangıç Tarihi',
                        DateFormat('dd.MM.yyyy')
                            .format(medication.baslangicTarihi),
                        icon: Icons.calendar_today,
                      ),
                      if (medication.bitisTarihi != null)
                        InfoRow(
                          'Bitiş Tarihi',
                          DateFormat('dd.MM.yyyy')
                              .format(medication.bitisTarihi!),
                          icon: Icons.event_busy,
                        ),
                      if (medication.etkinlikDegerlendirmesi != null)
                        InfoRow(
                          'Etkinlik Değerlendirmesi',
                          medication.etkinlikDegerlendirmesi!,
                          icon: Icons.assessment,
                        ),
                      if (medication.yanEtkiRaporlari != null)
                        InfoRow(
                          'Yan Etki Raporları',
                          medication.yanEtkiRaporlari!,
                          icon: Icons.warning,
                        ),
                      if (medication.hastalik != null)
                        InfoRow(
                          'Tedavi Edilen Hastalık',
                          medication.hastalik!.hastalikAdi,
                          icon: Icons.healing,
                        ),
                    ],
                  ),
                ),
              ),
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
  void _showDiseaseDetail(
      BuildContext context, HastaHastalikResponseModel disease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: disease.aktif
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: disease.aktif
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      child: Icon(
                        Icons.local_hospital,
                        color: disease.aktif
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disease.hastalik?.hastalikAdi ??
                                'Hastalık Detayları',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Teşhis: ${DateFormat('dd MMMM yyyy', 'tr_TR').format(disease.teshisTarihi)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: disease.aktif
                            ? Colors.orange.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        disease.aktif ? 'Aktif' : 'İyileşti',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: disease.aktif
                              ? Colors.orange[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InfoRow(
                        'ICD Kodu',
                        disease.hastalik?.icdKodu ?? '-',
                        icon: Icons.code,
                        isHighlighted: true,
                      ),
                      InfoRow(
                        'Kategori',
                        disease.hastalik?.hastalikKategorisi ?? '-',
                        icon: Icons.category,
                      ),
                      InfoRow(
                        'Teşhis Tarihi',
                        DateFormat('dd.MM.yyyy').format(disease.teshisTarihi),
                        icon: Icons.calendar_today,
                      ),
                      InfoRow(
                        'Şiddet',
                        disease.siddet ?? '-',
                        icon: Icons.trending_up,
                      ),
                      if (disease.notlar != null && disease.notlar!.isNotEmpty)
                        InfoRow(
                          'Notlar',
                          disease.notlar!,
                          icon: Icons.note,
                        ),
                      if (disease.hastalik?.aciklama != null)
                        InfoRow(
                          'Açıklama',
                          disease.hastalik!.aciklama!,
                          icon: Icons.info,
                        ),
                    ],
                  ),
                ),
              ),
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

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isHighlighted;

  const InfoRow(
    this.label,
    this.value, {
    Key? key,
    this.icon,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color:
                      isHighlighted ? Colors.blue.shade700 : Colors.grey[700],
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isHighlighted ? FontWeight.w600 : FontWeight.normal,
                    color:
                        isHighlighted ? Colors.blue.shade700 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Divider(color: Colors.grey.withOpacity(0.2)),
        ],
      ),
    );
  }
}

// Bilgi Öğesi Model Sınıfı
class InfoItemNew {
  final String label;
  final String value;
  final IconData icon;

  InfoItemNew(this.label, this.value, this.icon);
}
