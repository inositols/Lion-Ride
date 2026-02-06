import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nsuride_mobile/models/user_model.dart';
import '../models/ride_model.dart';

class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Student creates a ride request
  Future<void> createRideRequest(RideModel ride) async {
    await _firestore.collection('rides').doc(ride.rideId).set(ride.toMap());
  }

  // Student listens to their specific ride update
  Stream<RideModel?> streamRide(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return RideModel.fromMap(snapshot.data()!, snapshot.id);
    });
  }

  // Rider listens to all available rides (searching)
  Stream<List<RideModel>> streamOpenRides() {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'searching')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RideModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Handle trip status transitions: 'accepted', 'arrived', 'completed', 'cancelled'
  Future<void> updateRideStatus(
    String rideId,
    String status, {
    String? riderId,
  }) async {
    final Map<String, dynamic> data = {'status': status};
    if (riderId != null) {
      data['rider_id'] = riderId;
    }
    await _firestore.collection('rides').doc(rideId).update(data);
  }

  // Cancel ride
  Future<void> cancelRide(String rideId) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'cancelled',
    });
  }

  // --- NEW: Phase 9 Features ---

  // Update Rider's current location in real-time
  Future<void> updateRiderLocation(String riderId, GeoPoint position) async {
    await _firestore.collection('users').doc(riderId).update({
      'last_location': position,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  // Update Rider's online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _firestore.collection('users').doc(userId).update({
      'is_online': isOnline,
    });
  }

  // Watch a specific rider's location
  Stream<GeoPoint?> streamRiderLocation(String riderId) {
    return _firestore.collection('users').doc(riderId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return snapshot.data()?['last_location'] as GeoPoint?;
    });
  }

  // Fetch ride history for a user
  Stream<List<RideModel>> getRideHistory(String userId, String role) {
    final String field = role == 'student' ? 'student_id' : 'rider_id';
    return _firestore
        .collection('rides')
        .where(field, isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RideModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Stream all online riders for the "Ghost Riders" feature
  Stream<List<UserModel>> streamOnlineRiders() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'rider')
        .where('is_online', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            // Ensure UID is set from document ID if missing in data
            if (data['uid'] == null || (data['uid'] as String).isEmpty) {
              data['uid'] = doc.id;
            }
            return UserModel.fromMap(data);
          }).toList();
        });
  }
}
