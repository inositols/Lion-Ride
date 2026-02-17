import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show debugPrint;

class VerificationRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Step 1: Phone Verification
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String code, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<void> linkPhoneToAccount(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePhoneNumber(credential);
      await _firestore.collection('users').doc(user.uid).update({
        'is_phone_verified': true,
        'phone_number': user.phoneNumber,
      });
    }
  }

  // Step 2: Face Verification Update
  Future<void> markFaceVerified() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'is_face_verified': true,
      });
    }
  }

  // Step 3: Document Upload
  Future<String> uploadVerificationDoc(File file, String type) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    
    // Check if file is valid
    if (!await file.exists()) {
      debugPrint('File not found: ${file.path}');
      throw Exception('File does not exist: ${file.path}');
    }
    
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      debugPrint('File is empty: ${file.path}');
      throw Exception('File is empty');
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$type.jpg';
    final ref = _storage.ref().child('verification_docs/$uid/$fileName');
    
    debugPrint('Uploading to: ${ref.fullPath}');
    
    try {
      // Use putData for better reliability with temporary picker files
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = ref.putData(bytes, metadata);
      
      // Wait for task completion
      final snapshot = await uploadTask;
      debugPrint('Upload complete. State: ${snapshot.state}');

      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      // Retry mechanism for getDownloadURL
      String? url;
      int retries = 0;
      while (retries < 5) {
        try {
          url = await ref.getDownloadURL();
          debugPrint('Successfully got download URL: $url');
          break;
        } catch (e) {
          retries++;
          debugPrint('getDownloadURL retry $retries (failed: $e)');
          await Future.delayed(Duration(seconds: retries)); // Exponential backoff
        }
      }

      if (url == null) throw Exception('Failed to get download URL after retries');

      // Update Firestore
      final fieldName = type == 'nin' ? 'nin_url' : 'bike_papers_url';
      await _firestore.collection('users').doc(uid).update({
        fieldName: url,
      });
      debugPrint('Firestore updated with $fieldName');

      return url;
    } catch (e) {
      debugPrint('Storage Upload Error: $e');
      rethrow;
    }
  }

  Future<void> finalizeDocumentUpload() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'documents_uploaded': true,
      });
    }
  }

  // Step 4: Guarantor
  Future<void> submitGuarantorDetails(String name, String phone) async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'guarantor_name': name,
        'guarantor_phone': phone,
      });
    }
  }
}
