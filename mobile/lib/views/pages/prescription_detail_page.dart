// pages/prescription_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/prescription_cubit.dart';
import 'package:shimmer/shimmer.dart';

class PrescriptionDetailPage extends StatefulWidget {
  final String receteNo;

  const PrescriptionDetailPage({
    super.key,
    required this.receteNo,
  });

  @override
  State<PrescriptionDetailPage> createState() => _PrescriptionDetailPageState();
}

class _PrescriptionDetailPageState extends State<PrescriptionDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reçete Bilgileri"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocProvider(
        create: (context) {
          final cubit = PrescriptionCubit();
          // Hemen reçete bilgilerini yükle
          cubit.getPrescriptionByQR(widget.receteNo);
          return cubit;
        },
        child: BlocConsumer<PrescriptionCubit, PrescriptionState>(
          listener: (context, state) {
            if (state is PrescriptionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is PrescriptionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is PrescriptionDetailLoaded) {
              // Reçete yüklendiğinde otomatik olarak öneri iste
              context
                  .read<PrescriptionCubit>()
                  .requestPrescriptionRecommendations(
                      state.prescription.receteId, state.prescription);
            }
          },
          builder: (context, state) {
            print("state: $state");
            if (state is PrescriptionDetailLoading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is PrescriptionDetailLoaded) {
              return _buildPrescriptionDetails(context, state);
            } else if (state is PrescriptionRecommendationsLoading) {
              return _buildPrescriptionWithRecommendationsLoading(
                  context, state);
            } else if (state is PrescriptionRecommendationsLoaded) {
              return _buildPrescriptionWithRecommendations(context, state);
            } else {
              print("yükleniyor ama belirsiz olan state: $state");
              return Center(
                child: Text("Reçete bilgileri yükleniyor..."),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPrescriptionDetails(
    BuildContext context,
    PrescriptionDetailLoaded state,
  ) {
    final prescription = state.prescription;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reçete Başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Reçete Detayları",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reçete Bilgileri Kartı
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      Icons.numbers, "Reçete No", prescription.receteNo),
                  Divider(),
                  _buildInfoRow(Icons.date_range, "Tarih", prescription.tarih),
                  Divider(),
                  _buildInfoRow(Icons.person, "Hasta",
                      prescription.hasta?.ad ?? 'Bilinmiyor'),
                  Divider(),
                  _buildInfoRow(Icons.medical_information, "Hastalık",
                      prescription.hastalik?.hastalikAdi ?? 'Bilinmiyor'),
                  Divider(),
                  _buildInfoRow(
                    Icons.info_outline,
                    "Durum",
                    prescription.durum,
                    valueColor: prescription.durum == 'Onaylandı'
                        ? Colors.green
                        : prescription.durum == 'Beklemede'
                            ? Colors.orange
                            : Colors.red,
                  ),
                  if (prescription.notlar != null) ...[
                    Divider(),
                    _buildInfoRow(Icons.notes, "Notlar", prescription.notlar!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Yapay Zeka Önerileri Yükleniyor
          Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Yapay Zeka İlaç Önerileri Yükleniyor",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Mevcut İlaçlar Başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Reçetedeki İlaçlar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // İlaç Listesi
          if (prescription.ilaclar.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Henüz ilaç eklenmemiş"),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: prescription.ilaclar.length,
              itemBuilder: (context, index) {
                final ilac = prescription.ilaclar[index];
                return Card(
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.tertiaryContainer,
                      child: Icon(
                        Icons.medication_liquid,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    title: Text(
                      ilac.ilac?.ilacAdi ?? 'Bilinmeyen İlaç',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        if (ilac.dozaj != null)
                          _buildMedicationInfoItem(
                              Icons.timer, "Dozaj: ${ilac.dozaj}"),
                        if (ilac.kullanimTalimati != null)
                          _buildMedicationInfoItem(Icons.info_outline,
                              "Kullanım: ${ilac.kullanimTalimati}"),
                        _buildMedicationInfoItem(Icons.inventory_2_outlined,
                            "Miktar: ${ilac.miktar} kutu"),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionWithRecommendationsLoading(
    BuildContext context,
    PrescriptionState state,
  ) {
    // PrescriptionDetailLoaded state'inden reçete bilgilerini almak için
    final prescriptionState = context.read<PrescriptionCubit>().state;
    final prescription = prescriptionState is PrescriptionDetailLoaded
        ? prescriptionState.prescription
        : null;

    if (prescription == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reçete Başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Reçete Detayları",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reçete Bilgileri Kartı
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      Icons.numbers, "Reçete No", prescription.receteNo),
                  Divider(),
                  _buildInfoRow(Icons.date_range, "Tarih", prescription.tarih),
                  Divider(),
                  _buildInfoRow(Icons.person, "Hasta",
                      prescription.hasta?.ad ?? 'Bilinmiyor'),
                  Divider(),
                  _buildInfoRow(Icons.medical_information, "Hastalık",
                      prescription.hastalik?.hastalikAdi ?? 'Bilinmiyor'),
                  Divider(),
                  _buildInfoRow(
                    Icons.info_outline,
                    "Durum",
                    prescription.durum,
                    valueColor: prescription.durum == 'Onaylandı'
                        ? Colors.green
                        : prescription.durum == 'Beklemede'
                            ? Colors.orange
                            : Colors.red,
                  ),
                  if (prescription.notlar != null) ...[
                    Divider(),
                    _buildInfoRow(Icons.notes, "Notlar", prescription.notlar!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Shimmer İlaç Önerileri Başlığı
          Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.primary,
            highlightColor: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Yapay Zeka İlaç Önerileri",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Açıklama
          Text(
            "Hastanız için en uygun ilaçlar analiz ediliyor...",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),

          // Shimmer Loading İlaç Kartı
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Mevcut İlaçlar Başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Reçetedeki İlaçlar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // İlaç Listesi
          if (prescription.ilaclar.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Henüz ilaç eklenmemiş"),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: prescription.ilaclar.length,
              itemBuilder: (context, index) {
                final ilac = prescription.ilaclar[index];
                return Card(
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.tertiaryContainer,
                      child: Icon(
                        Icons.medication_liquid,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    title: Text(
                      ilac.ilac?.ilacAdi ?? 'Bilinmeyen İlaç',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        if (ilac.dozaj != null)
                          _buildMedicationInfoItem(
                              Icons.timer, "Dozaj: ${ilac.dozaj}"),
                        if (ilac.kullanimTalimati != null)
                          _buildMedicationInfoItem(Icons.info_outline,
                              "Kullanım: ${ilac.kullanimTalimati}"),
                        _buildMedicationInfoItem(Icons.inventory_2_outlined,
                            "Miktar: ${ilac.miktar} kutu"),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionWithRecommendations(
    BuildContext context,
    PrescriptionRecommendationsLoaded state,
  ) {
    final recommendations = state.recommendations;

    // PrescriptionDetailLoaded state'inden reçete bilgilerini almak için
    final prescriptionState = context.read<PrescriptionCubit>().state;
    final prescription = prescriptionState is PrescriptionDetailLoaded
        ? prescriptionState.prescription
        : (prescriptionState is PrescriptionRecommendationsLoaded
            ? prescriptionState.prescription
            : null);
    print("prescription null mu :  $prescription");

    if (prescription == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reçete Başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Reçete Detayları",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Reçete Bilgileri Kartı
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                      Icons.numbers, "Reçete No", prescription.receteNo),
                  Divider(),
                  _buildInfoRow(Icons.date_range, "Tarih", prescription.tarih),
                  Divider(),
                  _buildInfoRow(Icons.person, "Hasta",
                      prescription.hasta?.ad ?? 'Bilinmiyor'),
                  Divider(),
                  _buildInfoRow(Icons.medical_information, "Hastalık",
                      prescription.hastalik?.hastalikAdi ?? 'Bilinmiyor'),
                  Divider(),
                  _buildInfoRow(
                    Icons.info_outline,
                    "Durum",
                    prescription.durum,
                    valueColor: prescription.durum == 'Onaylandı'
                        ? Colors.green
                        : prescription.durum == 'Beklemede'
                            ? Colors.orange
                            : Colors.red,
                  ),
                  if (prescription.notlar != null) ...[
                    Divider(),
                    _buildInfoRow(Icons.notes, "Notlar", prescription.notlar!),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Yapay Zeka İlaç Önerileri Başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Yapay Zeka İlaç Önerileri",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            "Hasta için en uygun ilaç önerileri",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 16),

          // İlaç Önerileri
          recommendations.isEmpty
              ? Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              "Öneri bulunamadı. Tekrar denemek için tıklayınız."),
                        ),
                        SizedBox(
                          width: 140, // veya başka bir sabit genişlik
                          child: ElevatedButton(
                            onPressed: () {
                              context
                                  .read<PrescriptionCubit>()
                                  .requestPrescriptionRecommendations(
                                      prescription.receteId, prescription);
                            },
                            child: Text("Tekrar Dene"),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 250,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst Bilgi Çubuğu
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.red.shade400,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "% ${(recommendations[0].oneriPuani).toStringAsFixed(0)} Uyumluluk",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                              Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  "En Uygun Öneri",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // İlaç İçerik Kısmı
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.medication,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 30,
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      recommendations[0].ilac?.ilacAdi ??
                                          'Bilinmeyen İlaç',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    if (recommendations[0].oneriSebebi != null)
                                      Text(
                                        recommendations[0].oneriSebebi!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Spacer ekleyelim ki butonlar alta yapışsın
                        Spacer(),

                        // Alt Butonlar
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // Tüm önerileri gösterme işlevi
                                  _showAllRecommendations(
                                      context, recommendations);
                                },
                                icon: Icon(Icons.view_list),
                                label: Text("Tüm Öneriler"),
                              ),
                              SizedBox(width: 8),
                              SizedBox(
                                width: 190,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showAddToRecipeDialog(
                                        context, recommendations[0]);
                                  },
                                  icon: Icon(Icons.add),
                                  label: Text("Reçeteye Ekle"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

          const SizedBox(height: 24),

          // Mevcut İlaçlar Başlığı
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              SizedBox(width: 12),
              Text(
                "Reçetedeki İlaçlar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // İlaç Listesi
          if (prescription.ilaclar.isEmpty)
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text("Henüz ilaç eklenmemiş"),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: prescription.ilaclar.length,
              itemBuilder: (context, index) {
                final ilac = prescription.ilaclar[index];
                return Card(
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.tertiaryContainer,
                      child: Icon(
                        Icons.medication_liquid,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    title: Text(
                      ilac.ilac?.ilacAdi ?? 'Bilinmeyen İlaç',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        if (ilac.dozaj != null)
                          _buildMedicationInfoItem(
                              Icons.timer, "Dozaj: ${ilac.dozaj}"),
                        if (ilac.kullanimTalimati != null)
                          _buildMedicationInfoItem(Icons.info_outline,
                              "Kullanım: ${ilac.kullanimTalimati}"),
                        _buildMedicationInfoItem(Icons.inventory_2_outlined,
                            "Miktar: ${ilac.miktar} kutu"),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllRecommendations(
      BuildContext context, List<dynamic> recommendations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text("Tüm İlaç Önerileri"),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text("${index + 1}"),
                    ),
                    title: Text(
                      recommendation.ilac?.ilacAdi ?? 'Bilinmeyen İlaç',
                    ),
                    subtitle: Text(
                      "Uyumluluk: %${(recommendation.oneriPuani).toStringAsFixed(0)}",
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddToRecipeDialog(context, recommendation);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  void _showAddToRecipeDialog(
    BuildContext context,
    final recommendation,
  ) {
    final formKey = GlobalKey<FormState>();
    String? dozaj;
    String? kullanimTalimati;
    int miktar = 1;

    // Dozaj önerileri
    final dozajOnerileri = [
      '1x1 (Günde bir tablet)',
      '2x1 (Günde iki tablet)',
      '3x1 (Günde üç tablet)',
      '1x2 (Günde bir, iki adet)',
      'Gerektiğinde',
      'Sabah-Akşam 1 tablet',
    ];

    // Kullanım talimatı önerileri
    final kullanimTalimatiOnerileri = [
      'Yemeklerden sonra alınız',
      'Aç karnına alınız',
      'Tok karnına alınız',
      'Bol su ile alınız',
      'Gece yatmadan önce alınız',
      'Sabah aç karnına alınız',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_circle,
                  color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text("İlacı Reçeteye Ekle"),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recommendation.ilac?.ilacAdi ?? 'İlaç',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Dozaj",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Dozaj",
                      hintText: "Bir dozaj seçin veya yazın",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: dozajOnerileri.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      dozaj = newValue;
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Kullanım Talimatı",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Kullanım Talimatı",
                      hintText: "Bir talimat seçin veya yazın",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: kullanimTalimatiOnerileri.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      kullanimTalimati = newValue;
                    },
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Miktar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: "Kutu Sayısı",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: miktar.toString(),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Miktar gerekli";
                            }
                            if (int.tryParse(value) == null ||
                                int.parse(value) < 1) {
                              return "Geçerli bir miktar girin";
                            }
                            return null;
                          },
                          onSaved: (value) => miktar = int.parse(value!),
                          onChanged: (value) {
                            if (value.isNotEmpty &&
                                int.tryParse(value) != null) {
                              miktar = int.parse(value);
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () {
                                if (miktar > 1) {
                                  setState(() {
                                    miktar--;
                                  });
                                }
                              },
                            ),
                            Text(
                              miktar.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  miktar++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(context);

                  // Reçete ID'sini al (detayı yüklenen reçete)
                  final state = context.read<PrescriptionCubit>().state;
                  if (state is PrescriptionDetailLoaded) {
                    context
                        .read<PrescriptionCubit>()
                        .addSuggestionToPrescription(
                          state.prescription.receteId,
                          recommendation.oneriId,
                          dozaj: dozaj,
                          kullanimTalimati: kullanimTalimati,
                          miktar: miktar,
                        );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text("Ekle"),
            ),
          ],
        );
      },
    );
  }
}
