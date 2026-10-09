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
    return DateFormat('EEE, d MMM yyyy', 'en_US').format(date);
  }

  static DateTime? _readSessionDate(Map<String, dynamic> session) {
    final value = session['date'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is! String) return null;
    for (final format in [
      DateFormat('yyyy-MM-dd'),
      DateFormat('EEE, d MMM yyyy', 'en_US'),
    ]) {
      try {
        return format.parseStrict(value);
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  static bool _isSameDay(DateTime? first, DateTime second) {
    return first != null &&
        first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
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
      final existingSessions = await _db.collection('sessions').get();
      final existingById = {
        for (final doc in existingSessions.docs) doc.id: doc.data(),
      };

      var batch = _db.batch();
      var batchWrites = 0;
      var sessionCount = 0;
      Future<void> commitBatch() async {
        if (batchWrites == 0) return;
        await batch.commit();
        batch = _db.batch();
        batchWrites = 0;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      for (int dayOffset = 1; dayOffset <= 15; dayOffset++) {
        final date = today.add(Duration(days: dayOffset));
        final sessionDate = DateTime(date.year, date.month, date.day);
        final dateString = _formatSessionDate(date);
        final dayOfWeek = DateFormat('EEE', 'en_US').format(date);

        final sessions = [
          ('morning', 'Morning', '09:00 AM', '12:00 AM'),
          ('afternoon', 'Afternoon', '12:00 PM', '03:00 PM'),
          ('evening', 'Evening', '03:00 PM', '06:00 PM'),
        ];

        for (final session in sessions) {
          final sessionRef = _db
              .collection('sessions')
              .doc(
                'colombo-national_${DateFormat('yyyyMMdd').format(sessionDate)}_${session.$1}',
              );
          final sessionData = <String, dynamic>{
            'id': sessionRef.id,
            'scheduleScope': 'hospital',
            'hospitalId': 'colombo-national',
            'hospitalName': 'Colombo National Hospital',
            'date': Timestamp.fromDate(sessionDate),
            'dateLabel': dateString,
            'dayOfWeek': dayOfWeek,
            'sessionTypeKey': session.$1,
            'sessionType': session.$2,
            'startTime': session.$3,
            'endTime': session.$4,
            'time': '${session.$3} - ${session.$4}',
          };
          if (!existingById.containsKey(sessionRef.id)) {
            sessionData.addAll({
              'totalSlots': 5,
              'availableSlots': 5,
              'isAvailable': true,
            });
          } else {
            final existingData = existingById[sessionRef.id]!;
            final metadataMatches = sessionData.entries.every(
              (entry) =>
                  entry.key == 'date' || existingData[entry.key] == entry.value,
            );
            final dateMatches = _isSameDay(
              _readSessionDate(existingData),
              sessionDate,
            );
            if (metadataMatches && dateMatches) continue;
          }
          batch.set(sessionRef, sessionData, SetOptions(merge: true));
          batchWrites++;
          sessionCount++;
          if (batchWrites == 400) await commitBatch();
        }
      }

      await commitBatch();
      debugPrint('Created or updated $sessionCount shared OPD sessions.');
    } catch (error) {
      debugPrint('Unable to seed sessions: $error');
      rethrow;
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
          'createdAt': createdAt,
        },
      ];

      final batch = firestore.batch();

      batch.set(firestore.collection('hospitals').doc(hospitalId), {
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
      }, SetOptions(merge: true));

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
    } catch (e) {
      debugPrint('Error seeding Colombo National Hospital data: $e');
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
          'nextSession': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 2)),
          ),
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
