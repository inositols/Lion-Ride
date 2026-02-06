import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String txId;
  final String userId;
  final String type; // 'credit' | 'debit'
  final double amount;
  final String referenceId;
  final DateTime timestamp;
  final String description;

  TransactionModel({
    required this.txId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.referenceId,
    required this.timestamp,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'tx_id': txId,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'reference_id': referenceId,
      'timestamp': Timestamp.fromDate(timestamp),
      'description': description,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      txId: id,
      userId: map['user_id'] ?? '',
      type: map['type'] ?? 'debit',
      amount: (map['amount'] ?? 0.0).toDouble(),
      referenceId: map['reference_id'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      description: map['description'] ?? '',
    );
  }
}
