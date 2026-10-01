import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SeedService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const String adminEmail = "admin@opdconnect.lk";
  static const String adminPassword = "AdminPassword123!";

  static Future<void> seedAdminAccount() async {
    try {
      final query = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (query.docs.isEmpty) {
        UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        await _db.collection('users').doc(credential.user!.uid).set({
          'emailOrPhone': adminEmail,
          'name': 'Hospital IT Admin',
          'role': 'admin',
          'isVerified': true,
        });

        debugPrint("Admin account created: $adminEmail");
      }
    } catch (e) {
      debugPrint("Admin account check/seed completed.");
    }
  }
}