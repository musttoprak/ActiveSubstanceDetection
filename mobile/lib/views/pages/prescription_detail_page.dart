// pages/prescription_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/prescription_cubit.dart';
import 'package:mobile/models/response_models/drug_recommendation_model.dart';
import 'package:mobile/models/response_models/prescription_response_model.dart';
import 'package:mobile/views/medicine/medicine_detail_page.dart';

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
            print("listener: ${state.runtimeType}");
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
              if (!state.isAddMedicine) {
                // Reçete yüklendiğinde otomatik olarak öneri iste
                context
                    .read<PrescriptionCubit>()
                    .requestPrescriptionRecommendations(
                        state.prescription.receteId, state.prescription);
              }
            }
          },
          builder: (context, state) {
            // Birleştirilmiş reçete içerik builder kullanımı
            return _buildPrescriptionContent(context, state);
          },
        ),
      ),
    );
  }

  PrescriptionResponseModel? _getPrescriptionFromState(
      BuildContext context, PrescriptionState state) {
    if (state is PrescriptionDetailLoaded) {
      return state.prescription;
    } else if (state is PrescriptionRecommendationsLoaded) {
      return state.prescription;
    } else if (state is PrescriptionRecommendationsLoading) {
      // Önceki state'ten reçete bilgilerini almaya çalış
      final prevState = context.read<PrescriptionCubit>().state;
      if (prevState is PrescriptionDetailLoaded) {
        return prevState.prescription;
      }
    }
    return null;
  }

  Widget _buildPrescriptionContent(
      BuildContext context, PrescriptionState state) {
    // Reçete bilgilerini state'e göre al
    final prescription = _getPrescriptionFromState(context, state);

    // İlaç önerilerini state'e göre al
    final recommendations = state is PrescriptionRecommendationsLoaded
        ? state.recommendations
        : <DrugRecommendationModel>[];

    // Yükleme durumları
    final bool isLoadingRecommendations = state is PrescriptionDetailLoaded;
    final bool isLoadedRecommeddations =
        state is PrescriptionRecommendationsLoaded;
    print(state.runtimeType);
    // Hata durumu
    if (state is PrescriptionError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red.shade300,
            ),
            SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (state is PrescriptionDetailError) {
                  // Reçete detaylarını yeniden yükle
                  context
                      .read<PrescriptionCubit>()
                      .getPrescriptionByQR(state.receteNo);
                }
              },
              child: Text("Tekrar Dene"),
            ),
          ],
        ),
      );
    }

    // Reçete detayları henüz yüklenmediyse
    if (prescription == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Reçete bilgileri yükleniyor..."),
          ],
        ),
      );
    }

    // Ana içerik
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reçete Başlığı
          BaslikWidget(
            icon: Icons.receipt_long,
            title: "Reçete Detayları",
          ),

          const SizedBox(height: 16),

          // Reçete Bilgileri Kartı
          receteBilgileriCard(context, prescription),

          const SizedBox(height: 24),

          // Yapay Zeka Başlığı
          BaslikWidget(
            icon: Icons.lightbulb_outline,
            title: "Yapay Zeka İlaç Önerileri",
            subtitle: "Hasta için en uygun ilaç önerileri",
          ),

          const SizedBox(height: 16),

          // Öneriler durumu
          // Her bir parça için benzersiz bir key ile yeniden düzenlenmiş hali
          AnimatedSwitcher(
            duration: Duration(milliseconds: 800),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: isLoadingRecommendations
                ? oneriYukleniyor(context, key: ValueKey('loading'))
                : isLoadedRecommeddations && recommendations.isEmpty
                    ? ilacOnerisiBos(context, prescription,
                        key: ValueKey('empty'))
                    : isLoadedRecommeddations ? ilacOnerisi(context, recommendations,
                        key: ValueKey('loaded')) : null,
          ),

          const SizedBox(height: 24),

          // Reçetedeki İlaçlar
          BaslikWidget(
            icon: Icons.medication,
            title: "Reçetedeki İlaçlar",
          ),

          const SizedBox(height: 12),

          // İlaç Listesi
          if (prescription.ilaclar.isEmpty)
            ilacListesiBos(context)
          else
            ilacListesi(prescription),
        ],
      ),
    );
  }

  Card receteBilgileriCard(
      BuildContext context, PrescriptionResponseModel prescription) {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reçete bilgileri
              _buildInfoRowModern(
                context,
                Icons.numbers_rounded,
                "Reçete No",
                prescription.receteNo,
                isFirst: true,
              ),
              _buildInfoRowModern(
                context,
                Icons.calendar_today_rounded,
                "Tarih",
                prescription.tarih,
              ),
              _buildInfoRowModern(
                context,
                Icons.person_rounded,
                "Hasta",
                prescription.hasta?.ad ?? 'Bilinmiyor',
              ),
              _buildInfoRowModern(
                context,
                Icons.medical_services_rounded,
                "Hastalık",
                prescription.hastalik?.hastalikAdi ?? 'Bilinmiyor',
              ),
              _buildInfoRowModern(context, Icons.info_outline_rounded, "Durum",
                  prescription.durum,
                  valueColor: prescription.durum == 'Onaylandı'
                      ? Colors.green
                      : prescription.durum == 'Beklemede'
                          ? Colors.orange
                          : Colors.red,
                  iconColor: prescription.durum == 'Onaylandı'
                      ? Colors.green
                      : prescription.durum == 'Beklemede'
                          ? Colors.orange
                          : Colors.red,
                  isLast: prescription.notlar != null ? false : true),
              if (prescription.notlar != null)
                _buildInfoRowModern(
                  context,
                  Icons.notes_rounded,
                  "Notlar",
                  prescription.notlar!,
                  isLast: true,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Column ilacListesi(PrescriptionResponseModel prescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // İlaç Listesi
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: prescription.ilaclar.length,
          itemBuilder: (context, index) {
            final PrescriptionMedicationModel ilac =
                prescription.ilaclar[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.2),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // İlaç detaylarını göster
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MedicineDetailPage(medicine: ilac.ilac!),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // İlaç ikonu
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.tertiary,
                                index / prescription.ilaclar.length,
                              )!
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.medication_liquid,
                                color: Color.lerp(
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.tertiary,
                                  index / prescription.ilaclar.length,
                                ),
                                size: 26,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),

                          // İlaç bilgileri
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ilac.ilac?.ilacAdi ?? 'Bilinmeyen İlaç',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (ilac.dozaj != null) ...[
                                      _buildMedicationTagModern(
                                        context,
                                        Icons.timer_outlined,
                                        ilac.dozaj!,
                                        Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                    ],
                                    _buildMedicationTagModern(
                                      context,
                                      Icons.inventory_2_outlined,
                                      "${ilac.miktar} kutu",
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                                if (ilac.kullanimTalimati != null) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ilac.kullanimTalimati!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Detay ikonu
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Card ilacListesiBos(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.medication_outlined,
                color: Colors.orange,
                size: 40,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Henüz İlaç Eklenmemiş",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Yapay zeka önerilerinden reçeteye ilaç ekleyebilirsiniz",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox oneriYukleniyor(BuildContext context, {Key? key}) {
    return SizedBox(
      key: key,
      height: 240,
      child: Card(
        elevation: 4,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              // Animate shimmer effect
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Yapay Zeka Önerileri Hazırlanıyor",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Hasta bilgileri ve hastalık verilerine göre en uygun ilaçlar analiz ediliyor",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row receteBasligi(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.receipt_long, color: Colors.white),
        ),
        SizedBox(width: 12),
        Text(
          "Reçete Detayları",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  SizedBox ilacOnerisi(
      BuildContext context, List<DrugRecommendationModel> recommendations,
      {Key? key}) {
    return SizedBox(
      key: key,
      height: 240,
      child: Card(
        elevation: 4,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bilgi Çubuğu
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    Theme.of(context).colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Yapay Zeka Önerisi",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Hasta profiline en uygun ilaç",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red.shade100,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "${(recommendations[0].oneriPuani).toStringAsFixed(0)}% Uyumlu",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // İlaç İçerik Kısmı
            Expanded(
              child: InkWell(
                onTap: () {
                  // İlaç detaylarını göster
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MedicineDetailPage(medicine: recommendations[0].ilac!),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // İlaç ikonu
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.medication,
                                color: Theme.of(context).colorScheme.primary,
                                size: 32,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),

                          // İlaç bilgileri
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recommendations[0].ilac?.ilacAdi ??
                                      'Bilinmeyen İlaç',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                SizedBox(height: 6),
                                if (recommendations[0].oneriSebebi != null)
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant
                                          .withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 15,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            recommendations[0].oneriSebebi!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Alt Butonlar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showAllRecommendations(context, recommendations);
                              },
                              icon: Icon(Icons.list_alt),
                              label: Text("Tüm Öneriler"),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 165,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showAddToRecipeDialog(
                                    context, recommendations[0],
                                    isHome: true);
                              },
                              icon: Icon(Icons.add, color: Colors.white),
                              label: Text("Reçeteye Ekle"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox ilacOnerisiBos(
      BuildContext context, PrescriptionResponseModel prescription,
      {Key? key}) {
    return SizedBox(
      key: key,
      height: 240,
      child: Card(
        elevation: 4,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.errorContainer.withOpacity(0.7),
                Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.search_off_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Öneri Bulunamadı",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Yapay zeka önerileri için tekrar deneyebilirsiniz",
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer
                                .withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<PrescriptionCubit>()
                            .requestPrescriptionRecommendations(
                                prescription.receteId, prescription);
                      },
                      icon: Icon(Icons.refresh_rounded, size: 18),
                      label: Text("Yenile", style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
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

  Widget yapayZekaBaslik(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.lightbulb_outline,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Yapay Zeka İlaç Önerileri",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              "Hasta için en uygun ilaç önerileri",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Row recetedekiIlaclarBasligi(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.medication,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 12),
        Text(
          "Reçetedeki İlaçlar",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationTagModern(
    BuildContext context,
    IconData icon,
    String text,
    Color accentColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: accentColor.withOpacity(0.8),
          ),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: accentColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowModern(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    Color? iconColor,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAllRecommendations(
      BuildContext context, List<DrugRecommendationModel> recommendations) {
    final genelContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve kapatma butonu
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Tüm İlaç Önerileri",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${recommendations.length} farklı ilaç önerisi, hasta profili ve hastalık bilgilerine göre sıralandı",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // İlaç önerileri listesi
                Expanded(
                  child: recommendations.isEmpty
                      ? Center(
                          child: Text("Henüz ilaç önerisi bulunmuyor"),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            final recommendation = recommendations[index];
                            final uyumYuzdesi =
                                (recommendation.oneriPuani).toStringAsFixed(0);
                            final uyumColor = _getUyumColor(
                                recommendation.oneriPuani, context);

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .shadowColor
                                        .withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  // İlaç detaylarını göster
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MedicineDetailPage(medicine: recommendation.ilac!),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Sıralama numarası
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: index < 3
                                              ? [
                                                  Color(
                                                      0xFFFFD500), // Altın (1. sıra)
                                                  Color(
                                                      0xFFC0C0C0), // Gümüş (2. sıra)
                                                  Color(
                                                      0xFFCD7F32), // Bronz (3. sıra)
                                                ][index]
                                                  .withOpacity(0.2)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceVariant
                                                  .withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "${index + 1}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: index < 3
                                                  ? [
                                                      Color(
                                                          0xFFB59900), // Altın
                                                      Color(
                                                          0xFFC0C0C0), // Gümüş
                                                      Color(
                                                          0xFFCD7F32), // Bronz
                                                    ][index]
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),

                                      // İlaç bilgileri
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                recommendation.ilac?.ilacAdi ??
                                                    'Bilinmeyen İlaç',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 3,
                                              ),
                                              SizedBox(height: 4),
                                              if (recommendation.oneriSebebi !=
                                                  null) ...[
                                                Text(
                                                  recommendation.oneriSebebi!,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 8),
                                              ],

                                              // Uyum yüzdesi
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: uyumColor
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: uyumColor
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.favorite,
                                                      size: 14,
                                                      color: uyumColor,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "%$uyumYuzdesi Uyumluluk",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: uyumColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Ekle butonu
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.add,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _showAddToRecipeDialog(
                                                genelContext, recommendation);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Alt butonlar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: Text("Kapat"),
                      ),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (recommendations.isNotEmpty) {
                              _showAddToRecipeDialog(
                                  genelContext, recommendations[0]);
                            }
                          },
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text("En Uygun İlacı Ekle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getUyumColor(double uyumYuzdesi, BuildContext context) {
    if (uyumYuzdesi >= 80) {
      return Colors.green.shade700;
    } else if (uyumYuzdesi >= 60) {
      return Colors.amber.shade700;
    } else if (uyumYuzdesi >= 40) {
      return Colors.orange;
    } else {
      return Colors.red.shade400;
    }
  }

  void _showAddToRecipeDialog(BuildContext context, final recommendation,
      {bool isHome = false}) {
    final formKey = GlobalKey<FormState>();
    String? dozaj;
    String? kullanimTalimati;
    int miktar = 1;

    final prescriptionCubit =
        context.read<PrescriptionCubit>(); // 👈 Provider burada yakalanıyor

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
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              insetPadding: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.all(16),
              title: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.medication_liquid_sharp, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "İlacı Reçeteye Ekle",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // İlaç bilgisi
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          margin: EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(Icons.local_pharmacy,
                                  color: Theme.of(context).colorScheme.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recommendation.ilac?.ilacAdi ?? 'İlaç',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Dozaj
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration(
                              Icons.medication_outlined,
                              "Bir dozaj seçin",
                              context),
                          isExpanded: true,
                          items: dozajOnerileri
                              .map((value) => DropdownMenuItem(
                                  value: value, child: Text(value)))
                              .toList(),
                          onChanged: (newValue) => dozaj = newValue,
                        ),

                        SizedBox(height: 16),

                        // Kullanım Talimatı
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration(
                              Icons.info_outline, "Bir talimat seçin", context),
                          isExpanded: true,
                          items: kullanimTalimatiOnerileri
                              .map((value) => DropdownMenuItem(
                                  value: value, child: Text(value)))
                              .toList(),
                          onChanged: (newValue) => kullanimTalimati = newValue,
                        ),

                        SizedBox(height: 16),

                        // Miktar
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: miktar > 1
                                    ? () => dialogSetState(() => miktar--)
                                    : null,
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    "$miktar kutu",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: () => dialogSetState(() => miktar++),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
              ),
              actionsPadding: EdgeInsets.all(16),
              actions: [
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("İptal"),
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        Navigator.pop(context);
                        if (!isHome) {
                          Navigator.pop(context);
                        }
                        final state = prescriptionCubit.state;
                        if (state is PrescriptionRecommendationsLoaded) {
                          prescriptionCubit.addSuggestionToPrescription(
                            state.prescription.receteNo,
                            state.prescription.receteId,
                            state,
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
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("Ekle"),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(
      IconData icon, String hint, BuildContext context) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class BaslikWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const BaslikWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
      subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
          subtitle != null ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

