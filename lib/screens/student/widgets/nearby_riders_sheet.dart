import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nsuride_mobile/logic/location/location_bloc.dart';
import '../../../models/rider_model.dart';

class NearbyRidersSheet extends StatelessWidget {
  final List<RiderModel> riders;
  final LatLng studentPos;
  final Function(RiderModel) onRiderTap;
  final Function(LocationState) onRequestTap;
  final LocationState locState;

  const NearbyRidersSheet({
    super.key,
    required this.riders,
    required this.studentPos,
    required this.onRiderTap,
    required this.onRequestTap,
    required this.locState,
  });

  @override
  Widget build(BuildContext context) {
    // Sort riders by distance
    final sortedRiders = List<RiderModel>.from(riders);
    sortedRiders.sort((a, b) {
      if (a.lastLocation == null || b.lastLocation == null) return 0;
      final distA = Geolocator.distanceBetween(
        studentPos.latitude,
        studentPos.longitude,
        a.lastLocation!.latitude,
        a.lastLocation!.longitude,
      );
      final distB = Geolocator.distanceBetween(
        studentPos.latitude,
        studentPos.longitude,
        b.lastLocation!.latitude,
        b.lastLocation!.longitude,
      );
      return distA.compareTo(distB);
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.electric_bike, color: Color(0xFF004D40)),
                    const SizedBox(width: 10),
                    Text(
                      'Nearby Riders (${riders.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: sortedRiders.length,
                  itemBuilder: (context, index) {
                    final rider = sortedRiders[index];
                    final distance = rider.lastLocation != null
                        ? Geolocator.distanceBetween(
                                studentPos.latitude,
                                studentPos.longitude,
                                rider.lastLocation!.latitude,
                                rider.lastLocation!.longitude,
                              ) /
                              1000 // In KM
                        : 0.0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[100]!),
                      ),
                      child: ListTile(
                        onTap: () => onRiderTap(rider),
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF004D40,
                          ).withOpacity(0.1),
                          child: Text(
                            rider.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF004D40),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              rider.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (rider.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${rider.plateNumber ?? "No Plate"} • ${distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => onRequestTap(locState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF004D40),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Request',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
