import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_user_model.dart';
import '../core/services/encryption_service.dart';

class StudentModel extends BaseUserModel {
  StudentModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.role,
    super.walletBalance,
    super.isOnline,
    super.lastLocation,
    super.fcmToken,
    super.phoneNumber,
    super.isPhoneVerified,
  });

  @override
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
      'phone_number': EncryptionService.encrypt(phoneNumber),
      'is_phone_verified': isPhoneVerified,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      walletBalance: (map['wallet_balance'] ?? 0.0).toDouble(),
      isOnline: map['is_online'] ?? false,
      lastLocation: map['last_location'] as GeoPoint?,
      fcmToken: map['fcm_token'],
      phoneNumber: EncryptionService.decrypt(map['phone_number']),
      isPhoneVerified: map['is_phone_verified'] ?? false,
    );
  }
}
