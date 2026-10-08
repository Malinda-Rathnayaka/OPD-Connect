import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

class SeedService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static String get adminEmail =>
      dotenv.env['ADMIN_EMAIL'] ?? 'admin@opdconnect.lk';

  static String get adminPassword =>
      dotenv.env['ADMIN_PASSWORD'] ?? 'AdminPassword123!';

  static String _formatSessionDate(DateTime date) {
    return DateFormat('EEE, d MMM', 'en_US').format(date);
  }

  static Future<void> seedAdminAccount() async {
    try {
      final query = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (query.docs.isEmpty) {
        final credential = await _auth.createUserWithEmailAndPassword(
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

        await _auth.signOut();
        debugPrint('Admin account created successfully: $adminEmail');
      }
    } catch (e) {
      debugPrint('Admin seed check finished: ${e.toString()}');
    }
  }

  static Future<void> seedSessionsForDoctors() async {
    try {
      debugPrint('DEBUG: seeding sessions for doctors');

      final doctorsSnapshot = await _db
          .collection('doctors')
          .where('hospitalId', isEqualTo: 'colombo-national')
          .get();

      if (doctorsSnapshot.docs.isEmpty) {
        debugPrint('DEBUG: no doctors found for colombo-national');
        return;
      }

      final batch = _db.batch();
      for (int dayOffset = 0; dayOffset < 15; dayOffset++) {
        final date = DateTime.now().add(Duration(days: dayOffset));
        final dateString = _formatSessionDate(date);
        final dayOfWeek = DateFormat('EEE', 'en_US').format(date);

        for (final doctorDoc in doctorsSnapshot.docs) {
          final doctorData = doctorDoc.data();
          final doctorId = doctorDoc.id;
          final doctorName = doctorData['fullName']?.toString() ?? 'Doctor';
          final department = doctorData['department']?.toString() ?? 'General Medicine';
          final hospitalId = doctorData['hospitalId']?.toString() ?? 'colombo-national';
          final hospitalName = doctorData['hospitalName']?.toString() ?? 'Colombo National Hospital';

          final baseSlots = ((doctorDoc.id.length + dayOffset + (department.length % 3)) % 6);
          final morningSlots = baseSlots;
          final eveningSlots = ((baseSlots + 3) % 6);

          final morningDocRef = _db.collection('sessions').doc();
          batch.set(morningDocRef, {
            'id': morningDocRef.id,
            'hospitalId': hospitalId,
            'hospitalName': hospitalName,
            'doctorId': doctorId,
            'doctorName': doctorName,
            'department': department,
            'date': dateString,
            'dayOfWeek': dayOfWeek,
            'sessionType': 'Morning',
            'startTime': '09:00 AM',
            'endTime': '12:00 PM',
            'totalSlots': 5,
            'availableSlots': morningSlots,
            'isAvailable': morningSlots > 0,
          });

          final eveningDocRef = _db.collection('sessions').doc();
          batch.set(eveningDocRef, {
            'id': eveningDocRef.id,
            'hospitalId': hospitalId,
            'hospitalName': hospitalName,
            'doctorId': doctorId,
            'doctorName': doctorName,
            'department': department,
            'date': dateString,
            'dayOfWeek': dayOfWeek,
            'sessionType': 'Evening',
            'startTime': '02:00 PM',
            'endTime': '05:00 PM',
            'totalSlots': 5,
            'availableSlots': eveningSlots,
            'isAvailable': eveningSlots > 0,
          });
        }
      }

      await batch.commit();
      debugPrint('DEBUG: seeded 30 sessions per doctor for the next 15 days');
    } catch (error) {
      debugPrint('DEBUG: error seeding sessions: $error');
    }
  }

  static Future<void> seedColomboNationalHospital() async {
    try {
      final firestore = FirebaseFirestore.instance;
      const hospitalId = 'colombo-national';
      const hospitalName = 'Colombo National Hospital';
      final createdAt = Timestamp.now();

      final nextMonday = DateTime.now();
      var nextSessionDate = DateTime(
        nextMonday.year,
        nextMonday.month,
        nextMonday.day,
      );

      while (nextSessionDate.weekday != DateTime.monday) {
        nextSessionDate = nextSessionDate.add(const Duration(days: 1));
      }

      nextSessionDate = DateTime(
        nextSessionDate.year,
        nextSessionDate.month,
        nextSessionDate.day,
        9,
        0,
      );

      final doctors = [
        {
          'id': 'doctor-general',
          'fullName': 'Dr. Perera',
          'department': 'General Medicine',
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'isOnDuty': true,
          'avgWaitTime': 15,
          'patientRating': 4.9,
          'availableSlots': ['Mon, 22 Sep', 'Tue, 23 Sep'],
          'createdAt': createdAt,
        },
        {
          'id': 'doctor-dental',
          'fullName': 'Dr. Silva',
          'department': 'Dental',
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'isOnDuty': true,
          'avgWaitTime': 10,
          'patientRating': 4.7,
          'availableSlots': ['Mon, 22 Sep', 'Tue, 23 Sep'],
          'createdAt': createdAt,
        },
        {
          'id': 'doctor-eye',
          'fullName': 'Dr. Fernando',
          'department': 'Eye Clinic',
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'isOnDuty': true,
          'avgWaitTime': 20,
          'patientRating': 4.8,
          'availableSlots': ['Mon, 22 Sep', 'Tue, 23 Sep'],
          'createdAt': createdAt,
        },
        {
          'id': 'doctor-ent',
          'fullName': 'Dr. Jayawardena',
          'department': 'ENT',
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'isOnDuty': true,
          'avgWaitTime': 12,
          'patientRating': 4.6,
          'availableSlots': ['Mon, 22 Sep', 'Tue, 23 Sep'],
          'createdAt': createdAt,
        },
        {
          'id': 'doctor-cardio',
          'fullName': 'Dr. Wickramasinghe',
          'department': 'Cardiology',
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'isOnDuty': true,
          'avgWaitTime': 25,
          'patientRating': 4.9,
          'availableSlots': ['Mon, 22 Sep', 'Tue, 23 Sep'],
          'createdAt': createdAt,
        },
        {
          'id': 'doctor-pedia',
          'fullName': 'Dr. Rajapaksa',
          'department': 'Pediatrics',
          'hospitalId': hospitalId,
          'hospitalName': hospitalName,
          'isOnDuty': true,
          'avgWaitTime': 18,
          'patientRating': 4.8,
          'availableSlots': ['Mon, 22 Sep', 'Tue, 23 Sep'],
          'createdAt': createdAt,
        },
      ];

      final batch = firestore.batch();

      batch.set(
        firestore.collection('hospitals').doc(hospitalId),
        {
          'name': hospitalName,
          'district': 'Colombo',
          'city': 'Colombo',
          'address': 'Colombo 10',
          'distance': 2.3,
          'isOpen': true,
          'clinics': [
            'General Medicine',
            'Dental',
            'Eye Clinic',
            'ENT',
            'Cardiology',
            'Pediatrics',
          ],
          'phone': '+94 11 269 1111',
          'nextSession': Timestamp.fromDate(nextSessionDate),
        },
        SetOptions(merge: true),
      );

      for (final doctor in doctors) {
        final doctorId = doctor['id'] as String;
        final doctorData = {
          'fullName': doctor['fullName'],
          'department': doctor['department'],
          'hospitalId': doctor['hospitalId'],
          'hospitalName': doctor['hospitalName'],
          'isOnDuty': doctor['isOnDuty'],
          'avgWaitTime': doctor['avgWaitTime'],
          'patientRating': doctor['patientRating'],
          'availableSlots': doctor['availableSlots'],
          'createdAt': doctor['createdAt'],
        };

        batch.set(
          firestore.collection('doctors').doc(doctorId),
          doctorData,
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      debugPrint('Colombo National Hospital doctors seeded successfully');
      await seedSimpleSessions();
    } catch (e) {
      debugPrint('Error seeding Colombo National Hospital data: $e');
    }
  }

  static Future<void> seedSimpleSessions() async {
    try {
      // First, clear all existing sessions and appointments to avoid duplicates
      final oldSessions = await _db.collection('sessions').get();
      var batch = _db.batch();
      for (var doc in oldSessions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      final oldAppointments = await _db.collection('appointments').get();
      batch = _db.batch();
      for (var doc in oldAppointments.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      final doctorsSnapshot = await _db
          .collection('doctors')
          .where('hospitalId', isEqualTo: 'colombo-national')
          .get();

      if (doctorsSnapshot.docs.isEmpty) {
        debugPrint('No doctors found for colombo-national');
        return;
      }

      final times = ['09:00 AM', '12:00 PM', '03:00 PM'];
      int sessionCount = 0;

      for (int dayOffset = 0; dayOffset < 30; dayOffset++) {
        final date = DateTime.now().add(Duration(days: dayOffset));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        batch = _db.batch();

        for (final doc in doctorsSnapshot.docs) {
          final doctorId = doc.id;
          for (int i = 0; i < times.length; i++) {
            final timeStr = times[i];
            final docId = '${doctorId}_${dateStr}_${timeStr.replaceAll(':', '').replaceAll(' ', '')}';
            final sessionRef = _db.collection('sessions').doc(docId);
            
            // Generate some variation in available slots (0 to 5)
            // Use doctor id length, day offset, and time index to create pseudo-random but deterministic slots
            int availableSlots = ((doctorId.length + dayOffset * 3 + i * 7) % 6);

            batch.set(
              sessionRef,
              {
                'doctorId': doctorId,
                'hospitalId': 'colombo-national',
                'date': dateStr,
                'time': timeStr,
                'availableSlots': availableSlots,
              },
              SetOptions(merge: true),
            );
            sessionCount++;
          }
        }
        await batch.commit();
      }

      debugPrint('Sessions seeded: $sessionCount sessions for ${doctorsSnapshot.docs.length} doctors');
      print('Sessions seeded: $sessionCount sessions for ${doctorsSnapshot.docs.length} doctors');
    } catch (e) {
      debugPrint('Error seeding simple sessions: $e');
    }
  }

  static Future<void> cleanUpOtherHospitals() async {
    try {
      final firestore = FirebaseFirestore.instance;
      const keepHospitalId = 'colombo-national';

      int deletedHospitals = 0;
      final hospitalsSnapshot = await firestore.collection('hospitals').get();
      final hospitalDocs = hospitalsSnapshot.docs
          .where((doc) => doc.id != keepHospitalId)
          .toList();

      for (var i = 0; i < hospitalDocs.length; i += 500) {
        final batch = firestore.batch();
        final chunk = hospitalDocs.skip(i).take(500).toList();

        for (final doc in chunk) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        deletedHospitals += chunk.length;
      }

      debugPrint('Deleted $deletedHospitals hospitals');

      int deletedDoctors = 0;
      final doctorsSnapshot = await firestore
          .collection('doctors')
          .where('hospitalId', isNotEqualTo: keepHospitalId)
          .get();

      for (var i = 0; i < doctorsSnapshot.docs.length; i += 500) {
        final batch = firestore.batch();
        final chunk = doctorsSnapshot.docs.skip(i).take(500).toList();

        for (final doc in chunk) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        deletedDoctors += chunk.length;
      }

      debugPrint('Deleted $deletedDoctors doctors');

      int deletedSessions = 0;
      final sessionsSnapshot = await firestore
          .collection('sessions')
          .where('hospitalId', isNotEqualTo: keepHospitalId)
          .get();

      for (var i = 0; i < sessionsSnapshot.docs.length; i += 500) {
        final batch = firestore.batch();
        final chunk = sessionsSnapshot.docs.skip(i).take(500).toList();

        for (final doc in chunk) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        deletedSessions += chunk.length;
      }

      debugPrint('Deleted $deletedSessions sessions');
      debugPrint('Cleanup completed successfully');
    } catch (e) {
      debugPrint('Error cleaning up other hospitals: $e');
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
          'clinics': [
            'General Medicine',
            'Dental',
            'Eye Clinic',
            'ENT',
            'Cardiology',
            'Pediatrics',
          ],
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
      final hospitalsCount = hospitals.length;
      final doctorsCount = hospitals.length * 3;
      debugPrint(
        'Hospitals and doctors seeded successfully: $hospitalsCount hospitals, $doctorsCount doctors',
      );
    } catch (e) {
      debugPrint('Error seeding hospitals and doctors: $e');
    }
  }
}
