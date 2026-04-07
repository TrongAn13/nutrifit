import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/workout_history_model.dart';
import '../../data/models/routine_model.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/workout_repository.dart';
import '../../logic/active_workout_cubit.dart';
import 'workout_result_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kBg = Color(0xFF000000);
const Color _kLime = Color(0xFFD7FF1F);
const Color _kBarBg = Color(0xFF1C1C1E);
const Color _kCardBg = Color(0xFF2C2C2E);

/// Active workout session screen — single-exercise-at-a-time dark UI.
///
/// Displays exercise preparation, execution timer, and rest phases
/// in sequence, with a horizontal timeline strip at the bottom.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with WidgetsBindingObserver {
  
  /// Flat list of all sets and rests in order.
  List<_TimelineItem> _timelineItems = [];

  /// Current active item in the timeline list.
  int _activeTimelineIndex = 0;

  /// Phase for the current item.
  _ExercisePhase _phase = _ExercisePhase.prepare;

  /// Countdown timer for preparation phase (seconds).
  int _prepareSeconds = 10;
  Timer? _prepareTimer;

  /// Per-exercise elapsed timer (counts up during exercise execution).
  int _exerciseElapsed = 0;
  Timer? _exerciseTimer;

  /// Rest timer between exercises.
  int _restRemaining = 0;
  Timer? _restTimer;

  /// ScrollController for the timeline strip.
  final ScrollController _timelineScroll = ScrollController();

  /// The currently viewed (centered) item index. Updates during scroll.
  int _viewedTimelineIndex = 0;

  /// Whether to show the timeline strip.
  bool _showTimeline = true;

  /// Guard flag to prevent scroll listener from overriding index during programmatic scrolls.
  bool _isProgrammaticScroll = false;

  /// Whether the inline log panel is visible.
  bool _isLogPanelVisible = false;

  /// Exercise index currently shown in the inline log panel.
  int _logExerciseIndex = 0;

  @override
  void initState() {
    super.initState();
    _timelineScroll.addListener(_onTimelineScroll);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ActiveWorkoutCubit>();
      if (!cubit.state.isTimerRunning) {
        cubit.beginWorkout();
      }
      if (cubit.state.routine != null) {
        _timelineItems = _generateTimelineItems(cubit.state.routine!.exercises, cubit.state.setsData);

        // Restore from minimized state if applicable
        final wasMinimized = cubit.state.minimizedTimelineIndex > 0 ||
            cubit.state.minimizedPhaseIndex > 0;
        if (wasMinimized && _timelineItems.isNotEmpty) {
          final restoredIndex = cubit.state.minimizedTimelineIndex
              .clamp(0, _timelineItems.length - 1);
          _activeTimelineIndex = restoredIndex;
          _viewedTimelineIndex = restoredIndex;
          _restRemaining = cubit.state.minimizedRestRemaining;
          _prepareSeconds = cubit.state.minimizedPrepareSeconds;
          _exerciseElapsed = cubit.state.minimizedExerciseElapsed;

          // Restore phase
          switch (cubit.state.minimizedPhaseIndex) {
            case 0:
              _phase = _ExercisePhase.prepare;
              _startPreparePhase();
              break;
            case 1:
              _phase = _ExercisePhase.exercise;
              _startExercisePhase();
              break;
            case 2:
              _phase = _ExercisePhase.rest;
              _startRestPhase(_restRemaining);
              break;
          }
          _scrollTimeline();
        } else if (_timelineItems.isNotEmpty) {
          _startTimelineItem(0);
        }
      }
    });
  }

  void _onTimelineScroll() {
    if (!_timelineScroll.hasClients || _timelineItems.isEmpty) return;
    // Skip index updates during programmatic scroll (tap-to-view or return-to-now)
    if (_isProgrammaticScroll) return;

    int index = (_timelineScroll.offset / 72.0).round();
    if (index < 0) index = 0;
    if (index >= _timelineItems.length) index = _timelineItems.length - 1;
    if (_viewedTimelineIndex != index) {
      _viewedTimelineIndex = index;
      if (_isLogPanelVisible) {
        _logExerciseIndex = _timelineItems[index].exerciseIndex;
      }
      if (mounted) setState(() {});
    }
  }

  List<_TimelineItem> _generateTimelineItems(List<ExerciseEntry> exercises, Map<int, List<SetData>> setsData) {
    final List<_TimelineItem> items = [];
    int globalIndex = 0;
    for (int i = 0; i < exercises.length; i++) {
      final ex = exercises[i];
      final actualSets = setsData[i]?.length ?? ex.sets;
      for (int s = 0; s < actualSets; s++) {
        items.add(_TimelineItem(
          type: _TimelineType.exercise,
          index: globalIndex++,
          label: ex.exerciseName,
          restSeconds: ex.restTime,
          exerciseIndex: i,
          setIndex: s,
          exercise: ex,
        ));

        // Add rest if it's not the very last set of the workout
        bool isLastSetOfWorkout = (i == exercises.length - 1 && s == actualSets - 1);
        if (!isLastSetOfWorkout) {
          items.add(_TimelineItem(
            type: _TimelineType.rest,
            index: globalIndex++,
            label: 'Rest ${_formatRestLabel(ex.restTime)}',
            restSeconds: ex.restTime,
            exerciseIndex: i,
            setIndex: s,
          ));
        }
      }
    }
    return items;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prepareTimer?.cancel();
    _exerciseTimer?.cancel();
    _restTimer?.cancel();
    _timelineScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (!mounted) return;
    final cubit = context.read<ActiveWorkoutCubit>();
    if (!cubit.state.isTimerRunning) return;
    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.inactive) {
      cubit.pauseWorkout();
    } else if (appState == AppLifecycleState.resumed) {
      cubit.resumeWorkout();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Phase management
  // ─────────────────────────────────────────────────────────────────────────

  void _startTimelineItem(int index) {
    if (index >= _timelineItems.length) {
      _finishWorkout();
      return;
    }
    setState(() {
      _activeTimelineIndex = index;
      _viewedTimelineIndex = index;
      if (_isLogPanelVisible) {
        _logExerciseIndex = _timelineItems[index].exerciseIndex;
      }
    });

    final item = _timelineItems[index];

    if (item.type == _TimelineType.rest) {
      _startRestPhase(item.restSeconds);
    } else {
      // Show prepare phase 10s only for the first set of the exercise
      if (item.setIndex == 0) {
        _startPreparePhase();
      } else {
        _startExercisePhase();
      }
    }
    _scrollTimeline();
  }

  /// Browse to a cell without changing the active exercise or timers.
  void _viewTimelineItem(int index) {
    if (index < 0 || index >= _timelineItems.length) return;
    setState(() {
      _viewedTimelineIndex = index;
      if (_isLogPanelVisible) {
        _logExerciseIndex = _timelineItems[index].exerciseIndex;
      }
    });
    _programmaticScrollTo(index);
  }

  /// Save local state to the cubit and pop the screen.
  /// The mini-player bar will be shown at the main navigation level.
  void _minimizeWorkout() {
    final cubit = context.read<ActiveWorkoutCubit>();

    // Map phase enum to int for storage
    final phaseIndex = switch (_phase) {
      _ExercisePhase.prepare => 0,
      _ExercisePhase.exercise => 1,
      _ExercisePhase.rest => 2,
    };

    // Also save the exercise index being viewed
    if (_timelineItems.isNotEmpty) {
      final exerciseIdx = _timelineItems[_activeTimelineIndex].exerciseIndex;
      cubit.goToExercise(exerciseIdx);
    }

    cubit.minimizeWorkout(
      phaseIndex: phaseIndex,
      timelineIndex: _activeTimelineIndex,
      restRemaining: _restRemaining,
      prepareSeconds: _prepareSeconds,
      exerciseElapsed: _exerciseElapsed,
    );

    // Cancel local timers — cubit keeps the workout timer running
    _prepareTimer?.cancel();
    _exerciseTimer?.cancel();
    _restTimer?.cancel();

    Navigator.of(context).pop();
  }

  void _toggleLogPanel() {
    if (_timelineItems.isEmpty) return;
    setState(() {
      if (_isLogPanelVisible) {
        _isLogPanelVisible = false;
        return;
      }
      _logExerciseIndex = _timelineItems[_viewedTimelineIndex].exerciseIndex;
      _isLogPanelVisible = true;
    });
    FocusScope.of(context).unfocus();
  }

  void _completeSetFromLog(int exerciseIndex, int setIndex) {
    final cubit = context.read<ActiveWorkoutCubit>();
    final sets = cubit.state.setsData[exerciseIndex] ?? const <SetData>[];
    if (setIndex < 0 || setIndex >= sets.length || sets[setIndex].isCompleted) return;

    cubit.completeSet(exerciseIndex, setIndex);

    final itemIndex = _timelineItems.indexWhere(
      (item) =>
          item.type == _TimelineType.exercise &&
          item.exerciseIndex == exerciseIndex &&
          item.setIndex == setIndex,
    );
    if (itemIndex >= 0) {
      _startTimelineItem(itemIndex + 1);
    }
  }

  void _completeAllSetsFromLog(int exerciseIndex) {
    final cubit = context.read<ActiveWorkoutCubit>();
    cubit.completeAllSets(exerciseIndex);

    final lastExerciseItemIndex = _timelineItems.lastIndexWhere(
      (item) => item.type == _TimelineType.exercise && item.exerciseIndex == exerciseIndex,
    );
    if (lastExerciseItemIndex >= 0) {
      _startTimelineItem(lastExerciseItemIndex + 1);
    }
  }

  /// Scroll back to the currently active item and sync view.
  void _returnToNow() {
    setState(() {
      _viewedTimelineIndex = _activeTimelineIndex;
    });
    _scrollTimeline();
  }

  void _onActiveCellTapped() {
    if (_phase == _ExercisePhase.prepare) {
      _prepareTimer?.cancel();
      _startExercisePhase();
    } else if (_phase == _ExercisePhase.exercise) {
      _exerciseTimer?.cancel();
      final item = _timelineItems[_activeTimelineIndex];
      final cubit = context.read<ActiveWorkoutCubit>();
      final sets = cubit.state.setsData[item.exerciseIndex] ?? const <SetData>[];
      final isAlreadyCompleted =
          item.setIndex >= 0 && item.setIndex < sets.length && sets[item.setIndex].isCompleted;
      if (!isAlreadyCompleted) {
        cubit.completeSet(item.exerciseIndex, item.setIndex);
      }
      _startTimelineItem(_activeTimelineIndex + 1);
    } else if (_phase == _ExercisePhase.rest) {
      _restTimer?.cancel();
      _startTimelineItem(_activeTimelineIndex + 1);
    }
  }

  void _startPreparePhase() {
    _prepareTimer?.cancel();
    _exerciseTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _phase = _ExercisePhase.prepare;
      _prepareSeconds = 10;
      _exerciseElapsed = 0;
      _restRemaining = 0;
    });

    _prepareTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prepareSeconds <= 1) {
        timer.cancel();
        _startExercisePhase();
        return;
      }
      setState(() => _prepareSeconds--);
    });
  }

  void _startExercisePhase() {
    _prepareTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _phase = _ExercisePhase.exercise;
      _exerciseElapsed = 0;
    });

    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _exerciseElapsed++);
    });
  }

  void _startRestPhase(int duration) {
    _prepareTimer?.cancel();
    _exerciseTimer?.cancel();
    setState(() {
      _phase = _ExercisePhase.rest;
      _restRemaining = duration;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining <= 1) {
        timer.cancel();
        _startTimelineItem(_activeTimelineIndex + 1);
        return;
      }
      setState(() => _restRemaining--);
    });
  }

  void _scrollTimeline() {
    _scrollToItem(_activeTimelineIndex);
  }

  void _scrollToItem(int index) {
    if (_timelineScroll.hasClients) {
      final offset = index * 72.0;
      _timelineScroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Scrolls to [index] instantly, preventing _onTimelineScroll from overriding _viewedTimelineIndex.
  void _programmaticScrollTo(int index) {
    if (!_timelineScroll.hasClients) return;
    _isProgrammaticScroll = true;
    final offset = index * 72.0;
    _timelineScroll.jumpTo(offset);
    // Reset flag on next frame after jumpTo completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isProgrammaticScroll = false;
    });
  }

  void _finishWorkout() {
    _prepareTimer?.cancel();
    _exerciseTimer?.cancel();
    _restTimer?.cancel();
    _showFinishDialog(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dialog & navigation
  // ─────────────────────────────────────────────────────────────────────────

  String _formattedTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$mStr:$sStr';
    }
    return '0:$mStr:$sStr';
  }

  void _showFinishDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoTheme(
        data: const CupertinoThemeData(brightness: Brightness.dark),
        child: CupertinoAlertDialog(
          title: Text(
            'Incomplete Sets',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 17),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Incomplete sets will be removed if you finish the workout. Do you want to continue?',
              style: GoogleFonts.inter(height: 1.3, color: Colors.white, fontSize: 14),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Resume',
                style: GoogleFonts.inter(color: _kLime, fontSize: 17, fontWeight: FontWeight.normal),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await _saveAndNavigateToResults();
              },
              child: Text(
                'Finish',
                style: GoogleFonts.inter(color: _kLime, fontSize: 17, fontWeight: FontWeight.normal),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                _showDiscardWarning(context);
              },
              child: Text(
                'Discard',
                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 17, fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscardWarning(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kBg,
        title: Text(
          'Discard Workout?',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'All your workout data for this session will be lost. Are you sure?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // close dialog
              context.read<ActiveWorkoutCubit>().quitWorkout();
              Navigator.of(context).pop(); // exit workout screen
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Discard', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndNavigateToResults() async {
    final cubit = context.read<ActiveWorkoutCubit>();
    final state = cubit.state;

    final duration = state.workoutElapsedSeconds;
    final restTime = state.totalRestSeconds;
    final calories = (duration / 60 * 5).round();

    int totalReps = 0;
    double totalWeight = 0;
    int completedSetsCount = 0;
    int totalSetsCount = 0;

    for (final entry in state.setsData.entries) {
      final sets = entry.value;
      totalSetsCount += sets.length;
      for (final s in sets) {
        if (s.isCompleted) {
          completedSetsCount++;
          totalReps += s.reps;
          totalWeight += s.weight * s.reps;
        }
      }
    }

    final completionPercentage = totalSetsCount > 0
        ? (completedSetsCount / totalSetsCount) * 100
        : 0.0;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final historyId = DateTime.now().millisecondsSinceEpoch.toString();

    final List<ExerciseEntry> performedExercises = [];
    final routineExercises = state.routine?.exercises ?? const <ExerciseEntry>[];
    for (int i = 0; i < routineExercises.length; i++) {
      final original = routineExercises[i];
      final sets = state.setsData[i] ?? const <SetData>[];
      final completedSets = sets.where((s) => s.isCompleted).toList();
      if (completedSets.isEmpty) continue;

      final int completedCount = completedSets.length;
      final int repsSum = completedSets.fold(0, (sum, s) => sum + s.reps);
      final double weightSum = completedSets.fold(0.0, (sum, s) => sum + s.weight);
      final int avgReps = (repsSum / completedCount).round();
      final double avgWeight = weightSum / completedCount;

      performedExercises.add(
        original.copyWith(
          sets: completedCount,
          reps: avgReps > 0 ? avgReps : original.reps,
          weight: avgWeight > 0 ? avgWeight : original.weight,
        ),
      );
    }

    final history = WorkoutHistoryModel(
      id: historyId,
      userId: uid,
      planId: state.planId,
      routineName: state.routine?.name ?? 'Custom Workout',
      date: DateTime.now(),
      durationSeconds: duration,
      restTimeSeconds: restTime,
      caloriesBurned: calories,
      completionPercentage: completionPercentage,
      totalWeightLifted: totalWeight,
      totalReps: totalReps,
      exercises: performedExercises,
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _kLime)),
    );

    try {
      await WorkoutRepository().saveWorkoutHistory(history);
    } catch (e) {
      // Ignore failure
    }

    if (context.mounted) {
      Navigator.of(context).pop(); // Dismiss loading

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutResultScreen(
            history: history,
            onClose: () {},
          ),
        ),
      );
      cubit.quitWorkout();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveWorkoutCubit, ActiveWorkoutState>(
      builder: (context, state) {
        if (!state.isWorkoutActive) {
          return const Scaffold(
            backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kLime)),
          );
        }

        // Rebuild timeline to sync with any changes from Log Exercise safely
        if (state.routine != null) {
          _timelineItems = _generateTimelineItems(state.routine!.exercises, state.setsData);
        }

        // Keep indices valid after timeline length changes (for example after Log Exercise edits).
        if (_timelineItems.isNotEmpty) {
          if (_activeTimelineIndex >= _timelineItems.length) {
            _activeTimelineIndex = _timelineItems.length - 1;
          }
          if (_viewedTimelineIndex >= _timelineItems.length) {
            _viewedTimelineIndex = _timelineItems.length - 1;
          }
        }
        
        if (_timelineItems.isEmpty || _activeTimelineIndex >= _timelineItems.length) {
           return const Scaffold(backgroundColor: _kBg);
        }

        if (_viewedTimelineIndex >= _timelineItems.length) {
          _viewedTimelineIndex = _timelineItems.length - 1;
        }
        if (_viewedTimelineIndex < 0) _viewedTimelineIndex = 0;
        final viewedItem = _timelineItems[_viewedTimelineIndex];

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Top Bar ──
                _buildTopBar(viewedItem, state),
                // ── Main Content ──
                Expanded(
                  key: ValueKey('main_content_$_viewedTimelineIndex'),
                  child: _buildMainContent(viewedItem),
                ),
                // ── Timeline Strip ──
                Visibility(
                  visible: _showTimeline,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  child: _buildTimelineStrip(),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _isLogPanelVisible
                      ? _buildInlineLogPanel(context.read<ActiveWorkoutCubit>())
                      : const SizedBox.shrink(),
                ),
                // ── Bottom Control Bar ──
                _buildBottomBar(state),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Top Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTopBar(_TimelineItem currentItem, ActiveWorkoutState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Finish button
          GestureDetector(
            onTap: () => _showFinishDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: _kLime, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Finish',
                style: GoogleFonts.inter(
                  color: _kLime,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Exercise name
          Expanded(
            child: Text(
              currentItem.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Mute & minimize icons
          GestureDetector(
            onTap: () {},
            child: Icon(Icons.volume_off_rounded, color: Colors.white.withValues(alpha: 0.7), size: 24),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _minimizeWorkout,
            child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white.withValues(alpha: 0.7), size: 28),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Main Content — different for each phase
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMainContent(_TimelineItem viewedItem) {
    final bool isViewingActive = _viewedTimelineIndex == _activeTimelineIndex;

    // If viewing the active item, show phase-aware content
    if (isViewingActive) {
      if (viewedItem.type == _TimelineType.rest) {
        return _buildRestContent();
      }
      final exercise = viewedItem.exercise!;
      switch (_phase) {
        case _ExercisePhase.prepare:
          return _buildPrepareContent(exercise, viewedItem);
        case _ExercisePhase.exercise:
          return _buildExerciseContent(exercise, viewedItem);
        case _ExercisePhase.rest:
          return _buildRestContent();
      }
    }

    // Browsing a different item — show a static preview
    if (viewedItem.type == _TimelineType.rest) {
      return _buildRestPreview(viewedItem);
    }
    return _buildExercisePreview(viewedItem);
  }

  /// Static preview when browsing a non-active exercise cell.
  Widget _buildExercisePreview(_TimelineItem item) {
    final exercise = item.exercise!;
    final bool isPast = item.index < _activeTimelineIndex;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPast)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _kLime.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Completed', style: GoogleFonts.inter(color: _kLime, fontSize: 12, fontWeight: FontWeight.w600)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Upcoming', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 16),
            Text(
              exercise.exerciseName,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set ${item.setIndex + 1} of ${exercise.sets} × ${exercise.reps} reps',
              style: GoogleFonts.inter(color: Colors.black, fontSize: 16),
            ),
            if (exercise.weight != null) ...[
              const SizedBox(height: 4),
              Text(
                '${exercise.weight!.toStringAsFixed(1)} kg',
                style: GoogleFonts.inter(color: Colors.black, fontSize: 14),
              ),
            ],
            const SizedBox(height: 32),
            Container(
              
              width: 200, height: 200,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Icon(Icons.fitness_center_rounded, size: 80, color: Colors.white.withValues(alpha: 0.15))),
            ),
          ],
        ),
      ),
    );
  }

  /// Static preview when browsing a non-active rest cell.
  Widget _buildRestPreview(_TimelineItem item) {
    final bool isPast = item.index < _activeTimelineIndex;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPast ? Icons.check_circle_rounded : Icons.hourglass_empty_rounded,
            color: isPast ? _kLime : Colors.white30,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isPast ? 'Rest completed' : 'Rest',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _formatRestLabel(item.restSeconds),
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepareContent(ExerciseEntry exercise, _TimelineItem item) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Prepare',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise.exerciseName,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Exercise placeholder image
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Next: ${exercise.reps} reps • Set ${item.setIndex + 1}/${exercise.sets}',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            // Large countdown timer is removed to favor timeline interaction
            Text(
              '$_prepareSeconds s',
              style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseContent(ExerciseEntry exercise, _TimelineItem item) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              exercise.exerciseName,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Set ${item.setIndex + 1} of ${exercise.sets} × ${exercise.reps} reps',
              style: GoogleFonts.inter(
                color: _kLime,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (exercise.weight != null) ...[
              const SizedBox(height: 4),
              Text(
                '${exercise.weight!.toStringAsFixed(1)} kg',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Exercise image placeholder
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 90,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestContent() {
    _TimelineItem? nextExerciseItem;
    for (int i = _activeTimelineIndex + 1; i < _timelineItems.length; i++) {
        if (_timelineItems[i].type == _TimelineType.exercise) {
            nextExerciseItem = _timelineItems[i];
            break;
        }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rest',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 40),
            // Large countdown removed favoring timeline interaction
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formattedRestTime(_restRemaining),
                  style: GoogleFonts.inter(
                    color: Colors.white30,
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 24),
                // Time adjustment buttons (+10 / -10)
                Container(
                  decoration: BoxDecoration(
                    color: _kLime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _restRemaining += 10;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Text(
                            '+10',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 2,
                        width: 60,
                        color: Colors.black,
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _restRemaining -= 10;
                            if (_restRemaining < 0) _restRemaining = 0;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Text(
                            '-10',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            if (nextExerciseItem != null && nextExerciseItem.exercise != null) ...[
              Text(
                'Up Next',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nextExerciseItem.exercise!.exerciseName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Set ${nextExerciseItem.setIndex + 1} × ${nextExerciseItem.exercise!.reps} reps',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formattedRestTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m > 0 ? '$m:' : ''}${s.toString().padLeft(m > 0 ? 2 : 1, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Timeline Strip — horizontal scrollable list of sets + rests
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTimelineStrip() {
    final bool isViewingActive = _viewedTimelineIndex == _activeTimelineIndex;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          // Action buttons always visible — Finish set / Skip rest / Ready
          if (_phase == _ExercisePhase.prepare)
            _buildSmallActionButton(
              label: 'Ready? (${_prepareSeconds}s)',
              icon: Icons.check_rounded,
              onTap: _onActiveCellTapped,
            )
          else if (_phase == _ExercisePhase.exercise)
            _buildSmallActionButton(
              label: 'Finish set',
              icon: Icons.check_rounded,
              onTap: _onActiveCellTapped,
            )
          else if (_phase == _ExercisePhase.rest)
            _buildSmallActionButton(
              label: 'Skip rest',
              icon: Icons.skip_next_rounded,
              onTap: _onActiveCellTapped,
            ),

          const SizedBox(height: 12),

          // Scrollable timeline with optional NOW indicator
          SizedBox(
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ListView.separated(
                  key: const PageStorageKey('active_workout_timeline'),
                  controller: _timelineScroll,
                  scrollDirection: Axis.horizontal,
                  physics: const TimelineScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 2 - 32,
                  ),
                  itemCount: _timelineItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final item = _timelineItems[index];
                    if (item.type == _TimelineType.rest) {
                      return _buildRestCell(item);
                    }
                    return _buildExerciseCell(item);
                  },
                ),
                // Fixed white overlay box
                IgnorePointer(
                  child: Container(
                    width: 64,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // "NOW" pill — only visible when scrolled away from active
                if (!isViewingActive)
                  Positioned(
                    right: 8,
                    child: GestureDetector(
                      onTap: _returnToNow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kLime,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _kLime.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              'NOW',
                              style: GoogleFonts.inter(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _kLime.withValues(alpha: 0.15),
          border: Border.all(color: _kLime, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                color: _kLime,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, color: _kLime, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCell(_TimelineItem item) {
    final isCurrent = item.index == _activeTimelineIndex;
    final isPast = item.index < _activeTimelineIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _viewTimelineItem(item.index),
      child: Container(
        width: 64,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isPast 
           ? _kLime.withValues(alpha: 0.15) 
           : (isCurrent ? _kLime.withValues(alpha: 0.1) : _kCardBg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isPast)
             const Icon(Icons.check_circle_rounded, color: _kLime, size: 24)
          else if (isCurrent && _phase == _ExercisePhase.prepare)
             Text(
               '${_prepareSeconds}s',
               style: GoogleFonts.inter(
                 color: _kLime,
                 fontSize: 14,
                 fontWeight: FontWeight.w700,
               ),
             )
          else if (isCurrent && _phase == _ExercisePhase.exercise)
             Text(
               _formattedRestTime(_exerciseElapsed),
               style: GoogleFonts.inter(
                 color: _kLime,
                 fontSize: 14,
                 fontWeight: FontWeight.w700,
               ),
             )
          else
             // Future item or background item
             Column(
               children: [
                 const Icon(Icons.fitness_center_rounded, color: Colors.white54, size: 20),
                 const SizedBox(height: 2),
                 Text(
                   'S${item.setIndex + 1}',
                   style: GoogleFonts.inter(
                     color: Colors.white54,
                     fontSize: 10,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ],
             ),
        ],
      ),
      ),
    );
  }

  Widget _buildRestCell(_TimelineItem item) {
    final isCurrentRest = item.index == _activeTimelineIndex && _phase == _ExercisePhase.rest;
    final isPast = item.index < _activeTimelineIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _viewTimelineItem(item.index),
      child: Container(
        width: 64,
      height: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isPast 
           ? Colors.white.withValues(alpha: 0.05) 
           : (isCurrentRest ? _kLime.withValues(alpha: 0.1) : Colors.transparent),
      ),
      child: Center(
        child: Text(
          isCurrentRest ? _formattedRestTime(_restRemaining) : item.label,
          style: GoogleFonts.inter(
            color: isCurrentRest ? _kLime : (isPast ? Colors.white30 : Colors.white38),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
      ),
    );
  }

  String _formatRestLabel(int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return s > 0 ? '${m}m ${s}s' : '${m}m';
    }
    return '${seconds}s';
  }

  Widget _buildInlineLogPanel(ActiveWorkoutCubit cubit) {
    return Container(
      key: const ValueKey('inline_log_panel'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 60),
            child: Row(
              children: [
                SizedBox(
                  width: 38,
                  child: Text(
                    'SET',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Text(
                    'KG',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<ActiveWorkoutCubit, ActiveWorkoutState>(
            bloc: cubit,
            builder: (context, state) {
              final sets = state.setsData[_logExerciseIndex] ?? [];
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, setIndex) {
                  return _SetRowWidget(
                    exerciseIndex: _logExerciseIndex,
                    setIndex: setIndex,
                    setData: sets[setIndex],
                    cubit: cubit,
                    onComplete: () => _completeSetFromLog(_logExerciseIndex, setIndex),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => cubit.addSet(_logExerciseIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+ Add new set',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _completeAllSetsFromLog(_logExerciseIndex),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.playlist_add_check_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Finish all sets',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Control Bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(ActiveWorkoutState state) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12, 12, 12,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: _kBarBg,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left portion: Visibility Toggle + Timer
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _BottomBarIcon(
                  icon: _showTimeline ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                  onTap: () {
                    setState(() {
                      _showTimeline = !_showTimeline;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formattedTime(state.workoutElapsedSeconds),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Center portion: Play/Pause
          Container(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {
                final cubit = context.read<ActiveWorkoutCubit>();
                if (_phase == _ExercisePhase.exercise) {
                  if (_exerciseTimer?.isActive == true) {
                    _exerciseTimer?.cancel();
                    cubit.pauseWorkout();
                  } else {
                    _exerciseTimer = Timer.periodic(
                      const Duration(seconds: 1),
                      (timer) => setState(() => _exerciseElapsed++),
                    );
                    cubit.resumeWorkout();
                  }
                  setState(() {});
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _exerciseTimer?.isActive == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Right portion: Log Exercise
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _toggleLogPanel,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isLogPanelVisible ? _kLime.withValues(alpha: 0.15) : _kCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: _isLogPanelVisible ? Border.all(color: _kLime, width: 1) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Log Exercise',
                        style: GoogleFonts.inter(
                          color: _isLogPanelVisible ? _kLime : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isLogPanelVisible
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                        color: _isLogPanelVisible ? _kLime : Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets & models
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBarIcon extends StatelessWidget {
  const _BottomBarIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

enum _ExercisePhase { prepare, exercise, rest }

enum _TimelineType { exercise, rest }

class _TimelineItem {
  final _TimelineType type;
  final int index;
  final String label;
  final int restSeconds;
  final int exerciseIndex;
  final int setIndex;
  final ExerciseEntry? exercise;

  const _TimelineItem({
    required this.type,
    required this.index,
    required this.label,
    required this.restSeconds,
    required this.exerciseIndex,
    required this.setIndex,
    this.exercise,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TimelineItem &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          index == other.index &&
          label == other.label &&
          restSeconds == other.restSeconds &&
          exerciseIndex == other.exerciseIndex &&
          setIndex == other.setIndex;

  @override
  int get hashCode => Object.hash(
        type,
        index,
        label,
        restSeconds,
        exerciseIndex,
        setIndex,
      );
}

class _SetRowWidget extends StatefulWidget {
  final int exerciseIndex;
  final int setIndex;
  final SetData setData;
  final ActiveWorkoutCubit cubit;
  final VoidCallback? onComplete;

  const _SetRowWidget({
    required this.exerciseIndex,
    required this.setIndex,
    required this.setData,
    required this.cubit,
    this.onComplete,
  });

  @override
  State<_SetRowWidget> createState() => _SetRowWidgetState();
}

class _SetRowWidgetState extends State<_SetRowWidget> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default weight is empty if 0, Reps is always set from data
    _weightCtrl = TextEditingController(text: widget.setData.weight > 0 ? widget.setData.weight.toStringAsFixed(1).replaceAll('.0', '') : '');
    _repsCtrl = TextEditingController(text: widget.setData.reps.toString());
    
    _weightCtrl.addListener(_onWeightChanged);
    _repsCtrl.addListener(_onChanged);
  }

  void _onWeightChanged() {
    if (_weightFocus.hasFocus) {
       final w = double.tryParse(_weightCtrl.text) ?? 0;
       widget.cubit.updateWeight(widget.exerciseIndex, widget.setIndex, w);
    }
  }

  void _onChanged() {
    if (_repsFocus.hasFocus) {
       final r = int.tryParse(_repsCtrl.text) ?? 0;
       widget.cubit.updateReps(widget.exerciseIndex, widget.setIndex, r);
    }
  }

  @override
  void didUpdateWidget(_SetRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.setData.weight != widget.setData.weight && !_weightFocus.hasFocus) {
      _weightCtrl.text = widget.setData.weight > 0 ? widget.setData.weight.toStringAsFixed(1).replaceAll('.0', '') : '';
    }
    if (oldWidget.setData.reps != widget.setData.reps && !_repsFocus.hasFocus) {
      _repsCtrl.text = widget.setData.reps.toString();
    }
  }
  
  @override
  void dispose() {
    _weightCtrl.removeListener(_onWeightChanged);
    _repsCtrl.removeListener(_onChanged);
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setData.isCompleted;
    // High contrast theme: solid white inputs with black text
    final bgColor = Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Set number
        Container(
           width: 38,
           height: 44,
           decoration: BoxDecoration(
             border: Border.all(color: Colors.white54, width: 1),
             borderRadius: BorderRadius.circular(8),
             color: isCompleted ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
           ),
           alignment: Alignment.center,
           child: Text('${widget.setIndex + 1}', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
        ),
        const SizedBox(width: 12),
        // Weight
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                   children: [
                     Expanded(
                       child: TextField(
                         controller: _weightCtrl,
                         focusNode: _weightFocus,
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         textAlign: TextAlign.center,
                         style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700),
                         decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                       )
                     ),
                     Text('kg', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                   ]
                )
              ),
              const SizedBox(height: 4),
              Text('include bar', style: GoogleFonts.inter(color: Colors.white30, fontSize: 10)),
            ]
          ),
        ),
        const SizedBox(width: 8),
        // Reps
        Expanded(
          flex: 3,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: _repsCtrl,
                     focusNode: _repsFocus,
                     keyboardType: TextInputType.number,
                     textAlign: TextAlign.center,
                     style: GoogleFonts.inter(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700),
                     decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                   )
                 ),
                 Text('reps', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
               ]
            )
          ),
        ),
        const SizedBox(width: 16),
        // Check button
        GestureDetector(
          onTap: () {
             if (isCompleted) return;
             if (widget.onComplete != null) {
               widget.onComplete!.call();
             } else {
               widget.cubit.completeSet(widget.exerciseIndex, widget.setIndex);
             }
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? const Color(0xFFD7FF1F) : Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: isCompleted ? const Color(0xFFD7FF1F) : Colors.transparent, width: 1.5),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 24,
              color: isCompleted ? Colors.black : Colors.white38,
            ),
          )
        )
      ]
    );
  }
}

class TimelineScrollPhysics extends ScrollPhysics {
  const TimelineScrollPhysics({super.parent});

  @override
  TimelineScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TimelineScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Simulation? simulation = super.createBallisticSimulation(position, velocity);
    
    // Defer to parent for overscroll bouncing
    if (simulation != null && (position.pixels < position.minScrollExtent || position.pixels > position.maxScrollExtent)) {
      return simulation;
    }

    double targetOffset;
    if (velocity.abs() > 300.0) {
      final direction = velocity.sign;
      targetOffset = ((position.pixels / 72.0).round() + direction) * 72.0;
    } else {
      targetOffset = (position.pixels / 72.0).round() * 72.0;
    }

    if (targetOffset < position.minScrollExtent) targetOffset = position.minScrollExtent;
    if (targetOffset > position.maxScrollExtent) targetOffset = position.maxScrollExtent;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetOffset,
      velocity,
      tolerance: tolerance,
    );
  }
}

