part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role;
  final String phoneNumber;
  final String? plateNumber;
  final String? unionNumber;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.phoneNumber,
    this.plateNumber,
    this.unionNumber,
  });

  @override
  List<Object?> get props =>
      [email, password, name, role, phoneNumber, plateNumber, unionNumber];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {}
