import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'patient_home_screen.dart';
import 'find_opd_hospital.dart';
import 'doctor_availability.dart';
import '../../models/family_member_model.dart';
import '../../models/patient_model.dart';
import '../../services/patient_service.dart';

class MyFamilyProfileScreen extends StatefulWidget {
  const MyFamilyProfileScreen({super.key});

  @override
  State<MyFamilyProfileScreen> createState() => _MyFamilyProfileScreenState();
}

class _MyFamilyProfileScreenState extends State<MyFamilyProfileScreen> {
  final PatientService _patientService = PatientService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PatientModel? _patient;
  List<FamilyMemberModel> _familyMembers = [];
  String? _selectedBookingTarget;
  bool _isLoading = true;

  String get _patientId => _auth.currentUser?.uid ?? 'guest-patient';

  String get _displayName => _patient?.fullName.isNotEmpty == true
      ? _patient!.fullName
      : 'Kamal Perera';

  String get _displayNic => _patient?.nic.isNotEmpty == true
      ? _patient!.nic
      : '198920482V';

  String get _displayPhone => _patient?.phone.isNotEmpty == true
      ? _patient!.phone
      : '+94 77 123 4567';

  String get _displayLanguage => _patient?.preferredLanguage.isNotEmpty == true
      ? _patient!.preferredLanguage
      : 'English';

  String get _profileImageUrl => _patient?.profileImageUrl ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patient = await _patientService.getPatient(_patientId);
      final familyMembers = await _patientService.getFamilyMembers(_patientId);

