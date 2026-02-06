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
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.d('AuthCheckRequested received');
    try {
      // Use a timeout or a faster check for the initial state
      final firebaseUser = await _authRepository.user.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _logger.e('Auth check timed out');
          return null; // Treat as no user if it times out
        },
      );

      _logger.d('Firebase user check result: ${firebaseUser?.uid ?? 'Null'}');

      if (firebaseUser != null) {
        final profile = await _authRepository.getUserProfile(firebaseUser.uid);
        if (profile != null) {
          _logger.i('Profile found for UID: ${firebaseUser.uid}');
          emit(AuthAuthenticated(profile));
        } else {
          _logger.w('No profile found for UID: ${firebaseUser.uid}');
          emit(AuthUnauthenticated());
        }
      } else {
        _logger.i('No Firebase user found');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      _logger.e('Critical error in AuthCheckRequested: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
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
