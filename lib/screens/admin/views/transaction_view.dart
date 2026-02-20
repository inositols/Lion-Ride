import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';

class TransactionView extends StatelessWidget {
  const TransactionView({super.key});

  void _markAsCompleted(BuildContext context, String txId) async {
    try {
      await FirebaseFirestore.instance.collection('transactions').doc(txId).update({
        'description': 'Withdrawal Completed', // Or update a status field if it exists
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal marked as completed'), backgroundColor: Colors.green),
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
      padding: const EdgeInsets.all(32),
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
                  Text(
                    'Full platform financial history',
                    style: GoogleFonts.inter(color: Colors.black54),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Export functionality
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('EXPORT CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF004D40),
                  side: const BorderSide(color: Color(0xFF004D40)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
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

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 40,
                          headingRowHeight: 60,
                          dataRowMaxHeight: 70,
                          headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                          columns: const [
                            DataColumn(label: Text('DATE')),
                            DataColumn(label: Text('DESCRIPTION')),
                            DataColumn(label: Text('TYPE')),
                            DataColumn(label: Text('AMOUNT')),
                            DataColumn(label: Text('USER ID')),
                            DataColumn(label: Text('ACTIONS')),
                          ],
                          rows: transactions.map((tx) {
                            final isWithdrawal = tx.description.contains('Bank Withdrawal Request');
                            final isCompleted = tx.description.contains('Completed');
                            
                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((states) {
                                if (isWithdrawal && !isCompleted) return Colors.orange.withValues(alpha: 0.05);
                                return null;
                              }),
                              cells: [
                                DataCell(Text(DateFormat('MMM dd, HH:mm').format(tx.timestamp))),
                                DataCell(Text(tx.description)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: tx.type == 'credit' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Text(
                                      tx.type.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        color: tx.type == 'credit' ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text('₦${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(tx.userId, style: const TextStyle(fontSize: 11, color: Colors.grey))),
                                DataCell(
                                  isWithdrawal && !isCompleted
                                    ? TextButton(
                                        onPressed: () => _markAsCompleted(context, tx.txId),
                                        child: const Text('MARK DONE'),
                                      )
                                    : const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                ),
                              ],
                            );
                          }).toList(),
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
}
