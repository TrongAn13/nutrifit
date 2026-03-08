import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/health_metrics_utils.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../tracking/data/models/daily_log_model.dart';
import '../../logic/nutrition_bloc.dart';
import '../../logic/nutrition_event.dart';
import '../../logic/nutrition_state.dart';
import '../../logic/water_cubit.dart';
import '../../logic/water_state.dart';

/// Nutrition tab — displays daily macros, progress rings, and meal list.
class NutritionDashboard extends StatelessWidget {
  const NutritionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger initial load for today
    context.read<NutritionBloc>().add(NutritionLoadRequested(DateTime.now()));

    return Scaffold(
      backgroundColor: Colors.grey[50],
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

  // ── Computed nutrition goals from user profile ──
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'MỤC TIÊU DINH DƯỠNG',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // ── Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
              // ── Calorie Row ──
              _buildCalorieRow(theme),
              const SizedBox(height: 28),

              // ── Macros Row ──
              _buildMacrosRow(theme),
            ],
          ),
        ),
      ],
    );
  }

  // ── Calorie Row ──────────────────────────────────────────────────────────

  Widget _buildCalorieRow(ThemeData theme) {
    final percent = _caloriesGoal > 0
        ? (_caloriesConsumed / _caloriesGoal).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left — consumed
        _calorieStat(theme, value: '$_caloriesConsumed', label: 'Đã nạp'),

        // Center — circular indicator
        CircularPercentIndicator(
          radius: 70,
          lineWidth: 12,
          percent: percent,
          animation: true,
          animationDuration: 800,
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: const Color(0xFF4CAF50),
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.12),
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_caloriesRemaining',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Calo còn lại',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),

        // Right — goal
        _calorieStat(theme, value: '$_caloriesGoal', label: 'Mục tiêu'),
      ],
    );
  }

  Widget _calorieStat(
    ThemeData theme, {
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
        ),
      ],
    );
  }

  // ── Macros Row ──────────────────────────────────────────────────────────

  Widget _buildMacrosRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _macroColumn(
            theme,
            title: 'Protein',
            consumed: _proteinConsumed,
            goal: _proteinGoal,
            color: const Color(0xFFE91E63), // Pink
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _macroColumn(
            theme,
            title: 'Fat',
            consumed: _fatConsumed,
            goal: _fatGoal,
            color: const Color(0xFFFF9800), // Amber
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _macroColumn(
            theme,
            title: 'Carbs',
            consumed: _carbsConsumed,
            goal: _carbsGoal,
            color: const Color(0xFF9C27B0), // Purple
          ),
        ),
      ],
    );
  }

  Widget _macroColumn(
    ThemeData theme, {
    required String title,
    required double consumed,
    required double goal,
    required Color color,
  }) {
    final percent = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
          progressColor: color,
          backgroundColor: color.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 6),
        Text(
          '${consumed.toInt()}/${goal.toInt()}g',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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

  /// Dynamic meal definitions based on user goals
  List<_MealData> _getMeals() {
    final tdee = _getTDEE();
    // Typical macro split: 25% breakfast, 35% lunch, 25% dinner, 15% snack
    return [
      _MealData(
        key: 'breakfast',
        name: 'Bữa sáng',
        targetCalories: (tdee * 0.25).round(),
        consumedCalories: _getConsumedCalories('breakfast'),
        icon: Icons.wb_sunny,
        iconColor: Colors.orange,
        bgColor: Colors.orange.withValues(alpha: 0.12),
      ),
      _MealData(
        key: 'lunch',
        name: 'Bữa trưa',
        targetCalories: (tdee * 0.35).round(),
        consumedCalories: _getConsumedCalories('lunch'),
        icon: Icons.wb_sunny,
        iconColor: Colors.deepOrange,
        bgColor: Colors.deepOrange.withValues(alpha: 0.12),
      ),
      _MealData(
        key: 'dinner',
        name: 'Bữa tối',
        targetCalories: (tdee * 0.25).round(),
        consumedCalories: _getConsumedCalories('dinner'),
        icon: Icons.nightlight_round,
        iconColor: Colors.purple,
        bgColor: Colors.purple.withValues(alpha: 0.12),
      ),
      _MealData(
        key: 'snack',
        name: 'Bữa phụ',
        targetCalories: (tdee * 0.15).round(),
        consumedCalories: _getConsumedCalories('snack'),
        icon: Icons.wb_cloudy,
        iconColor: Colors.orange.shade300,
        bgColor: Colors.orange.shade50,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'BỮA ĂN',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meal.consumedCalories > 0
                      ? '${meal.consumedCalories} / ${meal.targetCalories} Calo'
                      : 'Khuyến nghị: ${meal.targetCalories} Calo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: meal.consumedCalories > meal.targetCalories
                        ? Colors.red.shade400
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // ── Trailing add button ──
          GestureDetector(
            onTap: () => _openFoodLibrary(context),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[100],
              child: Icon(Icons.add, color: Colors.grey[700], size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to the Food Search screen for this meal type.
  void _openFoodLibrary(BuildContext context) async {
    final now = DateTime.now();
    final result = await context.push<dynamic>(
      '/food-library?mealName=${Uri.encodeComponent(meal.name)}&date=${now.toIso8601String()}',
    );
    // Reload if we returned from FoodSearchScreen (which pops true if modified)
    // or MealDetailScreen.
    if (context.mounted && result != null) {
      context.read<NutritionBloc>().add(NutritionLoadRequested(now));
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'UỐNG NƯỚC VÀ VẬN ĐỘNG',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
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
    final theme = Theme.of(context);

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: ' / $goal ml',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
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
              child: Icon(
                Icons.local_drink,
                size: 32,
                color: Colors.lightBlue.shade200,
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
    final theme = Theme.of(context);

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '0',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: ' Calo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
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
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.orange.shade50,
              child: Icon(
                Icons.directions_run,
                size: 22,
                color: Colors.orange.shade800,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final baseColor = isLight ? Colors.grey.shade300 : Colors.grey.shade700;
    final highlightColor = isLight
        ? Colors.grey.shade100
        : Colors.grey.shade600;

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
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Goal card shimmer
            Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
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
                color: Colors.white,
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
                    color: Colors.white,
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
    final theme = Theme.of(context);
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
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
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
            icon: Icons.menu_book,
            label: 'Công thức',
            onTap: () {
              // TODO: Navigate to recipes
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickLinkCard(
            icon: Icons.class_,
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black87, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
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
    final isToday = now.year == selectedDate.year &&
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.black87),
            ],
          ),
        ),

        // ── Analysis Button (Right) ──
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.orangeAccent, Colors.lightGreen],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
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
                  const Icon(Icons.bar_chart, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Phân tích',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
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
                color: Colors.grey[300],
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
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                todayTextStyle: const TextStyle(fontWeight: FontWeight.bold),
                todayDecoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                ),
                selectedDecoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), // Green for selected
                  shape: BoxShape.circle,
                ),
                outsideTextStyle: TextStyle(color: Colors.grey.shade300),
                disabledTextStyle: TextStyle(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
