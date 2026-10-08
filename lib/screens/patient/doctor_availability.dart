import 'package:flutter/material.dart';
import 'select_appointment_slot.dart';

class DoctorAvailabilityScreen extends StatelessWidget {
  final String? hospitalId;
  final String? hospitalName;
  final String? department;

  const DoctorAvailabilityScreen({
    super.key,
    this.hospitalId,
    this.hospitalName,
    this.department,
  });

  @override
  Widget build(BuildContext context) {
    return const SelectAppointmentSlotScreen();
  }
}
