import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/health_metrics_utils.dart';
import '../../../../auth/data/models/user_model.dart';
import '../../../tracking/data/models/daily_log_model.dart';
import '../../logic/nutrition_bloc.dart';
import '../../logic/nutrition_event.dart';
import '../../logic/nutrition_state.dart';
import '../../logic/water_cubit.dart';
import '../../logic/water_state.dart';

// ── Dark theme constants matching TraineeDashboardScreen ──
const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1A1D23);
const Color _kLime = Color(0xFFE2FF54); // Electric Lime
const Color _kLimeDark = Color(0xFF8CFF00); // For Gradient

/// Nutrition tab — displays daily macros, progress rings, and meal list.
class NutritionDashboard extends StatelessWidget {
  const NutritionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger initial load for today
    context.read<NutritionBloc>().add(NutritionLoadRequested(DateTime.now()));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: BlocBuilder<NutritionBloc, NutritionState>(
          builder: (context, state) {
            if (state is NutritionLoading || state is NutritionInitial) {
              return const _ShimmerBody();
            }
            if (state is NutritionError) {
              return _ErrorBody(
                message: state.message,
                onRetry: () => context.read<NutritionBloc>().add(
                  NutritionLoadRequested(DateTime.now()),
                ),
              );
            }
            final loaded = state as NutritionLoaded;
            return _DashboardBody(
              dailyLog: loaded.dailyLog,
              selectedDate: loaded.selectedDate,
              user: loaded.user,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Body
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends StatelessWidget {
  final DailyLogModel? dailyLog;
  final DateTime selectedDate;
  final UserModel? user;

  const _DashboardBody({
    required this.dailyLog,
    required this.selectedDate,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nutrition Header ──
          NutritionHeaderWidget(selectedDate: selectedDate),
          const SizedBox(height: 16),

          // ── Nutrition Goal Card ──
          NutritionGoalCard(user: user, dailyLog: dailyLog),
          const SizedBox(height: 24),

          // ── Nutrition Quick Links ──
          const NutritionQuickLinksWidget(),
          const SizedBox(height: 24),

          // ── Meal List Section ──
          MealListSection(user: user, dailyLog: dailyLog),
          const SizedBox(height: 24),

          // ── Water & Exercise Section ──
          const WaterAndExerciseSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition Goal Card
// ─────────────────────────────────────────────────────────────────────────────

/// Displays daily calorie and macro goals with circular / linear indicators.
class NutritionGoalCard extends StatefulWidget {
  final UserModel? user;
  final DailyLogModel? dailyLog;

  const NutritionGoalCard({super.key, this.user, this.dailyLog});

  @override
  State<NutritionGoalCard> createState() => _NutritionGoalCardState();
}

class _NutritionGoalCardState extends State<NutritionGoalCard> {
  // ── Computed nutrition goals from trainee profile ──
  int get _caloriesGoal {
    final user = widget.user;
    if (user == null) return 2000;
    final bmr = HealthMetricsUtils.calculateBMR(user);
    if (bmr <= 0) return 2000;
    final tdee = HealthMetricsUtils.calculateTDEE(
      bmr,
      user.activityLevel ?? 'sedentary',
    );
    return HealthMetricsUtils.calculateTargetCalories(
      tdee,
      user.goal ?? 'maintain',
    );
  }

  int get _caloriesConsumed => widget.dailyLog?.totalCaloriesIn.toInt() ?? 0;
  int get _caloriesRemaining => _caloriesGoal - _caloriesConsumed;

  double get _proteinGoal =>
      HealthMetricsUtils.calculateMacroGoals(_caloriesGoal).protein;
  double get _proteinConsumed => widget.dailyLog?.totalProtein ?? 0;

  double get _fatGoal =>
      HealthMetricsUtils.calculateMacroGoals(_caloriesGoal).fat;
  double get _fatConsumed => widget.dailyLog?.totalFat ?? 0;

  double get _carbsGoal =>
      HealthMetricsUtils.calculateMacroGoals(_caloriesGoal).carbs;
  double get _carbsConsumed => widget.dailyLog?.totalCarbs ?? 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Nutrition Goal',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // ── Calorie Row ──
              _buildCalorieRow(),
              const SizedBox(height: 28),

              // ── Macros Row ──
              _buildMacrosRow(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Calorie Row ──────────────────────────────────────────────────────────

  Widget _buildCalorieRow() {
    final percent = _caloriesGoal > 0
        ? (_caloriesConsumed / _caloriesGoal).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left — consumed
        _calorieStat(value: '$_caloriesConsumed', label: 'Đã nạp'),

        // Center — circular indicator
        CircularPercentIndicator(
          radius: 70,
          lineWidth: 12,
          percent: percent,
          animation: true,
          animationDuration: 800,
          circularStrokeCap: CircularStrokeCap.round,
          linearGradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [_kLime, _kLimeDark],
          ),
          backgroundColor: _kLime.withValues(alpha: 0.12),
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_caloriesRemaining',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Calo còn lại',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        // Right — goal
        _calorieStat(value: '$_caloriesGoal', label: 'Mục tiêu'),
      ],
    );
  }

  Widget _calorieStat({required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ── Macros Row ──────────────────────────────────────────────────────────

  Widget _buildMacrosRow() {
    return Row(
      children: [
        Expanded(
          child: _macroColumn(
            title: 'Protein',
            consumed: _proteinConsumed,
            goal: _proteinGoal,
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF1866FF)],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _macroColumn(
            title: 'Fat',
            consumed: _fatConsumed,
            goal: _fatGoal,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF0080), Color(0xFFFF5252)],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _macroColumn(
            title: 'Carbs',
            consumed: _carbsConsumed,
            goal: _carbsGoal,
            gradient: const LinearGradient(
              colors: [Color(0xFFF9FF00), Color(0xFFFF9D00)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _macroColumn({
    required String title,
    required double consumed,
    required double goal,
    required LinearGradient gradient,
  }) {
    final percent = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          padding: EdgeInsets.zero,
          lineHeight: 8,
          percent: percent,
          animation: true,
          animationDuration: 800,
          barRadius: const Radius.circular(4),
          linearGradient: gradient,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
        ),
        const SizedBox(height: 6),
        Text(
          '${consumed.toInt()}/${goal.toInt()}g',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal List Section
// ─────────────────────────────────────────────────────────────────────────────

/// Displays four meal cards (Breakfast, Lunch, Dinner, Snack) with dynamic calorie data.
class MealListSection extends StatelessWidget {
  final UserModel? user;
  final DailyLogModel? dailyLog;

  const MealListSection({super.key, this.user, this.dailyLog});

  int _getTDEE() {
    if (user == null) return 2000;
    final bmr = HealthMetricsUtils.calculateBMR(user!);
    if (bmr <= 0) return 2000;
    final tdee = HealthMetricsUtils.calculateTDEE(
      bmr,
      user!.activityLevel ?? 'sedentary',
    );
    return HealthMetricsUtils.calculateTargetCalories(
      tdee,
      user!.goal ?? 'maintain',
    );
  }

  /// Get total calories consumed for a specific meal category
  int _getConsumedCalories(String mealType) {
    if (dailyLog == null) return 0;
    return dailyLog!.meals
        .where((m) => m.mealType == mealType)
        .fold<double>(0.0, (sum, m) => sum + m.calories)
        .toInt();
  }

  /// Dynamic meal definitions based on trainee goals
  List<_MealData> _getMeals() {
    final tdee = _getTDEE();
    // Typical macro split: 25% breakfast, 35% lunch, 25% dinner, 15% snack
    return [
      _MealData(
        key: 'breakfast',
        name: 'Bữa sáng',
        targetCalories: (tdee * 0.25).round(),
        consumedCalories: _getConsumedCalories('breakfast'),
        icon: Icons.wb_sunny_rounded,
        iconColor: const Color(0xFFFFB74D), // Bright amber
        bgColor: Colors.white,
      ),
      _MealData(
        key: 'lunch',
        name: 'Bữa trưa',
        targetCalories: (tdee * 0.35).round(),
        consumedCalories: _getConsumedCalories('lunch'),
        icon: Icons.wb_sunny_rounded,
        iconColor: const Color(0xFFFF8A65), // Bright deep orange
        bgColor: Colors.white,
      ),
      _MealData(
        key: 'dinner',
        name: 'Bữa tối',
        targetCalories: (tdee * 0.25).round(),
        consumedCalories: _getConsumedCalories('dinner'),
        icon: Icons.nightlight_round,
        iconColor: const Color(0xFFCE93D8), // Bright purple
        bgColor: Colors.white,
      ),
      _MealData(
        key: 'snack',
        name: 'Bữa phụ',
        targetCalories: (tdee * 0.15).round(),
        consumedCalories: _getConsumedCalories('snack'),
        icon: Icons.wb_cloudy_rounded,
        iconColor: const Color(0xFF81C784), // Bright green
        bgColor: Colors.white,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Meals',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── Meal Cards ──
        ...List.generate(_getMeals().length, (index) {
          final meal = _getMeals()[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MealCard(meal: meal),
          );
        }),
      ],
    );
  }
}

/// Internal data class for a single meal slot.
class _MealData {
  final String key;
  final String name;
  final int targetCalories;
  final int consumedCalories;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _MealData({
    required this.key,
    required this.name,
    required this.targetCalories,
    required this.consumedCalories,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });
}

/// A single meal card row.
class _MealCard extends StatelessWidget {
  final _MealData meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _handleCardTap(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // ── Leading icon ──
              CircleAvatar(
                radius: 22,
                backgroundColor: meal.bgColor,
                child: Icon(meal.icon, color: meal.iconColor, size: 22),
              ),
              const SizedBox(width: 14),

              // ── Center text ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meal.consumedCalories > 0
                          ? '${meal.consumedCalories} / ${meal.targetCalories} Calo'
                          : 'Khuyến nghị: ${meal.targetCalories} Calo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: meal.consumedCalories > meal.targetCalories
                            ? const Color(0xFFFF5252)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Trailing add button ──
              GestureDetector(
                onTap: () => _openFoodLibrary(context),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add, color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle tap on the meal card body
  void _handleCardTap(BuildContext context) async {
    final state = context.read<NutritionBloc>().state;
    DateTime mealDate = DateTime.now();
    if (state is NutritionLoaded) {
      mealDate = state.selectedDate;
    }

    if (meal.consumedCalories > 0) {
      await context.push<dynamic>(
        '/meal-detail?mealName=${Uri.encodeComponent(meal.name)}&date=${mealDate.toIso8601String()}',
      );
      if (context.mounted) {
        context.read<NutritionBloc>().add(NutritionLoadRequested(mealDate));
      }
    } else {
      final result = await context.push<dynamic>(
        '/food-library?mealName=${Uri.encodeComponent(meal.name)}&date=${mealDate.toIso8601String()}',
      );
      
      if (context.mounted) {
        context.read<NutritionBloc>().add(NutritionLoadRequested(mealDate));
        
        if (result == 'go_to_meal_detail') {
          await context.push<dynamic>(
            '/meal-detail?mealName=${Uri.encodeComponent(meal.name)}&date=${mealDate.toIso8601String()}',
          );
          if (context.mounted) {
            context.read<NutritionBloc>().add(NutritionLoadRequested(mealDate));
          }
        }
      }
    }
  }

  /// Navigate to the Food Search screen for this meal type.
  void _openFoodLibrary(BuildContext context) async {
    final state = context.read<NutritionBloc>().state;
    DateTime mealDate = DateTime.now();
    if (state is NutritionLoaded) {
      mealDate = state.selectedDate;
    }

    final result = await context.push<dynamic>(
      '/food-library?mealName=${Uri.encodeComponent(meal.name)}&date=${mealDate.toIso8601String()}',
    );

    if (context.mounted) {
      context.read<NutritionBloc>().add(NutritionLoadRequested(mealDate));
      
      if (result == 'go_to_meal_detail') {
        await context.push<dynamic>(
          '/meal-detail?mealName=${Uri.encodeComponent(meal.name)}&date=${mealDate.toIso8601String()}',
        );
        if (context.mounted) {
          context.read<NutritionBloc>().add(NutritionLoadRequested(mealDate));
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Water & Exercise Section
// ─────────────────────────────────────────────────────────────────────────────

/// Displays two side-by-side cards for water intake and exercise tracking.
class WaterAndExerciseSection extends StatelessWidget {
  const WaterAndExerciseSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Water and Excercise',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ── Two cards ──
        Row(
          children: [
            // Water card
            Expanded(child: _WaterCard()),
            const SizedBox(width: 16),
            // Exercise card
            Expanded(child: _ExerciseCard()),
          ],
        ),
      ],
    );
  }
}

/// Water intake tracking card.
class _WaterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.push('/water-tracking');
        if (context.mounted) {
          context.read<WaterCubit>().load();
        }
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // ── Text content ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Uống nước',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<WaterCubit, WaterState>(
                    builder: (context, state) {
                      int currentWater = 0;
                      int goal = 2500;

                      if (state is WaterLoaded) {
                        currentWater = state.entries.fold<int>(
                          0,
                          (sum, entry) => sum + entry.amountMl,
                        );
                        goal = state.dailyGoalMl;
                      }

                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$currentWater',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: ' / $goal ml',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Bottom-right icon ──
            Positioned(
              bottom: 12,
              right: 12,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.local_drink_rounded,
                  size: 22,
                  color: const Color(0xFF4FC3F7), // Bright light blue
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Exercise tracking card.
class _ExerciseCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // ── Text content ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tập luyện',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '0',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(
                        text: ' Calo',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom-right icon ──
          Positioned(
            bottom: 12,
            right: 12,
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.directions_run_rounded,
                size: 22,
                color: Color(0xFFFFAB40), // Bright amber
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Body
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBody extends StatelessWidget {
  const _ShimmerBody();

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF1A1D23);
    const highlightColor = Color(0xFF2A2D35);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label shimmer
            Container(
              width: 160,
              height: 14,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Goal card shimmer
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            // Section label shimmer
            Container(
              width: 80,
              height: 14,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // 4 Meal card shimmers
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Body
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kLime,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition Quick Links
// ─────────────────────────────────────────────────────────────────────────────

class NutritionQuickLinksWidget extends StatelessWidget {
  const NutritionQuickLinksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickLinkCard(
            icon: Icons.menu_book_rounded,
            label: 'Công thức',
            onTap: () => context.push('/recipes'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickLinkCard(
            icon: Icons.class_rounded,
            label: 'Bộ sưu tập',
            onTap: () {
              context.push('/food-collection');
            },
          ),
        ),
      ],
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(icon, color: _kCardBg, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nutrition Header Widget
// ─────────────────────────────────────────────────────────────────────────────

class NutritionHeaderWidget extends StatelessWidget {
  final DateTime selectedDate;

  const NutritionHeaderWidget({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday =
        now.year == selectedDate.year &&
        now.month == selectedDate.month &&
        now.day == selectedDate.day;

    final dateText = isToday
        ? 'Hôm nay'
        : 'Ngày ${DateFormat('dd/MM').format(selectedDate)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Date Selector (Left) ──
        GestureDetector(
          onTap: () => _showCalendar(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateText,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),

        // ── Analysis Button (Right) ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _kLime.withValues(alpha: 0.12),
            border: Border.all(color: _kLime.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            onTap: () {
              // TODO: Navigate to Analysis
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded, color: _kLime, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Phân tích',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _kLime,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCalendar(BuildContext context) {
    final nutritionBloc = context.read<NutritionBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: nutritionBloc,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: _CalendarBottomSheet(currentDate: selectedDate),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CalendarBottomSheet extends StatefulWidget {
  final DateTime currentDate;

  const _CalendarBottomSheet({required this.currentDate});

  @override
  State<_CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<_CalendarBottomSheet> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.currentDate;
    _selectedDay = widget.currentDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now(), // Disable future dates automatically
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                // Fire bloc event and pop
                context.read<NutritionBloc>().add(
                  NutritionLoadRequested(selectedDay),
                );
                Navigator.of(context).pop();
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                weekendStyle: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: GoogleFonts.inter(color: Colors.white),
                weekendTextStyle: GoogleFonts.inter(color: Colors.white70),
                todayTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: _kLime,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kLime, width: 1.5),
                ),
                selectedTextStyle: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: const BoxDecoration(
                  color: _kLime,
                  shape: BoxShape.circle,
                ),
                outsideTextStyle: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                disabledTextStyle: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
