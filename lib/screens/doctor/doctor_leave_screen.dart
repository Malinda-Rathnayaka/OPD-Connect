import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/doctor/doctor_leave_model.dart';
import '../../services/doctor_service.dart';

class DoctorLeaveScreen extends StatefulWidget {
  const DoctorLeaveScreen({super.key});

  @override
  State<DoctorLeaveScreen> createState() => _DoctorLeaveScreenState();
}

class _DoctorLeaveScreenState extends State<DoctorLeaveScreen> {
  final DoctorService _service = DoctorService();
  static const _violet = Color(0xFF7C3AED);
  static const _dark = Color(0xFF0F172A);

  String get _doctorId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _doctorName =>
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email ??
      'Doctor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: Colors.white,
        title: const Text('Availability & Leaves'),
      ),
      body: StreamBuilder<List<DoctorLeaveModel>>(
        stream: _service.getDoctorLeaves(_doctorId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _message('Unable to load leave requests.');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final leaves = snapshot.data!;
          if (leaves.isEmpty) {
            return _message('No leave requests yet. Tap + to submit one.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _leaveCard(leaves[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        onPressed: () => _showLeaveDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Request Leave'),
      ),
    );
  }

  Widget _leaveCard(DoctorLeaveModel leave) {
    final pending = leave.status == 'PENDING';
    final colors = _statusColors(leave.status);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_busy, color: _violet),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(leave.date,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.$2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(leave.status,
                      style: TextStyle(
                          color: colors.$1,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Reason: ${leave.reason}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (leave.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Notes: ${leave.notes}'),
            ],
            if (pending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showLeaveDialog(leave: leave),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteLeave(leave),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showLeaveDialog({DoctorLeaveModel? leave}) async {
    final dateController = TextEditingController(text: leave?.date ?? _date(DateTime.now()));
    final reasonController = TextEditingController(text: leave?.reason ?? '');
    final notesController = TextEditingController(text: leave?.notes ?? '');
    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(leave == null ? 'Request Leave' : 'Edit Leave Request'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                      labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) dateController.text = _date(picked);
                  },
                ),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Personal, Medical, Academic, Emergency',
                  ),
                ),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Additional notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (dateController.text.isEmpty || reasonController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(dialogContext, {
                  'date': dateController.text,
                  'reason': reasonController.text.trim(),
                  'notes': notesController.text.trim(),
                });
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (result == null) return;
      if (leave == null) {
        final now = DateTime.now();
        await _service.createLeaveRequest(DoctorLeaveModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          doctorId: _doctorId,
          doctorName: _doctorName,
          date: result['date']!,
          reason: result['reason']!,
          notes: result['notes']!,
          status: 'PENDING',
          createdAt: now,
          updatedAt: now,
        ));
      } else {
        await _service.updateLeaveRequest(leave.id, result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave request saved.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save leave request: $error')));
      }
    } finally {
      dateController.dispose();
      reasonController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _deleteLeave(DoctorLeaveModel leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel leave request?'),
        content: Text('Cancel the request for ${leave.date}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel request')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteLeaveRequest(leave.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not cancel leave request: $error')));
      }
    }
  }

  Widget _message(String text) => Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(text, textAlign: TextAlign.center)),
      );

  (Color, Color) _statusColors(String status) => switch (status) {
        'APPROVED' => (const Color(0xFF059669), const Color(0xFFD1FAE5)),
        'REJECTED' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
        _ => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      };

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
