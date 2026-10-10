import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
import '../models/family_member_model.dart';

class PatientService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get patient by Firestore document ID from the `patients` collection.
  /// If the patient record is not yet created, fall back to the `users` collection.
  Future<PatientModel?> getPatient(String patientId) async {
    try {
      final doc = await _db.collection('patients').doc(patientId).get();
      if (doc.exists && doc.data() != null) {
        return PatientModel.fromMap(doc.data()!, doc.id);
      }

      final userDoc = await _db.collection('users').doc(patientId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        return PatientModel(
          id: patientId,
          fullName: userData['name'] ?? userData['fullName'] ?? 'Patient',
          nic: userData['nic'] ?? '',
          phone: userData['phone'] ?? '',
          email: userData['email'] ?? '',
          preferredLanguage: userData['preferredLanguage'] ?? 'English',
          profileImageUrl: userData['profileImageUrl'] ?? '',
          createdAt: userData['createdAt'] is Timestamp
              ? (userData['createdAt'] as Timestamp).toDate()
              : null,
        );
      }

      return null;
    } catch (error) {
      rethrow;
    }
  }

  /// Create a new patient document in the `patients` collection.
  Future<void> createPatient(PatientModel patient) async {
    try {
      await _db.collection('patients').doc(patient.id).set(patient.toMap());
    } catch (error) {
      rethrow;
    }
  }

  /// Update an existing patient document in the `patients` collection.
  Future<void> updatePatient(PatientModel patient) async {
    try {
      await _db.collection('patients').doc(patient.id).update(patient.toMap());
    } catch (error) {
      rethrow;
    }
  }

  /// Delete a patient document by its Firestore document ID.
  Future<void> deletePatient(String patientId) async {
    try {
      await _db.collection('patients').doc(patientId).delete();
    } catch (error) {
      rethrow;
    }
  }

  /// Fetch all family members associated with a patient.
  Future<List<FamilyMemberModel>> getFamilyMembers(String patientId) async {
    try {
      final snapshot = await _db
          .collection('family_members')
          .where('patientId', isEqualTo: patientId)
          .get();

      return snapshot.docs
          .map((doc) => FamilyMemberModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (error) {
      rethrow;
    }
  }

  /// Add a new family member document to the `family_members` collection.
  Future<void> addFamilyMember(FamilyMemberModel member) async {
    try {
      await _db.collection('family_members').doc(member.id).set(member.toMap());
    } catch (error) {
      rethrow;
    }
  }

  /// Update an existing family member document.
  Future<void> updateFamilyMember(FamilyMemberModel member) async {
    try {
      await _db.collection('family_members').doc(member.id).update(member.toMap());
    } catch (error) {
      rethrow;
    }
  }

  /// Delete a family member document by its Firestore document ID.
  Future<void> deleteFamilyMember(String memberId) async {
    try {
      await _db.collection('family_members').doc(memberId).delete();
    } catch (error) {
      rethrow;
    }
  }
}
