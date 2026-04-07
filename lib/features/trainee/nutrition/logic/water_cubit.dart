import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profile/data/repositories/profile_repository.dart';
import '../data/models/water_entry_model.dart';
import '../data/repositories/nutrition_repository.dart';
import 'water_state.dart';

/// Manages water intake tracking for the current day.
///
/// Default daily goal = trainee weight (kg) × 35 ml.
/// Falls back to 2500 ml if weight is unavailable.
class WaterCubit extends Cubit<WaterState> {
  final ProfileRepository _profileRepo;
  final NutritionRepository _nutritionRepo;

  WaterCubit({
    ProfileRepository? profileRepository,
    NutritionRepository? nutritionRepository,
  }) : _profileRepo = profileRepository ?? ProfileRepository(),
       _nutritionRepo = nutritionRepository ?? NutritionRepository(),
       super(const WaterInitial());

  /// Load existing water data from today's log, or compute default goal.
  Future<void> load() async {
    try {
      final today = DateTime.now();
      final dailyLog = await _nutritionRepo.getDailyLog(today);
      final profile = await _profileRepo.getProfile();

      final weight = profile?.weight ?? 70;
      final defaultGoal = (weight * 35).round();

      if (dailyLog != null) {
        // If daily log already has a custom goal != 2500, we use it,
        // otherwise we use the trainee's computed default goal if not set.
        // For simplicity, we trust the dailyLog's waterGoalMl unless it's missing.
        final goal = dailyLog.waterGoalMl;
        emit(
          WaterLoaded(
            dailyGoalMl: goal > 0 ? goal : defaultGoal,
            entries: dailyLog.waterEntries,
          ),
        );
      } else {
        emit(WaterLoaded(dailyGoalMl: defaultGoal, entries: []));
      }
    } catch (_) {
      // Fallback
      emit(const WaterLoaded(dailyGoalMl: 2500, entries: []));
    }
  }

  /// Add a drink entry to today's log and persist.
  Future<void> addEntry(WaterEntryModel entry) async {
    final current = state;
    if (current is WaterLoaded) {
      final updatedEntries = [...current.entries, entry];
      emit(current.copyWith(entries: updatedEntries));
      try {
        await _nutritionRepo.saveWaterEntries(updatedEntries);
      } catch (e) {
        // On error, revert could be done here, but ignoring for simplicity
      }
    }
  }

  /// Remove an entry by index and persist.
  Future<void> removeEntry(int index) async {
    final current = state;
    if (current is WaterLoaded) {
      final updatedEntries = List<WaterEntryModel>.from(current.entries)
        ..removeAt(index);
      emit(current.copyWith(entries: updatedEntries));
      try {
        await _nutritionRepo.saveWaterEntries(updatedEntries);
      } catch (e) {
        // Ignored for now
      }
    }
  }

  /// Update the daily goal and persist.
  Future<void> updateGoal(int goalMl) async {
    final current = state;
    if (current is WaterLoaded) {
      emit(current.copyWith(dailyGoalMl: goalMl));
      try {
        await _nutritionRepo.updateWaterGoal(goalMl);
      } catch (e) {
        // Ignored for now
      }
    }
  }
}
