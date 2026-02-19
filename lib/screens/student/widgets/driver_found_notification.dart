import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class DriverFoundNotification extends StatelessWidget {
  final String driverName;
  final double rating;
  final String vehicleInfo;
  final String? plateNumber;
  final VoidCallback onTrackTap;

  const DriverFoundNotification({
    super.key,
    required this.driverName,
    required this.rating,
    required this.vehicleInfo,
    this.plateNumber,
    required this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF004D40);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Animation
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 80,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Driver Found!',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: tealColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your rider is heading to you',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Driver Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                   Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: tealColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: tealColor, size: 35),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$rating',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vehicle Info
            Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
               decoration: BoxDecoration(
                 color: tealColor.withValues(alpha: 0.05),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    const Icon(Icons.directions_bike, color: tealColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      plateNumber != null ? '$vehicleInfo • $plateNumber' : vehicleInfo,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: tealColor,
                      ),
                    ),
                 ],
               ),
            ),
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTrackTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tealColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'TRACK DRIVER',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
