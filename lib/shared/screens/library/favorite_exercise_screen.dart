import 'package:flutter/material.dart';

import 'muscle_group_screen.dart';

class FavoriteExerciseScreen extends StatelessWidget {
  const FavoriteExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MuscleGroupScreen(
      groupName: 'Favorite Exercises',
      showAllExercises: true,
      favoritesOnly: true,
      screenTitle: 'Favorite Exercises',
    );
  }
}
