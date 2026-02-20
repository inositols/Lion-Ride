import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time metrics for Nsuride platform',
            style: GoogleFonts.inter(color: Colors.black54),
          ),
          const SizedBox(height: 40),
          
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('system').doc('platform_fees').snapshots(),
            builder: (context, snapshot) {
              final feesData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
              final double platformEarnings = (feesData['total_earnings'] ?? 0.0).toDouble();

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard(
                    title: 'Admin Earnings',
                    value: '₦ ${NumberFormat('#,###.00').format(platformEarnings)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF004D40),
                  ),
                  FutureBuilder<AggregateQuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('users').count().get(),
                    builder: (context, snap) => _buildStatCard(
                      title: 'Total Users',
                      value: snap.data?.count?.toString() ?? '...',
                      icon: Icons.group_rounded,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  FutureBuilder<AggregateQuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('rides').count().get(),
                    builder: (context, snap) => _buildStatCard(
                      title: 'Active Rides',
                      value: snap.data?.count?.toString() ?? '...',
                      icon: Icons.local_taxi_rounded,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'rider')
                        .where('documents_uploaded', isEqualTo: true)
                        .where('is_verified', isEqualTo: false)
                        .get(),
                    builder: (context, snap) => _buildStatCard(
                      title: 'Pending Verifications',
                      value: snap.data?.docs.length.toString() ?? '...',
                      icon: Icons.pending_rounded,
                      color: const Color(0xFFE91E63),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 48),
          
          Text(
            'Recent Platform Activity',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityItem('Rider Approval Needed', 'Jane Smith uploaded documents for review', 'Just now'),
                const Divider(height: 32),
                _buildActivityItem('New User Registration', 'Michael Obi joined as a student', '15 mins ago'),
                const Divider(height: 32),
                _buildActivityItem('System Update', 'Platform fee distribution successful', '1 hour ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, color: Color(0xFF004D40), size: 20),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
