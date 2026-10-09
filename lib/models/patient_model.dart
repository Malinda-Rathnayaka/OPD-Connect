import 'package:cloud_firestore/cloud_firestore.dart';

class PatientModel {
  final String id;
  final String fullName;
  final String nic;
  final String phone;
  final String email;
  final String preferredLanguage;
  final DateTime? createdAt;

  PatientModel({
    required this.id,
    required this.fullName,
    required this.nic,
    required this.phone,
    required this.email,
    this.preferredLanguage = 'English',
    this.createdAt,
  });

  factory PatientModel.fromMap(Map<String, dynamic> map, String id) {
    final dynamic createdAtValue = map['createdAt'];

    return PatientModel(
      id: id,
      fullName: map['fullName'] ?? '',
      nic: map['nic'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      preferredLanguage: map['preferredLanguage'] ?? 'English',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : createdAtValue is DateTime
              ? createdAtValue
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'nic': nic,
      'phone': phone,
      'email': email,
      'preferredLanguage': preferredLanguage,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    };
  }

  PatientModel copyWith({
    String? id,
    String? fullName,
    String? nic,
    String? phone,
    String? email,
    String? preferredLanguage,
    DateTime? createdAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      nic: nic ?? this.nic,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PatientModel(id: $id, fullName: $fullName, nic: $nic, phone: $phone, email: $email, preferredLanguage: $preferredLanguage, createdAt: $createdAt)';
  }
}
