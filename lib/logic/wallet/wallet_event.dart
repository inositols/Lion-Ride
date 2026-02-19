part of 'wallet_bloc.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {}

class InitiateDeposit extends WalletEvent {
  final BuildContext context;
  final double amount;
  final String email;

  const InitiateDeposit({
    required this.context,
    required this.amount,
    required this.email,
  });

  @override
  List<Object?> get props => [context, amount, email];
}

class WithdrawFundsRequested extends WalletEvent {
  final double amount;
  final String bankDetails;
  const WithdrawFundsRequested({required this.amount, required this.bankDetails});

  @override
  List<Object?> get props => [amount, bankDetails];
}

// Internal event for real-time balance updates
class _WalletUpdated extends WalletEvent {
  final double balance;
  final List<TransactionModel> transactions;

  const _WalletUpdated(this.balance, this.transactions);

  @override
  List<Object?> get props => [balance, transactions];
}
