import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../nutrition/data/repositories/nutrition_repository.dart';
import '../../nutrition/logic/nutrition_bloc.dart';
import '../../nutrition/logic/nutrition_event.dart';
import '../../nutrition/logic/water_cubit.dart';
import '../../nutrition/presentation/screens/nutrition_dashboard.dart';
import '../../workout/data/repositories/workout_repository.dart';
import '../../workout/logic/workout_bloc.dart';
import '../../workout/logic/workout_event.dart';
import '../../workout/presentation/screens/workout_dashboard.dart';
import '../../plan/presentation/screens/plan_selection_screen.dart';
import '../../profile/presentation/screens/settings_screen.dart';
import '../logic/bottom_nav_cubit.dart';
import '../widgets/quick_action_bottom_sheet.dart';

/// Main shell screen with a 4-tab [BottomAppBar] and a center-docked FAB.
///
/// Tabs (left-to-right):
///   0 – Tập luyện (Workout)
///   1 – Dinh dưỡng (Nutrition)
///   (FAB – Quick Actions)
///   2 – Giáo án (Template plans)
///   3 – Cá nhân (Profile)
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  /// Ordered list of tab body pages (index 0-3).
  static List<Widget> buildPages() {
    return <Widget>[
      BlocProvider(
        create: (context) =>
            WorkoutBloc(workoutRepository: WorkoutRepository())
              ..add(const WorkoutLoadRequested()),
        child: const WorkoutDashboard(),
      ),
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                NutritionBloc(nutritionRepository: NutritionRepository())
                  ..add(NutritionLoadRequested(DateTime.now())),
          ),
          BlocProvider(
            create: (context) => WaterCubit()..load(),
          ),
        ],
        child: const NutritionDashboard(),
      ),
      BlocProvider(
        create: (context) =>
            WorkoutBloc(workoutRepository: WorkoutRepository())
              ..add(const WorkoutLoadRequested()),
        child: const PlanSelectionScreen(),
      ),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BottomNavCubit(),
      child: const _NavigationShell(),
    );
  }
}

/// Internal widget that rebuilds only when the tab index changes.
/// Requests notification permission on first build.
class _NavigationShell extends StatefulWidget {
  const _NavigationShell();

  @override
  State<_NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<_NavigationShell> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  /// Request notification permission on first login.
  Future<void> _requestNotificationPermission() async {
    try {
      await NotificationService().requestPermission();
    } catch (_) {
      // Silently ignore — permission handling is non-critical
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const QuickActionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    return BlocBuilder<BottomNavCubit, int>(
      builder: (context, currentIndex) {
        final pages = MainNavigationScreen.buildPages();
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: pages),

          // ── BottomAppBar ──
          bottomNavigationBar: BottomAppBar(
            color: isLight ? AppColors.lightSurface : AppColors.darkSurface,
            surfaceTintColor: Colors.transparent,
            shadowColor: isLight ? Colors.black12 : Colors.black45,
            elevation: 4,
            height: 68,
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                // ── Left side: Tab 0 + Tab 1 ──
                Expanded(
                  child: _NavItem(
                    icon: Icons.fitness_center_outlined,
                    selectedIcon: Icons.fitness_center_rounded,
                    label: 'Tập luyện',
                    isSelected: currentIndex == 0,
                    onTap: () => context.read<BottomNavCubit>().selectTab(0),
                    colorScheme: colorScheme,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.restaurant_outlined,
                    selectedIcon: Icons.restaurant_rounded,
                    label: 'Dinh dưỡng',
                    isSelected: currentIndex == 1,
                    onTap: () => context.read<BottomNavCubit>().selectTab(1),
                    colorScheme: colorScheme,
                  ),
                ),

                // ── Center Action Button ──
                Expanded(
                  child: InkWell(
                    onTap: () => _showQuickActions(context),
                    customBorder: const CircleBorder(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Right side: Tab 2 + Tab 3 ──
                Expanded(
                  child: _NavItem(
                    icon: Icons.assignment_outlined,
                    selectedIcon: Icons.assignment_rounded,
                    label: 'Giáo án',
                    isSelected: currentIndex == 2,
                    onTap: () => context.read<BottomNavCubit>().selectTab(2),
                    colorScheme: colorScheme,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_outlined,
                    selectedIcon: Icons.person_rounded,
                    label: 'Cá nhân',
                    isSelected: currentIndex == 3,
                    onTap: () => context.read<BottomNavCubit>().selectTab(3),
                    colorScheme: colorScheme,
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

// ═══════════════════════════════════════════════════════════════════════════════
// Navigation Item
// ═══════════════════════════════════════════════════════════════════════════════

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? selectedIcon : icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
