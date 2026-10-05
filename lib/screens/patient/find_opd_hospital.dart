import 'package:flutter/material.dart';
import 'doctor_availability.dart';

class FindOpdHospitalScreen extends StatelessWidget {
  const FindOpdHospitalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find OPD Hospital'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search Hospital Name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Colombo, LK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _FilterChip(label: 'General Medicine'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Dental'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Eye Clinic'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'ENT'),
                  SizedBox(width: 8),
                  _FilterChip(label: 'Cardiology'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _HospitalCard(
              hospitalName: 'Colombo National Hospital',
              status: 'OPEN',
              statusColor: Colors.green,
              distance: '2.3 km',
              clinics: 'Clinics: General, Dental, Eye, Cardiology',
              nextSession: 'Next Session: Mon 22 Sep',
            ),
            const SizedBox(height: 12),
            const _HospitalCard(
              hospitalName: 'Sri Jayawardenepura General Hospital',
              status: 'OPEN',
              statusColor: Colors.green,
              distance: '6.8 km',
              clinics: 'Clinics: General, ENT, Cardiology',
              nextSession: 'Next Session: Tue 23 Sep',
            ),
            const SizedBox(height: 12),
            const _HospitalCard(
              hospitalName: 'North Colombo Teaching Hospital',
              status: 'CLOSED',
              statusColor: Colors.red,
              distance: '14.5 km',
              clinics: 'Clinics: General, Eye, ENT',
              nextSession: 'Next Session: Tue 23 Sep',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (_) {},
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final String hospitalName;
  final String status;
  final Color statusColor;
  final String distance;
  final String clinics;
  final String nextSession;

  const _HospitalCard({
    required this.hospitalName,
    required this.status,
    required this.statusColor,
    required this.distance,
    required this.clinics,
    required this.nextSession,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    hospitalName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              distance,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(clinics),
            const SizedBox(height: 6),
            Text(nextSession),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorAvailabilityScreen(),
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
                child: const Text('View Doctors'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
