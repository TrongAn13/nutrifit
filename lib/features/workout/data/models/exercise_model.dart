import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an exercise in the Firestore `exercises` collection.
///
/// Exercises can be system-provided ([isSystem] = true) or user-created.
class ExerciseModel {
  final String exerciseId;
  final String? userId; // null for system exercises
  final String name;
  final String primaryMuscle; // e.g. 'Ngực', 'Lưng', 'Chân'
  final String equipment; // e.g. 'Tạ đòn', 'Máy', 'Tự do'
  final String instructions;
  final bool isSystem;
  final List<String> secondaryMuscles; // e.g. 'Vai', 'Tay sau'
  final String bodyPart; // e.g. 'Thân trên', 'Ngực', 'Tay'
  final DateTime createdAt;

  const ExerciseModel({
    required this.exerciseId,
    this.userId,
    required this.name,
    required this.primaryMuscle,
    this.equipment = '',
    this.instructions = '',
    this.isSystem = false,
    this.secondaryMuscles = const [],
    this.bodyPart = '',
    required this.createdAt,
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    // Ép kiểu an toàn cho Hướng dẫn tập (dù Firebase trả về List hay String)
    String parsedInstructions = '';
    if (json['instructions'] is List) {
      parsedInstructions = (json['instructions'] as List).join('\n');
    } else {
      parsedInstructions = json['instructions'] as String? ?? '';
    }
    DateTime parsedDate = DateTime.now(); // Mặc định nếu bị null
    if (json['createdAt'] != null) {
      if (json['createdAt'] is Timestamp) {
        // Nếu là Timestamp của Firebase
        parsedDate = (json['createdAt'] as Timestamp).toDate();
      } else if (json['createdAt'] is String) {
        // Nếu là String (do hàm toIso8601String sinh ra)
        parsedDate =
            DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now();
      }
    }

    return ExerciseModel(
      exerciseId: json['exerciseId'] as String? ?? '',
      userId: json['userId'] as String?,
      name: json['name'] as String? ?? 'Chưa có tên',
      primaryMuscle: json['primaryMuscle'] as String? ?? '',
      equipment: json['equipment'] as String? ?? '',
      instructions: parsedInstructions, // Dùng biến đã xử lý ở trên
      isSystem: json['isSystem'] as bool? ?? false,
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bodyPart: json['bodyPart'] as String? ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'userId': userId,
      'name': name,
      'primaryMuscle': primaryMuscle,
      'equipment': equipment,
      'instructions': instructions,
      'isSystem': isSystem,
      'secondaryMuscles': secondaryMuscles,
      'bodyPart': bodyPart,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  ExerciseModel copyWith({
    String? exerciseId,
    String? userId,
    String? name,
    String? primaryMuscle,
    String? equipment,
    String? instructions,
    bool? isSystem,
    List<String>? secondaryMuscles,
    String? bodyPart,
    DateTime? createdAt,
  }) {
    return ExerciseModel(
      exerciseId: exerciseId ?? this.exerciseId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      isSystem: isSystem ?? this.isSystem,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      bodyPart: bodyPart ?? this.bodyPart,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'ExerciseModel(name: $name, muscle: $primaryMuscle, system: $isSystem)';
}
