import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/auth/logic/auth_bloc.dart';
import '../../../features/auth/logic/auth_state.dart';
import '../../../features/trainee/workout/data/models/routine_model.dart';
import '../../../features/trainee/workout/data/models/workout_plan_model.dart';
import '../../../features/trainee/workout/data/repositories/workout_repository.dart';
import 'system_planning_exercises_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1B1D22);
const Color _kAccent = Color(0xFFC6F432); // Lime green
const Color _kReadMore = Color(0xFFC6F432);
const Color _kTextGrey = Color(0xFFA0A0A0);

/// Day labels in Vietnamese (index 0 = Monday).
const List<String> _kDayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

/// Detail screen for a system workout plan.
///
/// Displays hero image, plan metadata, overview with "read more",
/// a weekly schedule grid (Mon-Sun) with workout indicators,
/// and an equipment list section.
/// Now accepts a [WorkoutPlanModel] for real Firebase data.
class PlanDetailScreen extends StatefulWidget {
  final WorkoutPlanModel plan;
  final bool showEditMenu;
  final VoidCallback? onEdit;
  final bool showApplyButton;

  const PlanDetailScreen({
    super.key,
    required this.plan,
    this.showEditMenu = false,
    this.onEdit,
    this.showApplyButton = true,
  });

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  bool _isOverviewExpanded = false;
  bool _isApplying = false;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  int _currentWeek = 1;
  late final int _totalWeeks;
  late final PageController _pageController;
  final WorkoutRepository _workoutRepository = WorkoutRepository();

  /// Build schedule from plan's trainingDays and routines.
  late final List<_DaySchedule> _schedule;

  /// Collect unique equipment from all exercises in the plan.
  late final List<String> _equipmentList;

