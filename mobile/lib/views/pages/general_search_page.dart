import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mobile/models/response_models/active_ingredient_response_model.dart';
import 'package:mobile/models/response_models/medicine_response_model.dart';
import 'package:mobile/models/response_models/patient_response_model.dart';
import 'package:mobile/models/response_models/prescription_response_model.dart';
import 'package:mobile/models/response_models/search_result_model.dart';
import 'package:mobile/views/active_inredient/active_inredient_detail.dart';
import 'package:mobile/views/pages/prescription_detail_page.dart';
import 'package:mobile/views/patient/patient_detail_page.dart';
import '../../service/pages_service.dart';
import '../medicine/medicine_detail_page.dart';

class GeneralSearchPage extends StatefulWidget {
  const GeneralSearchPage({super.key});

  @override
  _GeneralSearchPageState createState() => _GeneralSearchPageState();
}

class _GeneralSearchPageState extends State<GeneralSearchPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  SearchResultsModel _searchResults = SearchResultsModel(
    medications: [],
    activeIngredients: [],
    patients: [],
    recetes: [],
  );
  PrescriptionResponseModel? _prescription;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _showFilterOptions = false;

  // Filtreleme seçenekleri
  bool _showMedicines = true;
  bool _showPrescriptions = true;
  bool _showActiveIngredients = true;
  bool _showPatients = true;

  // Animasyon kontrolcüsü
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Arama fonksiyonu
  Future<void> _searchData() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _prescription = null; // Yeni arama yaparken reçete sonucunu temizle
    });

    try {
      // Arama yap ve modeli doğrudan al
      final results = await PagesService.fetchSearchResults(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Arama sonuçları için animasyon efekti
      _animationController.reset();
      _animationController.forward();

      // Klavyeyi kapat
      FocusScope.of(context).unfocus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Arama sırasında bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  // Arama alanını temizleme
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = SearchResultsModel(
        medications: [],
        activeIngredients: [],
        patients: [],
        recetes: [],
      );
      _prescription = null;
      _errorMessage = '';
    });
  }

  // Filtreleme seçeneklerini göster/gizle
  void _toggleFilterOptions() {
    setState(() {
      _showFilterOptions = !_showFilterOptions;
    });
  }

  // Toplam sonuç sayısını hesapla
  int get _totalFilteredResults {
    int total = 0;
    if (_showMedicines) total += _searchResults.medications.length;
    if (_showPrescriptions)
      total += _searchResults.recetes.length + (_prescription != null ? 1 : 0);
    if (_showActiveIngredients)
      total += _searchResults.activeIngredients.length;
    if (_showPatients) total += _searchResults.patients.length;
    return total;
  }

  // Tüm filtreleri seç/kaldır
  void _toggleAllFilters(bool value) {
    setState(() {
      _showMedicines = value;
      _showPrescriptions = value;
      _showActiveIngredients = value;
      _showPatients = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Özel App Bar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            snap: true,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                "Genel Arama",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // Filtreleme butonu
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _toggleFilterOptions,
                tooltip: 'Filtreleme Seçenekleri',
              ),
            ],
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arama alanı
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'İlaç, barkod, etken madde, hasta, ara...',
                        filled: true,
                        fillColor: colorScheme.surface,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                                color: colorScheme.primary,
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchData,
                                color: colorScheme.primary,
                              ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (text) {
                        // Temizle butonunu göstermek için state güncelleme
                        setState(() {});
                      },
                      onSubmitted: (_) => _searchData(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Filtreleme seçenekleri
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showFilterOptions
                        ? Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'Filtreleme Seçenekleri',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _toggleAllFilters(true),
                                      child: const Text('Tümünü Seç'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () =>
                                          _toggleAllFilters(false),
                                      child: const Text('Tümünü Kaldır'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _filterChip(
                                      'İlaçlar',
                                      _showMedicines,
                                      () => setState(() =>
                                          _showMedicines = !_showMedicines),
                                      Colors.blue,
                                    ),
                                    _filterChip(
                                      'Reçeteler',
                                      _showPrescriptions,
                                      () => setState(() => _showPrescriptions =
                                          !_showPrescriptions),
                                      Colors.purple,
                                    ),
                                    _filterChip(
                                      'Etken Maddeler',
                                      _showActiveIngredients,
                                      () => setState(() =>
                                          _showActiveIngredients =
                                              !_showActiveIngredients),
                                      Colors.teal,
                                    ),
                                    _filterChip(
                                      'Hastalar',
                                      _showPatients,
                                      () => setState(
                                          () => _showPatients = !_showPatients),
                                      Colors.orange,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // Hata mesajı
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _errorMessage = ''),
                            color: colorScheme.error,
                            iconSize: 18,
                          ),
                        ],
                      ),
                    ),

                  // Yükleniyor göstergesi
                  if (_isLoading)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aranıyor...',
                            style: TextStyle(
                              color: colorScheme.onBackground.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Sonuç sayısı
                  if (!_isLoading &&
                      _searchController.text.isNotEmpty &&
                      _totalFilteredResults > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _totalFilteredResults.toString(),
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'sonuç bulundu',
                            style: TextStyle(
                              color: colorScheme.onBackground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Arama sorgusunu göster
                          Flexible(
                            child: Text(
                              '"${_searchController.text}"',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontStyle: FontStyle.italic,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Arama Sonuçları
          if (!_isLoading)
            SliverFadeTransition(
              opacity: _fadeAnimation,
              sliver: SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        // Reçete sonucu (varsa)
                        if (_prescription != null && _showPrescriptions)
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildPrescriptionCard(_prescription!),
                              ),
                            ),
                          ),

                        // İlaç sonuçları
                        if (_showMedicines)
                          for (int i = 0;
                              i < _searchResults.medications.length;
                              i++)
                            AnimationConfiguration.staggeredList(
                              position: i + 1,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildMedicineCard(
                                      _searchResults.medications[i]),
                                ),
                              ),
                            ),

                        // Reçete sonuçları
                        if (_showPrescriptions)
                          for (int i = 0;
                              i < _searchResults.recetes.length;
                              i++)
                            AnimationConfiguration.staggeredList(
                              position:
                                  i + _searchResults.medications.length + 1,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildReceteCard(
                                      _searchResults.recetes[i]),
                                ),
                              ),
                            ),

                        // Etken madde sonuçları
                        if (_showActiveIngredients)
                          for (int i = 0;
                              i < _searchResults.activeIngredients.length;
                              i++)
                            AnimationConfiguration.staggeredList(
                              position: i +
                                  _searchResults.medications.length +
                                  _searchResults.recetes.length +
                                  1,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildActiveIngredientCard(
                                      _searchResults.activeIngredients[i]),
                                ),
                              ),
                            ),

                        // Hasta sonuçları
                        if (_showPatients)
                          for (int i = 0;
                              i < _searchResults.patients.length;
                              i++)
                            AnimationConfiguration.staggeredList(
                              position: i +
                                  _searchResults.medications.length +
                                  _searchResults.recetes.length +
                                  _searchResults.activeIngredients.length +
                                  1,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildPatientCard(
                                      _searchResults.patients[i]),
                                ),
                              ),
                            ),

                        // Aramada sonuç yoksa
                        if (_searchController.text.isNotEmpty &&
                            _totalFilteredResults == 0 &&
                            !_isLoading)
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  margin: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Sonuç bulunamadı',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Lütfen farklı anahtar kelimeler deneyiniz veya filtreleme seçeneklerini kontrol ediniz.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Henüz arama yapılmadıysa
                        if (_searchController.text.isEmpty &&
                            !_isLoading &&
                            _searchResults.isEmpty &&
                            _prescription == null)
                          AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 500),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  margin: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 64,
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Arama yapmak için metin girin',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'İlaç, barkod, etken madde, hasta veya reçete bilgilerini arayabilirsiniz.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Sonuçların altına boşluk
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      // Hızlı arama butonu
      floatingActionButton: _searchController.text.isNotEmpty && !_isLoading
          ? FloatingActionButton(
              onPressed: _searchData,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              elevation: 4,
              child: const Icon(Icons.search),
            )
          : null,
    );
  }

  // Filtre chips
  Widget _filterChip(
      String label, bool selected, VoidCallback onTap, Color color) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected
            ? color.withOpacity(0.8)
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? color : Colors.grey.withOpacity(0.5),
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    );
  }

  // İlaç kartı
  Widget _buildMedicineCard(MedicineResponseModel medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailPage(
                medicine: medicine,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori ikonu
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.ilacAdi ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicine.barkod ?? "",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Kategori etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'İlaç',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reçete kartı
  Widget _buildReceteCard(PrescriptionResponseModel recete) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionDetailPage(
                receteNo: recete.receteNo,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori ikonu
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reçete #${recete.receteNo}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (recete.hasta != null)
                      Text(
                        "${recete.hasta!.ad} ${recete.hasta!.soyad}",
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Kategori etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Reçete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Etken madde kartı
  Widget _buildActiveIngredientCard(EtkenMaddeResponseModel activeIngredient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.teal.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.teal.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveIngredientDetailPage(
                ingredient: activeIngredient,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori ikonu
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.biotech,
                  color: Colors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeIngredient.etkenMaddeAdi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeIngredient.aciklama ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Kategori etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Etken Madde',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

// Hasta kartı
  Widget _buildPatientCard(PatientResponseModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.orange.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientDetailPage(
                hastaId: patient.hastaId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori ikonu
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${patient.ad} ${patient.soyad}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Yaş: ${patient.yas}",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Kategori etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Hasta',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

// Reçete kartı
  Widget _buildPrescriptionCard(PrescriptionResponseModel prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shadowColor: Colors.purple.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.purple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionDetailPage(
                receteNo: prescription.receteNo,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori ikonu
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_information,
                  color: Colors.purple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reçete #${prescription.receteNo}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (prescription.hasta != null &&
                        prescription.hastalik != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${prescription.hasta!.ad} ${prescription.hasta!.soyad}",
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            prescription.hastalik!.hastalikAdi,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Kategori etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Reçete',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
