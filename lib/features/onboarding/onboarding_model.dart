/// Data model representing a single onboarding page.
class OnboardingPageData {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingPageData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

/// Static list of all onboarding pages.
const List<OnboardingPageData> kOnboardingPages = [
  OnboardingPageData(
    imagePath: 'assets/images/onboarding/onboarding1.svg',
    title: 'Track Your Goal',
    description:
        "Don't worry if you have trouble determining your goals, We can help you determine your goals and track your goals",
  ),
  OnboardingPageData(
    imagePath: 'assets/images/onboarding/onboarding4.svg',
    title: 'Get Burn',
    description:
        "Let's keep burning, to achieve yours goals, it hurts only temporarily, if you give up now you will be in pain forever",
  ),
  OnboardingPageData(
    imagePath: 'assets/images/onboarding/onboarding2.svg',
    title: 'Eat Well',
    description:
        "Let's start a healthy lifestyle with us, we can determine your diet every day, healthy eating is fun",
  ),
  OnboardingPageData(
    imagePath: 'assets/images/onboarding/onboarding3.svg',
    title: 'Improve Sleep Quality',
    description:
        'Improve the quality of your sleep with us, good quality sleep can bring a good mood in the morning',
  ),
];
