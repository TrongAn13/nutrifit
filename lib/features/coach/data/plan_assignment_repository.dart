import 'package:cloud_firestore/cloud_firestore.dart';

import '../../trainee/workout/data/models/workout_plan_model.dart';

/// Handles Firestore operations for assigning workout plans
/// from a coach to a client.
class PlanAssignmentRepository {
  final FirebaseFirestore _db;

  PlanAssignmentRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _db.collection('trainee_templates');

  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _db.collection('coach_templates');

  // ───────────────────────── Read ─────────────────────────

  /// Fetches all workout plans created by [coachId].
  Future<List<WorkoutPlanModel>> getCoachPlans(String coachId) async {
    try {
      final snapshot = await _templatesRef
          .where('userId', isEqualTo: coachId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WorkoutPlanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải giáo án của HLV: $e');
    }
  }

  // ───────────────────────── Write ─────────────────────────

  /// Clones a coach's plan and assigns it to a client.
  ///
  /// 1. Deactivates all existing plans of the client.
  /// 2. Creates a new plan copy with [userId] = [clientId] and [isActive] = true.
  /// 3. Marks the clone with [assignedByCoachId] for traceability.
  Future<void> assignPlanToClient({
    required String coachId,
    required String clientId,
    required WorkoutPlanModel templatePlan,
  }) async {
    try {
      final batch = _db.batch();

      // 1. Deactivate all current plans of the client
      final existingPlans = await _plansRef
          .where('userId', isEqualTo: clientId)
          .get();

      for (final doc in existingPlans.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      // 2. Create a cloned plan for the client
      final newPlanId = _db.collection('trainee_templates').doc().id;
      final clonedPlan = templatePlan.copyWith(
        planId: newPlanId,
        userId: clientId,
        isActive: true,
        createdAt: DateTime.now(),
        assignedByCoachId: coachId,
        isTemplate: false, // Clone becomes a real trainee plan
      );

      batch.set(_plansRef.doc(newPlanId), clonedPlan.toJson());

      // 3. Commit atomically
      await batch.commit();
    } catch (e) {
      throw Exception('Giao giáo án thất bại: $e');
    }
  }
}
