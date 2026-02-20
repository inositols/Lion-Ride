import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';

class TransactionLedgerView extends StatelessWidget {
  const TransactionLedgerView({super.key});

  Future<void> _markAsPaid(BuildContext context, String txId) async {
    try {
      await FirebaseFirestore.instance.collection('transactions').doc(txId).update({
        'description': 'Withdrawal Completed (Paid)', // Updating description as requested
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal marked as Paid'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Ledger',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004D40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Audit all platform movements and process withdrawals',
                    style: GoogleFonts.inter(color: Colors.black54, fontSize: 16),
                  ),
                ],
              ),
              _buildExportButton(),
            ],
          ),
          const SizedBox(height: 40),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('transactions')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final transactions = snapshot.data?.docs.map((d) => 
                      TransactionModel.fromMap(d.data() as Map<String, dynamic>, d.id)
                    ).toList() ?? [];

                    if (transactions.isEmpty) {
                      return const Center(child: Text('No transactions recorded yet'));
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 360),
                          child: DataTable(
                            headingRowHeight: 64,
                            dataRowMaxHeight: 72,
                            columnSpacing: 24,
                            headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                            columns: const [
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('DESCRIPTION')),
                              DataColumn(label: Text('USER ID')),
                              DataColumn(label: Text('AMOUNT')),
                              DataColumn(label: Text('TYPE')),
                              DataColumn(label: Text('ACTION')),
                            ],
                            rows: transactions.map((tx) {
                              final isWithdrawalRequest = tx.description.contains('Bank Withdrawal Request');
                              final isPaid = tx.description.contains('Completed');
                              
                              return DataRow(
                                color: WidgetStateProperty.resolveWith<Color?>((states) {
                                  if (isWithdrawalRequest && !isPaid) return Colors.yellow.withOpacity(0.1);
                                  return null;
                                }),
                                cells: [
                                  DataCell(Text(DateFormat('MMM dd, yyyy · HH:mm').format(tx.timestamp), style: const TextStyle(fontSize: 13))),
                                  DataCell(
                                    Text(
                                      tx.description,
                                      style: TextStyle(
                                        fontWeight: isWithdrawalRequest ? FontWeight.bold : FontWeight.normal,
                                        color: isWithdrawalRequest ? const Color(0xFF004D40) : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(tx.userId, style: const TextStyle(fontSize: 10, color: Colors.grey))),
                                  DataCell(Text('₦${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(_buildTypeBadge(tx.type)),
                                  DataCell(
                                    isWithdrawalRequest && !isPaid
                                      ? ElevatedButton(
                                          onPressed: () => _markAsPaid(context, tx.txId),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            elevation: 0,
                                          ),
                                          child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
                                        )
                                      : const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final bool isCredit = type.toLowerCase() == 'credit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: isCredit ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.file_download_outlined),
      label: const Text('EXPORT DATA'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF004D40),
        side: const BorderSide(color: Color(0xFF004D40), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );
  }
}
