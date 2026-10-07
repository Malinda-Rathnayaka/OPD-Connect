import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'find_opd_hospital.dart';
import 'my_family_profile.dart';
import 'patient_home_screen.dart';
import 'select_appointment_slot.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;

  const DoctorAvailabilityScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<DoctorAvailabilityScreen> createState() => _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  Future<List<Map<String, dynamic>>> _loadDoctors() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .where('hospitalId', isEqualTo: widget.hospitalId)
        .get();

    final doctors = snapshot.docs.map((doc) {
      final data = doc.data();
      final doctorId = doc.id;
      final doctorName = (data['fullName'] ?? 'Doctor').toString();
      final department = (data['department'] ?? 'General').toString();
      final hospitalName = (data['hospitalName'] ?? widget.hospitalName).toString();
      final isOnDuty = data['isOnDuty'] == true;
      final avgWaitTime = data['avgWaitTime'] ?? 20;
      final patientRating = data['patientRating'] ?? 0.0;
      final availableSlots = data['availableSlots'];

      return {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'department': department,
        'hospitalName': hospitalName,
        'isOnDuty': isOnDuty,
        'avgWaitTime': avgWaitTime is num ? avgWaitTime.toInt() : 20,
        'patientRating': patientRating is num ? patientRating.toDouble() : 0.0,
        'availableSlots': availableSlots is List ? availableSlots.map((item) => item.toString()).toList() : <String>[],
        'createdAt': data['createdAt'],
      };
    }).toList();

    doctors.sort((a, b) {
      final aRating = (a['patientRating'] as double?) ?? 0.0;
      final bRating = (b['patientRating'] as double?) ?? 0.0;
      return bRating.compareTo(aRating);
    });

    return doctors;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(widget.hospitalName),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadDoctors(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load doctors. ${snapshot.error}'),
              );
            }

            final doctors = snapshot.data ?? const <Map<String, dynamic>>[];

            if (doctors.isEmpty) {
              return const Center(
                child: Text('No doctors available for this hospital.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                final doctorId = doctor['doctorId'] as String;
                final doctorName = doctor['doctorName'] as String;
                final department = doctor['department'] as String;
                final isOnDuty = doctor['isOnDuty'] as bool;
                final waitTimeMinutes = doctor['avgWaitTime'] as int;
                final waitTime = '$waitTimeMinutes mins';
                final rating = doctor['patientRating'] as double;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.medical_services_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctorName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      department,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isOnDuty ? Colors.green.shade50 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isOnDuty ? 'On Duty' : 'Off Duty',
                                  style: TextStyle(
                                    color: isOnDuty ? Colors.green : Colors.grey.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _InfoBox(
                                  label: 'Avg Wait Time',
                                  value: waitTime,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _InfoBox(
                                  label: 'Patient Rating',
                                  value: '${rating.toStringAsFixed(1)}/5',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SelectAppointmentSlotScreen(
                                      doctorId: doctorId,
                                      doctorName: doctorName,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Book Appointment'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PatientHomeScreen(),
                  ),
                );
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindOpdHospitalScreen(),
                  ),
                );
                break;
              case 2:
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyFamilyProfileScreen(),
                  ),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FindOpdHospitalScreen(),
                  ),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.queue_outlined),
              label: 'Queue',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
