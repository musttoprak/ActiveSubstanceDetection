import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/models/response_models/active_ingredient_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/active_ingredient_service.dart';

class ActiveIngredientCubit extends Cubit<ActiveIngredientState> {
  ActiveIngredientCubit() : super(ActiveIngredientInitial()) {
    loadSearchHistory();
  }

  Future<void> searchActiveIngredient(String query) async {
    emit(ActiveIngredientLoading());
    try {
      final response = await ActiveIngredientService.searchActiveIngredients(query);

      if (response.isEmpty) {
        emit(ActiveIngredientError("No active ingredients found."));
      } else {
        _saveSearchHistory(query);
        emit(ActiveIngredientLoaded(response));
      }
    } catch (e) {
      emit(ActiveIngredientError("Failed to fetch active ingredients: $e"));
    }
  }

  Future<void> loadSearchHistory() async {
    final history = await _getSearchHistory();
    emit(SearchHistoryLoaded(history));
  }

  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('searchHistory') ?? [];
    if (!history.contains(query)) {
      history.add(query);
      await prefs.setStringList('searchHistory', history);
    }
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
  final List<ActiveIngredientResponseModel> results;
  ActiveIngredientLoaded(this.results);
}

class SearchHistoryLoaded extends ActiveIngredientState {
  final List<String> history;
  SearchHistoryLoaded(this.history);
}

class ActiveIngredientError extends ActiveIngredientState {
  final String message;
  ActiveIngredientError(this.message);
}
