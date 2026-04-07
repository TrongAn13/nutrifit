import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/routes/app_router.dart';

import 'package:flutter_svg/flutter_svg.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

const Color _kAccent = Color(0xFF92A3FD);
const Color _kAccentSecondary = Color(0xFF9DCEFF);

/// Data class representing a single goal card.
class _GoalData {
  final String title;
  final String description;
  final String svgPath;
  final String value; // Firestore-compatible value

  const _GoalData({
    required this.title,
    required this.description,
    required this.svgPath,
    required this.value,
  });
}

const _goals = [
  _GoalData(
    title: 'Improve Shape',
    description:
        'I have a low amount of body fat and need / want to build more muscle',
    svgPath: 'assets/images/profile_setup/goal1.svg',
    value: 'improve_shape',
  ),
  _GoalData(
    title: 'Lean & Tone',
    description:
        'I\'m "skinny fat". look thin but have no muscle tone. I want to add lean muscle in the right way',
    svgPath: 'assets/images/profile_setup/goal2.svg',
    value: 'lean_and_tone',
  ),
  _GoalData(
    title: 'Lose a Fat',
    description:
        'I have over 20 lbs to lose. I want to drop all this fat and gain muscle mass',
    svgPath: 'assets/images/profile_setup/goal3.svg',
    value: 'lose_fat',
  ),
];

/// Screen 2 of the profile setup flow.
///
/// Displays a peek-style [PageView] carousel with 3 goal cards.
/// On confirm, writes all profile data to Firestore and navigates
/// to the welcome screen.
class GoalSelectionScreen extends StatefulWidget {
  final String gender;
  final DateTime? birthDate;
  final double weight;
  final double height;

  const GoalSelectionScreen({
    super.key,
    required this.gender,
    this.birthDate,
    required this.weight,
    required this.height,
  });

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  int _selectedIndex = 0;
  bool _isSaving = false;

  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    // Start at a high multiple of 3 to allow infinite backward scrolling.
    _pageCtrl = PageController(initialPage: 9000, viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  /// Writes all collected profile data to the trainee's Firestore document.
  Future<void> _onConfirm() async {
    setState(() => _isSaving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isSaving = false);
      return;
    }

    try {
      final updateData = <String, dynamic>{
        'gender': widget.gender,
        'weight': widget.weight,
        'height': widget.height,
        'goal': _goals[_selectedIndex].value,
        'isProfileComplete': true,
      };

      if (widget.birthDate != null) {
        updateData['birthDate'] = Timestamp.fromDate(widget.birthDate!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updateData);

      if (mounted) {
        context.go(AppRouter.welcomeSuccess);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ── Header ──
            Text(
              'What is your goal ?',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'It will help us to choose a best\nprogram for you',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ── Goal Carousel ──
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                // No itemCount => infinite scroll
                onPageChanged: (i) => setState(() => _selectedIndex = i % _goals.length),
                itemBuilder: (context, index) {
                  final realIndex = index % _goals.length;
                  return AnimatedBuilder(
                    animation: _pageCtrl,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageCtrl.position.haveDimensions) {
                        value = (_pageCtrl.page ?? 9000.0) - index;
                        value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                      }
                      return Center(
                        child: SizedBox(
                          height: Curves.easeOut.transform(value) * 600,
                          child: child,
                        ),
                      );
                    },
                    child: _GoalCard(
                      data: _goals[realIndex],
                      isSelected: _selectedIndex == realIndex,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Confirm Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: _buildConfirmButton(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [_kAccent, _kAccentSecondary]),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'Confirm',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
// Goal Card
// ═════════════════════════════════════════════════════════════════════════════

class _GoalCard extends StatelessWidget {
  final _GoalData data;
  final bool isSelected;

  const _GoalCard({required this.data, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [_kAccent, _kAccentSecondary]
              : [const Color(0xFFEEF1FF), const Color(0xFFE8ECFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _kAccent.withAlpha(60),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Expanded(
              child: SvgPicture.asset(
                data.svgPath,
                width: 300,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              data.title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Divider
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withAlpha(120)
                    : _kAccent.withAlpha(80),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              data.description,
              style: GoogleFonts.inter(
                fontSize: 12,
                height: 1.6,
                color: isSelected
                    ? Colors.white.withAlpha(220)
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
