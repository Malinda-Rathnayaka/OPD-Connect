import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Service class for patient operations:
/// - Appointments CRUD
/// - Departments (admin) CRUD
/// - Queue Entries (patient) CRUD
/// - Notifications CRUD
class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ============================================================
  //  APPOINTMENTS
  // ============================================================

  Future<String> createAppointment({
    required String doctorName,
    required String department,
    required String hospital,
    required String token,
    required DateTime dateTime,
    String status = 'upcoming',
    String? badgeText,
  }) async {
    final docRef = await _db.collection('appointments').add({
      'patientId': currentUserId,
      'doctorName': doctorName,
      'department': department,
      'hospital': hospital,
      'token': token,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'badgeText': badgeText,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      title: 'Appointment Confirmed',
      message:
          'Your appointment with $doctorName on ${_formatDate(dateTime)} is confirmed.',
      type: 'booking',
    );

    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> getUpcomingAppointments() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: uid)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList(),
        );
  }

  Future<Map<String, dynamic>?> getAppointment(String id) async {
    final doc = await _db.collection('appointments').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newSession,
  }) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'appointmentDate': Timestamp.fromDate(newDate),
      'appointmentTime': newSession,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      title: 'Appointment Rescheduled',
      message: 'Your appointment has been rescheduled.',
      type: 'reschedule',
    );
  }

  Stream<List<Map<String, dynamic>>> getPastAppointments() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('appointments')
        .where('patientId', isEqualTo: currentUserId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getPastVisits() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db.collection('patients').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <Map<String, dynamic>>[];
      final data = doc.data();
      if (data == null) return <Map<String, dynamic>>[];

      final history = data['history'];
      if (history == null || history is! List) {
        return <Map<String, dynamic>>[];
      }

      return history
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> updateAppointment({
    required String appointmentId,
    String? doctorName,
    String? department,
    String? hospital,
    String? token,
    DateTime? dateTime,
    String? status,
    String? badgeText,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (doctorName != null) updates['doctorName'] = doctorName;
    if (department != null) updates['department'] = department;
    if (hospital != null) updates['hospital'] = hospital;
    if (token != null) updates['token'] = token;
    if (dateTime != null) updates['dateTime'] = Timestamp.fromDate(dateTime);
    if (status != null) updates['status'] = status;
    if (badgeText != null) updates['badgeText'] = badgeText;

    await _db.collection('appointments').doc(appointmentId).update(updates);

    if (dateTime != null) {
      await createNotification(
        title: 'Appointment Rescheduled',
        message:
            'Your appointment has been rescheduled to ${_formatDate(dateTime)}.',
        type: 'reschedule',
      );
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      title: 'Appointment Cancelled',
      message: 'Your appointment has been cancelled successfully.',
      type: 'cancellation',
    );
  }

  Future<void> deleteAppointment(String appointmentId) async {
    await _db.collection('appointments').doc(appointmentId).delete();
  }

  // ============================================================
  //  QUEUE ENTRIES
  // ============================================================

  // ===== CREATE — Queue එකට join වෙන්න =====
  Future<String> joinQueue({
    required String patientName,
    required String department,
    required String hospital,
  }) async {
    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final existing = await _db
        .collection('queue_entries')
        .where('department', isEqualTo: department)
        .where('hospital', isEqualTo: hospital)
        .where('status', whereIn: ['waiting', 'serving'])
        .where(
          'joinedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('joinedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final count = existing.docs.length;
    final tokenNumber = 'T-${(count + 1).toString().padLeft(3, '0')}';
    final estimatedWait = (count + 1) * 5;

    final docRef = await _db.collection('queue_entries').add({
      'patientId': currentUserId,
      'patientName': patientName,
      'department': department,
      'hospital': hospital,
      'tokenNumber': tokenNumber,
      'status': 'waiting',
      'joinedAt': FieldValue.serverTimestamp(),
      'estimatedWait': estimatedWait,
      'patientsAhead': count,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      title: 'Queue Joined',
      message:
          'You joined the $department queue at $hospital. Your token is $tokenNumber.',
      type: 'queue',
    );

    return docRef.id;
  }

  // ===== READ — ඔයාගේ active queue entry =====
  Stream<Map<String, dynamic>?> getMyActiveQueueEntry() {
    if (currentUserId == null) return Stream.value(null);

    return _db
        .collection('queue_entries')
        .where('patientId', isEqualTo: currentUserId)
        .where('status', whereIn: ['waiting', 'serving'])
        .orderBy('joinedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) {
          if (s.docs.isEmpty) return null;
          final data = s.docs.first.data();
          data['id'] = s.docs.first.id;
          return data;
        });
  }

  // ===== READ — ඒ department එකේ දැන් serving කරන token =====
  Stream<Map<String, dynamic>?> getNowServingToken(
    String department,
    String hospital,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _db
        .collection('queue_entries')
        .where('department', isEqualTo: department)
        .where('hospital', isEqualTo: hospital)
        .where('status', isEqualTo: 'serving')
        .where(
          'joinedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .limit(1)
        .snapshots()
        .map((s) {
          if (s.docs.isEmpty) return null;
          final data = s.docs.first.data();
          data['id'] = s.docs.first.id;
          return data;
        });
  }

  // ===== READ — හැම department එකකම live queue =====
  Stream<List<Map<String, dynamic>>> getDepartmentQueues() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _db
        .collection('queue_entries')
        .where('status', whereIn: ['waiting', 'serving'])
        .where(
          'joinedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .snapshots()
        .map((s) {
          final Map<String, List<Map<String, dynamic>>> grouped = {};

          for (var doc in s.docs) {
            final data = doc.data();
            final dept = data['department'] as String? ?? 'Unknown';
            grouped.putIfAbsent(dept, () => []).add(data);
          }

          final List<Map<String, dynamic>> result = [];
          grouped.forEach((dept, entries) {
            final waiting = entries
                .where((e) => e['status'] == 'waiting')
                .length;
            final serving = entries
                .where((e) => e['status'] == 'serving')
                .length;

            String status;
            Color statusColor;
            if (waiting >= 30) {
              status = 'BUSY';
              statusColor = const Color(0xFFEF4444);
            } else if (waiting >= 15) {
              status = 'MODERATE';
              statusColor = const Color(0xFFF59E0B);
            } else {
              status = 'LOW';
              statusColor = const Color(0xFF3B82F6);
            }

            result.add({
              'name': dept,
              'queued': waiting + serving,
              'serving': serving,
              'waiting': waiting,
              'waitTime': (waiting + 1) * 5,
              'status': status,
              'statusColor': statusColor,
            });
          });

          result.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );

          return result;
        });
  }

  // ===== UPDATE — ඔයාගේ queue entry =====
  Future<void> updateQueueEntry({
    required String entryId,
    String? department,
    String? hospital,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (department != null) updates['department'] = department;
    if (hospital != null) updates['hospital'] = hospital;

    await _db.collection('queue_entries').doc(entryId).update(updates);
  }

  // ===== DELETE — Queue එකෙන් අයින් වෙන්න =====
  Future<void> leaveQueue(String entryId) async {
    await _db.collection('queue_entries').doc(entryId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await createNotification(
      title: 'Left Queue',
      message: 'You have left the queue successfully.',
      type: 'queue',
    );
  }

  // ============================================================
  //  NOTIFICATIONS
  // ============================================================

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    bool isRead = false,
  }) async {
    if (currentUserId == null) return;
    await _db.collection('notifications').add({
      'patientId': currentUserId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getNotifications() {
    if (currentUserId == null) return Stream.value([]);
    return _db
        .collection('notifications')
        .where('patientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList(),
        );
  }

  Future<void> markNotificationAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }

  // ============================================================
  //  HELPERS
  // ============================================================

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
