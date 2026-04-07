import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routes/app_router.dart';
import '../../../workout/logic/workout_bloc.dart';
import '../../../workout/logic/workout_event.dart';
import '../../../workout/logic/workout_state.dart';
import '../../../workout/data/models/workout_plan_model.dart';

/// Selection screen that lets the trainee choose between workout or nutrition
/// plan templates and manage personal workout plans.
/// This is the root screen for the "Giáo án" tab.
class PlanSelectionScreen extends StatelessWidget {
  const PlanSelectionScreen({super.key});

  void _confirmDelete(BuildContext context, WorkoutPlanModel plan) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xóa giáo án'),
        content: Text('Bạn có chắc muốn xóa "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<WorkoutBloc>().add(WorkoutDeleteRequested(plan.planId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đã xóa "${plan.name}"')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

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
                    onPressed: () => context.push(AppRouter.workoutTemplates),
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

          // ── Section 2 body: vertical plan list ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 40),
              child: BlocBuilder<WorkoutBloc, WorkoutState>(
                builder: (context, state) {
                  if (state is WorkoutLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is WorkoutLoaded) {
                    final allPlans = state.allPlans;

                    if (allPlans.isEmpty) {
                      return const _EmptyPlanCard();
                    }

                    // Filter: max 2 plans (1 active + 1 most recent inactive)
                    final activePlan = allPlans.where((p) => p.isActive).toList();
                    final inactivePlans = allPlans
                        .where((p) => !p.isActive)
                        .toList()
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    final latestInactive = inactivePlans.isNotEmpty
                        ? [inactivePlans.first]
                        : <WorkoutPlanModel>[];
                    final displayPlans = [...activePlan, ...latestInactive];

                    return Column(
                      children: [
                        ...displayPlans.map((plan) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MyPlanRow(
                            plan: plan,
                            onTap: () => context.push(AppRouter.myPlanDetail, extra: plan),
                            onDelete: plan.isActive ? null : () => _confirmDelete(context, plan),
                          ),
                        )),
                      ],
                    );
                  }

                  // Initial / error fallback
                  return const SizedBox.shrink();
                },
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
  const _EmptyPlanCard();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: Colors.grey.shade400,
        strokeWidth: 2,
        gap: 5,
        dashWidth: 8,
        radius: 20,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
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
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: Colors.grey.shade500,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bạn chưa có giáo án nào',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// My Plan Row (Compact horizontal bar)
// ═══════════════════════════════════════════════════════════════════════════════

class _MyPlanRow extends StatelessWidget {
  final WorkoutPlanModel plan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _MyPlanRow({
    required this.plan,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: plan.isActive
              ? Border.all(color: Colors.blue.shade400, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: plan.isActive
                    ? Colors.blue.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                plan.isActive
                    ? Icons.bolt
                    : Icons.assignment_outlined,
                color: plan.isActive
                    ? Colors.blue.shade600
                    : Colors.grey.shade600,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.trainingDays.length} buổi/tuần',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Active badge
            if (plan.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Đang dùng',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Delete button (only for non-active plans)
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Xóa giáo án',
              ),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}


