import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String? doctorId;

  const DoctorProfileScreen({super.key, this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final DoctorService _service = DoctorService();
  final ImagePicker _imagePicker = ImagePicker();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _specController = TextEditingController();
  final _phoneController = TextEditingController();
  final _roomController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;
  Uint8List? _pendingImage;
  String? _pendingImageType;

  String get _doctorId =>
      widget.doctorId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specController.dispose();
    _phoneController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _service.getDoctorProfile(_doctorId);
      if (!mounted) return;
      _nameController.text = profile['name']?.toString() ?? '';
      _specController.text = profile['specialization']?.toString() ?? '';
      _phoneController.text = profile['phone']?.toString() ?? '';
      _roomController.text = profile['roomNo']?.toString() ?? '';
      _emailController.text = profile['email']?.toString() ?? '';
      _profileImageUrl = profile['profileImageUrl']?.toString();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load doctor details: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _chooseProfileImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Choose an image smaller than 5 MB.')),
          );
        }
        return;
      }
      if (!mounted) return;
      final extension = image.name.split('.').last.toLowerCase();
      final contentType = image.mimeType ?? switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      setState(() {
        _pendingImage = bytes;
        _pendingImageType = contentType;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select image: $error')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the doctor’s name.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      String? imageUrl = _profileImageUrl;
      if (_pendingImage != null) {
        imageUrl = await _service.uploadDoctorProfileImage(
          doctorId: _doctorId,
          imageBytes: _pendingImage!,
          contentType: _pendingImageType ?? 'image/jpeg',
        );
      }
      await _service.updateDoctorProfile(
        doctorId: _doctorId,
        name: _nameController.text.trim(),
        specialization: _specController.text.trim(),
        phone: _phoneController.text.trim(),
        roomNo: _roomController.text.trim(),
        profileImageUrl: imageUrl,
      );
      if (!mounted) return;
      setState(() {
        _profileImageUrl = imageUrl;
        _pendingImage = null;
        _pendingImageType = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor profile updated.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not save profile: $error. Check that Firebase Storage is enabled and permits this doctor’s profile image.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access the doctor dashboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    try {
      await AuthService().signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not sign out: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Doctor Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfilePhoto(),
                  const SizedBox(height: 24),
                  _buildReadOnlyEmail(),
                  _buildInput('Doctor Full Name', _nameController,
                      icon: Icons.person_outline),
                  _buildInput('Specialization', _specController,
                      icon: Icons.medical_services_outlined),
                  _buildInput('Contact Phone', _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  _buildInput('Consultation Room Number', _roomController,
                      icon: Icons.meeting_room_outlined),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_pendingImage == null
                          ? 'Save Profile'
                          : 'Upload Photo & Save Profile'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _confirmLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfilePhoto() {
    ImageProvider? imageProvider;
    if (_pendingImage != null) {
      imageProvider = MemoryImage(_pendingImage!);
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 54,
          backgroundColor: const Color(0xFFDBEAFE),
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, size: 58, color: Color(0xFF2563EB))
              : null,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isSaving ? null : _chooseProfileImage,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(_pendingImage == null ? 'Choose profile photo' : 'Change photo'),
        ),
        if (_pendingImage != null)
          const Text('Photo selected. Save the profile to upload it.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildReadOnlyEmail() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: _emailController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Account Email',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: const Color(0xFFEFF4FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          scrollPadding: const EdgeInsets.only(bottom: 140),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}
