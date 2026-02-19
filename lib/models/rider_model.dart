import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_user_model.dart';
import '../core/services/encryption_service.dart';

class RiderModel extends BaseUserModel {
  final String? plateNumber;
  final String? unionNumber;
  final bool isFaceVerified;
  final bool documentsUploaded;
  final bool isVerified;
  final String? ninUrl;
  final String? bikePapersUrl;
  final String? guarantorName;
  final String? guarantorPhone;

  RiderModel({
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
    this.plateNumber,
    this.unionNumber,
    this.isFaceVerified = false,
    this.documentsUploaded = false,
    this.isVerified = false,
    this.ninUrl,
    this.bikePapersUrl,
    this.guarantorName,
    this.guarantorPhone,
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
      'plate_number': EncryptionService.encrypt(plateNumber),
      'union_number': unionNumber,
      'is_face_verified': isFaceVerified,
      'documents_uploaded': documentsUploaded,
      'is_verified': isVerified,
      'nin_url': EncryptionService.encrypt(ninUrl),
      'bike_papers_url': EncryptionService.encrypt(bikePapersUrl),
      'guarantor_name': guarantorName,
      'guarantor_phone': EncryptionService.encrypt(guarantorPhone),
    };
  }

  factory RiderModel.fromMap(Map<String, dynamic> map) {
    return RiderModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'rider',
      walletBalance: (map['wallet_balance'] ?? 0.0).toDouble(),
      isOnline: map['is_online'] ?? false,
      lastLocation: map['last_location'] as GeoPoint?,
      fcmToken: map['fcm_token'],
      phoneNumber: EncryptionService.decrypt(map['phone_number']),
      isPhoneVerified: map['is_phone_verified'] ?? false,
      plateNumber: EncryptionService.decrypt(map['plate_number']),
      unionNumber: map['union_number'],
      isFaceVerified: map['is_face_verified'] ?? false,
      documentsUploaded: map['documents_uploaded'] ?? false,
      isVerified: map['is_verified'] ?? false,
      ninUrl: EncryptionService.decrypt(map['nin_url']),
      bikePapersUrl: EncryptionService.decrypt(map['bike_papers_url']),
      guarantorName: map['guarantor_name'],
      guarantorPhone: EncryptionService.decrypt(map['guarantor_phone']),
    );
  }
}
