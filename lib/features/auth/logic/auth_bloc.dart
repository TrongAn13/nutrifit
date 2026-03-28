import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Manages authentication state across the application.
///
/// Listens to [AuthRepository.authStateChanges] and converts
/// [AuthEvent]s into [AuthState]s.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  late final StreamSubscription _authSub;

  AuthBloc({required AuthRepository authRepository})
      : _repo = authRepository,
        super(const AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthProfileSetupCompleted>(_onProfileSetupCompleted);

    // Listen to Firebase auth state changes
    _authSub = _repo.authStateChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        add(const AuthCheckRequested());
      }
    });
  }

  // ───────────────────────── Event Handlers ─────────────────────────

  /// Checks if a user is currently signed in and fetches profile.
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final firebaseUser = _repo.currentUser;
    if (firebaseUser == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    
    // Fetch user profile from Firestore to restore role
    try {
      final doc = await _repo.firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromJson(doc.data()!);
        // If profile setup is not complete, redirect to profile-setup flow
        if (!userModel.isProfileComplete) {
          emit(AuthNewlyRegistered(userModel));
        } else {
          emit(AuthAuthenticated(userModel));
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Handles email/password sign-in.
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Handles new account registration.
  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );
      emit(AuthNewlyRegistered(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Signs the user out.
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.signOut();
    emit(const AuthUnauthenticated());
  }

  /// Transitions from newly-registered to fully authenticated.
  Future<void> _onProfileSetupCompleted(
    AuthProfileSetupCompleted event,
    Emitter<AuthState> emit,
  ) async {
    final current = state;
    if (current is AuthAuthenticated) {
      // Re-fetch profile from Firestore to get updated fields
      try {
        final doc = await _repo.firestore
            .collection('users')
            .doc(current.user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final updatedUser = UserModel.fromJson(doc.data()!);
          emit(AuthAuthenticated(updatedUser));
        } else {
          emit(AuthAuthenticated(current.user));
        }
      } catch (_) {
        emit(AuthAuthenticated(current.user));
      }
    }
  }

  // ───────────────────────── Lifecycle ─────────────────────────

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
