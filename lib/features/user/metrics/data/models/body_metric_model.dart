import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a body metric entry in the `body_metrics` collection.
///
/// Tracks weight, height, and optional body composition data.
class BodyMetricModel {
  final String metricId;
  final String userId;
  final DateTime date;
  final double weight; // kg
  final double height; // cm
  final double? bodyFatPercent;
  final double? muscleMass; // kg
  final double? waist; // cm
  final double? chest; // cm
  final double? arm; // cm
  final String? notes;

  const BodyMetricModel({
    required this.metricId,
    required this.userId,
    required this.date,
    required this.weight,
    required this.height,
    this.bodyFatPercent,
    this.muscleMass,
    this.waist,
    this.chest,
    this.arm,
    this.notes,
  });

  /// Computed BMI = weight / (height_in_m)^2
  double get bmi {
    if (height <= 0) return 0;
    final heightM = height / 100;
    return weight / (heightM * heightM);
  }

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory BodyMetricModel.fromJson(Map<String, dynamic> json) {
    return BodyMetricModel(
      metricId: json['metricId'] as String,
      userId: json['userId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
      muscleMass: (json['muscleMass'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      arm: (json['arm'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metricId': metricId,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'bodyFatPercent': bodyFatPercent,
      'muscleMass': muscleMass,
      'waist': waist,
      'chest': chest,
      'arm': arm,
      'notes': notes,
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  BodyMetricModel copyWith({
    String? metricId,
    String? userId,
    DateTime? date,
    double? weight,
    double? height,
    double? bodyFatPercent,
    double? muscleMass,
    double? waist,
    double? chest,
    double? arm,
    String? notes,
  }) {
    return BodyMetricModel(
      metricId: metricId ?? this.metricId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
      muscleMass: muscleMass ?? this.muscleMass,
      waist: waist ?? this.waist,
      chest: chest ?? this.chest,
      arm: arm ?? this.arm,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() =>
      'BodyMetricModel(id: $metricId, weight: $weight, height: $height, bmi: ${bmi.toStringAsFixed(1)})';
}
