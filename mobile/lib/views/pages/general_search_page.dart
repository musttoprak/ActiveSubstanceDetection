import 'package:flutter/material.dart';

import '../../service/pages_service.dart';

class GeneralSearchPage extends StatefulWidget {
  const GeneralSearchPage({Key? key}) : super(key: key);

  @override
  _GeneralSearchPageState createState() => _GeneralSearchPageState();
}

class _GeneralSearchPageState extends State<GeneralSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchCategory = 'İlaçlar'; // Varsayılan kategori
  List<dynamic> _searchResults = [];

  // Arama sonuçlarını gösteren API çağrısı (Burada örnek bir API kullanıyoruz)
  Future<void> _searchData() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    // API çağrısını yapıyoruz
    final results = await PagesService.fetchSearchResults(query, _searchCategory);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Genel Arama"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arama Kategorisi Seçimi
            DropdownButton<String>(
              value: _searchCategory,
              onChanged: (value) {
                setState(() {
                  _searchCategory = value!;
                });
              },
              items: ['İlaçlar', 'Etken Maddeler', 'Hastalar']
                  .map((category) => DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Arama Alanı
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Aramak istediğiniz veriyi yazın...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchData,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Arama Sonuçları
            Expanded(
              child: _searchResults.isNotEmpty
                  ? ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_searchResults[index]['name']),
                    subtitle: Text(_searchResults[index]['description']),
                    onTap: () {
                      // Detay sayfasına gitmek için
                    },
                  );
                },
              )
                  : const Center(child: Text('Arama Sonucu Bulunamadı')),
            ),
          ],
        ),
      ),
    );
  }
}
