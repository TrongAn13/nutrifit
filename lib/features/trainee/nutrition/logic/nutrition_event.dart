import 'package:flutter/foundation.dart';

import '../../tracking/data/models/daily_log_model.dart';
import '../data/models/nutrition_plan_model.dart';

/// Events dispatched to [NutritionBloc].
@immutable
sealed class NutritionEvent {
  const NutritionEvent();
}

/// Load nutrition data for a specific [date].
final class NutritionLoadRequested extends NutritionEvent {
  final DateTime date;

  const NutritionLoadRequested(this.date);
}

/// Add a meal entry to the current day's daily log.
final class NutritionMealAdded extends NutritionEvent {
  final MealEntry mealEntry;

  const NutritionMealAdded(this.mealEntry);
}

/// Remove a meal entry from a specific day's log.
final class NutritionMealDeleted extends NutritionEvent {
  final DateTime date;
  final String mealId;

  const NutritionMealDeleted({required this.date, required this.mealId});
}

/// Add multiple meal entries at once (avoids race conditions).
final class NutritionMealsAdded extends NutritionEvent {
  final List<MealEntry> entries;

  const NutritionMealsAdded(this.entries);
}

/// Clone a system nutrition plan and apply it as the trainee's active plan.
final class NutritionCloneSystemPlan extends NutritionEvent {
  final NutritionPlanModel systemPlan;

  const NutritionCloneSystemPlan({required this.systemPlan});
}
