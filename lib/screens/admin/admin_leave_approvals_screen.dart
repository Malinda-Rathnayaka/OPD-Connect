import 'package:flutter/material.dart';

import '../../models/doctor/doctor_leave_model.dart';
import '../../services/admin_service.dart';

class AdminLeaveApprovalsScreen extends StatelessWidget {
  const AdminLeaveApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = AdminService();
    return StreamBuilder<List<DoctorLeaveModel>>(
      stream: service.getPendingDoctorLeaves(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load leave requests.'));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return const Center(child: Text('No pending leave requests.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _requestCard(context, service, requests[index]),
        );
      },
    );
  }

  Widget _requestCard(BuildContext context, AdminService service, DoctorLeaveModel leave) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(leave.doctorName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Leave date: ${leave.date}'),
          Text('Reason: ${leave.reason}'),
          if (leave.notes.isNotEmpty) Text('Notes: ${leave.notes}'),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton(
              onPressed: () => _changeStatus(context, service, leave, false),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _changeStatus(context, service, leave, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
              child: const Text('Approve'),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    AdminService service,
    DoctorLeaveModel leave,
    bool approve,
  ) async {
    try {
      if (approve) {
        await service.approveDoctorLeave(leave.id);
      } else {
        await service.rejectDoctorLeave(leave.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(approve ? 'Leave approved.' : 'Leave rejected.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update leave request: $error')));
      }
    }
  }
}
