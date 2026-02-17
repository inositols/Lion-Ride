import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/ride_model.dart';
import '../../models/user_model.dart';

class SafetyService {
  static const String emergencyNumber = "112"; // Or UNN Security: "080..."

  static Future<void> callEmergency() async {
    final Uri url = Uri.parse("tel:$emergencyNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  static Future<void> shareTripDetails({
    required RideModel ride,
    required UserModel driver,
  }) async {
    final String text = 
      "I'm on an Nsuride trip! \n"
      "Driver: ${driver.name}\n"
      "Plate: ${driver.plateNumber ?? 'N/A'}\n"
      "Union No: ${driver.unionNumber ?? 'N/A'}\n"
      "Route: ${ride.pickupAddress} to ${ride.dropoffAddress}.";
    
    await Share.share(text);
  }

  // Pre-existing SOS trigger (referenced in StudentHome)
  static Future<void> triggerSOS(String studentName, String? location) async {
    // Implementation for SOS (e.g., sending to backend)
  }
}
