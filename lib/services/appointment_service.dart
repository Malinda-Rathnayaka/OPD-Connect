import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create a new appointment document and return its Firestore document ID.
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = await _db.collection('appointments').add(appointment.toMap());
      return docRef.id;
    } catch (error) {
      rethrow;
    }
  }

  /// Get an appointment by Firestore document ID.
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      final doc = await _db.collection('appointments').doc(appointmentId).get();
      if (doc.exists && doc.data() != null) {
        return AppointmentModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (error) {
      rethrow;
    }
  }

  /// Get all appointments for a specific patient.
  Future<List<AppointmentModel>> getPatientAppointments(String patientId) async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Update the status of an appointment.
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _db.collection('appointments').doc(appointmentId).update({
        'status': status,
      });
    } catch (error) {
      rethrow;
    }
  }

  /// Mark an appointment as cancelled.
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(appointmentId, 'cancelled');
    } catch (error) {
      rethrow;
    }
  }

  /// Generate a reference number like OPD-2026-04821.
  String generateReferenceNumber() {
    final now = DateTime.now();
    final timestamp = now.microsecondsSinceEpoch.toString();
    final suffix = timestamp.substring(timestamp.length - 5);
    return 'OPD-${now.year}-$suffix';
  }

  /// Generate a token number like T-014.
  String generateTokenNumber(int slotNumber) {
    return 'T-${slotNumber.toString().padLeft(3, '0')}';
  }
}
