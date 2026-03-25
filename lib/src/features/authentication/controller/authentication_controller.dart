import 'package:control/control.dart';
import 'package:flutter/foundation.dart';
import 'package:websockets/src/features/authentication/data/authentication_repository.dart';
import 'package:websockets/src/features/authentication/model/user.dart';

/// for more information to change the controller's handler checkout this github page:
/// https://github.com/PlugFox/control/tree/master/lib/src/concurrency

@immutable
sealed class AuthenticationState {
  const AuthenticationState();

  const factory AuthenticationState.idle() = Authentication$IdleState;

  const factory AuthenticationState.inProgress() = Authentication$InProgressState;

  const factory AuthenticationState.error(String? error) = Authentication$ErrorState;

  const factory AuthenticationState.authenticated(User user) = Authentication$AuthenticatedState;

  String? get error => switch (this) {
    final Authentication$ErrorState state => state.error,
    _ => null,
  };

  User? get user => switch (this) {
    final Authentication$AuthenticatedState state => state.user,
    _ => null,
  };
}

final class Authentication$IdleState extends AuthenticationState {
  const Authentication$IdleState();
}

final class Authentication$InProgressState extends AuthenticationState {
  const Authentication$InProgressState();
}

final class Authentication$ErrorState extends AuthenticationState {
  const Authentication$ErrorState(this.error);

  @override
  final String? error;

  Authentication$ErrorState copyWith({String? error}) =>
      Authentication$ErrorState(error ?? this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Authentication$ErrorState && error == other.error);

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'AuthenticationState.error(error: $error)';
}

final class Authentication$AuthenticatedState extends AuthenticationState {
  const Authentication$AuthenticatedState(this.user);

  @override
  final User user;

  Authentication$AuthenticatedState copyWith({User? user}) =>
      Authentication$AuthenticatedState(user ?? this.user);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Authentication$AuthenticatedState && user == other.user);

  @override
  int get hashCode => user.hashCode;

  @override
  String toString() => 'AuthenticationState.authenticated(user: $user)';
}

class AuthenticationController extends StateController<AuthenticationState>
    with DroppableControllerHandler {
  AuthenticationController({
    required this.repository,
    super.initialState = const AuthenticationState.idle(),
  });

  final IAuthenticationRepository repository;

  void signIn(String displayName) => handle(() async {
    final uid = DateTime.now().millisecondsSinceEpoch % 100000 + 1;
    setState(AuthenticationState.authenticated(User(id: uid, name: displayName.trim())));
  });

  void logout() => handle(() async {
    if (state is! Authentication$AuthenticatedState) return;
    setState(const AuthenticationState.idle());
  });
}
