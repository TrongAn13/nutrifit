import 'package:flutter/material.dart';

import '../../data/models/workout_history_model.dart';
import 'workout_result_screen.dart';

/// Dedicated screen for viewing a saved workout record from schedule/history.
class WorkoutRecordScreen extends StatelessWidget {
  final WorkoutHistoryModel history;

  const WorkoutRecordScreen({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    return WorkoutResultScreen(
      history: history,
      showSaveButton: false,
      showBackButton: true,
      topRightIcon: Icons.more_vert_rounded,
    );
  }
}
