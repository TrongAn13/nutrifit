import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/utils/health_metrics_utils.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../tracking/data/models/daily_log_model.dart';
import '../../logic/nutrition_bloc.dart';
import '../../logic/nutrition_event.dart';
import '../../logic/nutrition_state.dart';
import 'meal_notification_screen.dart';

// ── Dark theme constants ────────────────────────────────────────────────────
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kLime = Color(0xFFE2FF54);
const Color _kBorder = Color(0xFF2A2D35);
const Color _kTextSecondary = Color(0xFF8A8F9D);

// Macro badge colors
const Color _kProteinColor = Color(0xFFFF8A80);
const Color _kFatColor = Color(0xFFFFD54F);
const Color _kCarbsColor = Color(0xFFB388FF);

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
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      body: BlocBuilder<NutritionBloc, NutritionState>(
        builder: (context, state) {
          if (state is NutritionLoading || state is NutritionInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _kLime),
            );
          }
          if (state is NutritionError) {
            return Center(
              child: Text(
                'Lỗi: ${state.message}',
                style: GoogleFonts.inter(color: Colors.white70),
              ),
            );
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
                onTap: () async {
                  await context.push(
                    '/food-library?mealName=${Uri.encodeComponent(mealName)}&date=${date.toIso8601String()}',
                  );
                  if (context.mounted) {
                    context.read<NutritionBloc>().add(NutritionLoadRequested(date));
                  }
                },
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
    return AppBar(
      backgroundColor: _kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
      ),
      centerTitle: true,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          '$mealName • ${date.day}/${date.month}',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.gearSix(), color: Colors.white, size: 22),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealNotificationScreen()),
            );
          },
        ),
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
            style: GoogleFonts.inter(
              color: _kTextSecondary,
              fontSize: 12,
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
            color: _kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: _kLime,
                              fontSize: 24,
                            ),
                          ),
                          TextSpan(
                            text: ' / $targetCalories Calo',
                            style: GoogleFonts.inter(
                              color: _kTextSecondary,
                              fontSize: 14,
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
                          ? Colors.redAccent.withOpacity(0.15)
                          : _kLime.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$percent%',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: percent > 100 ? Colors.redAccent : _kLime,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Progress bar ──
              SizedBox(
                height: 10,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final barWidth = constraints.maxWidth;
                    return Stack(
                      children: [
                        // Background
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: _kLime.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        // Filled
                        FractionallySizedBox(
                          widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: _kLime,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                        // Target marker
                        Positioned(
                          left: barWidth - 1.5,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                      color: _kProteinColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MacroColumn(
                      label: 'Fat',
                      consumed: fatConsumed,
                      goal: fatGoal,
                      color: _kFatColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MacroColumn(
                      label: 'Carbs',
                      consumed: carbsConsumed,
                      goal: carbsGoal,
                      color: _kCarbsColor,
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
    final progress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: _kTextSecondary, fontSize: 12),
        ),
        const SizedBox(height: 6),
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${consumed.toInt()}/${goal.toInt()} g',
          style: GoogleFonts.inter(
            color: _kTextSecondary,
            fontSize: 11,
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
    final totalGrams = entries.length * 100; // Placeholder: 100g per entry

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'THỰC PHẨM ĐÃ GHI',
            style: GoogleFonts.inter(
              color: _kTextSecondary,
              fontSize: 12,
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
            color: _kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '${entries.length} thực phẩm • $totalGrams gram',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              if (entries.isNotEmpty)
                Divider(height: 24, color: _kBorder),

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
                          color: _kTextSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có thực phẩm nào được ghi.',
                          style: GoogleFonts.inter(
                            color: _kTextSecondary,
                            fontSize: 13,
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
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: _kBorder),
                  itemBuilder: (_, index) {
                    final entry = entries[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 20,
                          color: _kTextSecondary.withOpacity(0.5),
                        ),
                      ),
                      title: Text(
                        entry.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${entry.calories.toInt()} Calo • 100g',
                        style: GoogleFonts.inter(
                          color: _kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          PhosphorIcons.trash(),
                          color: Colors.redAccent.withOpacity(0.7),
                          size: 20,
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
        color: _kCardBg,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add),
          label: Text(
            'Ghi thêm',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _kLime,
            foregroundColor: _kBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
