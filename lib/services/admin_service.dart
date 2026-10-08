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
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Real-time stream of all doctors
  Stream<List<UserModel>> getDoctorsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Real-time stream of doctors awaiting admin approval
  Stream<List<UserModel>> getPendingDoctorsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetch a single user by UID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────

  /// Update user profile fields (name, phone, email, etc.)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Approve a doctor account so they can log in to the dashboard
  Future<void> approveDoctor(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': true,
      'isVerified': true,
    });
  }

  /// Reject / revoke a doctor's approval
  Future<void> rejectDoctor(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isApproved': false,
      'isVerified': false,
    });
  }

  // ─────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────

  /// Delete a user's Firestore document.
  /// (Firebase Auth account deletion requires the Admin SDK or
  ///  the user to re-authenticate — Firestore doc is enough for
  ///  blocking access via isVerified / isApproved flags.)
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ─────────────────────────────────────────────────────────
  // DASHBOARD STATS
  // ─────────────────────────────────────────────────────────

  /// Quick counts for the dashboard summary cards
  Future<Map<String, int>> getDashboardStats() async {
    final usersSnapshot = await _db.collection('users').get();
    int totalPatients = 0;
    int totalDoctors = 0;
    int pendingDoctors = 0;

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final role = data['role'] ?? '';
      if (role == 'patient') {
        totalPatients++;
      } else if (role == 'doctor') {
        totalDoctors++;
        if (data['isApproved'] == false) pendingDoctors++;
      }
    }

    return {
      'totalPatients': totalPatients,
      'totalDoctors': totalDoctors,
      'pendingDoctors': pendingDoctors,
      'totalUsers': totalPatients + totalDoctors,
    };
  }
}
