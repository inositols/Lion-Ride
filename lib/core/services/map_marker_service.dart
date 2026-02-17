import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerService {
  static Future<BitmapDescriptor> loadBikeIcon() async {
    // Load asset and resize it
    final ByteData data = await rootBundle.load('assets/images/bike_top_down.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 100, // Resize to 100px width as requested
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? resizedData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    
    if (resizedData == null) {
      return BitmapDescriptor.defaultMarker;
    }
    
    return BitmapDescriptor.fromBytes(resizedData.buffer.asUint8List());
  }

  static double calculateBearing(LatLng start, LatLng end) {
    double lat1 = start.latitude * pi / 180;
    double lng1 = start.longitude * pi / 180;
    double lat2 = end.latitude * pi / 180;
    double lng2 = end.longitude * pi / 180;

    double dLon = lng2 - lng1;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double radiansBearing = atan2(y, x);

    // Convert to degrees and normalize to 0-360
    return (radiansBearing * 180 / pi + 360) % 360;
  }
}
