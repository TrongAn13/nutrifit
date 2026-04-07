import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/logic/auth_bloc.dart';
import '../../auth/logic/auth_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────────────────────────

const Color _kAccent = Color(0xFF92A3FD);
const Color _kAccentSecondary = Color(0xFF9DCEFF);

/// Screen 3 (final) of the profile setup flow.
///
/// Displays a congratulatory message with the trainee's name.
/// Tapping "Go To Home" dispatches [AuthProfileSetupCompleted],
/// which transitions the Bloc to [AuthAuthenticated] and triggers
/// the router to redirect to the main dashboard.
class WelcomeSuccessScreen extends StatelessWidget {
  const WelcomeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Bạn';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Illustration ──
              SvgPicture.asset(
                'assets/images/profile_setup/welcome.svg',
                height: 260,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),

              // ── Title ──
              Text(
                'Welcome, $userName',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── Subtitle ──
              Text(
                'You are all set now, let\'s reach your\ngoals together with us',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ── Go To Home Button ──
              _buildGoHomeButton(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoHomeButton(BuildContext context) {
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
        onPressed: () {
          // Dispatch event to transition from AuthNewlyRegistered → AuthAuthenticated.
          // The router redirect will automatically send trainee to the correct main screen.
          context.read<AuthBloc>().add(const AuthProfileSetupCompleted());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          'Go To Home',
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
