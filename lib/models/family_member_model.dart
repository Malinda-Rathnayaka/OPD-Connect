import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMemberModel {
  final String id;
  final String patientId;
  final String fullName;
  final String relationship;
  final String nic;
  final int age;
  final String gender;
  final DateTime? createdAt;

  FamilyMemberModel({
    required this.id,
    required this.patientId,
    required this.fullName,
    required this.relationship,
    required this.nic,
    required this.age,
    required this.gender,
    this.createdAt,
  });

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map, String id) {
    final dynamic createdAtValue = map['createdAt'];

    return FamilyMemberModel(
      id: id,
      patientId: map['patientId'] ?? '',
      fullName: map['fullName'] ?? '',
      relationship: map['relationship'] ?? '',
      nic: map['nic'] ?? '',
      age: (map['age'] ?? 0) as int,
      gender: map['gender'] ?? '',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is DateTime
              ? createdAtValue
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'fullName': fullName,
      'relationship': relationship,
      'nic': nic,
      'age': age,
      'gender': gender,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }

  FamilyMemberModel copyWith({
    String? id,
    String? patientId,
    String? fullName,
    String? relationship,
    String? nic,
    int? age,
    String? gender,
    DateTime? createdAt,
  }) {
    return FamilyMemberModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      fullName: fullName ?? this.fullName,
      relationship: relationship ?? this.relationship,
      nic: nic ?? this.nic,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'FamilyMemberModel(id: $id, patientId: $patientId, fullName: $fullName, relationship: $relationship, nic: $nic, age: $age, gender: $gender, createdAt: $createdAt)';
  }
}
