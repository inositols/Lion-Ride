import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/rider_model.dart';

class VerificationCenterView extends StatelessWidget {
  const VerificationCenterView({super.key});

  void _showReviewDialog(BuildContext context, RiderModel rider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _buildDialogHeader(context, rider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDocViewer('NIN Document', rider.ninUrl),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildDocViewer(
                          'Bike Papers',
                          rider.bikePapersUrl,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildDialogFooter(context, rider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, RiderModel rider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF5F7FA),
                child: Icon(Icons.person, color: Color(0xFF004D40)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider.name,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004D40),
                    ),
                  ),
                  Text(
                    rider.phoneNumber!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDocViewer(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: url != null && url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('Failed to load image')),
                    ),
                  )
                : const Center(child: Text('No document uploaded')),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogFooter(BuildContext context, RiderModel rider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () async {
              // Rejection logic could be more complex (e.g., reason), but for now simplified
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(rider.uid)
                  .update({'documents_uploaded': false, 'is_verified': false});
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text(
              'REJECT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(rider.uid)
                  .update({'is_verified': true});
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'APPROVE RIDER',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
            'Approve or reject rider applications',
            style: GoogleFonts.inter(color: Colors.black54, fontSize: 16),
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
                      .collection('users')
                      .where('role', isEqualTo: 'rider')
                      .where('is_verified', isEqualTo: false)
                      .where('documents_uploaded', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final riders =
                        snapshot.data?.docs
                            .map(
                              (d) => RiderModel.fromMap(
                                d.data() as Map<String, dynamic>,
                              ),
                            )
                            .toList() ??
                        [];

                    if (riders.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pending verifications',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 360,
                          ),
                          child: DataTable(
                            headingRowHeight: 64,
                            dataRowMaxHeight: 80,
                            columnSpacing: 24,
                            headingTextStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF004D40),
                            ),
                            columns: const [
                              DataColumn(label: Text('RIDER NAME')),
                              DataColumn(label: Text('PHONE')),
                              DataColumn(label: Text('PLATE')),
                              DataColumn(label: Text('GUARANTOR')),
                              DataColumn(label: Text('ACTION')),
                            ],
                            rows: riders
                                .map(
                                  (rider) => DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 16,
                                              backgroundColor: Color(
                                                0xFFF5F7FA,
                                              ),
                                              child: Icon(
                                                Icons.person,
                                                size: 16,
                                                color: Color(0xFF004D40),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              rider.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(rider.phoneNumber ?? 'N/A'),
                                      ),
                                      DataCell(
                                        Text(rider.plateNumber ?? 'N/A'),
                                      ),
                                      DataCell(
                                        Text(rider.guarantorName ?? 'N/A'),
                                      ),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: () =>
                                              _showReviewDialog(context, rider),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF004D40,
                                            ).withOpacity(0.05),
                                            foregroundColor: const Color(
                                              0xFF004D40,
                                            ),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Review Docs'),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
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
