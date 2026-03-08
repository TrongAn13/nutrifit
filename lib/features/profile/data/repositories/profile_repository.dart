import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../auth/data/models/user_model.dart';

/// Handles reading/updating user profile data in the `users` collection.
class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập.');
    return user.uid;
  }

  // ───────────────────────── Read ─────────────────────────

  /// Fetches the current user's profile from Firestore.
  Future<UserModel?> getProfile() async {
    try {
      final doc = await _usersRef.doc(_uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Không thể tải hồ sơ: ${e.toString()}');
    }
  }

  // ───────────────────────── Write ─────────────────────────

  /// Updates profile fields using merge to preserve existing data.
  Future<void> updateProfile({
    required String name,
    String? phone,
    DateTime? birthDate,
    String? gender,
    String? city,
    double? height,
    double? weight,
    String? activityLevel,
    String? goal,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'phone': phone,
        'gender': gender,
        'city': city,
        'height': height,
        'weight': weight,
        'activityLevel': activityLevel,
        'goal': goal,
      };

      if (birthDate != null) {
        data['birthDate'] = Timestamp.fromDate(birthDate);
      }

      await _usersRef.doc(_uid).set(data, SetOptions(merge: true));

      // Also update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(name);
    } catch (e) {
      throw Exception('Không thể cập nhật hồ sơ: ${e.toString()}');
    }
  }
}