      _patient = patient ??
          PatientModel(
            id: _patientId,
            fullName: 'Kamal Perera',
            nic: '198920482V',
            phone: '+94 77 123 4567',
            email: '',
            preferredLanguage: 'English',
            profileImageUrl: '',
            createdAt: DateTime.now(),
          );
      _familyMembers = familyMembers;
      _selectedBookingTarget ??= 'Myself ($_displayName)';
      if (!_bookingOptions.contains(_selectedBookingTarget)) {
        _selectedBookingTarget = 'Myself ($_displayName)';
      }
    } catch (error) {
      _patient ??= PatientModel(
        id: _patientId,
        fullName: 'Kamal Perera',
        nic: '198920482V',
        phone: '+94 77 123 4567',
        email: '',
        preferredLanguage: 'English',
        profileImageUrl: '',
        createdAt: DateTime.now(),
      );
      _familyMembers = [];
      _selectedBookingTarget ??= 'Myself ($_displayName)';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  List<String> get _bookingOptions {
    final options = <String>['Myself ($_displayName)'];
    options.addAll(
      _familyMembers.map(
        (member) => '${member.fullName} (${member.relationship})',
      ),
    );
    return options;
  }

  Future<void> _savePatientProfile({
    required String fullName,
    required String nic,
    required String phone,
    required String email,
    required String preferredLanguage,
    required String profileImageUrl,
  }) async {
    final updatedPatient = PatientModel(
      id: _patientId,
      fullName: fullName,
      nic: nic,
      phone: phone,
      email: email,
      preferredLanguage: preferredLanguage,
      profileImageUrl: profileImageUrl,
      createdAt: _patient?.createdAt,
    );

    try {
      final docRef = _db.collection('patients').doc(_patientId);
      final existing = await docRef.get();
      if (existing.exists) {
        await _patientService.updatePatient(updatedPatient);
      } else {
        await _patientService.createPatient(updatedPatient);
      }

      _patient = updatedPatient;
      _selectedBookingTarget ??= 'Myself ($_displayName)';
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update profile: $error')),
      );
    }
  }

  Future<void> _updateProfileImage(String imageUrl) async {
    await _savePatientProfile(
      fullName: _displayName,
      nic: _displayNic,
      phone: _displayPhone,
      email: _patient?.email ?? '',
      preferredLanguage: _displayLanguage,
      profileImageUrl: imageUrl,
    );
  }

  Future<void> _removeProfile() async {
    try {
      await _patientService.deletePatient(_patientId);
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to remove profile: $error')),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _saveFamilyMember({
    FamilyMemberModel? existing,
    required String fullName,
    required String relationship,
    required String nic,
    required int age,
    required String gender,
  }) async {
    try {
      final member = FamilyMemberModel(
        id: existing?.id ?? _db.collection('family_members').doc().id,
        patientId: _patientId,
        fullName: fullName,
        relationship: relationship,
        nic: nic,
        age: age,
        gender: gender,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      if (existing == null) {
        await _db.collection('family_members').doc(member.id).set(member.toMap());
      } else {
        await _patientService.updateFamilyMember(member);
      }

      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Family member added' : 'Family member updated'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save family member: $error')),
      );
    }
  }

  Future<void> _deleteFamilyMember(FamilyMemberModel member) async {
    try {
      await _patientService.deleteFamilyMember(member.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member removed')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete family member: $error')),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final fullNameController = TextEditingController(text: _displayName);
    final nicController = TextEditingController(text: _displayNic);
    final phoneController = TextEditingController(text: _displayPhone);
    final emailController = TextEditingController(text: _patient?.email ?? '');
    final languageController = TextEditingController(text: _displayLanguage);
    final imageUrlController = TextEditingController(text: _profileImageUrl);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: nicController,
                  decoration: const InputDecoration(labelText: 'NIC'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: languageController,
                  decoration: const InputDecoration(labelText: 'Preferred Language'),
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Profile Picture URL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _savePatientProfile(
                  fullName: fullNameController.text.trim(),
                  nic: nicController.text.trim(),
                  phone: phoneController.text.trim(),
                  email: emailController.text.trim(),
                  preferredLanguage: languageController.text.trim(),
                  profileImageUrl: imageUrlController.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showProfilePictureDialog() async {
    final imageUrlController = TextEditingController(text: _profileImageUrl);

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Profile Picture'),
          content: TextField(
            controller: imageUrlController,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _updateProfileImage(imageUrlController.text.trim());
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFamilyMemberDialog({FamilyMemberModel? existing}) async {
    final fullNameController = TextEditingController(text: existing?.fullName ?? '');
    final relationshipController = TextEditingController(text: existing?.relationship ?? '');
    final nicController = TextEditingController(text: existing?.nic ?? '');
    final ageController = TextEditingController(text: existing?.age.toString() ?? '');
    String genderValue = existing?.gender.isNotEmpty == true ? existing!.gender : 'Male';

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add New Family Member' : 'Edit Family Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: fullNameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: relationshipController,
                      decoration: const InputDecoration(labelText: 'Relationship'),
                    ),
                    TextField(
                      controller: nicController,
                      decoration: const InputDecoration(labelText: 'NIC'),
                    ),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                    ),
                    DropdownButtonFormField<String>(
                      value: genderValue,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            genderValue = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _saveFamilyMember(
                      existing: existing,
                      fullName: fullNameController.text.trim(),
                      relationship: relationshipController.text.trim(),
                      nic: nicController.text.trim(),
                      age: int.tryParse(ageController.text.trim()) ?? 0,
                      gender: genderValue,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _goToBookingFlow() {
    _navigateTo(const FindOpdHospitalScreen());
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('My Family & Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditProfileDialog();
              } else if (value == 'picture') {
                _showProfilePictureDialog();
              } else if (value == 'remove') {
                _removeProfile();
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
              PopupMenuItem(value: 'picture', child: Text('Add/Change Picture')),
              PopupMenuItem(value: 'remove', child: Text('Remove Profile')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditProfileDialog();
                                } else if (value == 'picture') {
                                  _showProfilePictureDialog();
                                } else if (value == 'remove') {
                                  _removeProfile();
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
                                PopupMenuItem(value: 'picture', child: Text('Add/Change Picture')),
                                PopupMenuItem(value: 'remove', child: Text('Remove Profile')),
                              ],
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: _profileImageUrl.isNotEmpty
                                    ? NetworkImage(_profileImageUrl)
                                    : null,
                                child: _profileImageUrl.isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 36,
                                        color: Colors.blue,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('NIC: $_displayNic'),
                                  const SizedBox(height: 4),
                                  Text('Phone: $_displayPhone'),
                                  const SizedBox(height: 4),
                                  Text('Preferred Language: $_displayLanguage'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Active Booking Target',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _bookingOptions.contains(_selectedBookingTarget)
                          ? _selectedBookingTarget
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Booking for',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: _bookingOptions
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBookingTarget = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _goToBookingFlow,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue to Booking'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Registered Family Members',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showFamilyMemberDialog();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Family Member'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_familyMembers.isEmpty)
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No family members added yet.'),
                        ),
                      )
                    else
                      Column(
                        children: _familyMembers
                            .map(
                              (member) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _FamilyMemberCard(
                                  member: member,
                                  onEdit: () {
                                    _showFamilyMemberDialog(existing: member);
                                  },
                                  onDelete: () {
                                    _deleteFamilyMember(member);
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 4,
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

class _FamilyMemberCard extends StatelessWidget {
  final FamilyMemberModel member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FamilyMemberCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(
                Icons.family_restroom,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Relationship: ${member.relationship}'),
                  const SizedBox(height: 4),
                  Text('NIC: ${member.nic}'),
                  const SizedBox(height: 4),
                  Text('Age: ${member.age}'),
                  const SizedBox(height: 4),
                  Text('Gender: ${member.gender}'),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
