import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final double walletBalance;
  final bool isOnline;
  final GeoPoint? lastLocation;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.walletBalance = 0.0,
    this.isOnline = false,
    this.lastLocation,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'wallet_balance': walletBalance,
      'is_online': isOnline,
      'last_location': lastLocation,
      'fcm_token': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      walletBalance: (map['wallet_balance'] ?? 0.0).toDouble(),
      isOnline: map['is_online'] ?? false,
      lastLocation: map['last_location'] as GeoPoint?,
      fcmToken: map['fcm_token'],
    );
  }
}
