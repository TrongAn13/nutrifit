import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../tracking/data/models/daily_log_model.dart';
import '../models/food_model.dart';
import '../models/nutrition_plan_model.dart';
import '../models/water_entry_model.dart';

/// Handles Firestore operations for daily nutrition logs and the food library.
/// Reads from `daily_logs` and `foods` collections.
class NutritionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NutritionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _logsRef =>
      _firestore.collection('daily_logs');

  CollectionReference<Map<String, dynamic>> get _foodsRef =>
      _firestore.collection('foods');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');
    return user.uid;
  }

  // ═══════════════════════════ Daily Logs ═══════════════════════════

  /// Fetches the daily log for a specific [date].
  /// Returns `null` if no log exists for that date.
  Future<DailyLogModel?> getDailyLog(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await _logsRef
          .where('userId', isEqualTo: _uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return DailyLogModel.fromJson(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Không thể tải dữ liệu dinh dưỡng: ${e.toString()}');
    }
  }

  /// Creates or updates a daily log document.
  Future<void> saveDailyLog(DailyLogModel log) async {
    try {
      await _logsRef.doc(log.logId).set(log.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Không thể lưu dữ liệu: ${e.toString()}');
    }
  }

  /// Adds a [MealEntry] to today's daily log.
  ///
  /// If no daily log exists for today, creates one with the entry.
  /// Also recalculates macro totals after adding.
  Future<DailyLogModel> addMealEntry(MealEntry entry, {DateTime? date}) async {
    return addMealEntries([entry], date: date);
  }

  /// Adds multiple [MealEntry] items to today's daily log in a single write.
  ///
  /// Avoids race conditions from multiple concurrent single-entry writes.
  Future<DailyLogModel> addMealEntries(List<MealEntry> entries, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();

    if (entries.isEmpty) {
      final existing = await getDailyLog(targetDate);
      if (existing != null) return existing;
      throw Exception('Không có món ăn để thêm.');
    }

    try {
      DailyLogModel? log = await getDailyLog(targetDate);

      if (log == null) {
        final logId =
            '${_uid}_${targetDate.year}${targetDate.month.toString().padLeft(2, '0')}${targetDate.day.toString().padLeft(2, '0')}';
        log = DailyLogModel(
          logId: logId,
          userId: _uid,
          date: DateTime(targetDate.year, targetDate.month, targetDate.day),
          meals: entries,
          totalCaloriesIn: entries.fold<double>(0.0, (s, m) => s + m.calories),
          totalProtein: entries.fold<double>(0.0, (s, m) => s + m.protein),
          totalFat: entries.fold<double>(0.0, (s, m) => s + m.fat),
          totalCarbs: entries.fold<double>(0.0, (s, m) => s + m.carbs),
        );
      } else {
        final updatedMeals = [...log.meals, ...entries];
        log = log.copyWith(
          meals: updatedMeals,
          totalCaloriesIn: updatedMeals.fold<double>(
            0.0,
            (double s, m) => s + m.calories,
          ),
          totalProtein: updatedMeals.fold<double>(
            0.0,
            (double s, m) => s + m.protein,
          ),
          totalFat: updatedMeals.fold<double>(0.0, (double s, m) => s + m.fat),
          totalCarbs: updatedMeals.fold<double>(
            0.0,
            (double s, m) => s + m.carbs,
          ),
        );
      }

      await saveDailyLog(log);
      return log;
    } catch (e) {
      throw Exception('Không thể thêm món ăn: ${e.toString()}');
    }
  }

  /// Removes a [MealEntry] from the daily log for a specific [date].
  Future<DailyLogModel> removeMealEntry(DateTime date, String mealId) async {
    try {
      DailyLogModel? log = await getDailyLog(date);
      if (log == null) throw Exception('Không tìm thấy dữ liệu.');

      final updatedMeals = log.meals.where((m) => m.mealId != mealId).toList();

      log = log.copyWith(
        meals: updatedMeals,
        totalCaloriesIn: updatedMeals.fold<double>(
          0.0,
          (double s, m) => s + m.calories,
        ),
        totalProtein: updatedMeals.fold<double>(
          0.0,
          (double s, m) => s + m.protein,
        ),
        totalFat: updatedMeals.fold<double>(0.0, (double s, m) => s + m.fat),
        totalCarbs: updatedMeals.fold<double>(
          0.0,
          (double s, m) => s + m.carbs,
        ),
      );

      await saveDailyLog(log);
      return log;
    } catch (e) {
      throw Exception('Không thể xóa món ăn: ${e.toString()}');
    }
  }

  // ═══════════════════════════ Water Tracking ═══════════════════════════

  /// Saves a list of water entries for today, replacing the existing list.
  Future<void> saveWaterEntries(List<WaterEntryModel> entries) async {
    try {
      final today = DateTime.now();
      DailyLogModel? log = await getDailyLog(today);

      if (log == null) {
        final logId =
            '${_uid}_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
        log = DailyLogModel(
          logId: logId,
          userId: _uid,
          date: DateTime(today.year, today.month, today.day),
          waterEntries: entries,
        );
      } else {
        log = log.copyWith(waterEntries: entries);
      }

      await saveDailyLog(log);
    } catch (e) {
      throw Exception('Không thể lưu lượng nước: ${e.toString()}');
    }
  }

  /// Updates the daily water goal for today.
  Future<void> updateWaterGoal(int goalMl) async {
    try {
      final today = DateTime.now();
      DailyLogModel? log = await getDailyLog(today);

      if (log == null) {
        final logId =
            '${_uid}_${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
        log = DailyLogModel(
          logId: logId,
          userId: _uid,
          date: DateTime(today.year, today.month, today.day),
          waterGoalMl: goalMl,
        );
      } else {
        log = log.copyWith(waterGoalMl: goalMl);
      }

      await saveDailyLog(log);
    } catch (e) {
      throw Exception('Không thể cập nhật mục tiêu nước: ${e.toString()}');
    }
  }

  // ═══════════════════════════ Food Library ═══════════════════════════

  /// Fetches all system foods (isSystem == true).
  Future<List<FoodModel>> getSystemFoods() async {
    try {
      final snapshot = await _foodsRef
          .where('isSystem', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải thư viện thực phẩm: ${e.toString()}');
    }
  }

  /// Fetches trainee-created foods (isSystem == false, userId == current trainee).
  Future<List<FoodModel>> getUserFoods() async {
    try {
      final snapshot = await _foodsRef
          .where('isSystem', isEqualTo: false)
          .where('userId', isEqualTo: _uid)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => FoodModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải thực phẩm của bạn: ${e.toString()}');
    }
  }

  /// Adds a new trainee-created food to the `foods` collection.
  Future<void> addFood(FoodModel food) async {
    try {
      await _foodsRef.doc(food.foodId).set(food.toJson());
    } catch (e) {
      throw Exception('Không thể thêm thực phẩm: ${e.toString()}');
    }
  }

  // ═══════════════════════════ Nutrition Plans ═══════════════════════════

  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('nutrition_plans');

  /// Fetches all nutrition plans belonging to the current trainee.
  Future<List<NutritionPlanModel>> getAllPlans() async {
    try {
      final snapshot = await _plansRef
          .where('userId', isEqualTo: _uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NutritionPlanModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách thực đơn: ${e.toString()}');
    }
  }

  /// Creates a new nutrition plan in Firestore.
  Future<void> createPlan(NutritionPlanModel plan) async {
    try {
      await _plansRef.doc(plan.planId).set(plan.toJson());
    } catch (e) {
      throw Exception('Không thể tạo thực đơn: ${e.toString()}');
    }
  }

  /// Updates an existing nutrition plan.
  Future<void> updatePlan(NutritionPlanModel plan) async {
    try {
      await _plansRef.doc(plan.planId).update(plan.toJson());
    } catch (e) {
      throw Exception('Không thể cập nhật thực đơn: ${e.toString()}');
    }
  }
}
