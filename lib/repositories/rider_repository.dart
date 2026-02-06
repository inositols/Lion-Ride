import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';

class RiderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of pending ride requests (status: 'searching')
  Stream<List<RideModel>> getIncomingRequests() {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: 'searching')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update rider online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _firestore.collection('users').doc(userId).update({
      'isOnline': isOnline,
    });
  }

  // Accept a ride request
  Future<void> acceptRide(String rideId, String riderId) async {
    final rideRef = _firestore.collection('rides').doc(rideId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);
      if (!snapshot.exists) throw Exception('Ride does not exist');
      
      final data = snapshot.data()!;
      if (data['status'] != 'searching') {
        throw Exception('Ride already taken or cancelled');
      }

      transaction.update(rideRef, {
        'status': 'ongoing',
        'rider_id': riderId,
      });
    });
  }

  // Complete a ride
  Future<void> completeRide(String rideId) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': 'completed',
    });
  }
}
