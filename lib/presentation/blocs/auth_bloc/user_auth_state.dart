part of 'user_auth_bloc.dart';

abstract class UserAuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends UserAuthState {}

class AuthLoading extends UserAuthState {}

class AuthAuthenticated extends UserAuthState {}

class AuthCheck extends UserAuthState {}

class AuthError extends UserAuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
