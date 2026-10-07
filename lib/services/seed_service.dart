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

  static Future<void> seedHospitalsAndDoctors() async {
    try {
      final hospitals = <Map<String, dynamic>>[
        {
          'id': 'colombo-national',
          'name': 'Colombo National Hospital',
          'district': 'Colombo',
          'city': 'Colombo',
          'address': 'Colombo 10, Sri Lanka',
          'distance': 2.3,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'ENT', 'Cardiology', 'Pediatrics'],
          'phone': '+94 11 269 1111',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        },
      ];

      final batch = _db.batch();
      final hospitalDepartmentMap = {
        'General Medicine': ['Dr. Perera', 'Dr. Silva', 'Dr. Jayawardena'],
        'Dental': ['Dr. Fernando', 'Dr. Gunasekara', 'Dr. Weerasinghe'],
        'Eye Clinic': ['Dr. Kularatne', 'Dr. Wickramasinghe', 'Dr. Senanayake'],
        'ENT': ['Dr. Rajapaksa', 'Dr. Dissanayake', 'Dr. Mendis'],
        'Cardiology': ['Dr. Dias', 'Dr. Bandara', 'Dr. Nimal'],
        'Pediatrics': ['Dr. Seneviratne', 'Dr. Ranasinghe', 'Dr. Karunaratne'],
      };

      final hospitalNames = <String>[];
      final now = Timestamp.now();

      for (int index = 0; index < hospitals.length; index++) {
        final hospital = hospitals[index];
        final hospitalId = hospital['id'] as String? ?? 'colombo-national';
        final hospitalData = {
          'name': hospital['name'],
          'district': hospital['district'],
          'city': hospital['city'],
          'address': hospital['address'],
          'distance': hospital['distance'],
          'isOpen': hospital['isOpen'],
          'clinics': hospital['clinics'],
          'phone': hospital['phone'],
          'nextSession': hospital['nextSession'],
        };

        hospitalNames.add(hospital['name'] as String);
        batch.set(
          _db.collection('hospitals').doc(hospitalId),
          hospitalData,
          SetOptions(merge: true),
        );

        final clinics = List<String>.from(hospital['clinics'] as List);
        for (int doctorIndex = 0; doctorIndex < 3; doctorIndex++) {
          final department = clinics[doctorIndex % clinics.length];
          final doctorName = hospitalDepartmentMap[department]![doctorIndex];
          final doctorId = 'doctor-${index + 1}-${doctorIndex + 1}';

          final doctorData = {
            'fullName': doctorName,
            'department': department,
            'hospitalId': hospitalId,
            'hospitalName': hospital['name'],
            'isOnDuty': true,
            'avgWaitTime': [15, 20, 10][doctorIndex % 3],
            'patientRating': [4.9, 4.7, 4.5][doctorIndex % 3],
            'availableSlots': [
              'Mon, 22 Sep',
              'Tue, 23 Sep',
              'Wed, 24 Sep',
            ],
            'createdAt': now,
          };

          batch.set(
            _db.collection('doctors').doc(doctorId),
            doctorData,
            SetOptions(merge: true),
          );
        }
      }

      await batch.commit();

      debugPrint(
        'Hospitals and doctors seeded successfully: ${hospitals.length} hospitals, ${hospitals.length * 3} doctors',
      );
    } catch (e) {
      debugPrint('Error seeding hospitals and doctors: $e');
    }
  }
}