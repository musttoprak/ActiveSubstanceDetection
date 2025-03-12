import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/response_models/medicine_response_model.dart';
import '../service/medicine_service.dart';

class MedicineCubit extends Cubit<MedicineState> {
  MedicineCubit() : super(MedicineInitial()) {
    loadSearchHistory();
  }

  // Store current results to append more
  List<MedicineResponseModel> currentMedicines = [];
  int totalItems = 0;
  int perPage = 15;

  Future<void> searchMedicines(String? query, {
    int page = 1,
    bool isNewSearch = true
  }) async {
    if (isNewSearch) {
      emit(MedicineLoading());
      currentMedicines = [];
    } else {
      emit(MedicineLoaded(
          currentMedicines,
          isLoadingMore: true,
          hasReachedEnd: false
      ));
    }

    try {
      List<MedicineResponseModel> medicines;
      if(query != null) {
        medicines = await MedicineService.searchMedicines(
            query,
            page: page,
            perPage: perPage
        );
      } else {
        medicines = await MedicineService.getMedicines(
            page: page,
            perPage: perPage
        );
      }

      final metadata = await MedicineService.getLastPaginationMetadata();
      totalItems = metadata['total'] ?? 0;

      if (medicines.isEmpty && isNewSearch) {
        emit(MedicineError("Sonuç bulunamadı."));
        return;
      }

      if (isNewSearch) {
        currentMedicines = medicines;
        //_saveSearchHistory(query);
      } else {
        currentMedicines = [...currentMedicines, ...medicines];
      }

      bool hasReachedEnd = currentMedicines.length >= totalItems;

      emit(MedicineLoaded(
          currentMedicines,
          isLoadingMore: false,
          hasReachedEnd: hasReachedEnd
      ));
    } catch (e) {
      if (isNewSearch) {
        emit(MedicineError("İlaç arama hatası: $e"));
      } else {
        emit(MedicineLoaded(
            currentMedicines,
            isLoadingMore: false,
            hasReachedEnd: true
        ));
      }
    }
  }

  Future<void> loadSearchHistory() async {
    final history = await _getSearchHistory();
    emit(SearchHistoryLoaded(history));
  }

  Future<void> _saveSearchHistory(String query) async {
    // SharedPreferences kullanımı burada
    final history = await _getSearchHistory();

    if (history.contains(query)) {
      history.remove(query);
    }
    history.insert(0, query);

    final limitedHistory = history.take(10).toList();

    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setStringList('medicineSearchHistory', limitedHistory);
    // });

    // Geçici olarak, SharedPreferences yerine sadece emit yapıyoruz
    emit(SearchHistoryLoaded(limitedHistory));
  }

  Future<List<String>> _getSearchHistory() async {
    // Normalde SharedPreferences'dan alınacak
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getStringList('medicineSearchHistory') ?? [];

    // Geçici olarak boş liste dönüyoruz
    return [];
  }

  Future<void> deleteHistory(String item) async {
    final history = await _getSearchHistory();
    history.remove(item);

    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setStringList('medicineSearchHistory', history);
    // });

    emit(SearchHistoryLoaded(history));
  }

  Future<void> clearAllHistory() async {
    // SharedPreferences.getInstance().then((prefs) {
    //   prefs.setStringList('medicineSearchHistory', []);
    // });

    emit(SearchHistoryLoaded([]));
  }
}

// States
abstract class MedicineState {}

class MedicineInitial extends MedicineState {}

class MedicineLoading extends MedicineState {}

class MedicineLoaded extends MedicineState {
  final List<MedicineResponseModel> medicines;
  final bool isLoadingMore;
  final bool hasReachedEnd;

  MedicineLoaded(
      this.medicines, {
        this.isLoadingMore = false,
        this.hasReachedEnd = false
      });
}

class SearchHistoryLoaded extends MedicineState {
  final List<String> history;
  SearchHistoryLoaded(this.history);
}

class MedicineError extends MedicineState {
  final String message;
  MedicineError(this.message);
}