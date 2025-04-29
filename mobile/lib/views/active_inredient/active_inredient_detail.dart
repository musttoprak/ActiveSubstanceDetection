import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/views/medicine/medicine_list_item.dart';
import '../../models/response_models/active_ingredient_response_model.dart';
import '../../models/response_models/medicine_response_model.dart';
import '../../service/active_ingredient_service.dart';

class ActiveIngredientDetailPage extends StatefulWidget {
  final EtkenMaddeResponseModel ingredient;

  const ActiveIngredientDetailPage({super.key, required this.ingredient});

  @override
  State<ActiveIngredientDetailPage> createState() =>
      _ActiveIngredientDetailPageState();
}

class _ActiveIngredientDetailPageState
    extends State<ActiveIngredientDetailPage> {
  List<MedicineResponseModel> _medicines = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRelatedMedicines();
  }

  Future<void> _loadRelatedMedicines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Etken maddeye ait ilaçları çek
      final medicines = await ActiveIngredientService.getRelatedMedicines(
          widget.ingredient.etkenMaddeId);

      setState(() {
        _medicines = medicines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "İlaç bilgileri yüklenirken bir hata oluştu: $e";
        _isLoading = false;
      });
      print("Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Etkin Madde Bilgisi"),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Üst Bilgi Bölümü
            _buildHeader(context),
            // Sekme Bölgesi
            const TabBar(
              indicatorColor: Colors.transparent, // Sekme altında görünen mor çizgiyi kaldırır
              labelColor: Colors.black, // Aktif sekmenin yazı rengini değiştirir
              unselectedLabelColor: Colors.grey, // Seçili olmayan sekmelerin yazı rengini değiştirir
              tabs: [
                Tab(icon: Icon(Icons.info), text: "Genel Bilgi"),
                Tab(icon: Icon(Icons.science), text: "Müstahzarlar"),
              ],
            ),
            // İçerik Bölgesi
            Expanded(
              child: TabBarView(
                children: [
                  _buildInfoTab(),
                  _buildProductsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildEtkenMaddeImage(),
          const SizedBox(height: 10),
          Text(
            widget.ingredient.etkenMaddeAdi,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (widget.ingredient.ingilizceAdi != null &&
              widget.ingredient.ingilizceAdi!.isNotEmpty)
            Text(
              "(${widget.ingredient.ingilizceAdi})",
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    "Formül: ${widget.ingredient.formul ?? 'Belirtilmemiş'}",
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Kütle: ${widget.ingredient.netKutle ?? 'Belirtilmemiş'}",
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          if (widget.ingredient.molekulAgirligi != null)
            Text(
              "Molekül Ağırlığı: ${widget.ingredient.molekulAgirligi}",
              style: const TextStyle(fontSize: 12),
            ),
          if (widget.ingredient.atcKodlari != null &&
              widget.ingredient.atcKodlari!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "ATC Kod: ${widget.ingredient.atcKodlari}",
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEtkenMaddeImage() {
    final String imageUrl = widget.ingredient.resimUrl ??
        'https://static.tebrp.com/etkin_resim/etkinMaddeNoImg.svg';

    if (imageUrl.endsWith('.svg')) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: SvgPicture.network(
            imageUrl,
            placeholderBuilder: (context) => const CircularProgressIndicator(),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.medication, size: 40, color: Colors.grey);
            },
          ),
        ),
      );
    }
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection("Genel Bilgi", widget.ingredient.genelBilgi),
          _buildInfoSection(
              "Etki Mekanizması", widget.ingredient.etkiMekanizmasi),
          _buildInfoSection("Farmakokinetik", widget.ingredient.farmakokinetik),
          if (widget.ingredient.etkenMaddeKategorisi != null)
            _buildInfoSection(
                "Kategori", widget.ingredient.etkenMaddeKategorisi),
          if (widget.ingredient.aciklama != null)
            _buildInfoSection("Ek Açıklama", widget.ingredient.aciklama),
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
        _buildSectionHeader(title),
        const SizedBox(height: 8),
        Text(content),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRelatedMedicines,
              child: const Text("Tekrar Dene"),
            ),
          ],
        ),
      );
    }

    // Özel ilaç listesi widget'ını kullan (buildMedicineList medicine_list.dart'dan geliyor)
    return buildMedicineList(_medicines);
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
