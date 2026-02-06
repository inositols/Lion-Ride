part of 'wallet_bloc.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final double balance;
  final List<TransactionModel> transactions;

  const WalletLoaded({required this.balance, required this.transactions});

  @override
  List<Object?> get props => [balance, transactions];
}

class PaymentProcessing extends WalletState {}

class PaymentSuccess extends WalletState {
  final String message;
  const PaymentSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentFailure extends WalletState {
  final String message;
  const PaymentFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class WalletError extends WalletState {
  final String message;
  const WalletError(this.message);

  @override
  List<Object?> get props => [message];
}
