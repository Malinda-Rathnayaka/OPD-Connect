import 'package:flutter/material.dart';
import 'patient_home_screen.dart';
import 'doctor_availability.dart';
import 'my_family_profile.dart';

class FindOpdHospitalScreen extends StatefulWidget {
  const FindOpdHospitalScreen({super.key});

  @override
  State<FindOpdHospitalScreen> createState() => _FindOpdHospitalScreenState();
}

class _FindOpdHospitalScreenState extends State<FindOpdHospitalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _hospitals = const [
    {
      'hospitalName': 'Colombo National Hospital',
      'status': 'OPEN',
      'statusColor': Colors.green,
      'distance': '2.3 km',
      'clinics': 'General Medicine, Dental, Eye Clinic, Cardiology',
      'nextSession': 'Mon 22 Sep',
    },
    {
      'hospitalName': 'Sri Jayawardenepura General Hospital',
      'status': 'OPEN',
      'statusColor': Colors.green,
      'distance': '6.8 km',
      'clinics': 'General Medicine, ENT, Cardiology',
      'nextSession': 'Tue 23 Sep',
    },
    {
      'hospitalName': 'North Colombo Teaching Hospital',
      'status': 'CLOSED',
      'statusColor': Colors.red,
      'distance': '14.5 km',
      'clinics': 'General Medicine, Eye Clinic, ENT',
      'nextSession': 'Tue 23 Sep',
    },
  ];

  final List<String> _categories = const [
    'All',
    'General Medicine',
    'Dental',
    'Eye Clinic',
    'ENT',
    'Cardiology',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredHospitals {
    final query = _searchController.text.trim().toLowerCase();

    return _hospitals.where((hospital) {
      final hospitalName = (hospital['hospitalName'] as String).toLowerCase();
      final clinics = (hospital['clinics'] as String).toLowerCase();
      final nextSession = (hospital['nextSession'] as String).toLowerCase();

      final matchesSearch = query.isEmpty ||
          hospitalName.contains(query) ||
          clinics.contains(query) ||
          nextSession.contains(query);

      final matchesCategory = _selectedCategory == 'All' ||
          clinics.contains(_selectedCategory.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredHospitals = _filteredHospitals;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
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
              controller: _searchController,
              onChanged: (_) {
                setState(() {});
              },
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
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: category,
                      isSelected: isSelected,
                      onSelected: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (filteredHospitals.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hospitals match your search or selected category.'),
                ),
              )
            else
              ...filteredHospitals.map((hospital) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _HospitalCard(
                    hospitalName: hospital['hospitalName'] as String,
                    status: hospital['status'] as String,
                    statusColor: hospital['statusColor'] as Color,
                    distance: hospital['distance'] as String,
                    clinics: 'Clinics: ${hospital['clinics'] as String}',
                    nextSession: 'Next Session: ${hospital['nextSession'] as String}',
                  ),
                );
              }),
          ],
        ),
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
                  builder: (context) => const DoctorAvailabilityScreen(),
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.blue,
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blue.shade800,
      ),
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.blue.shade200,
      ),
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
