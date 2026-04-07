import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_router.dart';
import '../../../features/trainee/workout/data/models/routine_model.dart';
import '../../../features/trainee/workout/data/models/workout_history_model.dart';
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

class MyPlanDetailScreen extends StatefulWidget {
  final WorkoutPlanModel plan;

  const MyPlanDetailScreen({
    super.key,
    required this.plan,
  });

  @override
  State<MyPlanDetailScreen> createState() => _MyPlanDetailScreenState();
}

class _MyPlanDetailScreenState extends State<MyPlanDetailScreen> {
  bool _isOverviewExpanded = false;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;
  bool _isActivating = false;
  int _currentWeek = 1;
  late final int _totalWeeks;
  late final PageController _pageController;
  late final List<_DaySchedule> _schedule;
  final WorkoutRepository _workoutRepository = WorkoutRepository();

  bool _initializedScroll = false;
  late final ScrollController _scrollController;
  late final List<String> _equipmentList;
  late Future<List<WorkoutHistoryModel>> _historiesFuture;

  @override
  void initState() {
    super.initState();
    _totalWeeks = widget.plan.totalWeeks;
    _pageController = PageController(initialPage: _currentWeek - 1);
    _schedule = _buildSchedule();
    _equipmentList = _collectEquipment();
    _historiesFuture = _workoutRepository.getWorkoutHistories();
    _loadFavoriteStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedScroll) {
      final screenHeight = MediaQuery.of(context).size.height;
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

  List<_DaySchedule> _buildSchedule() {
    final trainingDays = widget.plan.trainingDays;
    final routines = widget.plan.routines;

    return List.generate(7, (i) {
      final dayNum = i + 1;
      final isTraining = trainingDays.contains(dayNum);

      if (isTraining) {
        final routineIndex = trainingDays.indexOf(dayNum);
        final routineName = routineIndex < routines.length
            ? routines[routineIndex].name
            : 'Workout ${routineIndex + 1}';
        return _DaySchedule(
          day: _kDayLabels[i],
          workout: routineName,
          hasWorkout: true,
          routine: routineIndex < routines.length ? routines[routineIndex] : null,
        );
      }

      return _DaySchedule(
        day: _kDayLabels[i],
        workout: 'Nghỉ',
        hasWorkout: false,
      );
    });
  }

  List<String> _collectEquipment() {
    final equipSet = <String>{};
    for (final routine in widget.plan.routines) {
      for (final ex in routine.exercises) {
        if (ex.exerciseName.isNotEmpty) {
          equipSet.add(ex.exerciseName);
        }
      }
    }
    return equipSet.toList();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorite = await _workoutRepository.isSystemPlanFavorite(
        widget.plan.planId,
      );
      if (!mounted) return;
      setState(() => _isFavorite = favorite);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;
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

  Future<void> _deletePlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: _kCardBg,
          title: Text('Xóa giáo án', style: GoogleFonts.inter(color: Colors.white)),
          content: Text('Bạn có chắc muốn xóa "${widget.plan.name}"?', style: GoogleFonts.inter(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('Hủy', style: GoogleFonts.inter(color: Colors.white70)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Xóa', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      if (widget.plan.isTemplate) {
        await _workoutRepository.deleteCoachTemplate(widget.plan.planId);
      } else {
        await _workoutRepository.deletePlan(widget.plan.planId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Đã xóa giáo án')));
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Xóa giáo án thất bại: $e')));
    }
  }

  Future<void> _activatePlan() async {
    if (_isActivating) return;
    setState(() => _isActivating = true);

    try {
      await _workoutRepository.setActivePlan(widget.plan.planId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Plan is now active!')));
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to activate plan: $e')));
    } finally {
      if (mounted) setState(() => _isActivating = false);
    }
  }

  Widget _buildHeroImageContent(double heroHeight) {
    Widget fallbackIcon() {
      return Center(
        child: Icon(Icons.fitness_center_rounded, size: 64, color: Colors.grey.shade600),
      );
    }

    if (widget.plan.imageUrl.isNotEmpty) {
      if (widget.plan.imageUrl.startsWith('assets/')) {
        return Image.asset(widget.plan.imageUrl, fit: BoxFit.cover, width: double.infinity, height: heroHeight, errorBuilder: (_, __, ___) => fallbackIcon());
      } else {
        return Image.network(widget.plan.imageUrl, fit: BoxFit.cover, width: double.infinity, height: heroHeight, errorBuilder: (_, __, ___) => fallbackIcon());
      }
    }
    return fallbackIcon();
  }

  Widget _buildHeroImageBackground(double heroHeight) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: heroHeight + 150,
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          double scale = 1.0;
          double translateY = 0.0;
          if (_scrollController.hasClients) {
            final offset = _scrollController.offset;
            if (offset < 0) {
              scale = 1.0 + (-offset / heroHeight);
            } else {
              translateY = -offset * 0.4;
            }
          }
          return Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..translate(0.0, translateY)
              ..scale(scale, scale),
            child: child,
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImageContent(heroHeight + 150),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withAlpha(80), Colors.transparent, Colors.transparent, _kBg.withAlpha(120)],
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.65).clamp(450.0, 600.0);

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          _buildHeroImageBackground(heroHeight),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              _buildSliverAppBar(heroHeight),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(10),   // Gần như trong suốt hoàn toàn ở trên cùng
                        Colors.black.withAlpha(40),   // Rất nhạt
                        Colors.black.withAlpha(100),  // Mờ nhẹ ở đoạn Chip
                        _kBg.withAlpha(180),          // Điểm kết thúc chuyển mờ
                        _kBg,                         // Đen đặc để khớp dưới
                      ],
                      stops: const [0.0, 0.3, 0.7, 0.9, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              widget.plan.name,
                              style: GoogleFonts.inter(fontSize: 23, fontWeight: FontWeight.w700, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_outline, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Text('My Workout', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
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
                        ],
                      ),
                    ),
                  ),
              SliverToBoxAdapter(
                child: Container(
                  color: _kBg,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildApplyButton(),
                      if (widget.plan.isActive) ...[
                        const SizedBox(height: 12),
                        _buildPlanCompletionSummary(),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(Icons.bookmark_border, 'Save', () {}),
                          _buildActionButton(_isFavorite ? Icons.favorite : Icons.favorite_border, 'Like', _isFavoriteLoading ? null : _toggleFavorite, color: _isFavorite ? _kAccent : _kTextGrey),
                          _buildActionButton(Icons.ios_share, 'Share', () {}),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (widget.plan.description.isNotEmpty) ...[
                        _buildOverview(),
                        const SizedBox(height: 32),
                      ],
                      _buildWeeklySchedule(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
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
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: _kTextGrey)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(double heroHeight) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: heroHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.black.withAlpha(120), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onSelected: (value) async {
              if (value == 'edit') {
                final saved = await context.push<bool>(AppRouter.planDetail, extra: widget.plan);
                if (mounted && saved == true) context.pop(true);
              } else if (value == 'delete') {
                _deletePlan();
              }
            },
            color: _kCardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa', style: GoogleFonts.inter(color: Colors.white))),
              PopupMenuItem(value: 'delete', child: Text('Xóa', style: GoogleFonts.inter(color: Colors.redAccent))),
            ],
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
          final fullyHiddenOffset = heroHeight - collapsedHeight + 120;
          final startFadeOffset = fullyHiddenOffset - 40;
          final opacity = ((offset - startFadeOffset) / (fullyHiddenOffset - startFadeOffset)).clamp(0.0, 1.0);
          if (opacity == 0.0) return const SizedBox.shrink();
          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
        child: Text(widget.plan.name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        stretchModes: const [StretchMode.zoomBackground],
        background: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            double opacity = 0.0;
            if (_scrollController.hasClients) {
              final offset = _scrollController.offset;
              final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
              final threshold = heroHeight - collapsedHeight;
              if (offset > threshold - 20) {
                opacity = ((offset - (threshold - 20)) / 20).clamp(0.0, 1.0);
              }
            }
            return Container(color: _kBg.withOpacity(opacity * 0.5));
          },
        ),
      ),
    );
  }

  Widget _buildApplyButton() {
    final bool isActive = widget.plan.isActive;
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? Colors.transparent : _kAccent,
        borderRadius: BorderRadius.circular(24),
        border: isActive ? Border.all(color: _kAccent, width: 2) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: isActive ? null : _activatePlan,
          child: Center(
            child: _isActivating
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? Icons.check_circle_rounded : Icons.play_circle_filled_rounded,
                        color: isActive ? _kAccent : Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Currently Active' : 'Apply This Plan',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: isActive ? _kAccent : Colors.black),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final desc = widget.plan.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 12),
        Text(
          desc,
          style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: Colors.white70),
          maxLines: _isOverviewExpanded ? null : 3,
          overflow: _isOverviewExpanded ? null : TextOverflow.ellipsis,
        ),
        if (desc.length > 100) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _isOverviewExpanded = !_isOverviewExpanded),
            child: Text(
              _isOverviewExpanded ? 'Thu gọn' : 'Xem thêm',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _kReadMore),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanCompletionSummary() {
    return FutureBuilder<List<WorkoutHistoryModel>>(
      future: _historiesFuture,
      builder: (context, snapshot) {
        final histories = snapshot.data ?? const <WorkoutHistoryModel>[];
        final planHistories = histories.where((h) => h.planId == widget.plan.planId).toList();

        final now = DateTime.now();
        final startDate = DateTime(
          widget.plan.createdAt.year,
          widget.plan.createdAt.month,
          widget.plan.createdAt.day,
        );
        final totalPlanDays = widget.plan.totalWeeks * 7;
        final elapsedDays = totalPlanDays <= 0
            ? 0
            : (now.difference(startDate).inDays + 1).clamp(0, totalPlanDays);
        final planProgress = totalPlanDays > 0 ? elapsedDays / totalPlanDays : 0.0;
        final planProgressPercent = (planProgress * 100).round();
        final remainingDays = (totalPlanDays - elapsedDays).clamp(0, totalPlanDays);

        int scheduledUntilNow = 0;
        if (totalPlanDays > 0) {
          for (int i = 0; i < elapsedDays; i++) {
            final day = startDate.add(Duration(days: i));
            if (widget.plan.trainingDays.contains(day.weekday)) {
              scheduledUntilNow++;
            }
          }
        }

        final totalSessions = widget.plan.totalWeeks * widget.plan.sessionsPerWeek;
        final completed = planHistories.length;
        final completedPast = planHistories.where((h) {
          final date = DateTime(h.date.year, h.date.month, h.date.day);
          return !date.isAfter(now);
        }).length;

        final completedCapped = totalSessions > 0 && completed > totalSessions ? totalSessions : completed;
        final skipped = (scheduledUntilNow - completedPast).clamp(0, totalSessions);
        final upcoming = (totalSessions - completedCapped - skipped).clamp(0, totalSessions);
        final completionRate = totalSessions > 0 ? completedCapped / totalSessions : 0.0;
        final completionPercent = (completionRate * 100).round();
        final adherence = (completedCapped + skipped) > 0
            ? (completedCapped / (completedCapped + skipped))
            : 0.0;
        final adherencePercent = (adherence * 100).round();

        final completedBar = totalSessions > 0 ? completedCapped / totalSessions : 0.0;
        final skippedBar = totalSessions > 0 ? skipped / totalSessions : 0.0;
        final upcomingBar = (1.0 - completedBar - skippedBar).clamp(0.0, 1.0);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Plan Progress: $planProgressPercent%',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (widget.plan.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Active',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      if (completedBar > 0)
                        Expanded(
                          flex: (completedBar * 1000).round(),
                          child: Container(color: _kAccent),
                        ),
                      if (skippedBar > 0)
                        Expanded(
                          flex: (skippedBar * 1000).round(),
                          child: Container(color: const Color(0xFFFF3B30)),
                        ),
                      if (upcomingBar > 0)
                        Expanded(
                          flex: (upcomingBar * 1000).round(),
                          child: Container(color: Colors.white.withAlpha(50)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.circle, size: 10, color: _kAccent),
                  const SizedBox(width: 6),
                  Text(
                    'Done ($completedCapped)',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.circle, size: 10, color: Color(0xFFFF3B30)),
                  const SizedBox(width: 6),
                  Text(
                    'Skipped ($skipped)',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.circle, size: 10, color: Colors.white54),
                  const SizedBox(width: 6),
                  Text(
                    'Upcoming ($upcoming)',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    '$completionPercent% Complete',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$remainingDays days remaining',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildProgressStatCard(
                      icon: Icons.check_circle_rounded,
                      iconColor: _kAccent,
                      value: '$completedCapped',
                      label: 'Completed',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildProgressStatCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF9F1A),
                      value: '$adherencePercent%',
                      label: 'Adherence',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildProgressStatCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFFF3B30),
                      value: '$skipped',
                      label: 'Skipped',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    final workoutDaysCount = _schedule.where((day) => day.hasWorkout).length;
    final pageHeight = (120.0 + (workoutDaysCount * 95.0)).clamp(180.0, 650.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('In This Plan', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentWeek > 1) {
                      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: Icon(Icons.chevron_left, color: _currentWeek > 1 ? _kAccent : Colors.grey.shade700, size: 20),
                ),
                const SizedBox(width: 8),
                Text('Week $_currentWeek / $_totalWeeks', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_currentWeek < _totalWeeks) {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  child: Icon(Icons.chevron_right, color: _currentWeek < _totalWeeks ? _kAccent : Colors.grey.shade700, size: 20),
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
            onPageChanged: (index) => setState(() => _currentWeek = index + 1),
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Transform.rotate(
                          angle: pi / 4,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(6)),
                            child: Transform.rotate(
                              angle: -pi / 4,
                              child: Center(
                                child: Text('$weekNumber', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('Week $weekNumber', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        const Spacer(),
                        Row(
                          children: List.generate(7, (dotIndex) {
                            final isWorkout = dotIndex < _schedule.length ? _schedule[dotIndex].hasWorkout : false;
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: isWorkout ? _kAccent : Colors.grey.shade700),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(children: _schedule.where((day) => day.hasWorkout).map((day) => _buildDayRow(day)).toList()),
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
          SizedBox(width: 30, child: Text(day.day, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade400), textAlign: TextAlign.left)),
          const SizedBox(width: 8),
          Expanded(child: _buildWorkoutCard(day.workout, day.routine)),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(String title, RoutineModel? routine) {
    return GestureDetector(
      onTap: () {
        if (routine != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SystemPlanningExercisesScreen(plan: widget.plan, routine: routine)));
        }
      },
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            _buildPlanThumbnail(60),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanThumbnail(double size) {
    if (widget.plan.imageUrl.isNotEmpty) {
      if (widget.plan.imageUrl.startsWith('assets/')) {
        return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(widget.plan.imageUrl, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildThumbnailFallback(size)));
      }
      return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(widget.plan.imageUrl, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildThumbnailFallback(size)));
    }
    return _buildThumbnailFallback(size);
  }

  Widget _buildThumbnailFallback(double size) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: _kAccent.withAlpha(30), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.fitness_center_rounded, size: 22, color: _kAccent));
  }
}

class _DaySchedule {
  final String day;
  final String workout;
  final bool hasWorkout;
  final RoutineModel? routine;
  const _DaySchedule({required this.day, required this.workout, required this.hasWorkout, this.routine});
}

class _DarkMetaChip extends StatelessWidget {
  const _DarkMetaChip({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF2E2A12), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: GoogleFonts.inter(color: const Color(0xFFF4CB43), fontSize: 9, fontWeight: FontWeight.w400)),
    );
  }
}
