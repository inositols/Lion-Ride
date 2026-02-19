import 'package:flutter/material.dart';
import '../../../models/ride_model.dart';

class SearchingOverlay extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onCancel;

  const SearchingOverlay({
    super.key,
    required this.ride,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 30),
          const Text(
            'Searching for Drivers...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Offer: ₦${ride.cost.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text('CANCEL REQUEST'),
          ),
        ],
      ),
    );
  }
}
