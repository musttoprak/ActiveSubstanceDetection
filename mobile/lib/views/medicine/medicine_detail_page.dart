import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/service/active_ingredient_service.dart';
import 'package:mobile/views/active_inredient/active_inredient_detail.dart';

import '../../models/response_models/medicine_response_model.dart';

class MedicineDetailPage extends StatefulWidget {
  final MedicineResponseModel medicine;

  const MedicineDetailPage({super.key, required this.medicine});

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  Future<void> _fetchActiveIngredientDetails(int ingredientId) async {
    try {
      var response = await ActiveIngredientService.getActiveIngredientDetails(
          ingredientId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveIngredientDetailPage(
            ingredient: response,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Veri alınamadı')));
    }
  }

  // Helper method to truncate medicine name
  String _truncateMedicineName(String? medicineName) {
    if (medicineName == null || medicineName.isEmpty) return 'İlaç Bilgisi';

    print(medicineName.length);
    // Truncate to 60 characters if longer
    return medicineName.length > 200
        ? '${medicineName.substring(0, 200)}...'
        : medicineName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding:
                  const EdgeInsets.only(bottom: 16, left: 54, right: 54),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.9),
                          Theme.of(context).primaryColor.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),

                  // Content Column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Medication Icon
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.medication_rounded,
                          size: 50,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              title: Text(
                widget.medicine.ilacAdi ?? "İlaç Bilgisi",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İlaç Temel Bilgileri
                _buildBasicInfo(context),

                // Detaylar
                _buildTabContent(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Card(
      color: Color(0xFFF3F7FC),
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // İlaç adı ve firma
            if (widget.medicine.ilacAdiFirma != null &&
                widget.medicine.ilacAdiFirma != widget.medicine.ilacAdi)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.medicine.ilacAdiFirma ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // SGK Durumu
            if (widget.medicine.sgkDurumu != null &&
                widget.medicine.sgkDurumu!.isNotEmpty)
              _buildStatusCard(
                  context,
                  widget.medicine.sgkDurumu!.toLowerCase().contains('ödemez') ||
                          widget.medicine.sgkDurumu!
                              .toLowerCase()
                              .contains('ödenmez')
                      ? Colors.red
                      : Colors.green,
                  'SGK Durumu',
                  widget.medicine.sgkDurumu!,
                  Icons.health_and_safety),

            const SizedBox(height: 16),

            // Ana bilgiler - 3 kart
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    context,
                    Icons.business,
                    'Üretici',
                    widget.medicine.ureticiFirma ?? 'Belirtilmemiş',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    Icons.description,
                    'Reçete',
                    widget.medicine.receteTipi ?? 'Belirtilmemiş',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    context,
                    Icons.payments,
                    'Fiyat',
                    widget.medicine.perakendeSatisFiyati != null
                        ? '${widget.medicine.perakendeSatisFiyati} ₺'
                        : 'Belirtilmemiş',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Barkod ve ATC Kodu
            if (widget.medicine.barkod != null ||
                widget.medicine.atcKodu != null)
              Row(
                children: [
                  if (widget.medicine.barkod != null)
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        Icons.qr_code,
                        'Barkod',
                        widget.medicine.barkod!,
                        isCode: true,
                      ),
                    ),
                  if (widget.medicine.barkod != null &&
                      widget.medicine.atcKodu != null)
                    const SizedBox(width: 8),
                  if (widget.medicine.atcKodu != null)
                    Expanded(
                      child: _buildInfoCard(
                        context,
                        Icons.code,
                        'ATC Kodu',
                        widget.medicine.atcKodu!,
                        isCode: true,
                      ),
                    ),
                ],
              ),

            if (widget.medicine.miktar != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildInfoCard(
                  context,
                  Icons.science,
                  'Etken Madde Miktarı',
                  widget.medicine.miktar!,
                  fullWidth: true,
                ),
              ),

            // Etken Maddeler
            if (widget.medicine.etkenMaddeler != null &&
                widget.medicine.etkenMaddeler!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      'Etken Maddeler',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    buildActiveIngredientsList(
                        widget.medicine.etkenMaddeler ?? []),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildActiveIngredientsList(List<dynamic> etkenMaddeler) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: etkenMaddeler.length,
      itemBuilder: (context, index) {
        final etkenMadde = etkenMaddeler[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.blue.shade50,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () =>
                    _fetchActiveIngredientDetails(etkenMadde['etken_madde_id']),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Circular icon container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.science_rounded,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Ingredient name
                      Expanded(
                        child: Text(
                          etkenMadde['etken_madde_adi'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Forward arrow
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.blue.shade700,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context, Color color, String title,
      String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, IconData icon, String title, String value,
      {bool isCode = false, bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isCode ? 11 : 12,
              fontFamily: isCode ? 'Courier' : null,
            ),
            textAlign: TextAlign.center,
            maxLines: fullWidth ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection("Etken Madde Miktarı", widget.medicine.miktar),
          _buildInfoSection(
              "Etki Mekanizması", widget.medicine.etkiMekanizmasi),
          _buildInfoSection("Farmakokinetik", widget.medicine.farmakokinetik),
          _buildInfoSection("Farmakodinamik", widget.medicine.farmakodinamik),
          _buildInfoSection("Endikasyonlar", widget.medicine.endikasyonlar),
          _buildInfoSection(
              "Kontrendikasyonlar", widget.medicine.kontrendikasyonlar),
          _buildInfoSection("Kullanım Yolu", widget.medicine.kullanimYolu),
          _buildInfoSection("Yan Etkiler", widget.medicine.yanEtkiler),
          _buildInfoSection(
              "İlaç Etkileşimleri", widget.medicine.ilacEtkilesimleri),
          _buildInfoSection("Özel Popülasyon Bilgileri",
              widget.medicine.ozelPopulasyonBilgileri),
          _buildInfoSection(
              "Uyarılar ve Önlemler", widget.medicine.uyarilarVeOnlemler),
          _buildInfoSection("Formülasyon", widget.medicine.formulasyon),
          _buildInfoSection("Ambalaj Bilgisi", widget.medicine.ambalajBilgisi),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String? content) {
    if (content == null || content.isEmpty) {
      return const SizedBox.shrink(); // Boş içerik varsa gösterme
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(content),
        ),
        const Divider(height: 32),
      ],
    );
  }
}
