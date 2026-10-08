import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/family_member_model.dart';
import '../../models/patient_model.dart';
import '../../services/patient_service.dart';
import 'department_select.dart';
import 'patient_home_screen.dart';

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

  String get _displayName =>
      _patient?.fullName.trim().isNotEmpty == true ? _patient!.fullName : (_auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@').first ?? 'Patient');

  String get _displayNic => _patient?.nic.trim().isNotEmpty == true ? _patient!.nic : '';
  String get _displayPhone => _patient?.phone.trim().isNotEmpty == true ? _patient!.phone : (_auth.currentUser?.phoneNumber ?? '');
  String get _displayLanguage => _patient?.preferredLanguage.trim().isNotEmpty == true ? _patient!.preferredLanguage : 'English';
  String get _profileImageUrl => _patient?.profileImageUrl ?? '';

  List<String> get _bookingOptions {
    final options = <String>['Myself ($_displayName)'];
    for (final member in _familyMembers) {
      options.add('${member.fullName} (${member.relationship})');
    }
    return options;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<PatientModel?> _loadPatientData(String patientId) async {
    print('DEBUG: === Starting data load ===');
    print('DEBUG: UID = $patientId');
    print('DEBUG: Email = ${_auth.currentUser?.email}');

    final userDoc = await _db.collection('users').doc(patientId).get();
    print('DEBUG: users doc exists = ${userDoc.exists}');
    print('DEBUG: users doc data = ${userDoc.data()}');

    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data()!;
      final patientName = userData['name']?.toString().trim();
      final patientNIC = await _getPatientNic(patientId);

      final patientData = PatientModel(
        id: userDoc.id,
        fullName: patientName != null && patientName.isNotEmpty ? patientName : 'Patient',
        nic: patientNIC,
        phone: userData['phone'] ?? '',
        email: userData['email'] ?? '',
        preferredLanguage: userData['preferredLanguage'] ?? 'English',
        profileImageUrl: userData['profileImageUrl'] ?? '',
        createdAt: userData['createdAt'] is Timestamp
            ? (userData['createdAt'] as Timestamp).toDate()
            : null,
      );
      print('DEBUG: Loaded from users - ${patientData.fullName}');
      return patientData;
    }

    final patientDoc = await _db.collection('patients').doc(patientId).get();
    print('DEBUG: patients doc exists = ${patientDoc.exists}');

    if (patientDoc.exists && patientDoc.data() != null) {
      final patientData = PatientModel.fromMap(patientDoc.data()!, patientDoc.id);
      print('DEBUG: Loaded from patients - ${patientData.fullName}');
      return patientData;
    }

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final fallbackPatient = PatientModel(
        id: patientId,
        fullName: currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Patient',
        nic: '',
        phone: currentUser.phoneNumber ?? '',
        email: currentUser.email ?? '',
        preferredLanguage: 'English',
        profileImageUrl: '',
        createdAt: DateTime.now(),
      );
      print('DEBUG: Loaded from FirebaseAuth fallback - ${fallbackPatient.fullName}');
      return fallbackPatient;
    }

    return null;
  }

  Future<String> _getPatientNic(String patientId) async {
    final patientDoc = await _db.collection('patients').doc(patientId).get();
    if (patientDoc.exists && patientDoc.data() != null) {
      return patientDoc.data()!['nic']?.toString() ?? '';
    }
    return '';
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final patientId = _patientId;
      final patient = await _loadPatientData(patientId);
      final familyMembers = (await _patientService.getFamilyMembers(patientId))
          .where((member) => member.fullName.trim().isNotEmpty)
          .toList();

      setState(() {
        _patient = patient ?? PatientModel(
          id: patientId,
          fullName: 'Patient',
          nic: '',
          phone: '',
          email: _auth.currentUser?.email ?? '',
          preferredLanguage: 'English',
          profileImageUrl: '',
          createdAt: DateTime.now(),
        );
        _familyMembers = familyMembers;
        _selectedBookingTarget = (_selectedBookingTarget != null && _bookingOptions.contains(_selectedBookingTarget))
            ? _selectedBookingTarget
            : 'Myself (${_displayName})';
        _isLoading = false;
      });

      print('DEBUG: Final patientName = ${_patient?.fullName ?? 'Patient'}');
    } catch (error) {
      setState(() {
        _patient = PatientModel(
          id: _patientId,
          fullName: _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@').first ?? 'Patient',
          nic: '',
          phone: _auth.currentUser?.phoneNumber ?? '',
          email: _auth.currentUser?.email ?? '',
          preferredLanguage: 'English',
          profileImageUrl: '',
          createdAt: DateTime.now(),
        );
        _familyMembers = [];
        _selectedBookingTarget = 'Myself (${_displayName})';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to load profile: $error')),
        );
      }
    }
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
      createdAt: _patient?.createdAt ?? DateTime.now(),
    );

    try {
      final patientDoc = await _db.collection('patients').doc(_patientId).get();
      if (patientDoc.exists) {
        await _db.collection('patients').doc(_patientId).update(updatedPatient.toMap());
      } else {
        await _db.collection('patients').doc(_patientId).set(updatedPatient.toMap());
      }

      await _db.collection('users').doc(_patientId).set({
        'name': fullName,
        'phone': phone,
        'email': email,
        'preferredLanguage': preferredLanguage,
        'profileImageUrl': profileImageUrl,
      }, SetOptions(merge: true));

      _patient = updatedPatient;
      setState(() {});
      if (!mounted) return;
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

  bool _isValidRemoteImageUrl(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    return normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('data:image/');
  }

  ImageProvider<Object>? _buildProfileImageProvider() {
    final imageUrl = _profileImageUrl.trim();
    if (imageUrl.isEmpty) return null;
    if (_isValidRemoteImageUrl(imageUrl)) {
      return NetworkImage(imageUrl);
    }
    if (!kIsWeb && imageUrl.startsWith('/')) {
      return FileImage(File(imageUrl));
    }
    return null;
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null) return;

      String imageUrl = '';
      if (kIsWeb) {
        imageUrl = pickedFile.path;
      } else {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('$_patientId.jpg');

        final file = File(pickedFile.path);
        await storageRef.putFile(file);
        imageUrl = await storageRef.getDownloadURL();
      }

      await _savePatientProfile(
        fullName: _displayName,
        nic: _displayNic,
        phone: _displayPhone,
        email: _patient?.email ?? _auth.currentUser?.email ?? '',
        preferredLanguage: _displayLanguage,
        profileImageUrl: imageUrl,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update profile picture: $error')),
      );
    }
  }

  Future<void> _showEditProfileDialog() async {
    final fullNameController = TextEditingController(text: _displayName);
    final nicController = TextEditingController(text: _displayNic);
    final phoneController = TextEditingController(text: _displayPhone);
    final emailController = TextEditingController(text: _patient?.email ?? _auth.currentUser?.email ?? '');
    final languageController = TextEditingController(text: _displayLanguage);
    final imageUrlController = TextEditingController(text: _profileImageUrl);

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

  Future<void> _showFamilyMemberDialog({FamilyMemberModel? existing}) async {
    final fullNameController = TextEditingController(text: existing?.fullName ?? '');
    final relationshipController = TextEditingController(text: existing?.relationship ?? '');
    final nicController = TextEditingController(text: existing?.nic ?? '');
    final ageController = TextEditingController(text: existing?.age.toString() ?? '');
    String genderValue = existing?.gender.isNotEmpty == true ? existing!.gender : 'Male';

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
                    final member = FamilyMemberModel(
                      id: existing?.id ?? _db.collection('family_members').doc().id,
                      patientId: _patientId,
                      fullName: fullNameController.text.trim(),
                      relationship: relationshipController.text.trim(),
                      nic: nicController.text.trim(),
                      age: int.tryParse(ageController.text.trim()) ?? 0,
                      gender: genderValue,
                      createdAt: existing?.createdAt ?? DateTime.now(),
                    );

                    try {
                      if (existing == null) {
                        await _db.collection('family_members').doc(member.id).set(member.toMap());
                      } else {
                        await _db.collection('family_members').doc(member.id).update(member.toMap());
                      }

                      await _loadData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null ? 'Family member added successfully' : 'Family member updated successfully'),
                        ),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Unable to save family member: $error')),
                      );
                    }
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

  Future<void> _deleteFamilyMember(FamilyMemberModel member) async {
    try {
      await _db.collection('family_members').doc(member.id).delete();
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member removed successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete family member: $error')),
      );
    }
  }

  void _goToBookingFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DepartmentSelectScreen()),
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
              } else if (value == 'remove') {
                _db.collection('patients').doc(_patientId).delete();
              } else if (value == 'logout') {
                _auth.signOut();
                if (!mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
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
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.blue.shade100,
                                  backgroundImage: _buildProfileImageProvider(),
                                  child: _buildProfileImageProvider() == null
                                      ? const Icon(Icons.person, size: 36, color: Colors.blue)
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: InkWell(
                                    onTap: _pickProfileImage,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: _bookingOptions
                          .map((value) => DropdownMenuItem<String>(value: value, child: Text(value)))
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showFamilyMemberDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Family Member'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                child: Card(
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
                                          child: const Icon(Icons.family_restroom, color: Colors.blue),
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
                                              _showFamilyMemberDialog(existing: member);
                                            } else if (value == 'delete') {
                                              _deleteFamilyMember(member);
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
                MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DepartmentSelectScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DepartmentSelectScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DepartmentSelectScreen()),
              );
              break;
            case 4:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_outlined), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
