import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String name;
  final LatLng location;

  Place({required this.name, required this.location});
}

class LocationRepository {
  // UNN Main Gate coordinates as fallback
  static const LatLng unnMainGate = LatLng(6.8671, 7.4057);

  /// Mock Nsukka Landmarks for search
  static final List<Place> mockLandmarks = [
    Place(name: "Odenigwe Gate", location: const LatLng(6.8672, 7.4116)),
    Place(name: "Ziks Flats", location: const LatLng(6.8594, 7.4068)),
    Place(name: "Hilltop", location: const LatLng(6.8725, 7.4032)),
    Place(name: "Green House", location: const LatLng(6.8660, 7.4080)),
    Place(name: "Franco Hostel", location: const LatLng(6.8620, 7.4120)),
    Place(name: "CEC UNN", location: const LatLng(6.8645, 7.4095)),
    Place(name: "UNN Stadium", location: const LatLng(6.8610, 7.4050)),
    Place(name: "Main Gate UNN", location: unnMainGate),
  ];

  /// Get Current Position with permission handling
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Location services are disabled.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permissions are permanently denied.';
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Search for landmarks
  List<Place> searchLandmarks(String query) {
    if (query.isEmpty) return [];
    return mockLandmarks
        .where((place) => place.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Decode/Generate Polyline (Mocked line for now)
  List<LatLng> getRoutePolyline(LatLng start, LatLng end) {
    // In a real app, use flutter_polyline_points to decode the string from Google Directions API
    return [start, end];
  }

  /// Calculate distance between two points in km
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) / 1000;
  }
}
