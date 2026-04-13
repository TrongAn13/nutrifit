import 'package:flutter/material.dart';

import '../main_nav/coach_action_menu.dart';
import '../presentation/screens/coach_client_list_screen.dart';
import '../presentation/screens/coach_dashboard_screen.dart';
import '../presentation/screens/coach_profile_screen.dart';
import '../../../shared/screens/library/library_screen.dart';

/// Main navigation shell for coach accounts.
///
/// Provides a [BottomAppBar] with 4 nav items and a center action button,
/// styled with a minimal dot-indicator design.
class CoachMainScreen extends StatefulWidget {
  const CoachMainScreen({super.key});

  @override
  State<CoachMainScreen> createState() => _CoachMainScreenState();
}

class _CoachMainScreenState extends State<CoachMainScreen> {
  int _currentIndex = 0;

  /// Gradient for the active nav item.
  static const LinearGradient _activeGradient = LinearGradient(
    colors: [Color(0xFFEEA4CE), Color(0xFFC58BF2)],
  );
  static const Color _inactiveColor = Color(0xFFB0B0B0);

  /// Screens rendered by each tab.
  /// Index 2 is the FAB placeholder (never displayed).
  final List<Widget> _screens = const [
    CoachDashboardScreen(),  // Tab 0 — Tổng quan
    CoachClientListScreen(), // Tab 1 — Học viên
    SizedBox.shrink(),       // Tab 2 — FAB spacer
    CoachLibraryScreen(),    // Tab 3 — Giáo án
    CoachProfileScreen(),    // Tab 4 — Cá nhân
  ];

  void _onTabTapped(int index) {
    // Skip the center FAB spacer tab
    if (index == 2) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Navigation ──
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 20,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side tabs
                _buildNavItem(
                  outlinedIcon: Icons.home_outlined,
                  index: 0,
                ),
                _buildNavItem(
                  outlinedIcon: Icons.people_outlined,
                  index: 1,
                ),

                // Center action button
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: () => showCoachActionMenu(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF9DCEFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),

                // Right side tabs
                _buildNavItem(
                  outlinedIcon: Icons.menu_book_outlined,
                  index: 3,
                ),
                _buildNavItem(
                  outlinedIcon: Icons.person_outline,
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a single nav item with a dot-indicator for the active state.
  Widget _buildNavItem({
    required IconData outlinedIcon,
    required int index,
  }) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSelected
                ? ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        _activeGradient.createShader(bounds),
                    child: Icon(outlinedIcon, size: 24),
                  )
                : Icon(
                    outlinedIcon,
                    size: 24,
                    color: _inactiveColor,
                  ),
            const SizedBox(height: 4),
            // Dot indicator — visible only when selected
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  gradient: _activeGradient,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
