import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorLeaveModel {
  final String id;
  final String doctorId;
  final String doctorName;
  final String date;
  final String reason;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorLeaveModel({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.date,
    required this.reason,
    required this.notes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DoctorLeaveModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    return DoctorLeaveModel(
      id: document.id,
      doctorId: data['doctorId']?.toString() ?? '',
      doctorName: data['doctorName']?.toString() ?? 'Doctor',
      date: data['date']?.toString() ?? '',
      reason: data['reason']?.toString() ?? '',
      notes: data['notes']?.toString() ?? '',
      status: data['status']?.toString() ?? 'PENDING',
      createdAt: _dateValue(data['createdAt']),
      updatedAt: _dateValue(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'date': date,
        'reason': reason,
        'notes': notes,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
