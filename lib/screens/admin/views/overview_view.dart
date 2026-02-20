import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class OverviewView extends StatelessWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 40),
          _buildMetricCards(context),
          const SizedBox(height: 40),
          _buildMainSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF004D40),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track platform growth and financial performance',
          style: GoogleFonts.inter(color: Colors.black54, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMetricCards(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('system').doc('platform_fees').snapshots(),
      builder: (context, snapshot) {
        final feesData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final double platformEarnings = (feesData['total_earnings'] ?? 0.0).toDouble();

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            _MetricCard(
              title: 'Total Revenue',
              value: '₦${NumberFormat('#,###').format(platformEarnings)}',
              icon: Icons.payments_outlined,
              color: const Color(0xFF004D40),
              trend: '+12.5%',
              isPositive: true,
            ),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('rides').where('status', isEqualTo: 'ongoing').get(),
              builder: (context, snap) => _MetricCard(
                title: 'Active Rides',
                value: snap.data?.docs.length.toString() ?? '...',
                icon: Icons.local_taxi_outlined,
                color: const Color(0xFF2196F3),
                trend: 'Live',
                isPositive: true,
              ),
            ),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'rider')
                  .where('documents_uploaded', isEqualTo: true)
                  .where('is_verified', isEqualTo: false)
                  .get(),
              builder: (context, snap) => _MetricCard(
                title: 'Pending Approvals',
                value: snap.data?.docs.length.toString() ?? '...',
                icon: Icons.verified_user_outlined,
                color: const Color(0xFFFF9800),
                trend: 'Action Needed',
                isPositive: false,
              ),
            ),
            FutureBuilder<AggregateQuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').count().get(),
              builder: (context, snap) => _MetricCard(
                title: 'Total Users',
                value: snap.data?.count?.toString() ?? '...',
                icon: Icons.people_outline,
                color: const Color(0xFFE91E63),
                trend: '+4%',
                isPositive: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainSection(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 1200;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildRevenueChart(),
        ),
        if (isDesktop) ...[
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _buildRecentActivity(),
          ),
        ],
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend (Last 7 Days)',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF004D40),
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value >= 0 && value < 7) {
                          return Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 12));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5000,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) => Text('₦${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 5000),
                      FlSpot(1, 8000),
                      FlSpot(2, 6000),
                      FlSpot(3, 12000),
                      FlSpot(4, 9000),
                      FlSpot(5, 15000),
                      FlSpot(6, 11000),
                    ],
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFF004D40), Color(0xFF00897B)]),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF004D40).withOpacity(0.2),
                          const Color(0xFF004D40).withOpacity(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Rides',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF004D40),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('rides').orderBy('timestamp', descending: true).limit(5).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7FA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['riderName'] ?? 'Ride completed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text(data['studentName'] ?? 'Platform ride', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text('₦${data['fare'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF004D40))),
                      ],
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isPositive;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF004D40),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
