import 'package:flutter/foundation.dart';

import '../data/models/user_model.dart';

/// States emitted by [AuthBloc].
@immutable
sealed class AuthState {
  const AuthState();
}

/// Initial state before any auth check.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A sign-in / sign-up operation is in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
final class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);
}

/// An authentication error occurred.
final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

/// User has signed out (unauthenticated).
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User just registered and needs to complete profile setup.
///
/// Extends [AuthAuthenticated] so the trainee is technically signed in,
/// but the router will redirect to the profile-setup flow.
final class AuthNewlyRegistered extends AuthAuthenticated {
  const AuthNewlyRegistered(super.user);
}
