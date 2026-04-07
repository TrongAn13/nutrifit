import 'package:flutter/foundation.dart';


import '../../../auth/data/models/user_model.dart';
import '../../tracking/data/models/daily_log_model.dart';

/// States emitted by [NutritionBloc].
@immutable
sealed class NutritionState {
  const NutritionState();
}

/// Initial state before any data fetch.
final class NutritionInitial extends NutritionState {
  const NutritionInitial();
}

/// Data is being fetched.
final class NutritionLoading extends NutritionState {
  const NutritionLoading();
}

/// Daily log loaded (may be null if no entry exists for that date).
final class NutritionLoaded extends NutritionState {
  final DailyLogModel? dailyLog;
  final DateTime selectedDate;
  final UserModel? user;

  const NutritionLoaded({
    required this.dailyLog,
    required this.selectedDate,
    this.user,
  });
}

/// An error occurred.
final class NutritionError extends NutritionState {
  final String message;

  const NutritionError(this.message);
}
