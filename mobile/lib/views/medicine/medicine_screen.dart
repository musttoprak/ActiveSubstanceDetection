import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/bloc/medicine_cubit.dart';
import 'package:mobile/models/response_models/medicine_response_model.dart';
import 'package:mobile/views/medicine/medicine_detail_page.dart';

import '../drug_detection.dart';

class MedicineScreen extends StatefulWidget {
  final Color backgroundColor;

  const MedicineScreen({super.key, required this.backgroundColor});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen>
    with MedicineScreenMixin {
  @override
  void initState() {
    backgroundColor = widget.backgroundColor;
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MedicineCubit(),
      child: BlocBuilder<MedicineCubit, MedicineState>(
        builder: (context, state) {
          return buildScaffold(context, state);
        },
      ),
    );
  }
}

mixin MedicineScreenMixin {
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();
  final scrollController = ScrollController();
  late final Color backgroundColor;

  // Pagination control
  int currentPage = 1;
  bool isLoadingMore = false;
  bool hasReachedEnd = false;
  String lastSearchQuery = "";

  Scaffold buildScaffold(BuildContext context, MedicineState state) {
    _setupScrollListener(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text("İlaç Arama"),
      ),
      body: Column(
        children: [
          _buildSearchArea(context),
          const SizedBox(height: 8),
          Expanded(
            child: _buildStateWidget(state, context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[50],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Ensures the Column takes only as much space as needed
        children: [
          // Arama kutusu
          TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            decoration: InputDecoration(
              hintText: "İlaç adı, barkod veya firma ara",
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                      },
                    )
                  : null,
            ),
            onSubmitted: (value) {
              _performSearch(context);
            },
          ),

          // Arama butonları
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text("Ara"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: backgroundColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () => _performSearch(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  // Bu Expanded widget'ı ekleyin
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.filter_list,
                      size: 18,
                      color: backgroundColor,
                    ),
                    label: const Text("Gelişmiş"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: backgroundColor,
                      side: BorderSide(color: backgroundColor),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onPressed: () {
                      // Gelişmiş arama sayfasına gidiş
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DrugDetectionScreen(
                            backgroundColor: backgroundColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setupScrollListener(BuildContext context) {
    scrollController.removeListener(() {});

    scrollController.addListener(() {
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          !hasReachedEnd) {
        _loadMoreItems(context);
      }
    });
  }

  void _performSearch(BuildContext context) {
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      currentPage = 1;
      hasReachedEnd = false;
      lastSearchQuery = query;

      context
          .read<MedicineCubit>()
          .searchMedicines(query, page: currentPage, isNewSearch: true);
    } else {
      currentPage = 1;
      hasReachedEnd = false;
      lastSearchQuery = query;

      context
          .read<MedicineCubit>()
          .searchMedicines(null, page: currentPage, isNewSearch: true);
    }
  }

  void _loadMoreItems(BuildContext context) {
    if (lastSearchQuery.isEmpty) return;

    setState(() {
      isLoadingMore = true;
    });

    currentPage++;

    context.read<MedicineCubit>().searchMedicines(lastSearchQuery,
        page: currentPage, isNewSearch: false);
  }

  void setState(Function() fn) {
    fn();
  }

  Widget _buildStateWidget(MedicineState state, BuildContext context) {
    if (state is MedicineInitial) {
      return _buildInitialState();
    } else if (state is MedicineLoading && currentPage == 1) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is MedicineLoaded) {
      // Update loading state
      if (isLoadingMore && !state.isLoadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            isLoadingMore = false;
          });
        });
      }

      // Check if we've reached the end
      if (state.hasReachedEnd != hasReachedEnd) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            hasReachedEnd = state.hasReachedEnd;
          });
        });
      }

      if (state.medicines.isEmpty && currentPage == 1) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Aramanıza uygun ilaç bulunamadı",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                "Farklı anahtar kelimeler kullanarak tekrar deneyin",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      }
      return _buildMedicineList(state.medicines, state.isLoadingMore);
    } else if (state is SearchHistoryLoaded) {
      if (state.history.isEmpty) {
        return _buildInitialState();
      }
      return _buildHistoryList(state.history, context);
    } else if (state is MedicineError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              "Bir hata oluştu: ${state.message}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
              ),
              child: const Text("Tekrar Dene"),
            ),
          ],
        ),
      );
    }
    return _buildInitialState();
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_outlined, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 24),
          const Text(
            "İlaç aramak için yukarıdaki\narama kutusunu kullanın",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                "İlaç adı, firma veya barkod girebilirsiniz",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineList(
      List<MedicineResponseModel> medicines, bool isLoadingMore) {
    return ListView.builder(
      controller: scrollController,
      itemCount: medicines.length + (isLoadingMore ? 1 : 0),
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        // Show loading indicator at the end when loading more items
        if (index == medicines.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final MedicineResponseModel medicine = medicines[index];

        return Card(
          color: Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicineDetailPage(medicine: medicine),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İlaç ikonu veya resmi
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: backgroundColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medication,
                      color: backgroundColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // İlaç bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.ilacAdi ?? 'İsimsiz İlaç',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (medicine.ureticiFirma != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              medicine.ureticiFirma!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Alt bilgiler
                        Row(
                          children: [
                            if (medicine.receteTipi != null)
                              _buildInfoChip(
                                medicine.receteTipi!,
                                Icons.description_outlined,
                                backgroundColor.withOpacity(0.1),
                              ),
                            const SizedBox(width: 8),
                            if (medicine.sgkDurumu != null)
                              _buildInfoChip(
                                medicine.sgkDurumu!
                                            .toLowerCase()
                                            .contains('ödemez') ||
                                        medicine.sgkDurumu!
                                            .toLowerCase()
                                            .contains('ödenmez')
                                    ? 'SGK Ödemez'
                                    : 'SGK Öder',
                                Icons.health_and_safety_outlined,
                                medicine.sgkDurumu!
                                            .toLowerCase()
                                            .contains('ödemez') ||
                                        medicine.sgkDurumu!
                                            .toLowerCase()
                                            .contains('ödenmez')
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                textColor: medicine.sgkDurumu!
                                            .toLowerCase()
                                            .contains('ödemez') ||
                                        medicine.sgkDurumu!
                                            .toLowerCase()
                                            .contains('ödenmez')
                                    ? Colors.red
                                    : Colors.green,
                              ),
                          ],
                        ),
                        SizedBox(height: 12),
                        // Fiyat bilgisi
                        if (medicine.perakendeSatisFiyati != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${medicine.perakendeSatisFiyati} ₺',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color bgColor,
      {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor ?? Colors.black87,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<String> history, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Son Aramalar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<MedicineCubit>().clearAllHistory();
                },
                child: const Text("Tümünü Temizle"),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(item),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () {
                    context.read<MedicineCubit>().deleteHistory(item);
                  },
                ),
                onTap: () {
                  searchController.text = item;
                  _performSearch(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
