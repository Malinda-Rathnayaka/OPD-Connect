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
          'name': 'Colombo National Hospital',
          'district': 'Colombo',
          'city': 'Colombo',
          'address': 'Colombo 10, Sri Lanka',
          'distance': 2.3,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'Cardiology', 'Pediatrics'],
          'phone': '+94 11 269 1111',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        },
        {
          'name': 'Sri Jayawardenepura General Hospital',
          'district': 'Colombo',
          'city': 'Nugegoda',
          'address': 'Sri Jayawardenepura Kotte, Sri Lanka',
          'distance': 6.8,
          'isOpen': true,
          'clinics': ['General Medicine', 'ENT', 'Cardiology'],
          'phone': '+94 11 276 0000',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        },
        {
          'name': 'Kalubowila Teaching Hospital',
          'district': 'Colombo',
          'city': 'Dehiwala',
          'address': 'Kalubowila, Dehiwala, Sri Lanka',
          'distance': 8.2,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'ENT'],
          'phone': '+94 11 273 4567',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 4))),
        },
        {
          'name': 'North Colombo Teaching Hospital',
          'district': 'Gampaha',
          'city': 'Ragama',
          'address': 'Ragama, Sri Lanka',
          'distance': 14.5,
          'isOpen': true,
          'clinics': ['General Medicine', 'Eye Clinic', 'ENT', 'Pediatrics'],
          'phone': '+94 11 295 1111',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        },
        {
          'name': 'Kandy National Hospital',
          'district': 'Kandy',
          'city': 'Kandy',
          'address': 'Kandy, Sri Lanka',
          'distance': 115.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'Cardiology', 'Pediatrics'],
          'phone': '+94 81 223 3333',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        },
        {
          'name': 'Peradeniya Teaching Hospital',
          'district': 'Kandy',
          'city': 'Peradeniya',
          'address': 'Peradeniya, Sri Lanka',
          'distance': 110.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'ENT'],
          'phone': '+94 81 238 1476',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        },
        {
          'name': 'Galle Karapitiya Teaching Hospital',
          'district': 'Galle',
          'city': 'Galle',
          'address': 'Karapitiya, Galle, Sri Lanka',
          'distance': 125.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Eye Clinic', 'ENT', 'Cardiology'],
          'phone': '+94 91 223 7777',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        },
        {
          'name': 'Jaffna Teaching Hospital',
          'district': 'Jaffna',
          'city': 'Jaffna',
          'address': 'Jaffna, Sri Lanka',
          'distance': 400.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'ENT', 'Pediatrics'],
          'phone': '+94 21 222 3333',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        },
        {
          'name': 'Batticaloa Teaching Hospital',
          'district': 'Batticaloa',
          'city': 'Batticaloa',
          'address': 'Batticaloa, Sri Lanka',
          'distance': 320.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Eye Clinic', 'ENT'],
          'phone': '+94 65 222 4444',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 4))),
        },
        {
          'name': 'Anuradhapura Teaching Hospital',
          'district': 'Anuradhapura',
          'city': 'Anuradhapura',
          'address': 'Anuradhapura, Sri Lanka',
          'distance': 205.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'Cardiology', 'Pediatrics'],
          'phone': '+94 25 222 5555',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        },
        {
          'name': 'Kurunegala Teaching Hospital',
          'district': 'Kurunegala',
          'city': 'Kurunegala',
          'address': 'Kurunegala, Sri Lanka',
          'distance': 95.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Eye Clinic', 'ENT', 'Pediatrics'],
          'phone': '+94 37 222 6666',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        },
        {
          'name': 'Badulla Teaching Hospital',
          'district': 'Badulla',
          'city': 'Badulla',
          'address': 'Badulla, Sri Lanka',
          'distance': 220.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'Pediatrics'],
          'phone': '+94 55 222 7777',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        },
        {
          'name': 'Kalutara General Hospital',
          'district': 'Kalutara',
          'city': 'Kalutara',
          'address': 'Kalutara, Sri Lanka',
          'distance': 45.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Pediatrics'],
          'phone': '+94 34 223 8899',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 4))),
        },
        {
          'name': 'Matara General Hospital',
          'district': 'Matara',
          'city': 'Matara',
          'address': 'Matara, Sri Lanka',
          'distance': 160.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'ENT'],
          'phone': '+94 41 222 3344',
          'nextSession': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        },
        {
          'name': 'Ratnapura Teaching Hospital',
          'district': 'Ratnapura',
          'city': 'Ratnapura',
          'address': 'Ratnapura, Sri Lanka',
          'distance': 100.0,
          'isOpen': true,
          'clinics': ['General Medicine', 'Dental', 'Eye Clinic', 'Pediatrics'],
          'phone': '+94 45 223 9911',
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
        final hospitalId = 'hospital-${index + 1}';
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