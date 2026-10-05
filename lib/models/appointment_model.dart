import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String hospitalId;
  final String hospitalName;
  final String department;
  final String doctorId;
  final String doctorName;
  final DateTime? appointmentDate;
  final String appointmentTime;
  final int slotNumber;
  final String tokenNumber;
  final String status;
  final String referenceNumber;
  final DateTime? createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.hospitalId,
    required this.hospitalName,
    required this.department,
    required this.doctorId,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.slotNumber,
    required this.tokenNumber,
    required this.status,
    required this.referenceNumber,
    required this.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    final dynamic appointmentDateValue = map['appointmentDate'];
    final dynamic createdAtValue = map['createdAt'];

    return AppointmentModel(
      id: id,
      patientId: map['patientId'] ?? '',
      patientName: map['patientName'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      department: map['department'] ?? '',
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      appointmentDate: appointmentDateValue is Timestamp
          ? appointmentDateValue.toDate()
          : appointmentDateValue is DateTime
              ? appointmentDateValue
              : null,
      appointmentTime: map['appointmentTime'] ?? '',
      slotNumber: (map['slotNumber'] ?? 0) as int,
      tokenNumber: map['tokenNumber'] ?? '',
      status: map['status'] ?? '',
      referenceNumber: map['referenceNumber'] ?? '',
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
      'patientName': patientName,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      'department': department,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'appointmentDate': appointmentDate != null
          ? Timestamp.fromDate(appointmentDate!)
          : null,
      'appointmentTime': appointmentTime,
      'slotNumber': slotNumber,
      'tokenNumber': tokenNumber,
      'status': status,
      'referenceNumber': referenceNumber,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? hospitalId,
    String? hospitalName,
    String? department,
    String? doctorId,
    String? doctorName,
    DateTime? appointmentDate,
    String? appointmentTime,
    int? slotNumber,
    String? tokenNumber,
    String? status,
    String? referenceNumber,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      department: department ?? this.department,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      slotNumber: slotNumber ?? this.slotNumber,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      status: status ?? this.status,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppointmentModel(id: $id, patientId: $patientId, patientName: $patientName, hospitalId: $hospitalId, hospitalName: $hospitalName, department: $department, doctorId: $doctorId, doctorName: $doctorName, appointmentDate: $appointmentDate, appointmentTime: $appointmentTime, slotNumber: $slotNumber, tokenNumber: $tokenNumber, status: $status, referenceNumber: $referenceNumber, createdAt: $createdAt)';
  }
}
