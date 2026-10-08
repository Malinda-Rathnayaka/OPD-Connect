import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'department_select.dart';
import 'my_family_profile.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 0;
  int _selectedProfileIndex = 0;
  String _patientName = 'Patient';
  bool _isLoading = true;
  List<Map<String, dynamic>> _familyMembers = [];
  Map<String, dynamic>? _activeAppointment;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _patientName = 'Patient';
          _isLoading = false;
        });
        return;
      }

      final patientId = user.uid;
      final userDoc = await _firestore.collection('users').doc(patientId).get();

      String patientName = 'Patient';

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
          patientName = data['name'].toString().trim();
        }
      }

      final patientDoc = await _firestore.collection('patients').doc(patientId).get();
      if (patientDoc.exists && patientDoc.data() != null) {
        final data = patientDoc.data()!;
        if (patientName == 'Patient' || patientName.trim().isEmpty) {
          final fullName = data['fullName']?.toString().trim();
          if (fullName != null && fullName.isNotEmpty) {
            patientName = fullName;
          }
        }
      }

      final familySnapshot = await _firestore
          .collection('family_members')
          .where('patientId', isEqualTo: patientId)
          .get();

      final validFamilyMembers = familySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((member) =>
              member['fullName'] != null &&
              member['fullName'].toString().trim().isNotEmpty)
          .toList();

      final appointmentSnapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'confirmed')
          .limit(1)
          .get();

      setState(() {
        _selectedProfileIndex = 0;
        _patientName = patientName;
        _familyMembers = validFamilyMembers;
        _activeAppointment = appointmentSnapshot.docs.isNotEmpty
            ? {'id': appointmentSnapshot.docs.first.id, ...appointmentSnapshot.docs.first.data()}
            : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _patientName = _auth.currentUser?.displayName ??
            _auth.currentUser?.email?.split('@').first ??
            'Patient';
        _isLoading = false;
      });
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        _navigateTo(const DepartmentSelectScreen());
        break;
      case 2:
        _navigateTo(const DepartmentSelectScreen());
        break;
      case 3:
        _navigateTo(const DepartmentSelectScreen());
        break;
      case 4:
        _navigateTo(const MyFamilyProfileScreen());
        break;
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
  }

  Widget _buildProfileTab({
    required String title,
    required String subtitle,
    required String initials,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? Colors.blue : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: selected ? Colors.white : Colors.blue.shade50,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: selected ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileTabs = <Widget>[
      _buildProfileTab(
        title: _patientName,
        subtitle: 'Me',
        initials: _getInitials(_patientName),
        selected: _selectedProfileIndex == 0,
      ),
    ];

    for (var i = 0; i < _familyMembers.length; i++) {
      final member = _familyMembers[i];
      final name = member['fullName']?.toString().trim() ?? '';
      final relation = member['relationship']?.toString().trim() ?? '';

      if (name.isEmpty) continue;

      profileTabs.add(
        _buildProfileTab(
          title: name,
          subtitle: relation,
          initials: _getInitials(name),
          selected: _selectedProfileIndex == i + 1,
        ),
      );
    }

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ayubowan / Welcome',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                _patientName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _navigateTo(const MyFamilyProfileScreen()),
              icon: const Icon(Icons.notifications_none_outlined),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: profileTabs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProfileIndex = index;
                        });
                      },
                      child: profileTabs[index],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.amber.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.brown),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'ACTIVE QUEUE TRACKER',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '3 Patients Ahead',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Colombo General · Dental Clinic · Token #14',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_activeAppointment != null)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.blue,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'UPCOMING APPOINTMENT',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Confirmed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '${_activeAppointment!['doctorName'] ?? 'Doctor'} (${_activeAppointment!['department'] ?? 'Department'})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _activeAppointment!['hospitalName'] ?? 'Hospital',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_activeAppointment!['appointmentDate'] ?? ''} · ${_activeAppointment!['appointmentTime'] ?? ''}',
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: Colors.grey.shade200,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 32, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          'No upcoming appointments',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap the button below to book your first appointment',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateTo(const MyFamilyProfileScreen()),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('New OPD Appointment Booking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Quick Tools',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _QuickToolCard(
                    icon: Icons.calendar_today,
                    title: 'My Bookings',
                    subtitle: 'View or edit sessions',
                    onTap: () => _navigateTo(const DepartmentSelectScreen()),
                  ),
                  _QuickToolCard(
                    icon: Icons.people,
                    title: 'Queue Status',
                    subtitle: 'Check live counters',
                    onTap: () => _navigateTo(const DepartmentSelectScreen()),
                  ),
                  _QuickToolCard(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Announcements & news',
                    onTap: () => _navigateTo(const MyFamilyProfileScreen()),
                  ),
                  _QuickToolCard(
                    icon: Icons.person,
                    title: 'Profile',
                    subtitle: 'Family member details',
                    onTap: () => _navigateTo(const MyFamilyProfileScreen()),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: _handleBottomNavTap,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Appointments'),
            BottomNavigationBarItem(icon: Icon(Icons.queue_outlined), label: 'Queue'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
