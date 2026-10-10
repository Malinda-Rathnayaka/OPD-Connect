import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor/doctor_leave_model.dart';
import '../models/user_model.dart';

/// Service class for admin operations — CRUD on all user accounts
/// and doctor approval workflow.
class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<DoctorLeaveModel>> getPendingDoctorLeaves() {
    return _db
        .collection('doctor_leaves')
        .where('status', isEqualTo: 'PENDING')
        .snapshots()
        .map((snapshot) {
      final leaves = snapshot.docs
          .map(DoctorLeaveModel.fromFirestore)
          .toList();
      leaves.sort((a, b) => a.date.compareTo(b.date));
      return leaves;
    });
  }

  Future<void> approveDoctorLeave(String leaveId) async {
    await _updateLeaveStatus(leaveId, 'APPROVED');
  }

  Future<void> rejectDoctorLeave(String leaveId) async {
    await _updateLeaveStatus(leaveId, 'REJECTED');
  }

  Future<void> _updateLeaveStatus(String leaveId, String status) async {
    if (!{'APPROVED', 'REJECTED'}.contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    await _db.collection('doctor_leaves').doc(leaveId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────────────────
  // READ — streams & one-off fetches
  // ─────────────────────────────────────────────────────────

  /// Real-time stream of all patients
  Stream<List<UserModel>> getPatientsStream() {
    return _db
        .collection('patients')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _profileUser(doc.data(), doc.id, 'patient'))
            .toList());
  }

  /// Real-time stream of all doctors
  Stream<List<UserModel>> getDoctorsStream() {
    return _db
        .collection('doctors')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _profileUser(doc.data(), doc.id, 'doctor'))
            .toList());
  }

  /// Real-time stream of doctors awaiting admin approval
  Stream<List<UserModel>> getPendingDoctorsStream() {
    return _db
        .collection('doctors')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _profileUser(doc.data(), doc.id, 'doctor'))
            .toList());
  }

  UserModel _profileUser(Map<String, dynamic> data, String uid, String role) {
    return UserModel.fromMap({
      ...data,
      'name': data['name'] ?? data['fullName'] ?? '',
      'role': role,
      'isApproved': role == 'doctor' ? data['isApproved'] ?? false : true,
      'isVerified': role == 'doctor' ? data['isVerified'] ?? false : true,
    }, uid);
  }

  /// Fetch a single user by UID
  Future<UserModel?> getUserById(String uid) async {
    final results = await Future.wait([
      _db.collection('users').doc(uid).get(),
      _db.collection('patients').doc(uid).get(),
      _db.collection('doctors').doc(uid).get(),
    ]);
    final metadata = results[0].data();
    final patient = results[1].data();
    final doctor = results[2].data();
    final role = metadata?['role']?.toString() ??
        (doctor != null ? 'doctor' : patient != null ? 'patient' : null);
    if (role == null) return null;
    return UserModel.fromMap({
      ...?metadata,
      ...?(role == 'doctor' ? doctor : role == 'patient' ? patient : metadata),
      'role': role,
      'isApproved': metadata?['isApproved'] ?? doctor?['isApproved'] ?? role != 'doctor',
      'isVerified': metadata?['isVerified'] ?? doctor?['isVerified'] ?? role != 'doctor',
    }, uid);
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────

  /// Update user profile fields (name, phone, email, etc.)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final metadata = await _db.collection('users').doc(uid).get();
    final role = metadata.data()?['role']?.toString();
    final profileCollection = role == 'doctor' ? 'doctors' : 'patients';
    final profileData = Map<String, dynamic>.from(data);
    if (role == 'doctor' && profileData.containsKey('name')) {
      profileData['fullName'] = profileData.remove('name');
    }
    await _db.collection(profileCollection).doc(uid).update(profileData);
  }

  /// Approve a doctor account so they can log in to the dashboard
  Future<void> approveDoctor(String uid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {
      'isApproved': true,
      'isVerified': true,
    });
    batch.set(_db.collection('doctors').doc(uid), {
      'isApproved': true,
      'isVerified': true,
      'approvedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Reject / revoke a doctor's approval
  Future<void> rejectDoctor(String uid) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(uid), {
      'isApproved': false,
      'isVerified': false,
    });
    batch.update(_db.collection('doctors').doc(uid), {
      'isApproved': false,
      'isVerified': false,
    });
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────

  /// Delete a user's Firestore document.
  /// (Firebase Auth account deletion requires the Admin SDK or
  ///  the user to re-authenticate — Firestore doc is enough for
  ///  blocking access via isVerified / isApproved flags.)
  Future<void> deleteUser(String uid) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(uid));
    batch.delete(_db.collection('patients').doc(uid));
    batch.delete(_db.collection('doctors').doc(uid));
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────────────────────

  /// Quick counts for the dashboard summary cards
  Future<Map<String, int>> getDashboardStats() async {
    final snapshots = await Future.wait([
      _db.collection('patients').get(),
      _db.collection('doctors').get(),
      _db.collection('doctors').where('isApproved', isEqualTo: false).get(),
    ]);
    final totalPatients = snapshots[0].docs.length;
    final totalDoctors = snapshots[1].docs.length;
    final pendingDoctors = snapshots[2].docs.length;

    return {
      'totalPatients': totalPatients,
      'totalDoctors': totalDoctors,
      'pendingDoctors': pendingDoctors,
      'totalUsers': totalPatients + totalDoctors,
    };
  }
}
