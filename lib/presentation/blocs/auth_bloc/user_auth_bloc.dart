import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'user_auth_event.dart';
part 'user_auth_state.dart';

class UserAuthBloc extends Bloc<AuthEvent, UserAuthState> {
  final FirebaseAuth _auth;

  UserAuthBloc(this._auth) : super(AuthInitial()) {
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthCheckRequested>(_onCheck);
  }

  Future<void> _onSignUp(
      AuthSignUpRequested event, Emitter<UserAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.createUserWithEmailAndPassword(
          email: event.email, password: event.password);
      await _auth.signInWithEmailAndPassword(
          email: event.email, password: event.password);

      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignIn(
      AuthSignInRequested event, Emitter<UserAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(
          email: event.email, password: event.password);

      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event, Emitter<UserAuthState> emit) async {
    emit(AuthLoading());
    try {
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheck(
      AuthCheckRequested event, Emitter<UserAuthState> emit) async {
    emit(AuthAuthenticated());
  }
}
