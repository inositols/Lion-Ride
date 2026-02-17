import 'package:flutter/material.dart';

class RiderStatusCard extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;

  const RiderStatusCard({
    super.key,
    required this.isOnline,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFFE0F2F1) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? const Color(0xFF004D40) : Colors.amber[800]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOnline ? const Color(0xFF004D40) : Colors.amber[800],
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  isOnline ? 'Searching for trips...' : 'Go online to receive trips',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOnline,
            activeColor: const Color(0xFF004D40),
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
