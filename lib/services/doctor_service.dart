import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/doctor/doctor_leave_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createLeaveRequest(DoctorLeaveModel leave) async {
    if (leave.doctorId != FirebaseAuth.instance.currentUser?.uid) {
      throw StateError('You can only create leave requests for your own account.');
    }
    await _db.collection('doctor_leaves').doc(leave.id).set({
      ...leave.toFirestore(),
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<DoctorLeaveModel>> getDoctorLeaves(String doctorId) {
    return _db
        .collection('doctor_leaves')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final leaves = snapshot.docs
          .map(DoctorLeaveModel.fromFirestore)
          .toList();
      leaves.sort((a, b) => b.date.compareTo(a.date));
      return leaves;
    });
  }

  Future<void> updateLeaveRequest(
    String leaveId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('doctor_leaves').doc(leaveId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteLeaveRequest(String leaveId) async {
    await _db.collection('doctor_leaves').doc(leaveId).delete();
  }

  Future<bool> isDoctorOnApprovedLeave(String doctorId, String date) async {
    return await getApprovedLeaveReason(doctorId, date) != null;
  }

  Future<String?> getApprovedLeaveReason(String doctorId, String date) async {
    final result = await _db
        .collection('doctor_leaves')
        .where('doctorId', isEqualTo: doctorId)
        .get();
    for (final document in result.docs) {
      final data = document.data();
      if (data['date'] == date && data['status'] == 'APPROVED') {
        return data['reason']?.toString() ?? 'unspecified';
      }
    }
    return null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getDoctorSessions(
    String doctorId,
  ) => _db
      .collection('sessions')
      .where('doctorId', isEqualTo: doctorId)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> getSessionQueue(
    String sessionId,
  ) =>
      _db.collection('sessions').doc(sessionId).collection('queue').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> getCompletedRecords(
    String sessionId,
  ) => _db
      .collection('sessions')
      .doc(sessionId)
      .collection('completed_records')
      .snapshots();

  Future<Map<String, dynamic>> getDoctorProfile(String doctorId) async {
    final documents = await Future.wait([
      _db.collection('users').doc(doctorId).get(),
      _db.collection('doctors').doc(doctorId).get(),
    ]);
    final account = documents[0].data() ?? <String, dynamic>{};
    final doctor = documents[1].data() ?? <String, dynamic>{};
    final authUser = FirebaseAuth.instance.currentUser;
    return {
      'name': doctor['fullName'] ?? account['name'] ?? authUser?.displayName ?? '',
      'email': account['email'] ?? authUser?.email ?? '',
      'phone': doctor['phone'] ?? account['phone'] ?? '',
      'specialization': doctor['specialization'] ?? account['specialization'] ?? '',
      'roomNo': doctor['roomNo'] ?? account['roomNo'] ?? '',
      'profileImageUrl': doctor['profileImageUrl'] ??
          account['profileImageUrl'] ?? authUser?.photoURL,
    };
  }

  Future<String> uploadDoctorProfileImage({
    required String doctorId,
    required Uint8List imageBytes,
    required String contentType,
  }) async {
    final imageRef = FirebaseStorage.instance
        .ref()
        .child('doctor_profile_images/$doctorId/profile');
    final result = await imageRef.putData(
      imageBytes,
      SettableMetadata(contentType: contentType),
    );
    return result.ref.getDownloadURL();
  }

  /// Loads both supported patient locations, merging duplicate IDs in favor of
  /// the dedicated patients document while filling missing profile fields.
  Future<List<Map<String, dynamic>>> fetchPatients() async {
    final results = await Future.wait([
      _db.collection('patients').get(),
      _db.collection('users').where('role', isEqualTo: 'patient').get(),
    ]);
    final byId = <String, Map<String, dynamic>>{};
    for (final doc in results[1].docs) {
      byId[doc.id] = {...doc.data(), 'id': doc.id};
    }
    for (final doc in results[0].docs) {
      final user = byId[doc.id] ?? <String, dynamic>{};
      final patient = doc.data();
      byId[doc.id] = {
        ...user,
        ...patient,
        'id': doc.id,
        'name':
            patient['name'] ??
            patient['fullName'] ??
            user['name'] ??
            user['fullName'],
        'nic': patient['nic'] ?? user['nic'],
        'phone': patient['phone'] ?? user['phone'],
        'email': patient['email'] ?? user['email'],
      };
    }
    return byId.values.map((patient) {
      patient['name'] =
          patient['name'] ?? patient['fullName'] ?? 'Unknown Patient';
      patient['phone'] = patient['phone'] ?? '';
      patient['nic'] = patient['nic'] ?? '';
      patient['email'] = patient['email'] ?? '';
      return patient;
    }).toList()..sort(
      (a, b) => a['name'].toString().toLowerCase().compareTo(
        b['name'].toString().toLowerCase(),
      ),
    );
  }

  Future<String> startNewSession({
    required String doctorId,
    required String doctorName,
    required String timeSlot,
    required String slotDate,
    required List<Map<String, dynamic>> patients,
  }) async {
    if (patients.isEmpty) throw ArgumentError('Select at least one patient.');
    if (patients.length > 450)
      throw ArgumentError('A session can contain at most 450 patients.');
    final session = _db.collection('sessions').doc();
    await session.set({
      'doctorId': doctorId,
      'doctorName': doctorName,
      'timeSlot': timeSlot,
      'slotDate': slotDate,
      'maxPatients': patients.length,
      'status': 'IN_PROGRESS',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final batch = _db.batch();
    for (var i = 0; i < patients.length; i++) {
      batch.set(
        session.collection('queue').doc(),
        _queuePatient(patients[i], i),
      );
    }
    try {
      await batch.commit();
    } catch (_) {
      await session.delete();
      rethrow;
    }
    return session.id;
  }

  Map<String, dynamic> _queuePatient(
    Map<String, dynamic> patient,
    int index, {
    String? status,
  }) => {
    'patientId': patient['id'],
    'patientName': patient['name'] ?? patient['fullName'] ?? 'Unknown Patient',
    'nic': patient['nic'] ?? '',
    'phone': patient['phone'] ?? '',
    'email': patient['email'] ?? '',
    'tokenNo': 'T-${(index + 1).toString().padLeft(3, '0')}',
    'apptTime': '',
    'status': status ?? (index == 0 ? 'IN_CONSULTATION' : 'ARRIVED'),
    'order': index + 1,
    'createdAt': FieldValue.serverTimestamp(),
  };

  Future<void> updateSession({
    required String sessionId,
    String? timeSlot,
    String? slotDate,
    List<Map<String, dynamic>>? patients,
  }) async {
    final sessionRef = _db.collection('sessions').doc(sessionId);
    final queueRef = sessionRef.collection('queue');
    final existingDocs = patients == null
        ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
        : (await queueRef.get()).docs;
    if (patients != null && patients.isEmpty) {
      throw ArgumentError('A session must have at least one patient.');
    }
    if (patients != null && patients.length > 450) {
      throw ArgumentError('A session can contain at most 450 patients.');
    }
    final hasActivePatient = existingDocs.any(
      (doc) => doc.data()['status'] == 'IN_CONSULTATION',
    );
    final desiredIds = patients?.map((p) => p['id'].toString()).toSet();
    final existingByPatient =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in existingDocs) {
      final id = doc.data()['patientId']?.toString();
      if (id != null) existingByPatient[id] = doc;
    }

    final batch = _db.batch();
    final sessionUpdates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (timeSlot != null && timeSlot.trim().isNotEmpty)
      sessionUpdates['timeSlot'] = timeSlot.trim();
    if (slotDate != null && slotDate.trim().isNotEmpty)
      sessionUpdates['slotDate'] = slotDate.trim();
    if (patients != null) sessionUpdates['maxPatients'] = patients.length;
    batch.update(sessionRef, sessionUpdates);
    var order = 0;
    for (final patient in patients ?? const <Map<String, dynamic>>[]) {
      final patientId = patient['id'].toString();
      final old = existingByPatient[patientId];
      order++;
      if (old == null) {
        batch.set(
          queueRef.doc(),
          _queuePatient(
            patient,
            order - 1,
            status: hasActivePatient || order > 1
                ? 'ARRIVED'
                : 'IN_CONSULTATION',
          ),
        );
      } else {
        final oldData = old.data();
        final status = oldData['status']?.toString() ?? 'ARRIVED';
        batch.update(old.reference, {
          'patientName':
              patient['name'] ??
              patient['fullName'] ??
              oldData['patientName'] ??
              'Unknown Patient',
          'nic': patient['nic'] ?? oldData['nic'] ?? '',
          'phone': patient['phone'] ?? oldData['phone'] ?? '',
          'email': patient['email'] ?? oldData['email'] ?? '',
          'tokenNo': 'T-${order.toString().padLeft(3, '0')}',
          'order': order,
        });
        // Keep historical statuses and do not silently erase completed or active work.
        if (status == 'IN_CONSULTATION' ||
            status == 'COMPLETED' ||
            status == 'SKIPPED') {
          continue;
        }
      }
    }
    for (final doc in existingDocs) {
      final id = doc.data()['patientId']?.toString();
      if (id != null && !(desiredIds?.contains(id) ?? true)) {
        final status = doc.data()['status']?.toString();
        if (status == 'COMPLETED' || status == 'IN_CONSULTATION') {
          throw StateError(
            'Completed or currently treated patients cannot be removed from the session.',
          );
        }
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  }

  Future<void> setSessionStatus(String sessionId, String status) async {
    if (!{'IN_PROGRESS', 'COMPLETED'}.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    await _db.collection('sessions').doc(sessionId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSession(String sessionId) async {
    final session = _db.collection('sessions').doc(sessionId);
    for (final collection in ['queue', 'completed_records']) {
      final docs = await session.collection(collection).get();
      for (var start = 0; start < docs.docs.length; start += 450) {
        final batch = _db.batch();
        for (final doc in docs.docs.skip(start).take(450)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await session.delete();
  }

  Future<List<dynamic>> fetchPatientHistory(String patientId) async {
    final patientDoc = await _db.collection('patients').doc(patientId).get();
    final userDoc = await _db.collection('users').doc(patientId).get();
    final patientHistory = patientDoc.data()?['history'];
    final userHistory = userDoc.data()?['history'];
    final history = <dynamic>[
      if (patientHistory is List) ...patientHistory,
      if (userHistory is List) ...userHistory,
    ];
    history.sort((a, b) => _historyDate(b).compareTo(_historyDate(a)));
    return history;
  }

  DateTime _historyDate(dynamic entry) {
    if (entry is! Map) return DateTime.fromMillisecondsSinceEpoch(0);
    final value = entry['date'] ?? entry['completedAt'];
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> submitAndCallNext({
    required String sessionId,
    required String queueDocId,
    required String patientId,
    required String patientName,
    required String tokenNo,
    required String diagnosis,
    required String prescription,
    required String advice,
  }) async {
    final sessionRef = _db.collection('sessions').doc(sessionId);
    final queueRef = sessionRef.collection('queue');
    final patientRef = _db.collection('patients').doc(patientId);
    final patientDoc = await patientRef.get();
    final userRef = _db.collection('users').doc(patientId);
    final userDoc = patientDoc.exists ? null : await userRef.get();
    final historyRef = patientDoc.exists
        ? patientRef
        : (userDoc?.exists == true ? userRef : null);
    final next = await queueRef.where('status', isEqualTo: 'ARRIVED').get();
    next.docs.sort(
      (a, b) => ((a.data()['order'] as num?) ?? 0).compareTo(
        (b.data()['order'] as num?) ?? 0,
      ),
    );

    final now = DateTime.now();
    final recordRef = sessionRef.collection('completed_records').doc();
    final record = <String, dynamic>{
      'patientId': patientId,
      'patientName': patientName,
      'tokenNo': tokenNo,
      'diagnosis': diagnosis.trim(),
      'prescription': prescription.trim(),
      'advice': advice.trim(),
      'doctorId': FirebaseAuth.instance.currentUser?.uid,
      'sessionId': sessionId,
      'completedAt': FieldValue.serverTimestamp(),
      'date': now.toIso8601String(),
    };
    final batch = _db.batch();
    batch.update(queueRef.doc(queueDocId), {
      'status': 'COMPLETED',
      'diagnosis': diagnosis.trim(),
      'prescription': prescription.trim(),
      'advice': advice.trim(),
      'completedAt': FieldValue.serverTimestamp(),
    });
    batch.set(recordRef, record);
    if (historyRef != null) {
      batch.set(historyRef, {
        'history': FieldValue.arrayUnion([
          {
            'type': 'REGULAR_CONSULTATION',
            'date': now.toIso8601String(),
            'diagnosis': diagnosis.trim(),
            'prescription': prescription.trim(),
            'advice': advice.trim(),
            'sessionId': sessionId,
            'tokenNo': tokenNo,
            'doctorId': FirebaseAuth.instance.currentUser?.uid,
          },
        ]),
      }, SetOptions(merge: true));
    }
    if (next.docs.isNotEmpty) {
      batch.update(next.docs.first.reference, {'status': 'IN_CONSULTATION'});
    } else {
      batch.update(sessionRef, {
        'status': 'COMPLETED',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> skipCurrentPatient({
    required String sessionId,
    required String queueDocId,
    required String reason,
    required String details,
  }) async {
    if (reason.trim().isEmpty || details.trim().isEmpty) {
      throw ArgumentError('Emergency reason and details are required.');
    }
    final queueRef = _db
        .collection('sessions')
        .doc(sessionId)
        .collection('queue');
    final current = await queueRef.doc(queueDocId).get();
    final data = current.data() ?? <String, dynamic>{};
    final patientId = data['patientId']?.toString() ?? '';
    final patientRef = _db.collection('patients').doc(patientId);
    final patientDoc = patientId.isNotEmpty ? await patientRef.get() : null;
    final userRef = _db.collection('users').doc(patientId);
    final userDoc = patientDoc?.exists == true || patientId.isEmpty
        ? null
        : await userRef.get();
    final historyRef = patientDoc?.exists == true
        ? patientRef
        : (userDoc?.exists == true ? userRef : null);
    final next = await queueRef.where('status', isEqualTo: 'ARRIVED').get();
    next.docs.sort(
      (a, b) => ((a.data()['order'] as num?) ?? 0).compareTo(
        (b.data()['order'] as num?) ?? 0,
      ),
    );
    final batch = _db.batch();
    batch.update(current.reference, {
      'status': 'SKIPPED',
      'skipReason': reason.trim(),
      'skipDetails': details.trim(),
      'skippedAt': FieldValue.serverTimestamp(),
    });
    final emergencyRef = _db.collection('emergency_records').doc();
    batch.set(emergencyRef, {
      'doctorId': FirebaseAuth.instance.currentUser?.uid,
      'sessionId': sessionId,
      'queueDocId': queueDocId,
      'patientId': patientId,
      'patientName': data['patientName'],
      'reason': reason.trim(),
      'details': details.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (historyRef != null) {
      batch.set(historyRef, {
        'history': FieldValue.arrayUnion([
          {
            'type': 'EMERGENCY_TREATMENT',
            'date': DateTime.now().toIso8601String(),
            'diagnosis': 'EMERGENCY: ${reason.trim()}',
            'prescription': details.trim(),
            'advice': 'Queue patient skipped for emergency care.',
            'sessionId': sessionId,
          },
        ]),
      }, SetOptions(merge: true));
    }
    if (next.docs.isNotEmpty) {
      batch.update(next.docs.first.reference, {'status': 'IN_CONSULTATION'});
    }
    await batch.commit();
  }

  Future<void> logEmergencyTreatment({
    required String patientName,
    required String nicOrPhone,
    required String reason,
    required String treatmentGiven,
    required String notes,
  }) async {
    final doctorId = FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    final records = _db.collection('emergency_records');
    DocumentReference<Map<String, dynamic>>? patientRef;
    for (final collection in ['patients', 'users']) {
      for (final field in ['nic', 'phone']) {
        final matches = await _db
            .collection(collection)
            .where(field, isEqualTo: nicOrPhone)
            .limit(1)
            .get();
        if (matches.docs.isNotEmpty) {
          patientRef = matches.docs.first.reference;
          break;
        }
      }
      if (patientRef != null) break;
    }
    final entry = {
      'type': 'EMERGENCY_TREATMENT',
      'date': now.toIso8601String(),
      'diagnosis': 'EMERGENCY: $reason',
      'prescription': treatmentGiven,
      'advice': notes,
      'doctorId': doctorId,
    };
    final batch = _db.batch();
    batch.set(records.doc(), {
      'doctorId': doctorId,
      'patientId': patientRef?.id,
      'patientName': patientName,
      'nicOrPhone': nicOrPhone,
      'reason': reason,
      'treatmentGiven': treatmentGiven,
      'notes': notes,
      'date': now.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (patientRef != null) {
      batch.set(patientRef, {
        'history': FieldValue.arrayUnion([entry]),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<void> updateDoctorProfile({
    required String doctorId,
    required String name,
    required String specialization,
    required String phone,
    required String roomNo,
    String? profileImageUrl,
  }) async {
    final doctorData = <String, dynamic>{
      'fullName': name,
      'specialization': specialization,
      'phone': phone,
      'roomNo': roomNo,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (profileImageUrl != null) doctorData['profileImageUrl'] = profileImageUrl;

    await _db.collection('doctors').doc(doctorId).set(doctorData, SetOptions(merge: true));

    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null && authUser.uid == doctorId) {
      await authUser.updateDisplayName(name);
      if (profileImageUrl != null) {
        await authUser.updatePhotoURL(profileImageUrl);
      }
  /// Get all doctors for a specific hospital.
  Future<List<DoctorModel>> getDoctorsByHospital(String hospitalId) async {
    try {
      final snapshot = await _db
          .collection('doctors')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();

      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Get all doctors in a specific department.
  Future<List<DoctorModel>> getDoctorsByDepartment(String department) async {
    try {
      final snapshot = await _db
          .collection('doctors')
          .where('department', isEqualTo: department)
          .get();

      return snapshot.docs
          .map((doc) => DoctorModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Get a single doctor by Firestore document ID.
  Future<DoctorModel?> getDoctor(String doctorId) async {
    try {
      final doc = await _db.collection('doctors').doc(doctorId).get();
      if (doc.exists && doc.data() != null) {
        return DoctorModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (error) {
      rethrow;
    }
  }

  /// Get the available slot labels stored for a doctor.
  Future<List<String>> getAvailableSlots(String doctorId) async {
    try {
      final doc = await _db.collection('doctors').doc(doctorId).get();
      if (!doc.exists || doc.data() == null) {
        return <String>[];
      }

      final data = doc.data()!;
      final slots = data['availableSlots'];
      if (slots is List) {
        return slots.map((slot) => slot.toString()).toList();
      }
      return <String>[];
    } catch (error) {
      rethrow;
    }
  }
}
