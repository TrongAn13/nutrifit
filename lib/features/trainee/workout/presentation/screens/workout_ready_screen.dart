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

    // Circular progress animation for the "Ready" phase (2 seconds).
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _circleProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    // Start the Ready animation immediately.
    _circleController.forward();
    _circleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _countdownValue = 3;
    });

    // Reset and reuse the circle controller for each countdown tick (1 second).
    _circleController.duration = const Duration(milliseconds: 1000);
    _circleController.reset();
    _circleController.forward();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue <= 1) {
        timer.cancel();
        _onCountdownFinished();
        return;
      }

      setState(() {
        _countdownValue--;
      });

      // Restart circle animation for next tick.
      _circleController.reset();
      _circleController.forward();
    });
  }

  void _onCountdownFinished() {
    setState(() => _phase = _Phase.done);

    // Load the routine into global cubit and navigate.
    final cubit = context.read<ActiveWorkoutCubit>();
    cubit.loadRoutine(widget.routine, planId: widget.planId);

    // Small delay so the user sees "GO" briefly.
    Future.delayed(const Duration(milliseconds: 300), () {
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
            // Close / skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Center content
            Expanded(
              child: Center(
                child: _buildCenterContent(),
              ),
            ),
            // Health disclaimer
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
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
    switch (_phase) {
      case _Phase.ready:
        return _AnimatedCircle(
          progress: _circleProgress,
          child: Text(
            'Ready',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      case _Phase.countdown:
        return _AnimatedCircle(
          progress: _circleProgress,
          child: Text(
            '$_countdownValue',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      case _Phase.done:
        return Text(
          'GO!',
          style: GoogleFonts.inter(
            color: _kLime,
            fontSize: 72,
            fontWeight: FontWeight.w900,
          ),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Circle — a custom-drawn arc that fills up
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedCircle extends StatelessWidget {
  const _AnimatedCircle({
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
