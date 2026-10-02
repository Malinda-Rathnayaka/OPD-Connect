import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';

/// View & Edit a single user's profile from the admin side.
class AdminUserDetailScreen extends StatefulWidget {
  final UserModel user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final AdminService _adminService = AdminService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isEditing = false;
  bool _isSaving = false;

  // Colors
  static const Color _primaryDark = Color(0xFF0F172A);
  static const Color _accent = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(
        text: widget.user.email.isNotEmpty ? widget.user.email : widget.user.emailOrPhone);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await _adminService.updateUser(widget.user.uid, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: Text('Permanently delete "${widget.user.name}"?\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _adminService.deleteUser(widget.user.uid);
      if (!mounted) return;
      Navigator.pop(context); // Go back to list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.user.name}" has been deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleApproval() async {
    final isCurrentlyApproved = widget.user.isApproved;
    try {
      if (isCurrentlyApproved) {
        await _adminService.rejectDoctor(widget.user.uid);
      } else {
        await _adminService.approveDoctor(widget.user.uid);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyApproved
              ? 'Doctor approval revoked.'
              : 'Doctor has been approved!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Refresh by going back
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = widget.user.role == 'doctor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_isEditing ? 'Edit Profile' : 'User Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit',
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete',
            onPressed: _deleteUser,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Profile header ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: isDoctor
                        ? const Color(0xFF8B5CF6).withOpacity(0.12)
                        : _accent.withOpacity(0.12),
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isDoctor ? const Color(0xFF8B5CF6) : _accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: _primaryDark),
                  ),
                  const SizedBox(height: 6),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDoctor
                          ? const Color(0xFF8B5CF6).withOpacity(0.1)
                          : const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.user.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDoctor ? const Color(0xFF8B5CF6) : _accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (isDoctor) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.user.isApproved
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.user.isApproved ? '✓ Approved' : '⏳ Pending Approval',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.user.isApproved
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Editable fields ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Account Information',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primaryDark)),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Email Address',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  // UID (read-only)
                  _buildInfoRow('User ID', widget.user.uid),
                  if (widget.user.createdAt != null)
                    _buildInfoRow(
                      'Registered',
                      '${widget.user.createdAt!.day}/${widget.user.createdAt!.month}/${widget.user.createdAt!.year}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Action buttons ──────────────────────────
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],

            // Doctor approval / rejection button
            if (isDoctor && !_isEditing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.user.isApproved
                        ? Colors.orange.shade700
                        : const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _toggleApproval,
                  icon: Icon(widget.user.isApproved
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded),
                  label: Text(
                    widget.user.isApproved ? 'Revoke Approval' : 'Approve Doctor',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(
        color: enabled ? _primaryDark : Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
