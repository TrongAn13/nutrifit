import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../../core/utils/health_metrics_utils.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../tracking/data/models/daily_log_model.dart';
import '../../logic/nutrition_bloc.dart';
import '../../logic/nutrition_event.dart';
import '../../logic/nutrition_state.dart';

/// Displays detailed information about a specific meal slot for a given date.
///
/// Shows:
///   - A **Meal Goal Card** with calorie and macro targets.
///   - A **Logged Foods Card** listing all entries for this meal.
///   - A **Bottom Bar** to navigate back to [FoodSearchScreen].
class MealDetailScreen extends StatelessWidget {
  final String mealName;
  final DateTime date;

  const MealDetailScreen({
    super.key,
    required this.mealName,
    required this.date,
  });

  /// Map Vietnamese meal name → Firestore key.
  static const _mealKeyMap = {
    'Bữa sáng': 'breakfast',
    'Bữa trưa': 'lunch',
    'Bữa tối': 'dinner',
    'Bữa phụ': 'snack',
  };

  /// Fraction of TDEE allocated per meal.
  static const _mealFraction = {
    'breakfast': 0.25,
    'lunch': 0.35,
    'dinner': 0.25,
    'snack': 0.15,
  };

  String get _mealKey => _mealKeyMap[mealName] ?? 'snack';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: BlocBuilder<NutritionBloc, NutritionState>(
        builder: (context, state) {
          if (state is NutritionLoading || state is NutritionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NutritionError) {
            return Center(child: Text('Lỗi: ${state.message}'));
          }
          final loaded = state as NutritionLoaded;
          final dailyLog = loaded.dailyLog;
          final user = loaded.user;

          // Filter meals that belong to this meal type
          final mealEntries =
              dailyLog?.meals.where((m) => m.mealType == _mealKey).toList() ??
              [];

          // Calculate meal-specific goals
          final targetCalories = _computeTarget(user);
          final macros = HealthMetricsUtils.calculateMacroGoals(targetCalories);

          // Consumed totals
          final consumedCal = mealEntries.fold(
            0.0,
            (sum, m) => sum + m.calories,
          );
          final consumedPro = mealEntries.fold(
            0.0,
            (sum, m) => sum + m.protein,
          );
          final consumedFat = mealEntries.fold(0.0, (sum, m) => sum + m.fat);
          final consumedCarb = mealEntries.fold(0.0, (sum, m) => sum + m.carbs);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Meal Goal Card ──
                      _MealGoalCard(
                        targetCalories: targetCalories,
                        consumedCalories: consumedCal,
                        proteinGoal: macros.protein,
                        proteinConsumed: consumedPro,
                        fatGoal: macros.fat,
                        fatConsumed: consumedFat,
                        carbsGoal: macros.carbs,
                        carbsConsumed: consumedCarb,
                      ),
                      const SizedBox(height: 24),

                      // ── Logged Foods Card ──
                      _LoggedFoodsCard(
                        entries: mealEntries,
                        onDelete: (index) {
                          final foodId = mealEntries[index].mealId;
                          context.read<NutritionBloc>().add(
                            NutritionMealDeleted(date: date, mealId: foodId),
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Bottom Bar ──
              _BottomAddBar(
                onTap: () => context.push(
                  '/food-library?mealName=${Uri.encodeComponent(mealName)}&date=${date.toIso8601String()}',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _computeTarget(UserModel? user) {
    if (user == null) return 500;
    final bmr = HealthMetricsUtils.calculateBMR(user);
    if (bmr <= 0) return 500;
    final tdee = HealthMetricsUtils.calculateTDEE(
      bmr,
      user.activityLevel ?? 'sedentary',
    );
    final totalTarget = HealthMetricsUtils.calculateTargetCalories(
      tdee,
      user.goal ?? 'maintain',
    );
    final fraction = _mealFraction[_mealKey] ?? 0.25;
    return (totalTarget * fraction).round();
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.grey[50],
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$mealName • ${date.day}/${date.month}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Meal Goal Card
// ═══════════════════════════════════════════════════════════════════════════════

class _MealGoalCard extends StatelessWidget {
  final int targetCalories;
  final double consumedCalories;
  final double proteinGoal;
  final double proteinConsumed;
  final double fatGoal;
  final double fatConsumed;
  final double carbsGoal;
  final double carbsConsumed;

  const _MealGoalCard({
    required this.targetCalories,
    required this.consumedCalories,
    required this.proteinGoal,
    required this.proteinConsumed,
    required this.fatGoal,
    required this.fatConsumed,
    required this.carbsGoal,
    required this.carbsConsumed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = targetCalories > 0
        ? ((consumedCalories / targetCalories) * 100).round()
        : 0;
    final progress = targetCalories > 0
        ? (consumedCalories / targetCalories).clamp(0.0, 1.5)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'MỤC TIÊU BỮA',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Calorie header ──
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${consumedCalories.toInt()}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          TextSpan(
                            text: ' / $targetCalories Calo',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: percent > 100
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percent%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: percent > 100
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Progress bar with target marker ──
              SizedBox(
                height: 12,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    // Target marker position (clamped at bar width)
                    final markerX = barWidth.clamp(0.0, barWidth);

                    return Stack(
                      children: [
                        // Background
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF4CAF50,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        // Filled portion
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        // Target marker line
                        Positioned(
                          left: markerX - 1.5,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Macros row ──
              Row(
                children: [
                  Expanded(
                    child: _MacroColumn(
                      label: 'Protein',
                      consumed: proteinConsumed,
                      goal: proteinGoal,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MacroColumn(
                      label: 'Fat',
                      consumed: fatConsumed,
                      goal: fatGoal,
                      color: Colors.orange.shade400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MacroColumn(
                      label: 'Carbs',
                      consumed: carbsConsumed,
                      goal: carbsGoal,
                      color: Colors.purple.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroColumn extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final Color color;

  const _MacroColumn({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 6,
          percent: progress,
          barRadius: const Radius.circular(3),
          backgroundColor: color.withValues(alpha: 0.15),
          progressColor: color,
          animation: true,
          animationDuration: 600,
        ),
        const SizedBox(height: 4),
        Text(
          '${consumed.toInt()}/${goal.toInt()} g',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Logged Foods Card
// ═══════════════════════════════════════════════════════════════════════════════

class _LoggedFoodsCard extends StatelessWidget {
  final List<MealEntry> entries;
  final ValueChanged<int> onDelete;

  const _LoggedFoodsCard({required this.entries, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalGrams = entries.length * 100; // Placeholder: 100g per entry

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'THỰC PHẨM ĐÃ GHI',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '${entries.length} thực phẩm • $totalGrams gram',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (entries.isNotEmpty)
                Divider(height: 24, color: Colors.grey[200]),

              // Entry list
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.no_food_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có thực phẩm nào được ghi.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ),
                      title: Text(
                        entry.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${entry.calories.toInt()} Calo • 100g',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.grey[500],
                        ),
                        onPressed: () => onDelete(index),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom Add Bar
// ═══════════════════════════════════════════════════════════════════════════════

class _BottomAddBar extends StatelessWidget {
  final VoidCallback onTap;

  const _BottomAddBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add),
          label: const Text(
            'Ghi thêm',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
