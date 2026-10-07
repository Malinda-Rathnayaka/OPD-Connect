import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'doctor_availability.dart';
import 'my_family_profile.dart';
import 'patient_home_screen.dart';

class FindOpdHospitalScreen extends StatefulWidget {
  const FindOpdHospitalScreen({super.key});

  @override
  State<FindOpdHospitalScreen> createState() => _FindOpdHospitalScreenState();
}

class _FindOpdHospitalScreenState extends State<FindOpdHospitalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _districts = [
    'All Districts',
    'Colombo',
    'Gampaha',
    'Kalutara',
    'Kandy',
    'Matale',
    'Nuwara Eliya',
    'Galle',
    'Matara',
    'Hambantota',
    'Jaffna',
    'Kilinochchi',
    'Mannar',
    'Vavuniya',
    'Mullaitivu',
    'Batticaloa',
    'Ampara',
    'Trincomalee',
    'Kurunegala',
    'Puttalam',
    'Anuradhapura',
    'Polonnaruwa',
    'Badulla',
    'Monaragala',
    'Ratnapura',
    'Kegalle',
  ];

  final List<String> _categories = [
    'All',
    'General Medicine',
    'Dental',
    'Eye Clinic',
    'ENT',
    'Cardiology',
    'Pediatrics',
  ];

  String _selectedDistrict = 'All Districts';
  String _selectedCategory = 'All';
  late Future<List<Map<String, dynamic>>> _hospitalsFuture;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
    _hospitalsFuture = _fetchHospitals();
  }

  Future<List<Map<String, dynamic>>> _fetchHospitals() async {
    Query<Map<String, dynamic>> query = _firestore.collection('hospitals');

    if (_selectedDistrict != 'All Districts') {
      query = query.where('district', isEqualTo: _selectedDistrict);
    }

    if (_selectedCategory != 'All') {
      query = query.where('clinics', arrayContains: _selectedCategory);
    }

    final snapshot = await query.get();
    final hospitals = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final hospitalId = doc.id;
      final hospitalName = (data['name'] ?? 'Hospital').toString();
      final district = (data['district'] ?? 'Unknown').toString();
      final city = (data['city'] ?? '').toString();
      final address = (data['address'] ?? '').toString();
      final distanceValue = data['distance'] ?? 0.0;
      final isOpen = data['isOpen'] == true;
      final clinicsData = data['clinics'];
      final clinics = clinicsData is List
          ? clinicsData.map((item) => item.toString()).toList()
          : <String>[];
      final phone = (data['phone'] ?? '').toString();
      final nextSession = data['nextSession'];

      final doctorSnapshot = await _firestore
          .collection('doctors')
          .where('hospitalId', isEqualTo: hospitalId)
          .get();

      hospitals.add({
        'hospitalId': hospitalId,
        'hospitalName': hospitalName,
        'district': district,
        'city': city,
        'address': address,
        'distance': distanceValue is num
            ? '${distanceValue.toStringAsFixed(1)} km'
            : '0.0 km',
        'status': isOpen ? 'OPEN' : 'CLOSED',
        'statusColor': isOpen ? Colors.green : Colors.red,
        'clinics': clinics,
        'phone': phone,
        'nextSession': nextSession,
        'doctorCount': doctorSnapshot.docs.length,
      });
    }

    return hospitals;
  }

  void _reloadHospitals() {
    setState(() {
      _hospitalsFuture = _fetchHospitals();
    });
  }

  List<Map<String, dynamic>> _filterHospitals(List<Map<String, dynamic>> hospitals) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return hospitals;
    }

    return hospitals.where((hospital) {
      final hospitalName = (hospital['hospitalName'] as String).toLowerCase();
      final clinics = (hospital['clinics'] as List<String>).join(' ').toLowerCase();
      final district = (hospital['district'] as String).toLowerCase();

      return hospitalName.contains(query) ||
          clinics.contains(query) ||
          district.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final districtLabel = _selectedDistrict == 'All Districts'
        ? 'All Districts'
        : _selectedDistrict;
    final categoryLabel = _selectedCategory == 'All' ? 'All' : _selectedCategory;

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text('Find OPD Hospital'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedDistrict,
                decoration: InputDecoration(
                  labelText: 'District',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _districts
                    .map(
                      (district) => DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _selectedDistrict = value;
                  });
                  _reloadHospitals();
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search hospital or clinic',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;

                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue,
                      side: BorderSide(
                        color: isSelected ? Colors.blue : Colors.grey.shade400,
                        width: 1,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _reloadHospitals();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _hospitalsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Unable to load hospitals. ${snapshot.error}'),
                      );
                    }

                    final hospitals = _filterHospitals(snapshot.data ?? const []);

                    if (hospitals.isEmpty) {
                      return Center(
                        child: Text(
                          'No hospitals found for $districtLabel with $categoryLabel',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: hospitals.length,
                      itemBuilder: (context, index) {
                        final hospital = hospitals[index];
                        final hospitalName = hospital['hospitalName'] as String;
                        final hospitalId = hospital['hospitalId'] as String;
                        final status = hospital['status'] as String;
                        final statusColor = hospital['statusColor'] as Color;
                        final distance = hospital['distance'] as String;
                        final clinics = hospital['clinics'] as List<String>;
                        final doctorCount = hospital['doctorCount'] as int;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        distance,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Clinics',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (clinics.isEmpty)
                                    const Text('No listed clinics')
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: clinics
                                          .map(
                                            (clinic) => Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                clinic,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '$doctorCount available doctors',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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
                                            builder: (context) => DoctorAvailabilityScreen(
                                              hospitalId: hospitalId,
                                              hospitalName: hospitalName,
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
                                      child: const Text('View Doctors'),
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
              ),
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
                    builder: (context) => const DoctorAvailabilityScreen(
                      hospitalId: '',
                      hospitalName: 'Doctor Availability',
                    ),
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
