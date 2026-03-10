import 'package:flutter/foundation.dart';

import '../data/models/water_entry_model.dart';

/// States emitted by [WaterCubit].
@immutable
sealed class WaterState {
  const WaterState();
}

/// Initial state before any data.
final class WaterInitial extends WaterState {
  const WaterInitial();
}

/// Water tracking data loaded.
final class WaterLoaded extends WaterState {
  final int dailyGoalMl;
  final List<WaterEntryModel> entries;

  const WaterLoaded({required this.dailyGoalMl, required this.entries});

  /// Total ml consumed today.
  int get totalConsumed => entries.fold(0, (sum, e) => sum + e.effectiveMl);

  /// Progress ratio (0.0 – 1.0+).
  double get progress => dailyGoalMl > 0 ? totalConsumed / dailyGoalMl : 0;

  WaterLoaded copyWith({int? dailyGoalMl, List<WaterEntryModel>? entries}) {
    return WaterLoaded(
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      entries: entries ?? this.entries,
    );
  }
}
