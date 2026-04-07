import 'package:flutter/foundation.dart';

/// Events dispatched to [AuthBloc].
@immutable
sealed class AuthEvent {
  const AuthEvent();
}

/// Check if a trainee is already signed in (on app startup).
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User tapped "Đăng nhập".
final class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});
}

/// User tapped "Đăng ký".
final class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    this.role = 'trainee',
  });
}

/// User tapped "Đăng xuất".
final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Profile setup flow completed — transition to fully authenticated.
final class AuthProfileSetupCompleted extends AuthEvent {
  const AuthProfileSetupCompleted();
}
