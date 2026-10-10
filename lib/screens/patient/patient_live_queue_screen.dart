import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientLiveQueueScreen extends StatelessWidget {
  PatientLiveQueueScreen({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final patientId = _auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: patientId == null
          ? const Center(child: Text('Sign in to view your live queue.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('appointments')
                  .where('patientId', isEqualTo: patientId)
                  .where('status', isEqualTo: 'confirmed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _Message(
                    'Unable to load your appointment queue.\n${snapshot.error}',
                  );
                }

                final appointments = snapshot.data?.docs ?? [];
                if (appointments.isEmpty) {
                  return const _Message(
                    'You do not have an active appointment.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: appointments
                      .map(
                        (appointment) => _QueueSessionCard(
                          firestore: _firestore,
                          patientId: patientId,
                          appointment: appointment.data(),
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }
}

class _QueueSessionCard extends StatelessWidget {
  const _QueueSessionCard({
    required this.firestore,
    required this.patientId,
    required this.appointment,
  });

  final FirebaseFirestore firestore;
  final String patientId;
  final Map<String, dynamic> appointment;

  String _dateLabel(dynamic value) {
    final date = value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return value?.toString() ?? '';
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = appointment['sessionId']?.toString() ?? '';
    if (sessionId.isEmpty) {
      return const _Message(
        'This appointment is not linked to a live session.',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: firestore.collection('sessions').doc(sessionId).snapshots(),
      builder: (context, sessionSnapshot) {
        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (sessionSnapshot.hasError) {
          return const _Message('Unable to load the doctor session.');
        }

        final session = sessionSnapshot.data?.data() ?? <String, dynamic>{};
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('sessions')
              .doc(sessionId)
              .collection('queue')
              .orderBy('order')
              .snapshots(),
          builder: (context, queueSnapshot) {
            if (queueSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            if (queueSnapshot.hasError) {
              return const _Message('Unable to load the live patient queue.');
            }

            final queue = queueSnapshot.data?.docs ?? [];
            final activePatients = queue
                .map((doc) => doc.data())
                .where((data) => data['status'] == 'IN_CONSULTATION')
                .toList();
            final activePatient = activePatients.isEmpty
                ? null
                : activePatients.first;
            final upcomingPatients = queue
                .map((doc) => doc.data())
                .where((data) => data['status'] == 'ARRIVED')
                .toList();
            final date =
                '${_dateLabel(session['slotDate'] ?? appointment['appointmentDate'])} · '
                '${session['timeSlot'] ?? appointment['appointmentTime'] ?? ''}';

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activePatient != null)
                    _CurrentPatientCard(
                      patient: activePatient,
                      appointmentTime: date,
                    )
                  else
                    _InfoCard(
                      message: 'The doctor has not started this session yet.',
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upcoming Patient List',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (upcomingPatients.isEmpty)
                    const _InfoCard(message: 'No upcoming patients.'),
                  ...upcomingPatients.map(
                    (patient) => _QueuePatientRow(patient: patient),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CurrentPatientCard extends StatelessWidget {
  const _CurrentPatientCard({
    required this.patient,
    required this.appointmentTime,
  });

  final Map<String, dynamic> patient;
  final String appointmentTime;

  @override
  Widget build(BuildContext context) {
    final token =
        patient['tokenNo']?.toString() ??
        patient['tokenNumber']?.toString() ??
        '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'IN CONSULTATION',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Token: $token',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            patient['patientName']?.toString() ?? 'Patient',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'NIC: ${patient['nic'] ?? ''} • Appt Time: $appointmentTime',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text(
            'The doctor is currently treating this patient.',
            style: TextStyle(color: Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }
}

class _QueuePatientRow extends StatelessWidget {
  const _QueuePatientRow({required this.patient});

  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    final token =
        patient['tokenNo']?.toString() ??
        patient['tokenNumber']?.toString() ??
        '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Text(
            token,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              patient['patientName']?.toString() ?? 'Patient',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ARRIVED',
              style: TextStyle(
                color: Color(0xFF15803D),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
