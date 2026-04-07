import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/nutrition_repository.dart';
import 'food_event.dart';
import 'food_state.dart';

/// Manages the food library state (system + trainee foods).
class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final NutritionRepository _repo;

  FoodBloc({required NutritionRepository nutritionRepository})
    : _repo = nutritionRepository,
      super(const FoodInitial()) {
    on<FoodLoadRequested>(_onLoadRequested);
    on<FoodAdded>(_onFoodAdded);
  }

  Future<void> _onLoadRequested(
    FoodLoadRequested event,
    Emitter<FoodState> emit,
  ) async {
    emit(const FoodLoading());
    try {
      final results = await Future.wait([
        _repo.getSystemFoods(),
        _repo.getUserFoods(),
      ]);
      emit(FoodLoaded(systemFoods: results[0], userFoods: results[1]));
    } catch (e) {
      emit(FoodError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Saves food to Firestore, then reloads the list.
  Future<void> _onFoodAdded(FoodAdded event, Emitter<FoodState> emit) async {
    try {
      await _repo.addFood(event.food);
      // Reload after adding
      add(const FoodLoadRequested());
    } catch (e) {
      emit(FoodError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
