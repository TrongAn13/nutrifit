import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/exercise_model.dart';
import '../models/workout_plan_model.dart';
import '../models/workout_history_model.dart';

/// Handles Firestore operations for workout-related plan collections.
class WorkoutRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WorkoutRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

    /// Reference to trainee-owned workout plans.
  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('trainee_templates');

  /// Reference to the `coach_templates` collection for reusable plans.
  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _firestore.collection('coach_templates');

  /// Reference to system-owned templates visible to all users.
  CollectionReference<Map<String, dynamic>> get _systemTemplatesRef =>
      _firestore.collection('workout_plans');

    /// Reference to user favorite system plans.
    CollectionReference<Map<String, dynamic>> get _favoriteSystemPlansRef =>
      _firestore.collection('user_favorite_system_plans');

  /// Returns the currently signed-in trainee's UID, or throws.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');
    return user.uid;
  }

  // ───────────────────────── Read ─────────────────────────

  /// Fetches all **active** workout plans belonging to the current trainee.
  Future<List<WorkoutPlanModel>> getActivePlans() async {
    try {
      final snapshot = await _plansRef
          .where('userId', isEqualTo: _uid)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải giáo án: ${e.toString()}');
    }
  }

  /// Fetches ALL workout plans (active + inactive) for the current trainee.
  Future<List<WorkoutPlanModel>> getAllPlans() async {
    try {
      final snapshot = await _plansRef
          .where('userId', isEqualTo: _uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải giáo án: ${e.toString()}');
    }
  }

  /// Fetches ALL coach templates created by the current trainee.
  Future<List<WorkoutPlanModel>> getCoachTemplates() async {
    try {
      final snapshot = await _templatesRef
          .where('userId', isEqualTo: _uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải mẫu giáo án: ${e.toString()}');
    }
  }

  /// Fetches all global templates managed by the system.
  Future<List<WorkoutPlanModel>> getSystemTemplates() async {
    try {
      final snapshot = await _systemTemplatesRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải giáo án hệ thống: ${e.toString()}');
    }
  }

  /// Fetches all favorite system plans of current user.
  Future<List<WorkoutPlanModel>> getFavoriteSystemPlans() async {
    try {
      final snapshot = await _favoriteSystemPlansRef
          .where('userId', isEqualTo: _uid)
          .orderBy('favoriteAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final planData = Map<String, dynamic>.from(
          (data['planData'] as Map<String, dynamic>? ?? const {}),
        );
        if ((planData['planId'] as String?)?.isEmpty ?? true) {
          planData['planId'] = data['planId'] as String? ?? '';
        }
        return WorkoutPlanModel.fromJson(planData);
      }).toList();
    } catch (e) {
      throw Exception('Không thể tải giáo án yêu thích: ${e.toString()}');
    }
  }

  /// Fetches only favorite plan IDs of current user.
  Future<Set<String>> getFavoritePlanIds() async {
    try {
      final snapshot = await _favoriteSystemPlansRef
          .where('userId', isEqualTo: _uid)
          .get();

      final ids = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final planId = (data['planId'] as String?)?.trim() ?? '';
        if (planId.isNotEmpty) {
          ids.add(planId);
        }
      }
      return ids;
    } catch (e) {
      throw Exception('Không thể tải danh sách yêu thích: ${e.toString()}');
    }
  }

  /// Checks if a system plan is marked as favorite by current user.
  Future<bool> isSystemPlanFavorite(String planId) async {
    try {
      final docId = '${_uid}_$planId';
      final doc = await _favoriteSystemPlansRef.doc(docId).get();
      return doc.exists;
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
      final docId = '${_uid}_${plan.planId}';
      final docRef = _favoriteSystemPlansRef.doc(docId);
      if (isFavorite) {
        await docRef.set({
          'docId': docId,
          'userId': _uid,
          'planId': plan.planId,
          'favoriteAt': Timestamp.fromDate(DateTime.now()),
          'planData': plan.toJson(),
        });
      } else {
        await docRef.delete();
      }
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
      final normalizedName = planName.trim().toLowerCase();
      if (normalizedName.isEmpty) return false;

      final ref = isTemplate ? _templatesRef : _plansRef;
      final snapshot = await ref.where('userId', isEqualTo: _uid).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final existingId = (data['planId'] as String?) ?? doc.id;
        if (excludePlanId != null && existingId == excludePlanId) {
          continue;
        }

        final existingName = ((data['name'] as String?) ?? '').trim().toLowerCase();
        if (existingName == normalizedName) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Không thể kiểm tra trùng tên giáo án: ${e.toString()}');
    }
  }

  // ───────────────────────── Write ─────────────────────────

  /// Creates a new workout plan document.
  Future<void> createPlan(WorkoutPlanModel plan) async {
    try {
      final ref = plan.isTemplate ? _templatesRef : _plansRef;
      await ref.doc(plan.planId).set(plan.toJson());
    } catch (e) {
      throw Exception('Không thể tạo giáo án: ${e.toString()}');
    }
  }

  /// Updates an existing workout plan document or creates it if it doesn't exist.
  Future<void> updatePlan(WorkoutPlanModel plan) async {
    try {
      final ref = plan.isTemplate ? _templatesRef : _plansRef;
      await ref
          .doc(plan.planId)
          .set(plan.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Không thể lưu giáo án: ${e.toString()}');
    }
  }

  /// Activates a single plan and deactivates all others using a batch write.
  ///
  /// Ensures only ONE plan is active at any time.
  Future<void> setActivePlan(String planId) async {
    try {
      final snapshot = await _plansRef
          .where('userId', isEqualTo: _uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final isTarget = doc.id == planId;
        batch.update(doc.reference, {'isActive': isTarget});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Không thể kích hoạt giáo án: ${e.toString()}');
    }
  }

  /// Deletes a workout plan by its [planId].
  Future<void> deletePlan(String planId) async {
    try {
      await _plansRef.doc(planId).delete();
    } catch (e) {
      throw Exception('Không thể xóa giáo án: ${e.toString()}');
    }
  }

  /// Deletes a coach template by its [planId].
  Future<void> deleteCoachTemplate(String planId) async {
    try {
      await _templatesRef.doc(planId).delete();
    } catch (e) {
      throw Exception('Không thể xóa mẫu giáo án: ${e.toString()}');
    }
  }

  // ───────────────────────── Workout Log ─────────────────────────

  /// Marks today's daily log as workout completed.
  Future<void> markWorkoutCompleted() async {
    try {
      final today = DateTime.now();
      final logId =
          '${_uid}_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      await _firestore.collection('daily_logs').doc(logId).set({
        'logId': logId,
        'userId': _uid,
        'date': Timestamp.fromDate(
          DateTime(today.year, today.month, today.day),
        ),
        'workoutCompleted': true,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Không thể lưu kết quả tập: ${e.toString()}');
    }
  }

  // ───────────────────────── Workout History ─────────────────────────

  /// Reference to the `workout_histories` collection.
  CollectionReference<Map<String, dynamic>> get _historiesRef =>
      _firestore.collection('workout_histories');

  /// Saves a completed workout history to Firestore.
  Future<void> saveWorkoutHistory(WorkoutHistoryModel history) async {
    try {
      await _historiesRef.doc(history.id).set(history.toJson());
    } catch (e) {
      throw Exception('Không thể lưu lịch sử tập luyện: ${e.toString()}');
    }
  }

  /// Deletes a workout history entry by its [historyId].
  Future<void> deleteWorkoutHistory(String historyId) async {
    try {
      await _historiesRef.doc(historyId).delete();
    } catch (e) {
      throw Exception('Không thể xóa lịch sử tập luyện: ${e.toString()}');
    }
  }

  /// Fetches all workout histories for the current trainee, ordered by date.
  Future<List<WorkoutHistoryModel>> getWorkoutHistories() async {
    try {
      final snapshot = await _historiesRef
          .where('userId', isEqualTo: _uid)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutHistoryModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải lịch sử tập luyện: ${e.toString()}');
    }
  }

  // ───────────────────────── Exercises ─────────────────────────

  /// Reference to the `exercises` collection.
  CollectionReference<Map<String, dynamic>> get _exercisesRef =>
      _firestore.collection('exercises');

  /// Fetches exercises that are either system-wide or created by [userId].
  ///
  /// Firestore does not support OR across different fields, so we run two
  /// parallel queries and merge the results, deduplicating by [exerciseId].
  Future<List<ExerciseModel>> getExercises(String userId) async {
    try {
      final results = await Future.wait([
        _exercisesRef.where('isSystem', isEqualTo: true).get(),
        _exercisesRef.where('userId', isEqualTo: userId).get(),
      ]);

      final Map<String, ExerciseModel> exerciseMap = {};
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            doc.data(),
          );
          data['exerciseId'] = doc.id;

          final exercise = ExerciseModel.fromJson(data);
          // --- KẾT THÚC SỬA ---

          exerciseMap[exercise.exerciseId] = exercise;
        }
      }
      final list = exerciseMap.values.toList();
      list.sort((a, b) => a.name.compareTo(b.name));

      return list;
    } catch (e) {
      throw Exception('Không thể tải bài tập: ${e.toString()}');
    }
  }

  /// Adds a new trainee-created exercise to the `exercises` collection.
  Future<void> createCustomExercise(ExerciseModel exercise) async {
    try {
      await _exercisesRef.doc(exercise.exerciseId).set(exercise.toJson());
    } catch (e) {
      throw Exception('Không thể tạo bài tập: ${e.toString()}');
    }
  }
}
