import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/response_models/active_ingredient_response_model.dart';

class ActiveIngredientDetailPage extends StatelessWidget {
  final ActiveIngredientResponseModel ingredient;

  const ActiveIngredientDetailPage({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    print(ingredient);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("ETKİN MADDE BİLGİSİ"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Üst Bilgi Bölümü
            _buildHeader(context),
            // Sekme Bölgesi
            const TabBar(
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
          CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(ingredient.image_src ??
                'https://static.tebrp.com/etkin_resim/etkinMaddeNoImg.svg'),
          ),
          const SizedBox(height: 10),
          Text(
            ingredient.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Text(
                    "Formül: ${ingredient.formula ?? 'N/A'}",
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Ağırlık: ${ingredient.weight ?? 'N/A'}",
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Molekül Ağırlığı: ${ingredient.molecular_weight ?? 'N/A'}",
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Genel Bilgi"),
          Text(ingredient.general_info ?? "Bilgi bulunamadı."),
          const SizedBox(height: 20),
          _buildSectionHeader("Etki Mekanizması"),
          Text(ingredient.mechanism ?? "Bilgi bulunamadı."),
          const SizedBox(height: 20),
          _buildSectionHeader("Farmakokinetik"),
          Text(ingredient.pharmacokinetics ?? "Bilgi bulunamadı."),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return ListView.builder(
      itemCount: ingredient.preparations?.length ?? 0,
      itemBuilder: (context, index) {
        final preparation = ingredient.preparations![index];
        return ListTile(
          leading: const Icon(Icons.medical_services),
          title: Text(preparation.name),
          subtitle: Text(preparation.company ?? "Firma bilgisi yok"),
          trailing: Text(preparation.sgk_status ?? "Durum yok", style: TextStyle(color: preparation.sgk_status == 'SGK Yok' ? Colors.red : Colors.green),),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