  bool _initializedScroll = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _totalWeeks = widget.plan.totalWeeks;
    _pageController = PageController(initialPage: _currentWeek - 1);
    _schedule = _buildSchedule();
    _equipmentList = _collectEquipment();
    if (!widget.showEditMenu) {
      _loadFavoriteStatus();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedScroll) {
      final screenHeight = MediaQuery.of(context).size.height;
      // Start scrolled down slightly (about 30% of screen) so pulling down reveals more image
      final initOffset = (screenHeight * 0.3).clamp(180.0, 300.0);
      _scrollController = ScrollController(initialScrollOffset: initOffset);
      _initializedScroll = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Build a 7-day schedule from plan data.
  /// trainingDays contains the weekday numbers (1=Mon ... 7=Sun).
  /// Routines are matched to training days by order.
  List<_DaySchedule> _buildSchedule() {
    final trainingDays = widget.plan.trainingDays;
    final routines = widget.plan.routines;

    return List.generate(7, (i) {
      final dayNum = i + 1; // 1-7
      final isTraining = trainingDays.contains(dayNum);

      if (isTraining) {
        // Find the routine for this day
        final routineIndex = trainingDays.indexOf(dayNum);
        final routineName = routineIndex < routines.length
            ? routines[routineIndex].name
            : 'Workout ${routineIndex + 1}';
        return _DaySchedule(
          day: _kDayLabels[i],
          workout: routineName,
          hasWorkout: true,
          routine:
              routineIndex < routines.length ? routines[routineIndex] : null,
        );
      } else {
        return _DaySchedule(
          day: _kDayLabels[i],
          workout: 'Nghỉ',
          hasWorkout: false,
        );
      }
    });
  }

  /// Collect unique equipment names from all exercises across all routines.
  List<String> _collectEquipment() {
    final equipSet = <String>{};
    for (final routine in widget.plan.routines) {
      for (final ex in routine.exercises) {
        // ExerciseEntry doesn't have equipment directly,
        // so we use primaryMuscle as a fallback label
        if (ex.exerciseName.isNotEmpty) {
          equipSet.add(ex.exerciseName);
        }
      }
    }
    return equipSet.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Sliver App Bar with Hero Image ──
          _buildSliverAppBar(),

          // ── Rest of Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title & Chips (Scrolled up nicely with body) ──
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      widget.plan.name,
                      style: GoogleFonts.inter(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text('NutrifitVN', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runSpacing: 8,
                      spacing: 6,
                      children: [
                        _DarkMetaChip(text: '${widget.plan.totalWeeks} weeks'),
                        _DarkMetaChip(text: '${widget.plan.sessionsPerWeek} workouts/week'),
                        _DarkMetaChip(text: '${_equipmentList.length} equipments'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Apply Button ──
                  if (widget.showApplyButton) ...[
                    _buildApplyButton(),
                    const SizedBox(height: 12),
                  ],

                  // ── Actions Row (Save, Like, Share) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.bookmark_border, 'Save', () {}),
                      _buildActionButton(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        'Like',
                        _isFavoriteLoading ? null : _toggleFavorite,
                        color: _isFavorite ? _kAccent : _kTextGrey,
                      ),
                      _buildActionButton(Icons.ios_share, 'Share', () {}),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Overview Card ──
                  if (widget.plan.description.isNotEmpty) ...[
                    _buildOverview(),
                    const SizedBox(height: 32),
                  ],

                  // ── In This Plan (Weekly Schedule) ──
                  _buildWeeklySchedule(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: _kTextGrey),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sliver AppBar & Hero Image
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSliverAppBar() {
    final screenHeight = MediaQuery.of(context).size.height;
    // Taller image so pulling down reveals more.
    final heroHeight = (screenHeight * 0.65).clamp(450.0, 600.0);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: heroHeight,
      backgroundColor: _kBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
      actions: [
        if (widget.showEditMenu)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
              onSelected: (value) {
                if (value == 'edit') {
                  widget.onEdit?.call();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Chỉnh sửa'),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {}, // Home action if needed
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(120),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
      centerTitle: true,
      title: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          if (!_scrollController.hasClients) return const SizedBox.shrink();
          
          final offset = _scrollController.offset;
          final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
          
          // Trì hoãn hiện Title: Text trong Body cao tầm 120px, 
          // Chỉ bắt đầu hiện lên khi kéo qua đoạn text đó (sâu xuống dưới ~120px sau khi AppBar bị ghim)
          final fullyHiddenOffset = heroHeight - collapsedHeight + 120;
          final startFadeOffset = fullyHiddenOffset - 40; 

          final opacity = ((offset - startFadeOffset) / (fullyHiddenOffset - startFadeOffset)).clamp(0.0, 1.0);

          if (opacity == 0.0) return const SizedBox.shrink();

          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
        child: Text(
          widget.plan.name,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                _buildHeroImageContent(heroHeight),
                
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(60),
                          Colors.transparent,
                          _kBg.withAlpha(150),
                          _kBg,
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildHeroImageContent(double heroHeight) {
    Widget fallbackIcon() {
      return Center(
        child: Icon(
          Icons.fitness_center_rounded,
          size: 64,
          color: Colors.grey.shade600,
        ),
      );
    }

    if (widget.plan.imageUrl.isNotEmpty) {
      if (widget.plan.imageUrl.startsWith('assets/')) {
        return Image.asset(
          widget.plan.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: heroHeight,
          errorBuilder: (_, __, ___) => fallbackIcon(),
        );
      } else {
        return Image.network(
          widget.plan.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: heroHeight,
          errorBuilder: (_, __, ___) => fallbackIcon(),
        );
      }
    }
    return fallbackIcon();
  }

  // Header and Subtitle are no longer used independently, replaced by inline inside Hero Image.

  // ═══════════════════════════════════════════════════════════════════════════
  // Header (Title + Subtitle)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorite = await _workoutRepository.isSystemPlanFavorite(
        widget.plan.planId,
      );
      if (!mounted) return;
      setState(() => _isFavorite = favorite);
    } catch (_) {
      // Keep silent to avoid blocking detail usage when favorite state fails.
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isFavoriteLoading = true);
    try {
      final nextFavorite = !_isFavorite;
      await _workoutRepository.setSystemPlanFavorite(
        plan: widget.plan,
        isFavorite: nextFavorite,
      );

      if (!mounted) return;
      setState(() => _isFavorite = nextFavorite);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              nextFavorite
                  ? 'Đã thêm vào giáo án yêu thích.'
                  : 'Đã bỏ khỏi giáo án yêu thích.',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Cập nhật yêu thích thất bại: $e')),
        );
    } finally {
      if (mounted) setState(() => _isFavoriteLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Apply Button (Gradient Pill)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildApplyButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF9E9E9E), // Gray from the screenshot
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isApplying ? null : _applyToMyPlan,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: _isApplying
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Join This Plan',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyToMyPlan() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Bạn cần đăng nhập để áp dụng giáo án.')),
        );
      return;
    }

    setState(() => _isApplying = true);
    try {
      final authState = context.read<AuthBloc>().state;
      final isCoach = authState is AuthAuthenticated && authState.user.role == 'coach';

      final isTaken = await _workoutRepository.isPlanNameTaken(
        planName: widget.plan.name,
        isTemplate: isCoach,
      );
      if (isTaken) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Tên giáo án đã tồn tại trong giáo án của bạn.'),
            ),
          );
        return;
      }

      final now = DateTime.now();
      final clonedPlan = widget.plan.copyWith(
        planId: '${currentUser.uid}_${now.microsecondsSinceEpoch}',
        userId: currentUser.uid,
        isTemplate: isCoach,
        isActive: !isCoach,
        createdAt: now,
      );

      await _workoutRepository.createPlan(clonedPlan);
      if (!isCoach) {
        await _workoutRepository.setActivePlan(clonedPlan.planId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Đã áp dụng vào giáo án của tôi.')),
        );

      context.go('/workout-templates');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Áp dụng giáo án thất bại: $e')),
        );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Overview
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOverview() {
    final desc = widget.plan.description;
    final displayText = _isOverviewExpanded
        ? desc
        : desc.substring(0, min(180, desc.length));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade300,
            height: 1.6,
          ),
          children: [
            TextSpan(text: displayText),
            if (!_isOverviewExpanded && desc.length > 180) ...[
              const TextSpan(text: '... '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: () => setState(() => _isOverviewExpanded = true),
                  child: Text(
                    'more',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kReadMore,
                    ),
                  ),
                ),
              ),
            ],
            if (_isOverviewExpanded) ...[
              const TextSpan(text: ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: () => setState(() => _isOverviewExpanded = false),
                  child: Text(
                    'less',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kReadMore,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // In This Plan — Weekly Schedule
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWeeklySchedule() {
    final workoutDaysCount = _schedule.where((day) => day.hasWorkout).length;
    final pageHeight = (104.0 + (workoutDaysCount * 86.0)).clamp(180.0, 560.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'In This Plan',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentWeek > 1) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Icon(
                    Icons.chevron_left,
                    color: _currentWeek > 1 ? _kAccent : Colors.grey.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Week $_currentWeek / $_totalWeeks',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_currentWeek < _totalWeeks) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Icon(
                    Icons.chevron_right,
                    color: _currentWeek < _totalWeeks ? _kAccent : Colors.grey.shade700,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _totalWeeks,
            onPageChanged: (index) {
              setState(() {
                _currentWeek = index + 1;
              });
            },
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-header
                    Row(
                      children: [
                        // Hexagon indicator (rotated square with small radius)
                        Transform.rotate(
                          angle: pi / 4,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _kAccent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Transform.rotate(
                              angle: -pi / 4,
                              child: Center(
                                child: Text(
                                  '$weekNumber',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Week $weekNumber',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        // 7 dots representing each day
                        Row(
                          children: List.generate(7, (dotIndex) {
                            final isWorkout = dotIndex < _schedule.length
                                ? _schedule[dotIndex].hasWorkout
                                : false;
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isWorkout ? _kAccent : Colors.grey.shade700,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Day list (Only Active Days)
                    Column(
                      children: _schedule
                        .where((day) => day.hasWorkout)
                        .map((day) => _buildDayRow(day)).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(_DaySchedule day) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Day label
          SizedBox(
            width: 30,
            child: Text(
              day.day,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildWorkoutCard(day.workout, day.routine),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(String title, RoutineModel? routine) {
    return GestureDetector(
      onTap: () {
        if (routine != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SystemPlanningExercisesScreen(
                plan: widget.plan,
                routine: routine,
              ),
            ),
          );
        }
      },
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Thumbnail
            _buildPlanThumbnail(60),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed _buildRestCard()

  Widget _buildPlanThumbnail(double size) {
    if (widget.plan.imageUrl.isNotEmpty) {
      if (widget.plan.imageUrl.startsWith('assets/')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            widget.plan.imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildThumbnailFallback(size),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          widget.plan.imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildThumbnailFallback(size),
        ),
      );
    }

    return _buildThumbnailFallback(size);
  }

  Widget _buildThumbnailFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _kAccent.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.fitness_center_rounded,
        size: 22,
        color: _kAccent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models (internal)
// ─────────────────────────────────────────────────────────────────────────────

class _DaySchedule {
  final String day;
  final String workout;
  final bool hasWorkout;
  final RoutineModel? routine;

  const _DaySchedule({
    required this.day,
    required this.workout,
    required this.hasWorkout,
    this.routine,
  });
}

class _DarkMetaChip extends StatelessWidget {
  const _DarkMetaChip({required this.text});

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
