import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

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

    // Listen to Firebase auth state changes
    _authSub = _repo.authStateChanges.listen((firebaseUser) {
      if (firebaseUser == null) {
        add(const AuthCheckRequested());
      }
    });
  }

  // ───────────────────────── Event Handlers ─────────────────────────

  /// Checks if a user is currently signed in.
  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final firebaseUser = _repo.currentUser;
    if (firebaseUser == null) {
      emit(const AuthUnauthenticated());
    }
    // If user is already authenticated, do nothing — the state
    // was already set by login/register handler.
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
      );
      emit(AuthAuthenticated(user));
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

  // ───────────────────────── Lifecycle ─────────────────────────

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
