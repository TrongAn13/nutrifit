import '../../../features/auth/data/models/user_model.dart';

/// Static utility methods for health-related calculations.
///
/// All formulas follow the Mifflin-St Jeor equation for BMR
/// and standard TDEE activity multipliers.
class HealthMetricsUtils {
  HealthMetricsUtils._(); // Prevent instantiation

  // ───────────────────────── Age ─────────────────────────

  /// Returns the current age in years based on [birthDate].
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // ───────────────────────── BMI ─────────────────────────

  /// Body Mass Index = weight(kg) / height(m)².
  /// Returns 0 if height is zero or negative.
  static double calculateBMI(double weight, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weight / (heightM * heightM);
  }

  // ───────────────────────── BMR (Mifflin-St Jeor) ──────

  /// Basal Metabolic Rate.
  ///   Male:   (10 × weight) + (6.25 × height) − (5 × age) + 5
  ///   Female: (10 × weight) + (6.25 × height) − (5 × age) − 161
  ///
  /// Returns 0 if weight, height, birthDate, or gender is missing.
  static double calculateBMR(UserModel user) {
    final weight = user.weight;
    final height = user.height;
    final birthDate = user.birthDate;
    final gender = user.gender;

    if (weight == null || height == null || birthDate == null || gender == null) {
      return 0;
    }

    final age = calculateAge(birthDate);
    final base = (10 * weight) + (6.25 * height) - (5 * age);

    return gender == 'male' ? base + 5 : base - 161;
  }

  // ───────────────────────── TDEE ────────────────────────

  /// Activity-level multipliers.
  static const Map<String, double> _activityMultipliers = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very_active': 1.9,
  };

  /// Total Daily Energy Expenditure = BMR × activity multiplier.
  static double calculateTDEE(double bmr, String activityLevel) {
    final multiplier = _activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  // ───────────────────── Target Calories ─────────────────

  /// Adjusts TDEE based on the trainee's goal:
  ///   lose_weight  → tdee − 500
  ///   maintain     → tdee
  ///   gain_muscle  → tdee + 500
  static int calculateTargetCalories(double tdee, String goal) {
    switch (goal) {
      case 'lose_weight':
        return (tdee - 500).round();
      case 'gain_muscle':
        return (tdee + 500).round();
      case 'maintain':
      default:
        return tdee.round();
    }
  }

  // ───────────────── Macro Goals (grams) ─────────────────

  /// Computes macro goals in grams from total target calories.
  ///   Protein : 30% of cals  (1g = 4 kcal)
  ///   Fat     : 35% of cals  (1g = 9 kcal)
  ///   Carbs   : 35% of cals  (1g = 4 kcal)
  static ({double protein, double fat, double carbs}) calculateMacroGoals(
      int targetCalories) {
    return (
      protein: (targetCalories * 0.30) / 4,
      fat: (targetCalories * 0.35) / 9,
      carbs: (targetCalories * 0.35) / 4,
    );
  }
}
