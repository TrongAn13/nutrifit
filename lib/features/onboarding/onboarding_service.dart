import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting whether the trainee has completed onboarding.
class OnboardingService {
  static const String _key = 'has_seen_onboarding';

  /// Returns `true` if the trainee has already seen the onboarding flow.
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  /// Marks onboarding as completed so it is skipped on next launch.
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
