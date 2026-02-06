import 'package:url_launcher/url_launcher.dart';

class SafetyService {
  // UNN Campus Security or Trusted Contact
  static const String emergencyNumber = "0800-UNN-SECURE"; // Placeholder
  static const String emergencySMS = "08001234567";

  static Future<void> triggerSOS(String studentName, String? location) async {
    final String message =
        "EMERGENCY: Rider SOS from $studentName at $location. Please send help!";
    final Uri smsUri = Uri.parse(
      "sms:$emergencySMS?body=${Uri.encodeComponent(message)}",
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }
  }

  static Future<void> callSecurity() async {
    final Uri callUri = Uri.parse("tel:$emergencyNumber");
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}
