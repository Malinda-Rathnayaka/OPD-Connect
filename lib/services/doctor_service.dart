import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
