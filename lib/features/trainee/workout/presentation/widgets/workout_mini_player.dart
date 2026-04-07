import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../logic/active_workout_cubit.dart';
import '../screens/active_workout_screen.dart';

/// Compact mini-player bar shown at the bottom of the main navigation
/// when the user minimizes an active workout session.
///
/// Shows the current exercise name, set indicators, elapsed time,
/// a pause/play button, and a close button. Tapping anywhere on the
/// bar navigates back to the full [ActiveWorkoutScreen].
class WorkoutMiniPlayer extends StatelessWidget {
  const WorkoutMiniPlayer({super.key});

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveWorkoutCubit, ActiveWorkoutState>(
      builder: (context, state) {
        // Only show when workout is active AND minimized
        if (!state.isWorkoutActive || !state.isMinimized) {
          return const SizedBox.shrink();
        }

        final routine = state.routine!;
        final exercises = routine.exercises;

        // Determine current exercise from saved timeline index
        final exerciseIndex = state.currentExerciseIndex.clamp(0, exercises.length - 1);
        final currentExercise = exercises[exerciseIndex];
        final sets = state.setsData[exerciseIndex] ?? [];

        return GestureDetector(
          onTap: () {
            // Restore and navigate to full screen
            context.read<ActiveWorkoutCubit>().restoreWorkout();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ActiveWorkoutScreen(),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Exercise name + set indicators
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentExercise.exerciseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Set indicator circles
                      Row(
                        children: List.generate(sets.length, (i) {
                          final isCompleted = sets[i].isCompleted;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: isCompleted
                                ? Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD7FF1F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.black,
                                      size: 14,
                                    ),
                                  )
                                : Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${i + 1}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Elapsed time chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatElapsed(state.workoutElapsedSeconds),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Pause / resume button
                GestureDetector(
                  onTap: () {
                    final cubit = context.read<ActiveWorkoutCubit>();
                    if (state.isTimerRunning) {
                      cubit.pauseWorkout();
                    } else {
                      cubit.resumeWorkout();
                    }
                  },
                  child: Icon(
                    state.isTimerRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 8),

                // Close (quit) button
                GestureDetector(
                  onTap: () {
                    context.read<ActiveWorkoutCubit>().quitWorkout();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
