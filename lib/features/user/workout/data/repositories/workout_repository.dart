import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/exercise_model.dart';
import '../models/workout_plan_model.dart';
import '../models/workout_history_model.dart';

/// Handles Firestore operations for the `workout_plans` collection.
class WorkoutRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  WorkoutRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Reference to the `workout_plans` collection.
  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('workout_plans');

  /// Returns the currently signed-in user's UID, or throws.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');
    return user.uid;
  }

  // ───────────────────────── Read ─────────────────────────

  /// Fetches all **active** workout plans belonging to the current user.
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

  /// Fetches ALL workout plans (active + inactive) for the current user.
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

  // ───────────────────────── Write ─────────────────────────

  /// Creates a new workout plan document.
  Future<void> createPlan(WorkoutPlanModel plan) async {
    try {
      await _plansRef.doc(plan.planId).set(plan.toJson());
    } catch (e) {
      throw Exception('Không thể tạo giáo án: ${e.toString()}');
    }
  }

  /// Updates an existing workout plan document or creates it if it doesn't exist.
  Future<void> updatePlan(WorkoutPlanModel plan) async {
    try {
      await _plansRef
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

  /// Fetches all workout histories for the current user, ordered by date.
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

  /// Adds a new user-created exercise to the `exercises` collection.
  Future<void> createCustomExercise(ExerciseModel exercise) async {
    try {
      await _exercisesRef.doc(exercise.exerciseId).set(exercise.toJson());
    } catch (e) {
      throw Exception('Không thể tạo bài tập: ${e.toString()}');
    }
  }
}
