import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single drink/water entry logged by the trainee.
class WaterEntryModel {
  final String entryId;
  final String drinkName; // e.g. 'Nước', 'Sữa', 'Cà phê'
  final int amountMl;
  final double hydrationFactor; // 0.0-1.0, how much counts as water
  final DateTime loggedAt;

  const WaterEntryModel({
    required this.entryId,
    required this.drinkName,
    required this.amountMl,
    this.hydrationFactor = 1.0,
    required this.loggedAt,
  });

  /// The effective water amount after applying hydration factor.
  int get effectiveMl => (amountMl * hydrationFactor).round();

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory WaterEntryModel.fromJson(Map<String, dynamic> json) {
    return WaterEntryModel(
      entryId: json['entryId'] as String,
      drinkName: json['drinkName'] as String,
      amountMl: (json['amountMl'] as num).toInt(),
      hydrationFactor: (json['hydrationFactor'] as num?)?.toDouble() ?? 1.0,
      loggedAt: (json['loggedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'drinkName': drinkName,
      'amountMl': amountMl,
      'hydrationFactor': hydrationFactor,
      'loggedAt': Timestamp.fromDate(loggedAt),
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  WaterEntryModel copyWith({
    String? entryId,
    String? drinkName,
    int? amountMl,
    double? hydrationFactor,
    DateTime? loggedAt,
  }) {
    return WaterEntryModel(
      entryId: entryId ?? this.entryId,
      drinkName: drinkName ?? this.drinkName,
      amountMl: amountMl ?? this.amountMl,
      hydrationFactor: hydrationFactor ?? this.hydrationFactor,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  String toString() =>
      'WaterEntryModel(drinkName: $drinkName, amountMl: $amountMl)';
}
