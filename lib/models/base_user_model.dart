import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_model.dart';
import 'rider_model.dart';

abstract class BaseUserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final double walletBalance;
  final bool isOnline;
  final GeoPoint? lastLocation;
  final String? fcmToken;
  final String? phoneNumber;
  final bool isPhoneVerified;

  BaseUserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.walletBalance = 0.0,
    this.isOnline = false,
    this.lastLocation,
    this.fcmToken,
    this.phoneNumber,
    this.isPhoneVerified = false,
  });

  Map<String, dynamic> toMap();

  static BaseUserModel fromMap(Map<String, dynamic> map) {
    final role = map['role'] ?? 'student';
    if (role == 'rider') {
      return RiderModel.fromMap(map);
    } else {
      return StudentModel.fromMap(map);
    }
  }
}
