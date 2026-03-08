import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routes/app_router.dart';
import '../../../workout/data/repositories/workout_repository.dart';
import '../../../workout/logic/workout_template_bloc.dart';
import '../../../workout/logic/workout_template_event.dart';
import '../../../workout/logic/workout_bloc.dart';
import '../../../workout/logic/workout_state.dart';
import '../../../workout/data/models/workout_plan_model.dart';
import '../../../workout/presentation/screens/workout_template_list_screen.dart';
import 'nutrition_plan_template_screen.dart';

/// Selection screen that lets the user choose between workout or nutrition
/// plan templates and manage personal workout plans.
/// This is the root screen for the "Giáo án" tab.
class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // ── Safe-area header ──
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 16, bottom: 16,
                ),
                child: Text(
                  'Khám phá',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

          // ── Section 1: Hero Banners ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Banner 1: Workout plans
                  _HeroBanner(
                    title: 'Giáo án Tập luyện',
                    subtitle: 'Khám phá các mẫu bài tập đa dạng',
                    icon: Icons.fitness_center,
                    gradientColors: [
                      Colors.blue.shade400,
                      Colors.lightBlue.shade800,
                    ],
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

                  // Banner 2: Nutrition plans
                  _HeroBanner(
                    title: 'Giáo án Dinh dưỡng',
                    subtitle: 'Kế hoạch ăn uống khoa học cho bạn',
                    icon: Icons.restaurant,
                    gradientColors: [
                      Colors.green.shade400,
                      Colors.teal.shade800,
                    ],
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
          ),

          // ── Spacer ──
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // ── Section 2 header: My Plans ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giáo án của tôi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRouter.createPlan),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section 2 body: horizontal plan list ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 40),
              child: SizedBox(
                height: 160,
                child: BlocBuilder<WorkoutBloc, WorkoutState>(
                  builder: (context, state) {
                    if (state is WorkoutLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is WorkoutLoaded) {
                      final myPlans = state.allPlans;

                      if (myPlans.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _EmptyPlanCard(
                            onTap: () => context.push(AppRouter.createPlan),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: myPlans.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          return _MyPlanCard(plan: myPlans[index]);
                        },
                      );
                    }

                    // Initial / error fallback
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Hero Banner
// ═══════════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _HeroBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Background watermark icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 100,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),

            // Foreground content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Empty Plan Card (dashed border)
// ═══════════════════════════════════════════════════════════════════════════════

/// A custom painter that draws a dashed rounded-rectangle border.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.gap = 5,
    this.dashWidth = 8,
    this.radius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rRect);

    // Create dashed path from the solid one
    final dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        dashedPath.addPath(
          metric.extractPath(distance, end.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = end + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gap != oldDelegate.gap ||
      dashWidth != oldDelegate.dashWidth ||
      radius != oldDelegate.radius;
}

class _EmptyPlanCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyPlanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: Colors.grey.shade400,
          strokeWidth: 2,
          gap: 5,
          dashWidth: 8,
          radius: 20,
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.blue.shade600,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tạo giáo án đầu tiên của bạn',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
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
// My Plan Card
// ═══════════════════════════════════════════════════════════════════════════════

class _MyPlanCard extends StatelessWidget {
  final WorkoutPlanModel plan;

  const _MyPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRouter.planDetail, extra: plan),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: plan.isActive
              ? Border.all(color: Colors.blue.shade400, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon badge
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: plan.isActive
                    ? Colors.blue.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                plan.isActive
                    ? Icons.bolt
                    : Icons.assignment_outlined,
                color: plan.isActive
                    ? Colors.blue.shade600
                    : Colors.grey.shade600,
                size: 24,
              ),
            ),
            const Spacer(),

            // Plan name
            Text(
              plan.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Plan metadata
            Text(
              '${plan.totalWeeks} tuần • ${plan.trainingDays.length} buổi',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
