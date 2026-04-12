import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/routine_model.dart';
import '../../logic/active_workout_cubit.dart';
import 'active_workout_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF000000);
const Color _kLime = Color(0xFFD7FF1F);

/// Phases of the Ready-Countdown flow.
enum _Phase { ready, countdown, done }

/// A full-screen Ready → 3-2-1 Countdown → Navigate to Active Workout screen.
///
/// The screen must be pushed with a [RoutineModel] and optional [planId].
/// It will automatically navigate to [ActiveWorkoutScreen] when the
/// countdown finishes and load the routine into [ActiveWorkoutCubit].
class WorkoutReadyScreen extends StatefulWidget {
  const WorkoutReadyScreen({
    super.key,
    required this.routine,
    this.planId,
  });

  final RoutineModel routine;
  final String? planId;

  @override
  State<WorkoutReadyScreen> createState() => _WorkoutReadyScreenState();
}

class _WorkoutReadyScreenState extends State<WorkoutReadyScreen>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.ready;

  /// Ready phase: circular progress fills over 2 seconds.
  late AnimationController _circleController;
  late Animation<double> _circleProgress;

  /// Countdown phase: 3, 2, 1
  int _countdownValue = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), 
    );
    _circleProgress = _circleController; 

    _startCountdown();
  }

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _countdownValue = 3;
    });

    _circleController.animateTo(0.33, curve: Curves.fastOutSlowIn);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue <= 1) {
        timer.cancel();
        _onCountdownFinished();
        return;
      }

      setState(() {
        _countdownValue--;
      });

      final target = (4 - _countdownValue) / 3.0;
      _circleController.animateTo(target.clamp(0.0, 1.0), curve: Curves.fastOutSlowIn);
    });
  }

  void _onCountdownFinished() {
    _circleController.value = 1.0;
    setState(() => _phase = _Phase.done);

    final cubit = context.read<ActiveWorkoutCubit>();
    cubit.loadRoutine(widget.routine, planId: widget.planId);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ActiveWorkoutScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Center content
            Expanded(
              flex: 2,
              child: Center(
                child: _buildCenterContent(),
              ),
            ),
            const Spacer(),
            // Health disclaimer
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 48),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white.withValues(alpha: 0.4),
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please consult a health professional before starting any '
                    'workout, especially if you have any medical conditions '
                    'or injuries',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _phase == _Phase.done
          ? Text(
              'GO!',
              key: const ValueKey('go'),
              style: GoogleFonts.inter(
                color: _kLime,
                fontSize: 84,
                fontWeight: FontWeight.w900,
              ),
            )
          : _AnimatedCircle(
              key: ValueKey(_countdownValue),
              progress: _circleProgress,
              child: Text(
                '$_countdownValue',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 84,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Circle — a custom-drawn arc that fills up
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedCircle extends StatelessWidget {
  const _AnimatedCircle({
    super.key,
    required this.progress,
    required this.child,
  });

  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, innerChild) {
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring (dark)
              CustomPaint(
                size: const Size(200, 200),
                painter: _RingPainter(
                  progress: 1.0,
                  color: Colors.white.withValues(alpha: 0.08),
                  strokeWidth: 10,
                ),
              ),
              // Animated lime ring
              CustomPaint(
                size: const Size(200, 200),
                painter: _RingPainter(
                  progress: progress.value,
                  color: _kLime,
                  strokeWidth: 10,
                ),
              ),
              // Inner content (text)
              innerChild!,
            ],
          ),
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Ring Painter
// ─────────────────────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Start from the top (-π/2) and sweep clockwise.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
