import 'package:cloud_firestore/cloud_firestore.dart';

class RideModel {
  final String rideId;
  final String studentId;
  final String? riderId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String pickupAddress;
  final String dropoffAddress;
  final double cost;
  final String status; // 'searching' | 'ongoing' | 'completed' | 'cancelled'
  final DateTime timestamp;
  final bool isPaid;
  final String paymentMethod; // 'wallet' | 'cash'

  RideModel({
    required this.rideId,
    required this.studentId,
    this.riderId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.cost,
    required this.status,
    required this.timestamp,
    this.isPaid = false,
    this.paymentMethod = 'wallet',
  });

  Map<String, dynamic> toMap() {
    return {
      'ride_id': rideId,
      'student_id': studentId,
      'rider_id': riderId,
      'pickup_latlng': GeoPoint(pickupLat, pickupLng),
      'dropoff_latlng': GeoPoint(dropoffLat, dropoffLng),
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'cost': cost,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_paid': isPaid,
      'payment_method': paymentMethod,
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map, String id) {
    GeoPoint pickup = map['pickup_latlng'];
    GeoPoint dropoff = map['dropoff_latlng'];
    
    return RideModel(
      rideId: id,
      studentId: map['student_id'] ?? '',
      riderId: map['rider_id'],
      pickupLat: pickup.latitude,
      pickupLng: pickup.longitude,
      dropoffLat: dropoff.latitude,
      dropoffLng: dropoff.longitude,
      pickupAddress: map['pickup_address'] ?? '',
      dropoffAddress: map['dropoff_address'] ?? '',
      cost: (map['cost'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'searching',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isPaid: map['is_paid'] ?? false,
      paymentMethod: map['payment_method'] ?? 'wallet',
    );
  }
}
