import 'package:flutter/material.dart';

class RiderEarningsCard extends StatelessWidget {
  final String totalEarnings;
  final String totalTrips;

  const RiderEarningsCard({
    super.key,
    required this.totalEarnings,
    required this.totalTrips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEarningItem('Total Earnings', totalEarnings, Icons.account_balance_wallet),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildEarningItem('Total Trips', totalTrips, Icons.route),
        ],
      ),
    );
  }

  Widget _buildEarningItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
