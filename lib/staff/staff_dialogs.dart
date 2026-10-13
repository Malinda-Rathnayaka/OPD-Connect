import 'package:flutter/material.dart';

import 'staff_controller.dart';
import 'staff_models.dart';
import 'staff_widgets.dart';

enum AccountDialogMode { details, edit, review }

class AccountDialog extends StatefulWidget {
  final StaffController controller;
  final StaffAccount account;
  final AccountDialogMode mode;
  const AccountDialog({
    super.key,
    required this.controller,
    required this.account,
    this.mode = AccountDialogMode.details,
  });
  @override
  State<AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<AccountDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _phone, _department;
  late String _staffRole;
  bool _identityChecked = false, _credentialsChecked = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account.name);
    _phone = TextEditingController(text: widget.account.phone);
    _department = TextEditingController(text: widget.account.department);
    _staffRole = widget.account.staffRole;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _department.dispose();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final a = widget.account;
    final review = widget.mode == AccountDialogMode.review;
    final edit = widget.mode == AccountDialogMode.edit;
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review
                              ? 'Review registration'
                              : edit
                              ? 'Edit account'
                              : 'Account details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      AccountAvatar(a, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              a.roleLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            StatusPill.account(a),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (edit) ...[
                    TextFormField(
                      controller: _name,
                      readOnly: _busy,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) => (v ?? '').trim().length < 2
                          ? 'Enter a full name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phone,
                      readOnly: _busy,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.isNotEmpty &&
                              !RegExp(r'^\+?[\d\s()-]{7,20}$').hasMatch(v)
                          ? 'Enter a valid phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _department,
                      readOnly: _busy,
                      decoration: const InputDecoration(
                        labelText: 'Department / team',
                      ),
                    ),
                    if (a.role == 'admin' &&
                        a.id != widget.controller.actorId &&
                        widget.controller.canManageStaff) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _staffRole,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Staff role',
                        ),
                        items:
                            const [
                                  'Super administrator',
                                  'Hospital administrator',
                                  'Support coordinator',
                                ]
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(
                                      r,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: _busy
                            ? null
                            : (v) => setState(() => _staffRole = v!),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const InfoBanner(
                      'The login email stays unchanged. Contact the account owner to update their sign-in details.',
                    ),
                  ] else ...[
                    _field('Email address', a.email),
                    _field(
                      'Phone number',
                      a.phone.isEmpty ? 'Not provided' : a.phone,
                    ),
                    _field(
                      'Department',
                      a.department.isEmpty ? 'Not assigned' : a.department,
                    ),
                    _field('Registered', readableDate(a.createdAt)),
                    if (a.role == 'doctor')
                      _field(
                        'Medical registration',
                        a.registration.isEmpty
                            ? 'Not provided'
                            : a.registration,
                      ),
                    if (a.nic.isNotEmpty) _field('Identity number', a.nic),
                    if (a.reviewNote.isNotEmpty)
                      _field('Last decision', a.reviewNote),
                    if (a.accountStatusReason.isNotEmpty)
                      _field('Account status reason', a.accountStatusReason),
                  ],
                  if (review) ...[
                    const SizedBox(height: 16),
                    InfoBanner(
                      widget.controller.preview
                          ? 'Example registration. In a live review, check the doctor’s identity and medical registration with the hospital’s approved process.'
                          : 'Confirm the doctor’s identity and medical registration using the hospital’s approved process before granting access.',
                      warning: true,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _identityChecked,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _identityChecked = v!),
                      title: const Text(
                        'Identity and contact details checked',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _credentialsChecked,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() => _credentialsChecked = v!),
                      title: const Text(
                        'Medical registration and hospital assignment checked',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    InfoBanner(_error!, warning: true),
                  ],
                  if (review &&
                      widget.controller.reviewUnavailableReason != null) ...[
                    const SizedBox(height: 12),
                    InfoBanner(
                      widget.controller.reviewUnavailableReason!,
                      warning: true,
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        if (edit)
                          FilledButton(
                            onPressed: () {
                              if (!_form.currentState!.validate()) return;
                              _perform(
                                () => widget.controller.updateAccount(
                                  a,
                                  {
                                    'name': _name.text.trim(),
                                    'phone': _phone.text.trim(),
                                    'department': _department.text.trim(),
                                    if (a.role == 'admin' &&
                                        _staffRole != a.staffRole)
                                      'staffRole': _staffRole,
                                  },
                                  'Account details updated',
                                  '${a.name} · Name: ${_name.text.trim()} · Phone: ${_phone.text.trim()} · Team: ${_department.text.trim()}${a.role == 'admin' ? ' · Role: $_staffRole' : ''}',
                                ),
                              );
                            },
                            child: const Text('Save changes'),
                          ),
                        if (review) ...[
                          OutlinedButton(
                            onPressed: !widget.controller.canReview
                                ? null
                                : () async {
                                    final reason = await reasonDialog(
                                      context,
                                      'Reject registration',
                                      'The account will remain on record. Explain what needs to be corrected before this doctor can be approved.',
                                      'Reject registration',
                                    );
                                    if (reason != null && mounted) {
                                      _perform(
                                        () => widget.controller.review(
                                          a,
                                          approve: false,
                                          reason: reason,
                                        ),
                                      );
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: StaffStyle.red,
                            ),
                            child: const Text('Reject'),
                          ),
                          FilledButton.icon(
                            onPressed:
                                _identityChecked &&
                                    _credentialsChecked &&
                                    widget.controller.canReview
                                ? () => _perform(
                                    () => widget.controller.review(
                                      a,
                                      approve: true,
                                      identityChecked: _identityChecked,
                                      credentialsChecked: _credentialsChecked,
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve doctor'),
                          ),
                        ],
                        if (!edit && !review)
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

Future<String?> reasonDialog(
  BuildContext context,
  String title,
  String detail,
  String action,
) async {
  final controller = TextEditingController();
  final key = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 18),
              TextFormField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'Explain the change for the activity record',
                ),
                validator: (v) => (v ?? '').trim().length < 8
                    ? 'Enter a reason of at least 8 characters'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (key.currentState!.validate()) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: Text(action),
        ),
      ],
    ),
  );
  // Dialog exit animations can still reference its TextField for one frame.
  await Future<void>.delayed(const Duration(milliseconds: 250));
  controller.dispose();
  return result;
}

class StaffInviteDialog extends StatefulWidget {
  final StaffController controller;
  const StaffInviteDialog({super.key, required this.controller});
  @override
  State<StaffInviteDialog> createState() => _StaffInviteDialogState();
}

class _StaffInviteDialogState extends State<StaffInviteDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController();
  String _role = 'Support coordinator';
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Prepare staff invitation'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const InfoBanner(
                'Preview only. This adds an invitation to the example directory. No email is sent and no login account is created.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'Enter a full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Work email'),
                validator: (v) =>
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v ?? '')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _role,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Staff role'),
                items: const ['Hospital administrator', 'Support coordinator']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                InfoBanner(_error!, warning: true),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!_key.currentState!.validate()) return;
          try {
            widget.controller.invitePreviewStaff(
              _name.text.trim(),
              _email.text.trim(),
              _role,
            );
            Navigator.pop(context, true);
          } catch (error) {
            setState(
              () => _error = error.toString().replaceFirst('Bad state: ', ''),
            );
          }
        },
        child: const Text('Prepare invitation'),
      ),
    ],
  );
}
