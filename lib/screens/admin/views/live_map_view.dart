import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMapView extends StatefulWidget {
  const LiveMapView({super.key});

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  GoogleMapController? _mapController;

  // Default campus center (Example: Obafemi Awolowo University)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(7.5218, 4.5222),
    zoom: 15.0,
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMap(),
        _buildLegend(),
      ],
    );
  }

  Widget _buildMap() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'rider').where('is_online', isEqualTo: true).snapshots(),
      builder: (context, ridersSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rides').where('status', whereIn: ['ongoing', 'searching']).snapshots(),
          builder: (context, ridesSnapshot) {
            final markers = _calculateMarkers(ridersSnapshot.data?.docs ?? [], ridesSnapshot.data?.docs ?? []);
            
            return GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) => _mapController = controller,
              markers: markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapType: MapType.normal,
            );
          },
        );
      },
    );
  }

  Set<Marker> _calculateMarkers(List<DocumentSnapshot> riders, List<DocumentSnapshot> rides) {
    final Set<Marker> newMarkers = {};

    // 1. Add Online Riders (Blue)
    for (var doc in riders) {
      final data = doc.data() as Map<String, dynamic>;
      final pos = data['location'] as Map<String, dynamic>?;
      if (pos != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('rider_${doc.id}'),
            position: LatLng(pos['latitude'], pos['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(title: data['name'] ?? 'Rider', snippet: 'Status: Online'),
          ),
        );
      }
    }

    // 2. Add Active/Searching Rides (Green/Red)
    for (var doc in rides) {
      final data = doc.data() as Map<String, dynamic>;
      final pickup = data['pickup_location'] as Map<String, dynamic>?;
      final dropoff = data['dropoff_location'] as Map<String, dynamic>?;
      final status = data['status'];

      if (pickup != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('pickup_${doc.id}'),
            position: LatLng(pickup['latitude'], pickup['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(title: 'Pickup: ${data['studentName']}', snippet: 'Ride ID: ${doc.id}'),
          ),
        );
      }

      if (dropoff != null && status == 'ongoing') {
        newMarkers.add(
          Marker(
            markerId: MarkerId('dropoff_${doc.id}'),
            position: LatLng(dropoff['latitude'], dropoff['longitude']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(title: 'Dropoff Target', snippet: 'Ride ID: ${doc.id}'),
          ),
        );
      }
    }

    return newMarkers;
  }

  Widget _buildLegend() {
    return Positioned(
      top: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('LEGEND', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF004D40))),
            const SizedBox(height: 12),
            _legendItem(Colors.blue, 'Online Riders'),
            const SizedBox(height: 8),
            _legendItem(Colors.green, 'Pickups / Searching'),
            const SizedBox(height: 8),
            _legendItem(Colors.red, 'Active Dropoffs'),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}
