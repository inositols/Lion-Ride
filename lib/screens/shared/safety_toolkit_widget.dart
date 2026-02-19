import 'package:flutter/material.dart';
import '../../core/services/safety_service.dart';
import '../../models/ride_model.dart';
import '../../models/base_user_model.dart';

class SafetyToolkitWidget extends StatelessWidget {
  final RideModel ride;
  final BaseUserModel? driver;

  const SafetyToolkitWidget({
    super.key,
    required this.ride,
    this.driver,
  });

  void _showSafetySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => buildSafetySheet(context),
    );
  }

  Widget buildSafetySheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Safety Toolkit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildOption(
            context,
            icon: Icons.share,
            color: Colors.blue,
            label: 'Share Trip Details',
            onTap: () {
              Navigator.pop(context);
              if (driver != null) {
                SafetyService.shareTripDetails(ride: ride, driver: driver!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Driver details not available')),
                );
              }
            },
          ),
          _buildOption(
            context,
            icon: Icons.phone,
            color: Colors.red,
            label: 'Call Campus Security',
            onTap: () {
              Navigator.pop(context);
              SafetyService.callEmergency();
            },
          ),
          _buildOption(
            context,
            icon: Icons.report,
            color: Colors.orange,
            label: 'Report Issue',
            onTap: () {
              Navigator.pop(context);
              // Implementation for reporting
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report feature coming soon')),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'safety_toolkit_fab',
      onPressed: () => _showSafetySheet(context),
      backgroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.security, color: Colors.blue),
    );
  }
}
