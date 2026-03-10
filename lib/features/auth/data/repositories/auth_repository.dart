import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/user_model.dart';

/// Handles all authentication logic: sign-up, sign-in, sign-out,
/// Firestore user profile creation, and FCM token management.
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  /// Stream of auth state changes (login / logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  FirebaseFirestore get firestore => _firestore;

  // ───────────────────────── Sign Up ─────────────────────────

  /// Creates a new account with [email] and [password], then stores a
  /// [UserModel] document in the `users` collection and saves the FCM token.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'user',
  }) async {
    try {
      // 1. Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Tạo tài khoản thất bại. Vui lòng thử lại.');
      }

      // 2. Update display name
      await firebaseUser.updateDisplayName(name);

      // 3. Get FCM token
      final fcmToken = await _getFcmToken();

      // 4. Build user model with role
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
      );

      // 5. Write user document to Firestore
      final docData = userModel.toJson();
      if (fcmToken != null) {
        docData['fcmToken'] = fcmToken;
      }
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(docData);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (e) {
      throw Exception('Đăng ký thất bại: ${e.toString()}');
    }
  }

  // ───────────────────────── Sign In ─────────────────────────

  /// Signs in with [email] and [password], updates the FCM token in Firestore,
  /// and returns the corresponding [UserModel].
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
      }

      // 2. Update FCM token in Firestore
      final fcmToken = await _getFcmToken();
      if (fcmToken != null) {
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .update({'fcmToken': fcmToken});
      }

      // 3. Fetch user profile from Firestore
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }

      // If profile missing (edge case), create a minimal one
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: firebaseUser.displayName ?? 'Người dùng',
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userModel.toJson());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  // ───────────────────────── Sign Out ─────────────────────────

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Đăng xuất thất bại: ${e.toString()}');
    }
  }

  // ───────────────────────── Helpers ─────────────────────────

  /// Retrieves the FCM device token, returns null on failure.
  Future<String?> _getFcmToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      // FCM may not be available on all platforms (e.g. emulator).
      return null;
    }
  }

  /// Maps Firebase Auth error codes to user-friendly Vietnamese messages.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Sai mật khẩu. Vui lòng thử lại.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không hợp lệ.';
      default:
        return 'Đã xảy ra lỗi ($code). Vui lòng thử lại.';
    }
  }
}
