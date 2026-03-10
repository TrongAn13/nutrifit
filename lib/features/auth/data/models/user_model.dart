import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile stored in Firestore `users` collection.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? avatarUrl;
  final String role; // e.g. 'user', 'admin', 'trainer'
  final bool isSynced;
  final String? phone;
  final DateTime? birthDate;
  final String? gender; // 'male', 'female', 'other'
  final String? city;
  final double? height; // cm
  final double? weight; // kg
  final String? activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final String? workActivity; // 'sedentary', 'light', 'moderate', 'active'
  final String? homeActivity; // 'sedentary', 'light', 'moderate', 'active'
  final String? goal; // 'lose_weight', 'maintain', 'gain_muscle'
  final List<String>? allergies; // list of selected allergies
  final String? otherAllergies; // custom allergies text
  final String? coachId; // ID of linked coach (for users)
  final List<String>? clientIds; // IDs of managed clients (for coaches)
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.role = 'user',
    this.isSynced = false,
    this.phone,
    this.birthDate,
    this.gender,
    this.city,
    this.height,
    this.weight,
    this.activityLevel,
    this.workActivity,
    this.homeActivity,
    this.goal,
    this.allergies,
    this.otherAllergies,
    this.coachId,
    this.clientIds,
    required this.createdAt,
  });

  // ───────────────────────── JSON Serialization ─────────────────────────

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'user',
      isSynced: json['isSynced'] as bool? ?? false,
      phone: json['phone'] as String?,
      birthDate: json['birthDate'] != null
          ? (json['birthDate'] as Timestamp).toDate()
          : null,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String?,
      workActivity: json['workActivity'] as String?,
      homeActivity: json['homeActivity'] as String?,
      goal: json['goal'] as String?,
      allergies: (json['allergies'] as List<dynamic>?)?.cast<String>(),
      otherAllergies: json['otherAllergies'] as String?,
      coachId: json['coachId'] as String?,
      clientIds: (json['clientIds'] as List<dynamic>?)?.cast<String>(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role,
      'isSynced': isSynced,
      'phone': phone,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'city': city,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'workActivity': workActivity,
      'homeActivity': homeActivity,
      'goal': goal,
      'allergies': allergies,
      'otherAllergies': otherAllergies,
      'coachId': coachId,
      'clientIds': clientIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ───────────────────────── copyWith ─────────────────────────

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? avatarUrl,
    String? role,
    bool? isSynced,
    String? phone,
    DateTime? birthDate,
    String? gender,
    String? city,
    double? height,
    double? weight,
    String? activityLevel,
    String? workActivity,
    String? homeActivity,
    String? goal,
    List<String>? allergies,
    String? otherAllergies,
    String? coachId,
    List<String>? clientIds,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isSynced: isSynced ?? this.isSynced,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      workActivity: workActivity ?? this.workActivity,
      homeActivity: homeActivity ?? this.homeActivity,
      goal: goal ?? this.goal,
      allergies: allergies ?? this.allergies,
      otherAllergies: otherAllergies ?? this.otherAllergies,
      coachId: coachId ?? this.coachId,
      clientIds: clientIds ?? this.clientIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, name: $name, role: $role)';
}
