import 'package:flutter/foundation.dart';

import '../data/models/food_model.dart';

/// States emitted by [FoodBloc].
@immutable
sealed class FoodState {
  const FoodState();
}

final class FoodInitial extends FoodState {
  const FoodInitial();
}

final class FoodLoading extends FoodState {
  const FoodLoading();
}

/// Both system and trainee food lists loaded.
final class FoodLoaded extends FoodState {
  final List<FoodModel> systemFoods;
  final List<FoodModel> userFoods;

  const FoodLoaded({required this.systemFoods, required this.userFoods});
}

final class FoodError extends FoodState {
  final String message;

  const FoodError(this.message);
}
