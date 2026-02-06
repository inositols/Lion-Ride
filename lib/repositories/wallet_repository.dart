import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class WalletRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // PLACEHOLDERS: Put your actual Paystack keys here
  static const String _secretKey =
      'sk_test_b5adf7fee6e8755de201bc9a228a2732c84d6a7f';

  /// Trigger Paystack UI to fund wallet using flutter_paystack_max
  Future<void> fundWallet({
    required BuildContext context,
    required double amount,
    required String email,
    required Function(String reference) onSuccess,
    required Function(String? message) onError,
  }) async {
    try {
      final request = PaystackTransactionRequest(
        reference: 'dep_${DateTime.now().microsecondsSinceEpoch}',
        secretKey: _secretKey,
        email: email,
        amount: (amount * 100).toDouble(),
        currency: PaystackCurrency.ngn,
        channel: [
          PaystackPaymentChannel.mobileMoney,
          PaystackPaymentChannel.card,
          PaystackPaymentChannel.ussd,
          PaystackPaymentChannel.bankTransfer,
          PaystackPaymentChannel.bank,
          PaystackPaymentChannel.qr,
          PaystackPaymentChannel.eft,
        ],
      );

      final initializedTransaction = await PaymentService.initializeTransaction(
        request,
      );

      if (!initializedTransaction.status) {
        onError(initializedTransaction.message);
        return;
      }

      await PaymentService.showPaymentModal(
        context,
        transaction: initializedTransaction,
        // Optional: Replace with your actual callback URL if needed
        callbackUrl: 'https://standard.paystack.co/close',
      );

      // Verify the transaction
      final response = await PaymentService.verifyTransaction(
        paystackSecretKey: _secretKey,
        initializedTransaction.data?.reference ?? request.reference,
      );

      if (response.status) {
        onSuccess(response.data?.reference ?? request.reference);
      } else {
        onError(response.message ?? 'Payment failed or cancelled.');
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Atomic Transaction: Create transaction log AND increment user balance
  Future<void> processSuccessfulDeposit({
    required String userId,
    required double amount,
    required String reference,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final txId = const Uuid().v4();
    final txRef = _firestore.collection('transactions').doc(txId);

    final transaction = TransactionModel(
      txId: txId,
      userId: userId,
      type: 'credit',
      amount: amount,
      referenceId: reference,
      timestamp: DateTime.now(),
      description: 'Wallet Deposit via Paystack',
    );

    return _firestore.runTransaction((transactionBatch) async {
      // 1. Get current user data
      DocumentSnapshot userSnap = await transactionBatch.get(userRef);
      if (!userSnap.exists) {
        throw 'User profile not found.';
      }

      double currentBalance = (userSnap.get('wallet_balance') ?? 0.0)
          .toDouble();

      // 2. Update user balance AND tx ID (for security rules verification)
      transactionBatch.update(userRef, {
        'wallet_balance': currentBalance + amount,
        'last_tx_id': txId,
      });

      // 3. Create transaction record
      transactionBatch.set(txRef, transaction.toMap());
    });
  }

  /// Stream of transaction history
  Stream<List<TransactionModel>> getTransactionHistory(String userId) {
    return _firestore
        .collection('transactions')
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return TransactionModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
