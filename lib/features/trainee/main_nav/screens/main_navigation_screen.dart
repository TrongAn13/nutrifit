import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/services/notification_service.dart';
import '../../nutrition/data/repositories/nutrition_repository.dart';
import '../../nutrition/logic/nutrition_bloc.dart';
import '../../nutrition/logic/nutrition_event.dart';
import '../../nutrition/logic/water_cubit.dart';
import '../../nutrition/presentation/screens/nutrition_dashboard.dart';
import '../../dashboard/presentation/screens/trainee_dashboard_screen.dart';
import '../../../../shared/Screens/library/library_screen.dart';
import '../../profile/presentation/screens/settings_screen.dart';
import '../../workout/presentation/widgets/workout_mini_player.dart';
import '../logic/bottom_nav_cubit.dart';
import '../widgets/quick_action_bottom_sheet.dart';
/// Main shell screen with a 4-tab [BottomAppBar] and a center action button.
///
/// Tabs (left-to-right):
///   0 – Tập luyện (Workout)
///   1 – Dinh dưỡng (Nutrition)
///   (Center button – Quick Actions)
///   2 – Giáo án (Template plans)
///   3 – Cá nhân (Profile)
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  /// Ordered list of tab body pages (index 0–3).
  static List<Widget> buildPages() {
    return <Widget>[
      const TraineeDashboardScreen(),
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
      const CoachLibraryScreen(),
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
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = MainNavigationScreen.buildPages();
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
    return BlocBuilder<BottomNavCubit, int>(
      builder: (context, currentIndex) {
        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: IndexedStack(index: currentIndex, children: _pages),
              ),
              // Mini-player bar — visible when a workout is minimized
              const WorkoutMiniPlayer(),
            ],
          ),

          // ── BottomAppBar ──
          bottomNavigationBar: BottomAppBar(
            color: Colors.black,
            surfaceTintColor: Colors.black,
            shadowColor: Colors.transparent,
            elevation: 0,
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: PhosphorIcons.barbell(),
                  activeIcon: PhosphorIcons.barbell(PhosphorIconsStyle.fill),
                  label: 'Workout',
                  isSelected: currentIndex == 0,
                  onTap: () => context.read<BottomNavCubit>().selectTab(0),
                ),
                _NavItem(
                  icon: PhosphorIcons.appleLogo(),
                  activeIcon: PhosphorIcons.appleLogo(PhosphorIconsStyle.fill),
                  label: 'Nutrition',
                  isSelected: currentIndex == 1,
                  onTap: () => context.read<BottomNavCubit>().selectTab(1),
                ),
                _NavItem(
                  icon: PhosphorIcons.plusCircle(),
                  activeIcon: PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
                  label: 'Create',
                  isSelected: false,
                  onTap: () => _showQuickActions(context),
                ),
                _NavItem(
                  icon: PhosphorIcons.personSimpleRun(),
                  activeIcon: PhosphorIcons.personSimpleRun(PhosphorIconsStyle.fill),
                  label: 'Explore',
                  isSelected: currentIndex == 2,
                  onTap: () => context.read<BottomNavCubit>().selectTab(2),
                ),
                _NavItem(
                  icon: PhosphorIcons.user(),
                  activeIcon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                  label: 'Me',
                  isSelected: currentIndex == 3,
                  onTap: () => context.read<BottomNavCubit>().selectTab(3),
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

/// A single bottom-nav item with an icon and label, matching the dark UI.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colors matching the dark UI screenshot
    final color = isSelected ? Colors.white : const Color(0xFF6E6E73);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 25,
              color: color,
            ),
            const SizedBox(height: 1),
            Text( // Fixed missing ')' below by replacing the whole thing cleanly
              label,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
