import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

/// Cubit that manages the app-wide [ThemeMode].
///
/// Emits a new [ThemeMode] whenever the trainee selects a different option
/// (light, dark, or system default).
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark);

  /// Switch to the given [mode].
  void setTheme(ThemeMode mode) => emit(mode);
}
