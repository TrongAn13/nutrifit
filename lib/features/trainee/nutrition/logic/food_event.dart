import 'package:flutter/foundation.dart';

import '../data/models/food_model.dart';

/// Events dispatched to [FoodBloc].
@immutable
sealed class FoodEvent {
  const FoodEvent();
}

/// Load both system and trainee foods.
final class FoodLoadRequested extends FoodEvent {
  const FoodLoadRequested();
}

/// A new food was added — reload the list.
final class FoodAdded extends FoodEvent {
  final FoodModel food;

  const FoodAdded(this.food);
}
