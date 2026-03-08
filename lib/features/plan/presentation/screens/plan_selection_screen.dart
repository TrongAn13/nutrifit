import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../workout/data/repositories/workout_repository.dart';
import '../../../workout/logic/workout_template_bloc.dart';
import '../../../workout/logic/workout_template_event.dart';
import '../../../workout/presentation/screens/workout_template_list_screen.dart';
import 'nutrition_plan_template_screen.dart';

/// Selection screen that lets the user choose between workout or nutrition
/// plan templates. This is the root screen for the "Giáo án" tab.
class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Giáo án mẫu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // ── Card 1: Workout Plans ──
            _PlanCategoryCard(
              icon: Icons.fitness_center,
              iconBackgroundColor: Colors.blue.shade50,
              iconColor: Colors.blue.shade600,
              title: 'Giáo án tập luyện',
              subtitle: 'Các mẫu bài tập được thiết kế sẵn cho từng mục tiêu',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => WorkoutTemplateBloc(
                        workoutRepository: WorkoutRepository(),
                      )..add(const WorkoutTemplateLoadRequested()),
                      child: const WorkoutTemplateListScreen(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Card 2: Nutrition Plans ──
            _PlanCategoryCard(
              icon: Icons.restaurant,
              iconBackgroundColor: Colors.green.shade50,
              iconColor: Colors.green.shade600,
              title: 'Giáo án dinh dưỡng',
              subtitle: 'Kế hoạch ăn uống khoa học dựa trên chỉ số cá nhân',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NutritionPlanTemplateScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plan Category Card
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCategoryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PlanCategoryCard({
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              // Leading: Icon in circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),

              // Center: Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing: Chevron
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
