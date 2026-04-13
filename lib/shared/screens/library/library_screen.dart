import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_router.dart';
import '../../../features/auth/logic/auth_bloc.dart';
import '../../../features/auth/logic/auth_state.dart';
import '../../../features/trainee/workout/data/models/workout_plan_model.dart';
import '../../../features/trainee/workout/data/repositories/workout_repository.dart';
import '../plans/system_plans_screen.dart';
import 'exercise_library_screen.dart';
import 'muscle_group_screen.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF000000);
const Color _kCardBg = Color(0xFF121212);
const Color _kLime = Color(0xFFE2FF54);
const List<Color> _kPlanCardColors = [
  Color(0xFF2A2A2A),
  Color(0xFF333333),
  Color(0xFF222222),
  Color(0xFF1A1A1A),
  Color(0xFF2E2E2E),
  Color(0xFF1F1F1F),
];

/// Coach Library Screen — Tab 3 in CoachMainScreen.
///
/// Redesigned layout featuring:
/// 1. Top grid (Exercise & Nutrition repositories)
/// 2. System plan banners
/// 3. Personal plans list with image cards and toggle
class CoachLibraryScreen extends StatefulWidget {
  const CoachLibraryScreen({super.key});

  @override
  State<CoachLibraryScreen> createState() => _CoachLibraryScreenState();
}

class _CoachLibraryScreenState extends State<CoachLibraryScreen> {
  final _workoutRepo = WorkoutRepository();

  Future<List<WorkoutPlanModel>> _getMyLibraryPlans() async {
    final authState = context.read<AuthBloc>().state;
    final isCoach =
        authState is AuthAuthenticated && authState.user.role == 'coach';

    if (isCoach) {
      return _workoutRepo.getCoachTemplates();
    }
    return _workoutRepo.getAllPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section 1: Main Library Grid ──
              _buildMainLibraryList(),
              const SizedBox(height: 24),
  
              // ── Section 3: My Plans ──
              _buildMyPlansHeader(),
              const SizedBox(height: 14),
              _buildMyPlansList(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Section 1: Main Library Grid (Horizontal Cards)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMainLibraryList() {
    return Column(
      children: [
        _HybridGridCard(
          title: 'Giáo án tập',
          subtitle: 'LỘ TRÌNH',
          imageUrl: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&h=300&fit=crop',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemPlansScreen()));
          },
        ),
        const SizedBox(height: 16),
        _HybridGridCard(
          title: 'Kho bài tập',
          subtitle: '500+ BÀI TẬP',
          imageUrl: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=600&h=300&fit=crop',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()));
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Section 3: My Plans Header
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMyPlansHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Giáo án của tôi',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        InkWell(
          onTap: () async {
            await context.push(AppRouter.workoutTemplates);
            if (!mounted) return;
            setState(() {});
          },
          child: Text(
            'Xem tất cả',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _kLime,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Section 3: My Plans List
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMyPlansList() {
    return FutureBuilder<List<WorkoutPlanModel>>(
      future: _getMyLibraryPlans(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Không tải được giáo án của bạn',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final plans = (snapshot.data ?? []).take(2).toList();
        if (plans.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Bạn chưa có giáo án nào',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            mainAxisExtent: 320,
          ),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return _MyPlanPreviewCard(
              plan: plan,
              onTap: () async {
                await context.push('/my-plan-detail', extra: plan);
                if (!context.mounted) return;
                setState(() {});
              },
            );
          },
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Hybrid Grid Card (White card layout over semi-transparent image background)
// ═════════════════════════════════════════════════════════════════════════════

class _HybridGridCard extends StatelessWidget {
  const _HybridGridCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.height = 120, // Increased slightly to accommodate 3 lines of content
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100),
            ),
            
            // Sublte Gradient for Text Readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Plan Hero Card (image card with overlay)
// ═════════════════════════════════════════════════════════════════════════════

class _PlanHeroCard extends StatelessWidget {
  const _PlanHeroCard({
    required this.imageUrl,
    required this.title,
    required this.studentCount,
    required this.tags,
    required this.onMore,
  });

  final String imageUrl;
  final String title;
  final String studentCount;
  final List<String> tags;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stack) => Container(color: Colors.grey.shade100),
          ),

          // White Semi-transparent Overlay
          Container(color: Colors.white.withOpacity(0.9)),

          // Top right badge
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.black87, size: 12),
                const SizedBox(width: 4),
                Text(
                  studentCount,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Title + tags
          Positioned(
            left: 12,
            bottom: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => _tag(tag)).toList(),
                ),
              ],
            ),
          ),

          // More button
          Positioned(
            right: 4,
            bottom: 4,
            child: InkWell(
              onTap: onMore,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Firestore Template Card (existing plans from DB)
// ═════════════════════════════════════════════════════════════════════════════

class _MyPlanPreviewCard extends StatelessWidget {
  final WorkoutPlanModel plan;
  final VoidCallback onTap;

  const _MyPlanPreviewCard({
    required this.plan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackColor =
        _kPlanCardColors[plan.name.length % _kPlanCardColors.length];
    final subtitle =
        '${plan.totalWeeks} tuần • ${plan.sessionsPerWeek} buổi/tuần';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: fallbackColor,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: plan.imageUrl.isNotEmpty
                ? Image.asset(
                    plan.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(
                        Icons.fitness_center_rounded,
                        size: 50,
                        color: Colors.white.withAlpha(50),
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.fitness_center_rounded,
                      size: 50,
                      color: Colors.white.withAlpha(50),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            plan.name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Color(0xFFF4CB43),
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
