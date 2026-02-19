import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_paystack_max/flutter_paystack_max.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../models/ride_model.dart';
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

  /// Atomic Transaction: Transfer funds from Student to Rider and track Platform Fee.
  /// Ensures all parties are updated or none (atomic safety).
  Future<void> processRidePayment(RideModel ride) async {
    final studentRef = _firestore.collection('users').doc(ride.studentId);
    final riderRef = _firestore.collection('users').doc(ride.riderId);
    final platformRef = _firestore.collection('system').doc('platform_fees');
    final rideRef = _firestore.collection('rides').doc(ride.rideId);

    return _firestore.runTransaction((transaction) async {
      // 1. READ phase: Atomic read of current balances
      DocumentSnapshot studentSnap = await transaction.get(studentRef);
      DocumentSnapshot riderSnap = await transaction.get(riderRef);

      if (!studentSnap.exists) throw 'Student profile not found.';
      if (!riderSnap.exists) throw 'Rider profile not found.';

      double studentBalance = (studentSnap.get('wallet_balance') ?? 0.0).toDouble();
      double rideCost = ride.cost;
      double totalDebit = rideCost + 20;

      // 2. VALIDATE phase: Immediate rollback if student cannot afford fare + fee
      if (studentBalance < totalDebit) {
        throw 'Insufficient funds. ₦$totalDebit required for this ride.';
      }

      // 3. WRITE phase: Update balances atomically using FieldValue.increment
      // Decrement Student by Total Amount (Fare + Fee)
      transaction.update(studentRef, {
        'wallet_balance': FieldValue.increment(-totalDebit),
      });
      // Increment Rider by Fare ONLY
      transaction.update(riderRef, {
        'wallet_balance': FieldValue.increment(rideCost),
      });

      // Update centralized Platform Earnings by the ₦20 Transfer Fee
      transaction.set(
        platformRef,
        {'total_earnings': FieldValue.increment(20)},
        SetOptions(merge: true),
      );

      // Mark the Ride as Paid atomically with the wallet movement
      transaction.update(rideRef, {'is_paid': true});

      // 4. LOG Transactions for audit and visibility in user transaction history
      final studentRideLog = TransactionModel(
        txId: const Uuid().v4(),
        userId: ride.studentId,
        type: 'debit',
        amount: rideCost,
        referenceId: ride.rideId,
        timestamp: DateTime.now(),
        description: 'Ride Payment',
      );
      final studentFeeLog = TransactionModel(
        txId: const Uuid().v4(),
        userId: ride.studentId,
        type: 'debit',
        amount: 20,
        referenceId: ride.rideId,
        timestamp: DateTime.now(),
        description: 'Transfer Fee',
      );
      final riderLog = TransactionModel(
        txId: const Uuid().v4(),
        userId: ride.riderId!,
        type: 'credit',
        amount: rideCost,
        referenceId: ride.rideId,
        timestamp: DateTime.now(),
        description: 'Ride Earnings',
      );

      transaction.set(_firestore.collection('transactions').doc(studentRideLog.txId), studentRideLog.toMap());
      transaction.set(_firestore.collection('transactions').doc(studentFeeLog.txId), studentFeeLog.toMap());
      transaction.set(_firestore.collection('transactions').doc(riderLog.txId), riderLog.toMap());
    });
  }

  /// Process bank withdrawal with a ₦20 fee
  /// Atomic Transaction ensuring the Rider balance and Platform fees are updated together.
  Future<void> processWithdrawal({
    required String riderId,
    required double amount,
    required String bankDetails,
  }) async {
    final riderRef = _firestore.collection('users').doc(riderId);
    final platformRef = _firestore.collection('system').doc('platform_fees');

    return _firestore.runTransaction((transaction) async {
      // 1. READ: Atomic snapshot of rider balance
      DocumentSnapshot riderSnap = await transaction.get(riderRef);
      if (!riderSnap.exists) throw 'Profile not found.';

      double riderBalance = (riderSnap.get('wallet_balance') ?? 0.0).toDouble();
      double totalDebit = amount + 20;

      // 2. VALIDATE: Ensure rider has sufficient funds for amount + fee
      if (riderBalance < totalDebit) {
        throw 'Insufficient funds. ₦$totalDebit required (Amount: ₦$amount + Fee: ₦20).';
      }

      // 3. WRITE: Update balances atomically using increment
      transaction.update(riderRef, {
        'wallet_balance': FieldValue.increment(-totalDebit),
      });
      transaction.set(
        platformRef,
        {'total_earnings': FieldValue.increment(20)},
        SetOptions(merge: true),
      );

      // 4. LOG Transactions for audit trail
      final String refId = 'WITHDRAW_${DateTime.now().millisecondsSinceEpoch}';
      
      final withdrawalLog = {
        'tx_id': const Uuid().v4(),
        'user_id': riderId,
        'type': 'debit',
        'amount': amount,
        'reference_id': refId,
        'timestamp': FieldValue.serverTimestamp(),
        'description': 'Bank Withdrawal Request',
        'status': 'pending', // Important for Cloud Function triggers
        'metadata': {
          'bank_details': bankDetails,
          'version': 'v1',
          'external_provider': 'paystack'
        }
      };

      final feeLog = TransactionModel(
        txId: const Uuid().v4(),
        userId: riderId,
        type: 'debit',
        amount: 20,
        referenceId: refId,
        timestamp: DateTime.now(),
        description: 'Withdrawal Fee',
      );

      transaction.set(_firestore.collection('transactions').doc(withdrawalLog['tx_id'] as String), withdrawalLog);
      transaction.set(_firestore.collection('transactions').doc(feeLog.txId), feeLog.toMap());
    });
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

      // 2. Update user balance AND tx ID (for security rules verification)
      transactionBatch.update(userRef, {
        'wallet_balance': FieldValue.increment(amount),
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
