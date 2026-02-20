import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/rider_model.dart';

class VerificationCenterView extends StatelessWidget {
  const VerificationCenterView({super.key});

  void _showDocumentPreview(BuildContext context, String title, String? url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(title, style: GoogleFonts.outfit(color: const Color(0xFF004D40), fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: url != null && url.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(child: Text('Failed to load image')),
                          ),
                        )
                      : const Center(child: Text('No document uploaded')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveRider(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_verified': true,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rider Approved Successfully'), backgroundColor: Colors.green),
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
          Text(
            'Verification Center',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review and approve rider applications',
            style: GoogleFonts.inter(color: Colors.black54),
          ),
          const SizedBox(height: 40),
          
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
                      .collection('users')
                      .where('role', isEqualTo: 'rider')
                      .where('is_verified', isEqualTo: false)
                      .where('documents_uploaded', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final riders = snapshot.data?.docs.map((d) => 
                      RiderModel.fromMap(d.data() as Map<String, dynamic>)
                    ).toList() ?? [];

                    if (riders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_outlined, size: 64, color: Colors.grey[200]),
                            const SizedBox(height: 16),
                            Text('All clear! No pending verifications.', style: GoogleFonts.inter(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 340),
                          child: DataTable(
                            headingRowHeight: 60,
                            dataRowMaxHeight: 80,
                            headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
                            columns: const [
                              DataColumn(label: Text('NAME')),
                              DataColumn(label: Text('PLATE NUMBER')),
                              DataColumn(label: Text('DOCUMENTS')),
                              DataColumn(label: Text('GUARANTOR')),
                              DataColumn(label: Text('ACTIONS')),
                            ],
                            rows: riders.map((rider) => DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      const CircleAvatar(radius: 16, backgroundColor: Color(0xFFF5F7F9), child: Icon(Icons.person, size: 16, color: Color(0xFF004D40))),
                                      const SizedBox(width: 12),
                                      Text(rider.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(rider.plateNumber ?? 'N/A')),
                                DataCell(
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showDocumentPreview(context, 'NIN: ${rider.name}', rider.ninUrl),
                                        icon: const Icon(Icons.badge_outlined, size: 14),
                                        label: const Text('NIN', style: TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => _showDocumentPreview(context, 'Papers: ${rider.name}', rider.bikePapersUrl),
                                        icon: const Icon(Icons.description_outlined, size: 14),
                                        label: const Text('Papers', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(rider.guarantorName ?? 'N/A', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text(rider.guarantorPhone ?? 'N/A', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () => _approveRider(context, rider.uid),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF004D40),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('APPROVE'),
                                  ),
                                ),
                              ],
                            )).toList(),
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
}
