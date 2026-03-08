import 'package:flutter_bloc/flutter_bloc.dart';

/// Manages the currently selected tab index for [MainNavigationScreen].
class BottomNavCubit extends Cubit<int> {
  BottomNavCubit() : super(0);

  /// Switch to a specific tab by [index].
  void selectTab(int index) {
    if (index != state) emit(index);
  }
}
