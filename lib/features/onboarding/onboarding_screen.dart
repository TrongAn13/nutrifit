import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/routes/app_router.dart';
import 'onboarding_model.dart';
import 'onboarding_service.dart';

/// 4-page onboarding carousel shown after [GetStartedScreen].
///
/// Persists completion state via [OnboardingService] then navigates
/// to the login screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Primary accent colour used throughout the onboarding flow.
  static const Color _blue = Color(0xFF92A3FD);
  static const Color _blueLight = Color(0xFFEEF1FF);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await OnboardingService.markSeen();
    if (mounted) context.go(AppRouter.login);
  }

  void _next() {
    if (_currentPage < kOnboardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLast = _currentPage == kOnboardingPages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      // ── Skip button ──────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton(
          onPressed: _complete,
          child: Text(
            'Skip',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // ── PageView ─────────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: kOnboardingPages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final page = kOnboardingPages[index];
                return _OnboardingPage(page: page, accentColor: _blue, accentLight: _blueLight);
              },
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Dot indicator
                SmoothPageIndicator(
                  controller: _pageController,
                  count: kOnboardingPages.length,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: _blue,
                    dotColor: Color(0xFFDDE1FF),
                    expansionFactor: 3,
                    spacing: 6,
                  ),
                ),

                // Next / Finish button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withAlpha(80),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: isLast
                      ? TextButton(
                          onPressed: _complete,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Hoàn tất',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: _next,
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single onboarding page widget ────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.page,
    required this.accentColor,
    required this.accentLight,
  });

  final OnboardingPageData page;
  final Color accentColor;
  final Color accentLight;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Column(
      children: [
        // ── Header: illustration container (45% of screen height) ──────
        SizedBox(
          width: double.infinity, // Bắt buộc rộng full mép màn hình
          height: size.height * 0.55,
          child: SvgPicture.asset(
            page.imagePath,
            // ĐÂY LÀ CHÌA KHÓA: fitWidth ép bức ảnh giãn ra vừa khít 2 mép trái/phải
            fit: BoxFit.fitWidth,
            // Đẩy bức ảnh lên sát mép trên cùng của màn hình
            alignment: Alignment.topCenter,
          ),
        ),

        // ── Body: title + description ──────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  page.title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  page.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade500,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


