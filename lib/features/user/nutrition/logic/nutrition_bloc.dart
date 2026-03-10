import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../profile/data/repositories/profile_repository.dart';
import '../data/repositories/nutrition_repository.dart';
import 'nutrition_event.dart';
import 'nutrition_state.dart';

/// Manages nutrition data for the NutritionDashboard.
class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final NutritionRepository _repo;
  final ProfileRepository _profileRepo;

  NutritionBloc({
    required NutritionRepository nutritionRepository,
    ProfileRepository? profileRepository,
  }) : _repo = nutritionRepository,
       _profileRepo = profileRepository ?? ProfileRepository(),
       super(const NutritionInitial()) {
    on<NutritionLoadRequested>(_onLoadRequested);
    on<NutritionMealAdded>(_onMealAdded);
    on<NutritionMealsAdded>(_onMealsAdded);
    on<NutritionMealDeleted>(_onMealDeleted);
    on<NutritionCloneSystemPlan>(_onCloneSystemPlan);
  }

  /// Fetches the daily log and user profile for the requested [date].
  Future<void> _onLoadRequested(
    NutritionLoadRequested event,
    Emitter<NutritionState> emit,
  ) async {
    emit(const NutritionLoading());
    try {
      final results = await Future.wait([
        _repo.getDailyLog(event.date),
        _profileRepo.getProfile(),
      ]);
      emit(
        NutritionLoaded(
          dailyLog: results[0] as dynamic,
          selectedDate: event.date,
          user: results[1] as dynamic,
        ),
      );
    } catch (e) {
      emit(NutritionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Adds a meal entry to today's log and reloads.
  Future<void> _onMealAdded(
    NutritionMealAdded event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      final updatedLog = await _repo.addMealEntry(event.mealEntry);
      // Preserve user from current state
      final currentUser = state is NutritionLoaded
          ? (state as NutritionLoaded).user
          : null;
      emit(
        NutritionLoaded(
          dailyLog: updatedLog,
          selectedDate: updatedLog.date,
          user: currentUser,
        ),
      );
    } catch (e) {
      emit(NutritionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Adds multiple meal entries at once (batch write).
  Future<void> _onMealsAdded(
    NutritionMealsAdded event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      final updatedLog = await _repo.addMealEntries(event.entries);
      final currentUser = state is NutritionLoaded
          ? (state as NutritionLoaded).user
          : null;
      emit(
        NutritionLoaded(
          dailyLog: updatedLog,
          selectedDate: updatedLog.date,
          user: currentUser,
        ),
      );
    } catch (e) {
      emit(NutritionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Removes a meal entry and reloads.
  Future<void> _onMealDeleted(
    NutritionMealDeleted event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      final updatedLog = await _repo.removeMealEntry(event.date, event.mealId);
      final currentUser = state is NutritionLoaded
          ? (state as NutritionLoaded).user
          : null;
      emit(
        NutritionLoaded(
          dailyLog: updatedLog,
          selectedDate: updatedLog.date,
          user: currentUser,
        ),
      );
    } catch (e) {
      emit(NutritionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Clones a system nutrition plan and saves it as the user's personal active plan.
  Future<void> _onCloneSystemPlan(
    NutritionCloneSystemPlan event,
    Emitter<NutritionState> emit,
  ) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        emit(const NutritionError('Chưa đăng nhập'));
        return;
      }

      // 1. Deactivate all existing plans
      final allPlans = await _repo.getAllPlans();
      for (final plan in allPlans) {
        if (plan.isActive) {
          await _repo.updatePlan(plan.copyWith(isActive: false));
        }
      }

      // 2. Generate new planId for the clone
      final newPlanId = 'nutrition_plan_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Clone the system plan with new ID and user ownership
      final clonedPlan = event.systemPlan.copyWith(
        planId: newPlanId,
        userId: userId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // 4. Save the cloned plan
      await _repo.createPlan(clonedPlan);

      // 5. Reload the current state
      add(NutritionLoadRequested(DateTime.now()));
    } catch (e) {
      emit(NutritionError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
