import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/base_user_model.dart';
import '../models/student_model.dart';
import '../models/rider_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get the current authenticated user's profile from Firestore
  Future<BaseUserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return BaseUserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Sign In with Email and Password
  Future<BaseUserModel> signIn(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userProfile = await getUserProfile(userCredential.user!.uid);
      if (userProfile == null) {
        throw 'User profile not found in database.';
      }
      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Sign Up with Email, Password, Name, and Role
  Future<BaseUserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phoneNumber,
    String? plateNumber,
    String? unionNumber,
  }) async {
    if (role == 'rider') {
      if (plateNumber == null || plateNumber.trim().isEmpty) {
        throw 'Plate number is required for riders.';
      }
      if (unionNumber == null || unionNumber.trim().isEmpty) {
        throw 'Association/Union number is required for riders.';
      }
    }
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      BaseUserModel newUser;
      if (role == 'rider') {
        newUser = RiderModel(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          role: role,
          phoneNumber: phoneNumber,
          plateNumber: plateNumber,
          unionNumber: unionNumber,
        );
      } else {
        newUser = StudentModel(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
          role: role,
          phoneNumber: phoneNumber,
        );
      }

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw _handleException(e);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Update FCM Token in Firestore
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'fcm_token': token,
      });
    } catch (e) {
      // We don't want to throw here as it's a background task usually,
      // but we should log it.
      print('Error updating FCM token: $e');
    }
  }

  /// Stream of Auth State Changes
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  String _handleFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }

  String _handleException(dynamic e) {
    return e.toString();
  }
}
