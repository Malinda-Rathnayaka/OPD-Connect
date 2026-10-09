import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String id;
  final String fullName;
  final String department;
  final String hospitalId;
  final String hospitalName;
  final bool isOnDuty;
  final int avgWaitTime;
  final double patientRating;
  final List<String> availableSlots;
  final DateTime? createdAt;

  DoctorModel({
    required this.id,
    required this.fullName,
    required this.department,
    required this.hospitalId,
    required this.hospitalName,
    required this.isOnDuty,
    required this.avgWaitTime,
    required this.patientRating,
    required this.availableSlots,
    required this.createdAt,
  });

  factory DoctorModel.fromMap(Map<String, dynamic> map, String id) {
    final dynamic createdAtValue = map['createdAt'];

    return DoctorModel(
      id: id,
      fullName: map['fullName'] ?? '',
      department: map['department'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      isOnDuty: map['isOnDuty'] ?? false,
      avgWaitTime: (map['avgWaitTime'] ?? 0) as int,
      patientRating: (map['patientRating'] as num?)?.toDouble() ?? 0.0,
      availableSlots: (map['availableSlots'] as List<dynamic>? ?? const [])
          .map((slot) => slot.toString())
          .toList(),
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
      'department': department,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'isOnDuty': isOnDuty,
      'avgWaitTime': avgWaitTime,
      'patientRating': patientRating,
      'availableSlots': availableSlots,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  DoctorModel copyWith({
    String? id,
    String? fullName,
    String? department,
    String? hospitalId,
    String? hospitalName,
    bool? isOnDuty,
    int? avgWaitTime,
    double? patientRating,
    List<String>? availableSlots,
    DateTime? createdAt,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      department: department ?? this.department,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      isOnDuty: isOnDuty ?? this.isOnDuty,
      avgWaitTime: avgWaitTime ?? this.avgWaitTime,
      patientRating: patientRating ?? this.patientRating,
      availableSlots: availableSlots ?? this.availableSlots,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'DoctorModel(id: $id, fullName: $fullName, department: $department, hospitalId: $hospitalId, hospitalName: $hospitalName, isOnDuty: $isOnDuty, avgWaitTime: $avgWaitTime, patientRating: $patientRating, availableSlots: $availableSlots, createdAt: $createdAt)';
  }
}
