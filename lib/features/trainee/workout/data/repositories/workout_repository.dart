import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data_sources/workout_remote_data_source.dart';
import '../models/exercise_model.dart';
import '../models/workout_plan_model.dart';
import '../models/workout_history_model.dart';

/// Handles workout data orchestration and error mapping.
class WorkoutRepository {
  final WorkoutRemoteDataSource _remoteDataSource;

  WorkoutRepository({
    WorkoutRemoteDataSource? remoteDataSource,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _remoteDataSource =
           remoteDataSource ??
           WorkoutRemoteDataSource(firestore: firestore, auth: auth);

  // ───────────────────────── Read ─────────────────────────

  /// Fetches all **active** workout plans belonging to the current trainee.
  Future<List<WorkoutPlanModel>> getActivePlans() async {
    try {
      return await _remoteDataSource.getActivePlans();
    } catch (e) {
      throw Exception('Không thể tải giáo án: ${e.toString()}');
    }
  }

  /// Fetches ALL workout plans (active + inactive) for the current trainee.
  Future<List<WorkoutPlanModel>> getAllPlans() async {
    try {
      return await _remoteDataSource.getAllPlans();
    } catch (e) {
      throw Exception('Không thể tải giáo án: ${e.toString()}');
    }
  }

  /// Fetches ALL coach templates created by the current trainee.
  Future<List<WorkoutPlanModel>> getCoachTemplates() async {
    try {
      return await _remoteDataSource.getCoachTemplates();
    } catch (e) {
      throw Exception('Không thể tải mẫu giáo án: ${e.toString()}');
    }
  }

  /// Fetches all global templates managed by the system.
  Future<List<WorkoutPlanModel>> getSystemTemplates() async {
    try {
      return await _remoteDataSource.getSystemTemplates();
    } catch (e) {
      throw Exception('Không thể tải giáo án hệ thống: ${e.toString()}');
    }
  }

  /// Fetches all favorite system plans of current user.
  Future<List<WorkoutPlanModel>> getFavoriteSystemPlans() async {
    try {
      return await _remoteDataSource.getFavoriteSystemPlans();
    } catch (e) {
      throw Exception('Không thể tải giáo án yêu thích: ${e.toString()}');
    }
  }

  /// Fetches only favorite plan IDs of current user.
  Future<Set<String>> getFavoritePlanIds() async {
    try {
      return await _remoteDataSource.getFavoritePlanIds();
    } catch (e) {
      throw Exception('Không thể tải danh sách yêu thích: ${e.toString()}');
    }
  }

  /// Checks if a system plan is marked as favorite by current user.
  Future<bool> isSystemPlanFavorite(String planId) async {
    try {
      return await _remoteDataSource.isSystemPlanFavorite(planId);
    } catch (e) {
      throw Exception('Không thể kiểm tra trạng thái yêu thích: ${e.toString()}');
    }
  }

  /// Marks or unmarks a system plan as favorite.
  Future<void> setSystemPlanFavorite({
    required WorkoutPlanModel plan,
    required bool isFavorite,
  }) async {
    try {
      await _remoteDataSource.setSystemPlanFavorite(
        plan: plan,
        isFavorite: isFavorite,
      );
    } catch (e) {
      throw Exception('Không thể cập nhật giáo án yêu thích: ${e.toString()}');
    }
  }

  /// Checks whether [planName] already exists for the current user.
  ///
  /// Uses [isTemplate] to choose coach template vs trainee plan collection.
  /// [excludePlanId] can be provided when editing an existing plan.
  Future<bool> isPlanNameTaken({
    required String planName,
    required bool isTemplate,
    String? excludePlanId,
  }) async {
    try {
      return await _remoteDataSource.isPlanNameTaken(
        planName: planName,
        isTemplate: isTemplate,
        excludePlanId: excludePlanId,
      );
    } catch (e) {
      throw Exception('Không thể kiểm tra trùng tên giáo án: ${e.toString()}');
    }
  }

  // ───────────────────────── Write ─────────────────────────

  /// Creates a new workout plan document.
  Future<void> createPlan(WorkoutPlanModel plan) async {
    try {
      await _remoteDataSource.createPlan(plan);
    } catch (e) {
      throw Exception('Không thể tạo giáo án: ${e.toString()}');
    }
  }

  /// Updates an existing workout plan document or creates it if it doesn't exist.
  Future<void> updatePlan(WorkoutPlanModel plan) async {
    try {
      await _remoteDataSource.updatePlan(plan);
    } catch (e) {
      throw Exception('Không thể lưu giáo án: ${e.toString()}');
    }
  }

  /// Activates a single plan and deactivates all others using a batch write.
  ///
  /// Ensures only ONE plan is active at any time.
  Future<void> setActivePlan(String planId) async {
    try {
      await _remoteDataSource.setActivePlan(planId);
    } catch (e) {
      throw Exception('Không thể kích hoạt giáo án: ${e.toString()}');
    }
  }

  /// Deletes a workout plan by its [planId].
  Future<void> deletePlan(String planId) async {
    try {
      await _remoteDataSource.deletePlan(planId);
    } catch (e) {
      throw Exception('Không thể xóa giáo án: ${e.toString()}');
    }
  }

  /// Deletes a coach template by its [planId].
  Future<void> deleteCoachTemplate(String planId) async {
    try {
      await _remoteDataSource.deleteCoachTemplate(planId);
    } catch (e) {
      throw Exception('Không thể xóa mẫu giáo án: ${e.toString()}');
    }
  }

  // ───────────────────────── Workout Log ─────────────────────────

  /// Marks today's daily log as workout completed.
  Future<void> markWorkoutCompleted() async {
    try {
      await _remoteDataSource.markWorkoutCompleted();
    } catch (e) {
      throw Exception('Không thể lưu kết quả tập: ${e.toString()}');
    }
  }

  // ───────────────────────── Workout History ─────────────────────────

  /// Saves a completed workout history to Firestore.
  Future<void> saveWorkoutHistory(WorkoutHistoryModel history) async {
    try {
      await _remoteDataSource.saveWorkoutHistory(history);
    } catch (e) {
      throw Exception('Không thể lưu lịch sử tập luyện: ${e.toString()}');
    }
  }

  /// Deletes a workout history entry by its [historyId].
  Future<void> deleteWorkoutHistory(String historyId) async {
    try {
      await _remoteDataSource.deleteWorkoutHistory(historyId);
    } catch (e) {
      throw Exception('Không thể xóa lịch sử tập luyện: ${e.toString()}');
    }
  }

  /// Fetches all workout histories for the current trainee, ordered by date.
  Future<List<WorkoutHistoryModel>> getWorkoutHistories() async {
    try {
      return await _remoteDataSource.getWorkoutHistories();
    } catch (e) {
      throw Exception('Không thể tải lịch sử tập luyện: ${e.toString()}');
    }
  }

  // ───────────────────────── Exercises ─────────────────────────

  /// Fetches exercises that are either system-wide or created by [userId].
  ///
  /// Firestore does not support OR across different fields, so we run two
  /// parallel queries and merge the results, deduplicating by [exerciseId].
  Future<List<ExerciseModel>> getExercises(String userId) async {
    try {
      return await _remoteDataSource.getExercises(userId);
    } catch (e) {
      throw Exception('Không thể tải bài tập: ${e.toString()}');
    }
  }

  /// Adds a new trainee-created exercise to the `exercises` collection.
  Future<void> createCustomExercise(ExerciseModel exercise) async {
    try {
      await _remoteDataSource.createCustomExercise(exercise);
    } catch (e) {
      throw Exception('Không thể tạo bài tập: ${e.toString()}');
    }
  }

  /// Fetches a GIF URL for a specific exercise by its name.
  Future<String?> getExerciseGifByName(String name) async {
    try {
      return await _remoteDataSource.getExerciseGifByName(name);
    } catch (e) {
      return null;
    }
  }

  /// Fetches an image URL for a specific exercise by its name.
  Future<String?> getExerciseImageByName(String name) async {
    try {
      return await _remoteDataSource.getExerciseImageByName(name);
    } catch (e) {
      return null;
    }
  }

  /// Fetches a workout plan image URL by [planId].
  ///
  /// A plan can be stored in one of these collections depending on origin:
  /// trainee templates, coach templates, or system plans.
  Future<String?> getPlanImageById(String planId) async {
    try {
      return await _remoteDataSource.getPlanImageById(planId);
    } catch (_) {
      return null;
    }
  }
}
