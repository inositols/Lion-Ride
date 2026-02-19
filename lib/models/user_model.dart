import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/encryption_service.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final double walletBalance;
  final bool isOnline;
  final GeoPoint? lastLocation;
  final String? fcmToken;

  // Verification Flags
  final bool isPhoneVerified;
  final bool isFaceVerified;
  final bool documentsUploaded;
  final bool isVerified; // Overall admin approval

  // Document & Info
  final String? ninUrl;
  final String? bikePapersUrl;
  final String? guarantorName;
  final String? guarantorPhone;
  final String? phoneNumber;
  final String? plateNumber;
  final String? unionNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.walletBalance = 0.0,
    this.isOnline = false,
    this.lastLocation,
    this.fcmToken,
    this.isPhoneVerified = false,
    this.isFaceVerified = false,
    this.documentsUploaded = false,
    this.isVerified = false,
    this.ninUrl,
    this.bikePapersUrl,
    this.guarantorName,
    this.guarantorPhone,
    this.phoneNumber,
    this.plateNumber,
    this.unionNumber,
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
      'is_phone_verified': isPhoneVerified,
      'is_face_verified': isFaceVerified,
      'documents_uploaded': documentsUploaded,
      'is_verified': isVerified,
      'nin_url': EncryptionService.encrypt(ninUrl),
      'bike_papers_url': EncryptionService.encrypt(bikePapersUrl),
      'guarantor_name': guarantorName,
      'guarantor_phone': EncryptionService.encrypt(guarantorPhone),
      'phone_number': EncryptionService.encrypt(phoneNumber),
      'plate_number': EncryptionService.encrypt(plateNumber),
      'union_number': unionNumber,
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
      isPhoneVerified: map['is_phone_verified'] ?? false,
      isFaceVerified: map['is_face_verified'] ?? false,
      documentsUploaded: map['documents_uploaded'] ?? false,
      isVerified: map['is_verified'] ?? false,
      ninUrl: EncryptionService.decrypt(map['nin_url']),
      bikePapersUrl: EncryptionService.decrypt(map['bike_papers_url']),
      guarantorName: map['guarantor_name'],
      guarantorPhone: EncryptionService.decrypt(map['guarantor_phone']),
      phoneNumber: EncryptionService.decrypt(map['phone_number']),
      plateNumber: EncryptionService.decrypt(map['plate_number']),
      unionNumber: map['union_number'],
    );
  }

  UserModel copyWith({
    String? name,
    double? walletBalance,
    bool? isOnline,
    GeoPoint? lastLocation,
    String? fcmToken,
    bool? isPhoneVerified,
    bool? isFaceVerified,
    bool? documentsUploaded,
    bool? isVerified,
    String? ninUrl,
    String? bikePapersUrl,
    String? guarantorName,
    String? guarantorPhone,
    String? phoneNumber,
    String? plateNumber,
    String? unionNumber,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role,
      walletBalance: walletBalance ?? this.walletBalance,
      isOnline: isOnline ?? this.isOnline,
      lastLocation: lastLocation ?? this.lastLocation,
      fcmToken: fcmToken ?? this.fcmToken,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
      documentsUploaded: documentsUploaded ?? this.documentsUploaded,
      isVerified: isVerified ?? this.isVerified,
      ninUrl: ninUrl ?? this.ninUrl,
      bikePapersUrl: bikePapersUrl ?? this.bikePapersUrl,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorPhone: guarantorPhone ?? this.guarantorPhone,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      plateNumber: plateNumber ?? this.plateNumber,
      unionNumber: unionNumber ?? this.unionNumber,
    );
  }
}
