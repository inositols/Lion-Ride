import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../repositories/wallet_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../models/transaction_model.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:logger/logger.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;
  final AuthRepository _authRepository;
  final Logger _logger = Logger();
  StreamSubscription? _walletSubscription;
  StreamSubscription? _txSubscription;

  WalletBloc({
    required WalletRepository walletRepository,
    required AuthRepository authRepository,
  })  : _walletRepository = walletRepository,
        _authRepository = authRepository,
        super(WalletInitial()) {
    on<LoadWallet>(_onLoadWallet);
    on<InitiateDeposit>(_onInitiateDeposit);
    on<_WalletUpdated>(_onWalletUpdated);
    on<_WalletErrorOccurred>(_onWalletErrorOccurred);
  }

  Future<void> _onLoadWallet(LoadWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading());
    _logger.i('Loading wallet...');

    try {
      final firebaseUser = await _authRepository.user.first;
      if (firebaseUser == null) {
        _logger.w('No authenticated user found for wallet loading.');
        emit(const WalletError('User not authenticated.'));
        return;
      }

      final userId = firebaseUser.uid;
      _logger.d('User ID: $userId');

      // Cancel existing subscriptions
      await _walletSubscription?.cancel();
      await _txSubscription?.cancel();

      // Listen to user document for balance
      _walletSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen(
        (userSnap) {
          if (!userSnap.exists) {
            _logger.e('User document does not exist in Firestore for UID: $userId');
            add(_WalletErrorOccurred('User profile not found.'));
            return;
          }
          
          final balance = (userSnap.get('wallet_balance') ?? 0.0).toDouble();
          _logger.d('Wallet balance updated: $balance');
          
          // We need transactions too to emit WalletLoaded
          _txSubscription?.cancel();
          _txSubscription = _walletRepository.getTransactionHistory(userId).listen(
            (txs) {
              _logger.d('Transaction history updated: ${txs.length} transactions');
              add(_WalletUpdated(balance, txs));
            },
            onError: (error) {
              _logger.e('Error fetching transaction history: $error');
              // If it's a missing index error, the log will show the link
              add(_WalletErrorOccurred('Failed to load transaction history. If this is a new environment, a composite index might be required. Check logs for the creation link.'));
            },
          );
        },
        onError: (error) {
          _logger.e('Error fetching user document: $error');
          add(_WalletErrorOccurred('Failed to load wallet data.'));
        },
      );
    } catch (e) {
      _logger.e('Unexpected error in _onLoadWallet: $e');
      emit(WalletError(e.toString()));
    }
  }

  void _onWalletUpdated(_WalletUpdated event, Emitter<WalletState> emit) {
    emit(WalletLoaded(
      balance: event.balance,
      transactions: event.transactions,
    ));
  }

  void _onWalletErrorOccurred(_WalletErrorOccurred event, Emitter<WalletState> emit) {
    emit(WalletError(event.message));
  }

  Future<void> _onInitiateDeposit(
    InitiateDeposit event,
    Emitter<WalletState> emit,
  ) async {
    final firebaseUser = await _authRepository.user.first;
    if (firebaseUser == null) return;

    final userId = firebaseUser.uid;
    emit(PaymentProcessing());

    final Completer<void> completer = Completer<void>();
    String? errorMessage;
    String? successMessage;

    try {
      await _walletRepository.fundWallet(
        context: event.context,
        amount: event.amount,
        email: event.email,
        onSuccess: (reference) async {
          try {
            await _walletRepository.processSuccessfulDeposit(
              userId: userId,
              amount: event.amount,
              reference: reference,
            );
            successMessage = 'Deposit successful!';
          } catch (e) {
            errorMessage = e.toString();
          }
          completer.complete();
        },
        onError: (message) {
          errorMessage = message;
          completer.complete();
        },
      );

      await completer.future;

      if (successMessage != null) {
        emit(PaymentSuccess(successMessage!));
      } else if (errorMessage != null) {
        emit(PaymentFailure(errorMessage!));
      }
    } catch (e) {
      emit(WalletError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _walletSubscription?.cancel();
    _txSubscription?.cancel();
    return super.close();
  }
}

// New event for internal error reporting from streams
class _WalletErrorOccurred extends WalletEvent {
  final String message;
  const _WalletErrorOccurred(this.message);
  @override
  List<Object?> get props => [message];
}
