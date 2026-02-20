import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/rider_model.dart';

class VerificationView extends StatelessWidget {
  const VerificationView({super.key});

  void _showDocumentDialog(BuildContext context, RiderModel rider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verification: ${rider.name}', style: GoogleFonts.outfit()),
        content: SizedBox(
          width: 800,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection('Rider Info', {
                  'Name': rider.name,
                  'Phone': rider.phoneNumber ?? 'N/A',
                  'Email': rider.email,
                  'Plate': rider.plateNumber ?? 'N/A',
                  'Union': rider.unionNumber ?? 'N/A',
                }),
                const SizedBox(height: 24),
                _buildInfoSection('Guarantor Info', {
                  'Name': rider.guarantorName ?? 'N/A',
                  'Phone': rider.guarantorPhone ?? 'N/A',
                }),
                const SizedBox(height: 24),
                Text('Proof of Identity (NIN)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildImagePreview(rider.ninUrl),
                const SizedBox(height: 24),
                Text('Bike Ownership Papers', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildImagePreview(rider.bikePapersUrl),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _updateVerificationStatus(context, rider.uid, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                    child: const Text('REJECT'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _updateVerificationStatus(context, rider.uid, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('APPROVE RIDER'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateVerificationStatus(BuildContext context, String uid, bool approve) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'is_verified': approve,
        'documents_uploaded': approve ? true : false, // Reset if rejected to allow re-upload
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Rider Approved Successfully' : 'Rider Rejected'),
            backgroundColor: approve ? Colors.green : Colors.orange,
          ),
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

  Widget _buildInfoSection(String title, Map<String, String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF004D40))),
        const Divider(),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: details.entries.map((e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.key, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              Text(e.value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildImagePreview(String? url) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: url != null && url.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(child: Text('Image failed to load')),
              ),
            )
          : const Center(child: Text('No Image Provided')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
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
            'Pending rider approvals',
            style: GoogleFonts.inter(color: Colors.black54),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'rider')
                  .where('documents_uploaded', isEqualTo: true)
                  .where('is_verified', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final riders = snapshot.data?.docs.map((d) => RiderModel.fromMap(d.data() as Map<String, dynamic>)).toList() ?? [];
                
                if (riders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No pending verifications', style: GoogleFonts.inter(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: riders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final rider = riders[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFF5F7F9),
                          child: Icon(Icons.person, color: Color(0xFF004D40)),
                        ),
                        title: Text(rider.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        subtitle: Text('${rider.plateNumber ?? 'No Plate'} • ${rider.phoneNumber ?? 'No Phone'}'),
                        trailing: OutlinedButton(
                          onPressed: () => _showDocumentDialog(context, rider),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF004D40)),
                          ),
                          child: const Text('REVIEW DOCUMENTS'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
