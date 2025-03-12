import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/models/response_models/active_ingredient_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/active_ingredient_service.dart';

class ActiveIngredientCubit extends Cubit<ActiveIngredientState> {
  ActiveIngredientCubit() : super(ActiveIngredientInitial()) {
    loadSearchHistory();
  }

  // Store the current results to append more items
  List<EtkenMaddeResponseModel> currentResults = [];
  int totalItems = 0;
  int perPage = 15;

  Future<void> searchActiveIngredient(String? query, {
    int page = 1,
    bool isNewSearch = true
  }) async {
    if (isNewSearch) {
      emit(ActiveIngredientLoading());
      currentResults = [];
    } else {
      // Loading more, update with current results plus loading state
      emit(ActiveIngredientLoaded(
          currentResults,
          isLoadingMore: true,
          hasReachedEnd: false
      ));
    }

    try {
      List<EtkenMaddeResponseModel> response;
      if(query != null) {
        response = await ActiveIngredientService.searchActiveIngredients(
            query,
            page: page,
            perPage: perPage
        );
      } else {
        response = await ActiveIngredientService.getActiveIngredients(
            page: page,
            perPage: perPage
        );
      }


      // Extract pagination metadata
      final metadata = await ActiveIngredientService.getLastPaginationMetadata();
      totalItems = metadata['total'] ?? 0;

      if (response.isEmpty && isNewSearch) {
        emit(ActiveIngredientError("No active ingredients found."));
        return;
      }

      if (isNewSearch) {
        currentResults = response;
        query != null ? _saveSearchHistory(query) : null;
      } else {
        // Append to existing results
        currentResults = [...currentResults, ...response];
      }

      // Check if we've reached the end
      bool hasReachedEnd = currentResults.length >= totalItems;

      emit(ActiveIngredientLoaded(
          currentResults,
          isLoadingMore: false,
          hasReachedEnd: hasReachedEnd
      ));
    } catch (e) {
      if (isNewSearch) {
        emit(ActiveIngredientError("Failed to fetch active ingredients: $e"));
      } else {
        // If error while loading more, keep existing data but show reached end
        emit(ActiveIngredientLoaded(
            currentResults,
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
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('searchHistory') ?? [];

    // Remove if exists and add to beginning (most recent first)
    if (history.contains(query)) {
      history.remove(query);
    }
    history.insert(0, query);

    // Keep at most 10 recent searches
    final limitedHistory = history.take(10).toList();
    await prefs.setStringList('searchHistory', limitedHistory);
  }

  Future<List<String>> _getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('searchHistory') ?? [];
  }

  Future<void> deleteHistory(String item) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('searchHistory') ?? [];
    history.remove(item);
    await prefs.setStringList('searchHistory', history);
    await loadSearchHistory();
  }
}

abstract class ActiveIngredientState {}

class ActiveIngredientInitial extends ActiveIngredientState {}

class ActiveIngredientLoading extends ActiveIngredientState {}

class ActiveIngredientLoaded extends ActiveIngredientState {
  final List<EtkenMaddeResponseModel> results;
  final bool isLoadingMore;
  final bool hasReachedEnd;

  ActiveIngredientLoaded(
      this.results, {
        this.isLoadingMore = false,
        this.hasReachedEnd = false
      });
}

class SearchHistoryLoaded extends ActiveIngredientState {
  final List<String> history;
  SearchHistoryLoaded(this.history);
}

class ActiveIngredientError extends ActiveIngredientState {
  final String message;
  ActiveIngredientError(this.message);
}