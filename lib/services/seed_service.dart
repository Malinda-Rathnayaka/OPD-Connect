import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SeedService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ===========================================================================
  // ADMIN CREDENTIALS CONFIGURATION
  // Reads values dynamically from the .env file in the project root directory.
  // Fallback defaults are provided if .env variables are missing.
  // ===========================================================================
  static String get adminEmail =>
      dotenv.env['ADMIN_EMAIL'] ?? "admin@opdconnect.lk";

  static String get adminPassword =>
      dotenv.env['ADMIN_PASSWORD'] ?? "AdminPassword123!";

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
          'email': adminEmail,
          'name': 'Hospital IT Admin',
          'role': 'admin',
          'isVerified': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Sign out immediately so auto-login doesn't bypass onboarding/login screen
        await _auth.signOut();

        debugPrint("Admin account created successfully: $adminEmail");
      }
    } catch (e) {
      debugPrint("Admin seed check finished: ${e.toString()}");
    }
  }
}