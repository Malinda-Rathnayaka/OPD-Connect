import 'package:flutter/material.dart';

import 'staff_controller.dart';
import 'staff_models.dart';
import 'staff_widgets.dart';

class StaffRecordsPanel extends StatefulWidget {
  final StaffController controller;
  final StaffRecordType type;
  const StaffRecordsPanel({
    super.key,
    required this.controller,
    required this.type,
  });
  @override
  State<StaffRecordsPanel> createState() => _StaffRecordsPanelState();
}

class _StaffRecordsPanelState extends State<StaffRecordsPanel> {
  String _query = '';
  bool get _directory => widget.type == StaffRecordType.directory;
  String get _singular => _directory ? 'staff contact' : 'notice';

  Future<void> _edit([StaffRecord? record]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StaffRecordDialog(
        controller: widget.controller,
        type: widget.type,
        record: record,
      ),
    );
    if (saved == true && mounted) {
      _notify('${_directory ? 'Staff contact' : 'Notice'} saved.');
    }
  }

  void _notify(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _delete(StaffRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $_singular?'),
        content: Text('Remove "${record.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.saveRecord(record, delete: true);
      if (mounted) {
        _notify('${_directory ? 'Staff contact' : 'Notice'} deleted.');
      }
    } catch (error) {
      if (mounted) _notify(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _view(StaffRecord record) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(record.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(record.detail),
            if (record.contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(record.contact),
            ],
            const SizedBox(height: 16),
            StatusPill(record.active ? 'Active' : 'Inactive'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final records =
          c.records
              .where(
                (r) =>
                    r.type == widget.type &&
                    '${r.title} ${r.detail} ${r.category} ${r.contact}'
                        .toLowerCase()
                        .contains(_query),
              )
              .toList()
            ..sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );
      return StaffCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _directory ? 'Staff directory' : 'Hospital notices',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              _directory
                  ? 'Hospital contact records. Login access is managed in Staff profiles.'
                  : 'Internal messages for hospital staff. Audience labels help organize notices.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: c.canEditRecords ? () => _edit() : null,
                icon: const Icon(Icons.add, size: 18),
                label: Text(_directory ? 'Add staff contact' : 'Add notice'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                labelText: _directory
                    ? 'Search staff contacts'
                    : 'Search notices',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (c.errors.containsKey('Staff records')) ...[
              InfoBanner(c.errors['Staff records']!, warning: true),
              TextButton(
                onPressed: c.busy ? null : c.connect,
                child: const Text('Retry records'),
              ),
            ] else if (!c.recordsLoaded)
              const LinearProgressIndicator()
            else ...[
              if (c.recordsFromCache)
                const InfoBanner(
                  'Showing cached records. Reconnect to make changes.',
                  warning: true,
                ),
              if (records.isEmpty)
                EmptyState(
                  icon: _directory
                      ? Icons.people_outline
                      : Icons.campaign_outlined,
                  title: _query.isEmpty
                      ? (_directory
                            ? 'No staff contacts yet'
                            : 'No notices yet')
                      : 'No matching records',
                  detail: _query.isEmpty
                      ? 'Use Add to create your first $_singular.'
                      : 'Try a different name or keyword.',
                ),
              for (final record in records)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        record.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.category} · ${record.active ? 'Active' : 'Inactive'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        record.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (record.contact.isNotEmpty) Text(record.contact),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => _view(record),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                            ),
                            label: const Text('View'),
                          ),
                          TextButton.icon(
                            onPressed: c.canEditRecords
                                ? () => _edit(record)
                                : null,
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          ),
                          TextButton.icon(
                            onPressed: c.canEditRecords
                                ? () => _delete(record)
                                : null,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                          ),
                        ],
                      ),
                      const Divider(),
                    ],
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}

class StaffRecordDialog extends StatefulWidget {
  final StaffController controller;
  final StaffRecordType type;
  final StaffRecord? record;
  const StaffRecordDialog({
    super.key,
    required this.controller,
    required this.type,
    this.record,
  });
  @override
  State<StaffRecordDialog> createState() => _StaffRecordDialogState();
}

class _StaffRecordDialogState extends State<StaffRecordDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title, _detail, _category, _contact;
  late bool _active;
  bool _saving = false;
  String? _error;
  bool get _directory => widget.type == StaffRecordType.directory;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.record?.title);
    _detail = TextEditingController(text: widget.record?.detail);
    _category = TextEditingController(
      text: widget.record?.category ?? (_directory ? '' : 'All staff'),
    );
    _contact = TextEditingController(text: widget.record?.contact);
    _active = widget.record?.active ?? true;
  }

  @override
  void dispose() {
    for (final controller in [_title, _detail, _category, _contact]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.saveRecord(
        StaffRecord(
          id:
              widget.record?.id ??
              '${widget.controller.actorId}-${DateTime.now().microsecondsSinceEpoch}',
          type: widget.type,
          title: _title.text,
          detail: _detail.text,
          category: _category.text,
          contact: _contact.text,
          active: _active,
          revision: widget.record?.revision ?? 0,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int max = 100,
    int lines = 1,
    bool phone = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLength: max,
      maxLines: lines,
      keyboardType: phone
          ? TextInputType.phone
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: lines > 1,
      ),
      validator: (value) => phone
          ? (RegExp(r'^\+?[0-9\s()-]{7,20}$').hasMatch((value ?? '').trim())
                ? null
                : 'Enter a valid contact number')
          : ((value ?? '').trim().length < 2 ? 'Enter $label' : null),
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          '${widget.record == null ? 'Add' : 'Edit'} ${_directory ? 'staff contact' : 'notice'}',
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(_title, _directory ? 'Full name' : 'Notice title'),
                  _field(
                    _detail,
                    _directory ? 'Job title / responsibilities' : 'Message',
                    max: 1000,
                    lines: _directory ? 2 : 4,
                  ),
                  if (_directory) ...[
                    _field(_category, 'Department / team'),
                    _field(_contact, 'Contact number', max: 20, phone: true),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _category.text,
                      decoration: const InputDecoration(labelText: 'Audience'),
                      items:
                          const [
                                'All staff',
                                'Doctors',
                                'Reception',
                                'Administration',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => _category.text = value!,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: _active,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _active = value),
                  ),
                  if (_error != null) InfoBanner(_error!, warning: true),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving || !widget.controller.canEditRecords
                ? null
                : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
    ),
  );
}
