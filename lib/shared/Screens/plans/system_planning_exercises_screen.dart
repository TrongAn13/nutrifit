import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../features/trainee/workout/data/models/exercise_model.dart';
import '../../../features/trainee/workout/data/models/routine_model.dart';
import '../../../features/trainee/workout/data/models/workout_plan_model.dart';
import '../library/exercise_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF060708);
const Color _kCardBg = Color(0xFF1B1D22);
const Color _kAccent = Color(0xFFC6F432); // Lime green
const Color _kTextGrey = Color(0xFFA0A0A0);

class SystemPlanningExercisesScreen extends StatefulWidget {
  final WorkoutPlanModel plan;
  final RoutineModel routine;

  const SystemPlanningExercisesScreen({
    super.key,
    required this.plan,
    required this.routine,
  });

  @override
  State<SystemPlanningExercisesScreen> createState() => _SystemPlanningExercisesScreenState();
}

class _SystemPlanningExercisesScreenState extends State<SystemPlanningExercisesScreen> {
  bool _initializedScroll = false;
  late final ScrollController _scrollController;

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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildExercises(),
                  const SizedBox(height: 16),
                  _buildEquipments(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final screenHeight = MediaQuery.of(context).size.height;
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
      centerTitle: true,
      title: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          if (!_scrollController.hasClients) return const SizedBox.shrink();
          
          final offset = _scrollController.offset;
          final collapsedHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
          
          final fullyHiddenOffset = heroHeight - collapsedHeight + 90; 
          final startFadeOffset = fullyHiddenOffset - 40; 

          final opacity = ((offset - startFadeOffset) / (fullyHiddenOffset - startFadeOffset)).clamp(0.0, 1.0);

          if (opacity == 0.0) return const SizedBox.shrink();

          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
        child: Text(
          widget.routine.name,
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
            _buildHeroImageContent(heroHeight),
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
          color: Colors.white24,
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

  Widget _buildHeader() {
    return Column(
      children: [
        Center(
          child: Text(
            widget.plan.name,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            widget.routine.name, // Show routine name as subtitle instead
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kAccent,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildExercises() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'In this workout',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '${widget.routine.exercises.length} exercises',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _kTextGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.routine.exercises.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No exercises in this workout',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _kTextGrey,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.routine.exercises.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ex = widget.routine.exercises[index];
              return _buildExerciseCard(context, ex);
            },
          ),
      ],
    );
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseEntry ex) {
    return GestureDetector(
      onTap: () => _navigateToExerciseDetail(context, ex),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  color: _kAccent,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.exerciseName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${ex.sets} sets • ${ex.reps} reps${ex.restTime > 0 ? " • ${ex.restTime}s rest" : ""}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _kTextGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Info Icon
            GestureDetector(
              onTap: () => _navigateToExerciseDetail(context, ex),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    'i',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  void _navigateToExerciseDetail(BuildContext context, ExerciseEntry entry) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Find the exercise in Firestore by name
      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('name', isEqualTo: entry.exerciseName)
          .limit(1)
          .get();

      if (context.mounted) Navigator.pop(context); // Hide loading

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['exerciseId'] = snapshot.docs.first.id;
        final exercise = ExerciseModel.fromJson(data);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(
                exercise: exercise,
                groupName: exercise.bodyPart.isNotEmpty ? exercise.bodyPart : 'Exercise',
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exercise details not found in library')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildEquipments() {
    // For now, list mock equipments to simulate UI since ExerciseEntry doesn't have an itemized equipment field.
    final mockEquipments = [
      _EquipmentData(name: 'Barbell', icon: Icons.fitness_center_rounded),
      _EquipmentData(name: 'Dumbbell', icon: Icons.fitness_center),
      _EquipmentData(name: 'Cable Machine', icon: Icons.cable_rounded),
    ];

    if (widget.routine.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Equipments',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '${mockEquipments.length} selected',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: _kTextGrey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mockEquipments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final eq = mockEquipments[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      eq.icon,
                      size: 20,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      eq.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EquipmentData {
  final String name;
  final IconData icon;

  const _EquipmentData({required this.name, required this.icon});
}
