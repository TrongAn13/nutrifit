import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/models/workout_plan_model.dart';

/// Bottom sheet that displays plan distribution and statistics.
///
/// Call via `showModalBottomSheet(isScrollControlled: true, ...)`.
class PlanStatisticsBottomSheet extends StatelessWidget {
  final WorkoutPlanModel plan;

  const PlanStatisticsBottomSheet({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ── Compute statistics ──
    final totalRoutines = plan.routines.length;
    final allExercises = plan.routines.expand((r) => r.exercises).toList();
    final totalExercises = allExercises.length;
    final avgPerSession = totalRoutines > 0
        ? (totalExercises / totalRoutines).round()
        : 0;
    final totalSets = allExercises.fold<int>(0, (sum, e) => sum + e.sets);

    // Muscle distribution: group by primaryMuscle, sum sets
    final Map<String, int> muscleMap = {};
    for (final ex in allExercises) {
      final muscle = ex.primaryMuscle.isNotEmpty ? ex.primaryMuscle : 'Khác';
      muscleMap[muscle] = (muscleMap[muscle] ?? 0) + ex.sets;
    }
    // Sort by sets descending
    final sortedMuscles = muscleMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxSets = sortedMuscles.isNotEmpty ? sortedMuscles.first.value : 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header ──
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Phân bố & Thống kê giáo án',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Tổng quan chương trình "${plan.name}"',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),

              // ── Stats Grid 2x2 ──
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Tổng buổi tập',
                      value: '$totalRoutines',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.auto_graph_rounded,
                      label: 'TB bài/buổi',
                      value: '$avgPerSession',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fitness_center_rounded,
                      label: 'Tổng bài tập',
                      value: '$totalExercises',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.repeat_rounded,
                      label: 'Tổng số hiệp',
                      value: '$totalSets',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Routine Structure ──
              Text(
                'Cấu trúc lịch tập',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plan.routines.length,
                itemBuilder: (context, index) {
                  final r = plan.routines[index];
                  final rSets = r.exercises.fold<int>(0, (s, e) => s + e.sets);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${r.exercises.length} bài tập • $rSets sets',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Muscle Distribution ──
              Text(
                'Phân bố nhóm cơ',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (sortedMuscles.isEmpty)
                Center(
                  child: Text(
                    'Chưa có dữ liệu',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                )
              else
                ...sortedMuscles.map((entry) {
                  final ratio = entry.value / max(maxSets, 1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        // Muscle name
                        SizedBox(
                          width: 80,
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Progress bar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 10,
                              backgroundColor: Colors.deepOrange.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepOrange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Sets count
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${entry.value} sets',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.deepOrange),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
