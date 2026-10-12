import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital_model.dart';

class HospitalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get all hospitals from the `hospitals` collection.
  Future<List<HospitalModel>> getAllHospitals() async {
    try {
      final snapshot = await _db.collection('hospitals').get();
      return snapshot.docs
          .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Get hospitals that contain the given clinic in their `clinics` array.
  Future<List<HospitalModel>> getHospitalsByClinic(String clinic) async {
    try {
      final snapshot = await _db
          .collection('hospitals')
          .where('clinics', arrayContains: clinic)
          .get();

      return snapshot.docs
          .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Get a hospital by Firestore document ID.
  Future<HospitalModel?> getHospital(String hospitalId) async {
    try {
      final doc = await _db.collection('hospitals').doc(hospitalId).get();
      if (doc.exists && doc.data() != null) {
        return HospitalModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (error) {
      rethrow;
    }
  }

  /// Search hospitals by name using a case-insensitive prefix search.
  Future<List<HospitalModel>> searchHospitals(String query) async {
    try {
      final normalizedQuery = query.trim();
      if (normalizedQuery.isEmpty) {
        return getAllHospitals();
      }

      final snapshot = await _db
          .collection('hospitals')
          .orderBy('name')
          .startAt([normalizedQuery])
          .endAt(['$normalizedQuery\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      rethrow;
    }
  }
}
