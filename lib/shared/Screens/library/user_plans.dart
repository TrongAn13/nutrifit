import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_router.dart';
import '../../../features/coach/data/plan_assignment_repository.dart';
import '../../../features/trainee/workout/data/models/workout_plan_model.dart';
import '../../../features/trainee/workout/data/repositories/workout_repository.dart';

const Color _kBg = Color(0xFF060708);
const Color _kBackBtnBg = Color(0xFF1B1D22);
const Color _kSearchBg = Color(0xFF1B1D22);

const List<Color> _kCardColors = [
  Color(0xFF2A2D35),
  Color(0xFF1E2428),
  Color(0xFF2D2A22),
  Color(0xFF2A1E28),
  Color(0xFF1E2D2A),
  Color(0xFF282A2D),
];

/// Displays all trainee plans with a system-plan-like UI.
///
/// trainee can select one plan and press Save to set it as active.
enum UserPlansRole { trainee, coach }

class WorkoutTemplateListScreen extends StatefulWidget {
  final UserPlansRole role;

  const WorkoutTemplateListScreen({
    super.key,
    this.role = UserPlansRole.trainee,
  });

  @override
  State<WorkoutTemplateListScreen> createState() =>
      _WorkoutTemplateListScreenState();
}

class _WorkoutTemplateListScreenState extends State<WorkoutTemplateListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  final PlanAssignmentRepository _planAssignmentRepository =
      PlanAssignmentRepository();
  String _searchQuery = '';
  bool _favoritesOnly = false;
  late Future<_PlansPayload> _plansFuture;

  void _reloadPlans() {
    setState(() {
      _plansFuture = _loadPlansPayload();
    });
  }

  Future<_PlansPayload> _loadPlansPayload() async {
    final plans = await (widget.role == UserPlansRole.coach
        ? _workoutRepository.getCoachTemplates()
        : _workoutRepository.getAllPlans());
    final favoriteIds = await _workoutRepository.getFavoritePlanIds();
    return _PlansPayload(plans: plans, favoriteIds: favoriteIds);
  }

  @override
  void initState() {
    super.initState();
    _reloadPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _assignPlanToTrainee(WorkoutPlanModel plan) async {
    final traineeIdController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Giao giáo án'),
          content: TextField(
            controller: traineeIdController,
            decoration: const InputDecoration(
              labelText: 'Trainee ID',
              hintText: 'Nhập UID học viên',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Giao'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      traineeIdController.dispose();
      return;
    }

    final traineeId = traineeIdController.text.trim();
    traineeIdController.dispose();
    if (traineeId.isEmpty) return;

    final coachId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (coachId.isEmpty) return;

    try {
      await _planAssignmentRepository.assignPlanToClient(
        coachId: coachId,
        clientId: traineeId,
        templatePlan: plan,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Đã giao giáo án "${plan.name}"')),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Giao giáo án thất bại: $e')),
        );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          'My Plan',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          if (widget.role == UserPlansRole.trainee)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  setState(() => _favoritesOnly = !_favoritesOnly);
                },
                icon: Icon(
                  _favoritesOnly ? Icons.star : Icons.star_border,
                  color: _favoritesOnly ? const Color(0xFFF4B400) : Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBar(
              controller: _searchController,
              backgroundColor: WidgetStateProperty.all(_kSearchBg),
              elevation: WidgetStateProperty.all(0),
              hintText: 'Search for plans',
              hintStyle: WidgetStateProperty.all(
                GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              textStyle: WidgetStateProperty.all(
                GoogleFonts.inter(fontSize: 14, color: Colors.white),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16),
              ),
              leading: Icon(
                Icons.search,
                color: Colors.white.withValues(alpha: 0.4),
                size: 20,
              ),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
              ],
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<_PlansPayload>(
                future: _plansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Không thể tải giáo án',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                    final payload = snapshot.data;
                    final plans = payload?.plans ?? <WorkoutPlanModel>[];
                    final favoriteIds = payload?.favoriteIds ?? <String>{};
                  final filteredPlans = _searchQuery.isEmpty
                      ? plans
                      : plans.where((plan) {
                          final query = _searchQuery.toLowerCase();
                          return plan.name.toLowerCase().contains(query) ||
                              plan.category.toLowerCase().contains(query);
                        }).toList();

                    final displayPlans = _favoritesOnly
                      ? filteredPlans
                        .where((plan) => favoriteIds.contains(plan.planId))
                        .toList()
                      : filteredPlans;

                    if (displayPlans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _favoritesOnly
                                ? 'Chưa có giáo án yêu thích'
                                : _searchQuery.isNotEmpty
                                ? 'Không tìm thấy giáo án'
                                : 'Chưa có giáo án nào',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return MasonryGridView.count(
                    padding: const EdgeInsets.only(bottom: 16),
                    crossAxisCount: 2,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 6,
                    itemCount: displayPlans.length,
                    itemBuilder: (context, index) {
                      final plan = displayPlans[index];
                      final cardColor = _kCardColors[index % _kCardColors.length];
                      return _SelectablePlanCard(
                        plan: plan,
                        fallbackColor: cardColor,
                        onTap: () async {
                          final saved = await context.push<bool>(
                            AppRouter.myPlanDetail,
                            extra: plan,
                          );
                          if (!mounted) return;
                          if (saved == true) {
                            _reloadPlans();
                          }
                        },
                        onAssign: widget.role == UserPlansRole.coach
                            ? () => _assignPlanToTrainee(plan)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final saved = await context.push<bool>(
                        widget.role == UserPlansRole.coach
                            ? '/create-template'
                            : '/create-plan',
                      );
                      if (!mounted) return;
                      if (saved == true) {
                        _reloadPlans();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7FF1F),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.role == UserPlansRole.coach
                          ? 'Create new template'
                          : 'Create new plan',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
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

class _PlansPayload {
  final List<WorkoutPlanModel> plans;
  final Set<String> favoriteIds;

  const _PlansPayload({
    required this.plans,
    required this.favoriteIds,
  });
}

class _SelectablePlanCard extends StatelessWidget {
  const _SelectablePlanCard({
    required this.plan,
    required this.fallbackColor,
    required this.onTap,
    this.onAssign,
  });

  final WorkoutPlanModel plan;
  final Color fallbackColor;
  final VoidCallback onTap;
  final VoidCallback? onAssign;

  Widget _buildPlanImage() {
    if (plan.imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/default_plan.jpg',
        fit: BoxFit.cover,
      );
    }

    if (plan.imageUrl.startsWith('assets/')) {
      return Image.asset(
        plan.imageUrl,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      plan.imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/default_plan.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniqueEquipments = plan.routines
        .expand((routine) => routine.exercises)
        .map((entry) => entry.exerciseName.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: fallbackColor,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildPlanImage(),
          ),
          const SizedBox(height: 4),
          Text(
            plan.name,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _PlanMetaChip(text: '${plan.totalWeeks} weeks'),
                const SizedBox(width: 4),
                _PlanMetaChip(text: '${plan.sessionsPerWeek} workouts/week'),
                const SizedBox(width: 4),
                _PlanMetaChip(text: '$uniqueEquipments equipment'),
              ],
            ),
          ),
          if (onAssign != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAssign,
                icon: const Icon(Icons.send_rounded, size: 16),
                label: const Text('Giao giáo án'),
              ),
            ),
          ],
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _PlanMetaChip extends StatelessWidget {
  const _PlanMetaChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E2A12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: const Color(0xFFF4CB43),
          fontSize: 9,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
