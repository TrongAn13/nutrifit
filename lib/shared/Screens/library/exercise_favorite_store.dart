import 'package:flutter/foundation.dart';

class ExerciseFavoriteStore {
  ExerciseFavoriteStore._();

  static final ValueNotifier<Set<String>> favorites =
      ValueNotifier<Set<String>>(<String>{});

  static bool isFavorite(String exerciseId) {
    return favorites.value.contains(exerciseId);
  }

  static void toggle(String exerciseId) {
    final next = Set<String>.from(favorites.value);
    if (next.contains(exerciseId)) {
      next.remove(exerciseId);
    } else {
      next.add(exerciseId);
    }
    favorites.value = next;
  }
}
