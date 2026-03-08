import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../data/models/water_entry_model.dart';
import '../../logic/water_cubit.dart';
import '../../logic/water_state.dart';
import '../widgets/drink_selection_bottom_sheet.dart';
import '../widgets/water_goal_bottom_sheet.dart';

/// Main screen for daily water intake tracking.
///
/// Layout (top → bottom):
///   1. Goal banner
///   2. Circular progress indicator
///   3. Quick-log grid (2 × 2)
///   4. History list
///   5. Bottom "Ghi đồ uống" sticky button
class WaterTrackingScreen extends StatelessWidget {
  const WaterTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
            'Hôm nay • ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<WaterCubit, WaterState>(
        builder: (context, state) {
          if (state is! WaterLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
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
                      _GoalBanner(
                        current: state.totalConsumed,
                        goal: state.dailyGoalMl,
                        onTap: () => _showGoalSheet(context, state),
                      ),
                      const SizedBox(height: 28),
                      _CircularProgress(
                        current: state.totalConsumed,
                        goal: state.dailyGoalMl,
                      ),
                      const SizedBox(height: 28),
                      _QuickLogGrid(
                        onQuickAdd: (entry) =>
                            context.read<WaterCubit>().addEntry(entry),
                        onCustom: () => _showDrinkSheet(context),
                      ),
                      const SizedBox(height: 24),
                      _HistorySection(
                        entries: state.entries,
                        onDelete: (i) =>
                            context.read<WaterCubit>().removeEntry(i),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Sticky bottom button ──
              _BottomLogButton(onTap: () => _showDrinkSheet(context)),
            ],
          );
        },
      ),
    );
  }

  void _showGoalSheet(BuildContext context, WaterLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WaterGoalBottomSheet(
        currentGoalMl: state.dailyGoalMl,
        recommendedGoalMl: state.dailyGoalMl,
        onSave: (goal) => context.read<WaterCubit>().updateGoal(goal),
      ),
    );
  }

  void _showDrinkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DrinkSelectionBottomSheet(
          onSave: (entry) => context.read<WaterCubit>().addEntry(entry),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Goal Banner
// ═══════════════════════════════════════════════════════════════════════════════

class _GoalBanner extends StatelessWidget {
  final int current;
  final int goal;
  final VoidCallback onTap;

  const _GoalBanner({
    required this.current,
    required this.goal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đã uống: $current / $goal ml',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Circular Progress
// ═══════════════════════════════════════════════════════════════════════════════

class _CircularProgress extends StatelessWidget {
  final int current;
  final int goal;

  const _CircularProgress({required this.current, required this.goal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Center(
      child: CircularPercentIndicator(
        radius: 100,
        lineWidth: 16,
        percent: progress,
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: Colors.lightBlue,
        backgroundColor: Colors.lightBlue.shade100.withValues(alpha: 0.3),
        animation: true,
        animationDuration: 800,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$current',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'ml',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Quick Log Grid (2×2)
// ═══════════════════════════════════════════════════════════════════════════════

class _QuickLogGrid extends StatelessWidget {
  final ValueChanged<WaterEntryModel> onQuickAdd;
  final VoidCallback onCustom;

  const _QuickLogGrid({required this.onQuickAdd, required this.onCustom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'GHI NHANH',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _quickTile(
              context,
              icon: Icons.water_drop,
              name: 'Nước',
              ml: 250,
              color: Colors.lightBlue,
              onTap: () => _addQuickEntry('Nước', 250, 1.0),
            ),
            _quickTile(
              context,
              icon: Icons.local_cafe,
              name: 'Sữa',
              ml: 250,
              color: Colors.orange.shade300,
              onTap: () => _addQuickEntry('Sữa', 250, 0.87),
            ),
            _quickTile(
              context,
              icon: Icons.emoji_food_beverage,
              name: 'Trà chanh',
              ml: 250,
              color: Colors.green.shade400,
              onTap: () => _addQuickEntry('Trà chanh', 250, 0.90),
            ),
            _addMoreTile(context),
          ],
        ),
      ],
    );
  }

  void _addQuickEntry(String name, int ml, double factor) {
    onQuickAdd(
      WaterEntryModel(
        entryId: 'water_${DateTime.now().millisecondsSinceEpoch}',
        drinkName: name,
        amountMl: ml,
        hydrationFactor: factor,
        loggedAt: DateTime.now(),
      ),
    );
  }

  Widget _quickTile(
    BuildContext context, {
    required IconData icon,
    required String name,
    required int ml,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${ml}ml',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addMoreTile(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onCustom,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.lightBlue.shade100, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 20,
                color: Colors.lightBlue,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Thêm đồ uống',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.lightBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// History Section
// ═══════════════════════════════════════════════════════════════════════════════

class _HistorySection extends StatelessWidget {
  final List<WaterEntryModel> entries;
  final ValueChanged<int> onDelete;

  const _HistorySection({required this.entries, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ĐÃ UỐNG ${entries.length} LẦN',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),

        if (entries.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa ghi đồ uống nào hôm nay',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: entries.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.water_drop,
                      size: 20,
                      color: Colors.lightBlue,
                    ),
                  ),
                  title: Text(
                    entry.drinkName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${entry.amountMl} ml • ${entry.effectiveMl} ml nước',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                    onPressed: () => onDelete(index),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Bottom Log Button
// ═══════════════════════════════════════════════════════════════════════════════

class _BottomLogButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BottomLogButton({required this.onTap});

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
          icon: const Icon(Icons.local_drink),
          label: const Text(
            'Ghi đồ uống',
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
