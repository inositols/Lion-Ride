import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  final Logger _logger = Logger();

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
  }

  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final profile = await _authRepository.getUserProfile(currentUser.uid);
      if (profile != null) {
        emit(AuthAuthenticated(profile));
      }
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.d('AuthCheckRequested received');
    try {
      // Check current user directly for faster initial response
      final firebaseUser = FirebaseAuth.instance.currentUser;
      _logger.d('Direct FirebaseAuth.instance.currentUser: ${firebaseUser?.uid ?? 'Null'}');

      if (firebaseUser != null) {
        final profile = await _authRepository.getUserProfile(firebaseUser.uid);
        if (profile != null) {
          _logger.i('Profile found for UID: ${firebaseUser.uid}');
          emit(AuthAuthenticated(profile));
        } else {
          _logger.w('No profile found in Firestore for UID: ${firebaseUser.uid}');
          emit(AuthUnauthenticated());
        }
      } else {
        _logger.i('No active Firebase session found');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      _logger.e('Error in AuthCheckRequested: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('Attempting login for email: ${event.email}');
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(event.email, event.password);
      _logger.i('Login successful for UID: ${user.uid}');
      emit(AuthAuthenticated(user));
    } catch (e) {
      _logger.e('Login failed: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        name: event.name,
        role: event.role,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }
}
