import 'package:flutter/material.dart';

import 'staff_controller.dart';
import 'staff_dialogs.dart';
import 'staff_models.dart';
import 'staff_widgets.dart';
import 'staff_records_panel.dart';

class HospitalStaffWorkspace extends StatefulWidget {
  final bool preview;
  final String actorId, actorName;
  final VoidCallback? onSignOut;
  final StaffController? controller;
  const HospitalStaffWorkspace({
    super.key,
    this.preview = false,
    this.actorId = 'preview-admin',
    this.actorName = 'Ayesha Fernando',
    this.onSignOut,
    this.controller,
  });
  @override
  State<HospitalStaffWorkspace> createState() => _HospitalStaffWorkspaceState();
}

class _HospitalStaffWorkspaceState extends State<HospitalStaffWorkspace> {
  late final StaffController c;
  final _search = TextEditingController();
  int _page = 0, _overviewTab = 0, _staffTab = 0;
  bool _hospitalDirty = false;
  bool _confirmingNavigation = false;
  String _roleFilter = 'All roles', _statusFilter = 'All statuses';
  static const _titles = [
    'Overview',
    'User accounts',
    'Verifications',
    'Staff & roles',
    'Hospital setup',
    'Activity log',
    'System health',
  ];
  static const _icons = [
    Icons.grid_view_rounded,
    Icons.people_outline_rounded,
    Icons.fact_check_outlined,
    Icons.admin_panel_settings_outlined,
    Icons.local_hospital_outlined,
    Icons.history_rounded,
    Icons.monitor_heart_outlined,
  ];
  @override
  void initState() {
    super.initState();
    c =
        widget.controller ??
        StaffController(
          preview: widget.preview,
          actorId: widget.actorId,
          actorName: widget.actorName,
        );
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget.controller == null) c.dispose();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    if (c.busy) {
      _notify('Wait for the current save to finish.');
      return false;
    }
    if (_confirmingNavigation) return false;
    if (_page == 4 && _hospitalDirty) {
      _confirmingNavigation = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: const Text(
            'Your hospital information has not been saved. Stay here to finish, or discard the changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard changes'),
            ),
          ],
        ),
      );
      _confirmingNavigation = false;
      if (discard != true || !mounted) return false;
    }
    return mounted;
  }

  Future<bool> _navigate(int page) async {
    if (_page == page) return true;
    if (!await _confirmLeave()) return false;
    setState(() {
      _page = page;
      _hospitalDirty = false;
      _search.clear();
      _roleFilter = 'All roles';
      _statusFilter = 'All statuses';
    });
    return true;
  }

  Future<void> _account(StaffAccount account, AccountDialogMode mode) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Theme(
        data: StaffStyle.theme(),
        child: AccountDialog(controller: c, account: account, mode: mode),
      ),
    );
    if (result == true && mounted) {
      _notify(
        mode == AccountDialogMode.review
            ? 'Review decision saved.'
            : 'Account updated.',
      );
    }
  }

  void _notify(String message, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? StaffStyle.red : StaffStyle.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) => Theme(
    data: StaffStyle.theme(),
    child: Builder(
      builder: (context) => AnimatedBuilder(
        animation: c,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 1050;
            return Scaffold(
              body: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (desktop) _sidebar(context),
                    Expanded(
                      child: Column(
                        children: [
                          _topbar(context, desktop),
                          Expanded(
                            child: SelectionArea(
                              child: SingleChildScrollView(
                                key: ValueKey(_page),
                                padding: EdgeInsets.all(desktop ? 32 : 18),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 1240,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (c.preview)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 24,
                                            ),
                                            child: InfoBanner(
                                              'Preview workspace · Example data. Changes stay in this session and reset when you restart.',
                                              action: const Padding(
                                                padding: EdgeInsets.only(
                                                  left: 8,
                                                ),
                                                child: Icon(
                                                  Icons.science_outlined,
                                                  color: StaffStyle.primary,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        _pageHeading(context),
                                        if (c.accountAccessIssue != null) ...[
                                          InfoBanner(
                                            c.accountAccessIssue!,
                                            warning: true,
                                            action: TextButton(
                                              onPressed: c.connect,
                                              child: const Text('Retry'),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                        if (c.accountsFromCache &&
                                            !c.errors.containsKey('Accounts') &&
                                            !c.preview) ...[
                                          const InfoBanner(
                                            'Showing cached account data. Changes are disabled until Firebase reconnects.',
                                            warning: true,
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                        if (c.errors.containsKey(
                                          'Accounts',
                                        )) ...[
                                          InfoBanner(
                                            c.errors['Accounts']!,
                                            warning: true,
                                            action: TextButton(
                                              onPressed: c.connect,
                                              child: const Text('Retry'),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                        ],
                                        if (c.actorLoaded &&
                                            !c.canReadWorkspace)
                                          const EmptyState(
                                            icon: Icons.lock_outline,
                                            title: 'Staff access unavailable',
                                            detail: 'Verify your account permissions before loading hospital records.',
                                          )
                                        else if (c.loading || !c.actorLoaded)
                                          const Padding(
                                            padding: EdgeInsets.all(45),
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          )
                                        else
                                          switch (_page) {
                                            0 => _overview(context),
                                            1 => _accounts(context),
                                            2 => _verifications(context),
                                            3 => _staff(context),
                                            4 => _hospital(context),
                                            5 => _activity(context),
                                            _ => _health(context),
                                          },
                                        const SizedBox(height: 30),
                                        Text(
                                          'OPD Connect  /  Hospital staff workspace',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: desktop
                  ? null
                  : NavigationBar(
                      height: 72,
                      backgroundColor: Colors.white,
                      indicatorColor: StaffStyle.primarySoft,
                      selectedIndex: _page <= 2 ? _page : 3,
                      onDestinationSelected: (index) =>
                          index == 3 ? _more(context) : _navigate(index),
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_rounded),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.people_outline_rounded),
                          label: 'Accounts',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.fact_check_outlined),
                          label: 'Reviews',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu_rounded),
                          label: 'More',
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    ),
  );

  Widget _sidebar(BuildContext context) => Container(
    width: 246,
    color: Colors.white,
    child: LayoutBuilder(
      builder: (context, size) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 28, 25, 35),
                  child: _brand(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Text(
                    'HOSPITAL WORKSPACE',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                for (var i = 0; i < _titles.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    child: Material(
                      color: _page == i ? StaffStyle.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _navigate(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _icons[i],
                                size: 20,
                                color: _page == i
                                    ? StaffStyle.primary
                                    : StaffStyle.muted,
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Text(
                                  _titles[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _page == i
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _page == i
                                        ? StaffStyle.primary
                                        : StaffStyle.muted,
                                  ),
                                ),
                              ),
                              if (i == 2 && c.pending.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1D9),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    '${c.pending.length}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: StaffStyle.amber,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: StaffCard(
                    padding: const EdgeInsets.all(16),
                    color: StaffStyle.canvas,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.support_agent_rounded,
                          color: StaffStyle.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'A little help goes a long way.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Find the scope and responsibilities of your staff role.',
                          style: TextStyle(
                            fontSize: 11,
                            color: StaffStyle.muted,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () async {
                            if (await _navigate(3) && mounted) {
                              setState(() => _staffTab = 1);
                            }
                          },
                          child: const Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'View role guide',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: StaffStyle.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: StaffStyle.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 13,
                        color: StaffStyle.muted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          c.preview
                              ? 'Isolated preview session'
                              : 'Authenticated workspace',
                          style: const TextStyle(
                            color: StaffStyle.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _brand(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: StaffStyle.primary,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      const SizedBox(width: 11),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPD Connect',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: StaffStyle.ink,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Care, connected.',
              style: TextStyle(fontSize: 10, color: StaffStyle.muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _topbar(BuildContext context, bool desktop) => Container(
    padding: EdgeInsets.symmetric(horizontal: desktop ? 32 : 18, vertical: 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: StaffStyle.line)),
    ),
    child: Row(
      children: [
        if (!desktop) ...[
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: StaffStyle.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${c.hospitalName}${c.settingsFromCache ? ' (cached)' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: StaffStyle.ink,
                ),
              ),
              Text(
                desktop
                    ? 'Hospital administration / ${_titles[_page]}'
                    : 'Hospital staff',
                style: const TextStyle(fontSize: 11, color: StaffStyle.muted),
              ),
            ],
          ),
        ),
        if (desktop) ...[
          StatusPill(
            c.connectionLabel,
            color: c.errors.containsKey('Accounts')
                ? StaffStyle.amber
                : StaffStyle.primary,
          ),
          const SizedBox(width: 24),
        ],
        IconButton(
          tooltip: 'View alerts',
          onPressed: () async {
            if (await _navigate(0) && mounted) setState(() => _overviewTab = 1);
          },
          icon: Badge(
            isLabelVisible:
                c.pending.isNotEmpty || c.alerts.any((a) => !a.acknowledged),
            smallSize: 7,
            child: const Icon(Icons.notifications_none_rounded, size: 22),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Your account',
          onSelected: (action) async {
            if (action == 'role') {
              if (await _navigate(3) && mounted) setState(() => _staffTab = 1);
            } else {
              if (!await _confirmLeave()) return;
              if (widget.onSignOut != null) {
                widget.onSignOut!();
              } else if (context.mounted && Navigator.canPop(context)) {
                // HospitalSettingsPanel protects route pops until its draft is discarded.
                if (_hospitalDirty) {
                  setState(() {
                    _page = 0;
                    _hospitalDirty = false;
                  });
                  await WidgetsBinding.instance.endOfFrame;
                }
                if (context.mounted) Navigator.pop(context);
              } else {
                _notify('Close this tab to leave the preview.');
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Text(c.actorName)),
            PopupMenuItem(value: 'role', child: Text(c.actorRole)),
            PopupMenuItem(
              value: 'exit',
              child: Text(c.preview ? 'Leave preview' : 'Sign out'),
            ),
          ],
          child: CircleAvatar(
            radius: 18,
            backgroundColor: StaffStyle.primarySoft,
            child: Text(
              c.actorName.split(' ').take(2).map((s) => s[0]).join(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: StaffStyle.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _more(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 3; i < _titles.length; i++)
              ListTile(
                leading: Icon(_icons[i], color: StaffStyle.primary),
                title: Text(_titles[i]),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  _navigate(i);
                },
              ),
          ],
        ),
      ),
    ),
  );

  Widget _pageHeading(BuildContext context) {
    const subtitles = [
      'A clear view of your hospital, and what needs your attention.',
      'Keep patient, doctor and staff information up to date.',
      'Review credentials carefully. Help the right people get access.',
      'The right people, with the right responsibilities.',
      'One source of truth for hospital and department information.',
      'A clear record of changes across your workspace.',
      'Know which services are available, and where attention is needed.',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CARE OPERATIONS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: StaffStyle.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _page == 0 ? 'Hospital overview' : _titles[_page],
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 7),
          Text(
            subtitles[_page],
            style: const TextStyle(fontSize: 13, color: StaffStyle.muted),
          ),
        ],
      ),
    );
  }

  Widget _tabs(
    List<String> labels,
    int selected,
    ValueChanged<int> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < labels.length; i++)
          TextButton(
            onPressed: () => change(i),
            style: TextButton.styleFrom(
              backgroundColor: i == selected ? StaffStyle.ink : Colors.white,
              foregroundColor: i == selected ? Colors.white : StaffStyle.muted,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Text(
              labels[i],
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    ),
  );

  Widget _columns(
    Widget left,
    Widget right, {
    int leftFlex = 3,
    int rightFlex = 2,
  }) => LayoutBuilder(
    builder: (context, size) => size.maxWidth < 760
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 20), right],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: 22),
              Expanded(flex: rightFlex, child: right),
            ],
          ),
  );

  Widget _overview(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _tabs(
        ['Overview', 'Alerts'],
        _overviewTab,
        (index) => setState(() => _overviewTab = index),
      ),
      if (_overviewTab == 1)
        _alerts(context)
      else ...[
        StaffCard(
          color: StaffStyle.primarySoft,
          padding: const EdgeInsets.all(26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusPill('YOUR DAILY BRIEF'),
                    const SizedBox(height: 16),
                    Text(
                      c.pending.isEmpty
                          ? 'Ready for a smoother day.'
                          : 'A little attention.\nA lot of care.',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 28, height: 1.15),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      c.pending.isEmpty
                          ? 'Your doctor review queue is clear. Keep an eye on accounts and hospital information.'
                          : '${c.pending.length} doctor registrations are waiting for review.\nA quick check today helps keep care moving.',
                      style: const TextStyle(
                        color: StaffStyle.muted,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _navigate(2),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const Text('Open review queue'),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 700)
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: _careIllustration(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, size) {
            final count = size.maxWidth < 620 ? 2 : 4;
            final width = (size.maxWidth - (count - 1) * 14) / count;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _stat(
                  context,
                  width,
                  'Total accounts',
                  '${c.accounts.length}',
                  Icons.people_outline_rounded,
                  'Patients, doctors & staff',
                  1,
                ),
                _stat(
                  context,
                  width,
                  'Active doctors',
                  '${c.doctorsCount}',
                  Icons.medical_services_outlined,
                  'Approved for hospital access',
                  1,
                  role: 'Doctor',
                ),
                _stat(
                  context,
                  width,
                  'Needs review',
                  '${c.pending.length}',
                  Icons.fact_check_outlined,
                  'Doctor registrations',
                  2,
                  amber: true,
                ),
                _stat(
                  context,
                  width,
                  'Hospital staff',
                  '${c.staff.length}',
                  Icons.admin_panel_settings_outlined,
                  'Your administration team',
                  3,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _columns(
          StaffCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'Waiting for your review',
                  subtitle: 'New doctor registrations',
                  trailing: TextButton(
                    onPressed: () => _navigate(2),
                    child: const Text(
                      'View all',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (c.pending.isEmpty)
                  const EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'All caught up',
                    detail:
                        'There are no doctor registrations waiting for review.',
                  )
                else ...[
                  for (final a in c.pending.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          AccountAvatar(a),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  a.department.isEmpty
                                      ? 'Department not supplied'
                                      : a.department,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: StaffStyle.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: c.canReview
                                ? () => _account(a, AccountDialogMode.review)
                                : null,
                            child: const Text(
                              'Review',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          StaffCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'Workspace status',
                  subtitle: c.preview
                      ? 'Example service information'
                      : 'Based on available connection data',
                ),
                _serviceLine(
                  Icons.cloud_done_outlined,
                  'Account database',
                  c.connectionLabel,
                  !c.loading &&
                      !c.accountsFromCache &&
                      !c.errors.containsKey('Accounts'),
                ),
                const SizedBox(height: 20),
                _serviceLine(
                  Icons.sms_outlined,
                  'SMS notifications',
                  c.preview ? 'Delayed · example' : 'Not connected',
                  false,
                ),
                const SizedBox(height: 20),
                _serviceLine(
                  Icons.backup_outlined,
                  'Backup monitoring',
                  c.preview ? 'Needs check · example' : 'Not connected',
                  false,
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _navigate(6),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'View system health',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 15),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _columns(
          StaffCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  'Recent activity',
                  subtitle: c.activityFromCache
                      ? 'Cached activity records'
                      : 'Changes with a clear trail',
                  trailing: TextButton(
                    onPressed: () => _navigate(5),
                    child: const Text(
                      'View log',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (!c.activityLoaded || c.errors.containsKey('Activity'))
                  const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Activity unavailable',
                    detail: 'Waiting for authorized Firebase activity records.',
                  )
                else if (c.activity.isEmpty)
                  const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No activity yet',
                    detail: 'Saved changes will appear here.',
                  )
                else
                  for (final item in c.activity.take(3)) _activityRow(item),
              ],
            ),
          ),
          StaffCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading(
                  'Quick access',
                  subtitle: 'Everyday tasks, a little closer',
                ),
                _quick(
                  'Manage user accounts',
                  'Search, update or deactivate',
                  Icons.people_outline_rounded,
                  1,
                ),
                _quick(
                  'Staff responsibilities',
                  'Profiles, roles and access',
                  Icons.badge_outlined,
                  3,
                ),
                _quick(
                  'Hospital information',
                  'Departments and contact details',
                  Icons.local_hospital_outlined,
                  4,
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  Widget _careIllustration() => SizedBox(
    width: 160,
    height: 158,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 144,
          height: 144,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        Transform.rotate(
          angle: -0.12,
          child: Container(
            width: 100,
            height: 116,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: StaffStyle.primary.withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.medical_services_outlined,
                  size: 42,
                  color: StaffStyle.primary,
                ),
                const SizedBox(height: 12),
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: StaffStyle.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 35,
                  height: 5,
                  decoration: BoxDecoration(
                    color: StaffStyle.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 2,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: StaffStyle.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 25,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stat(
    BuildContext context,
    double width,
    String label,
    String value,
    IconData icon,
    String note,
    int destination, {
    bool amber = false,
    String? role,
  }) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (await _navigate(destination) && mounted && role != null) {
            setState(() => _roleFilter = role);
          }
        },
        child: StaffCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: StaffStyle.muted,
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 19,
                    color: amber ? StaffStyle.amber : StaffStyle.primary,
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Text(
                c.errors.containsKey('Accounts') ? '—' : value,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: amber ? StaffStyle.amber : StaffStyle.ink,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 10,
                  color: StaffStyle.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _serviceLine(
    IconData icon,
    String title,
    String state,
    bool good,
  ) => Row(
    children: [
      Icon(icon, size: 20, color: StaffStyle.muted),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              state,
              style: TextStyle(
                fontSize: 11,
                color: good ? StaffStyle.primary : StaffStyle.amber,
              ),
            ),
          ],
        ),
      ),
      Icon(
        good ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
        size: 17,
        color: good ? StaffStyle.primary : StaffStyle.amber,
      ),
    ],
  );

  Widget _quick(String title, String detail, IconData icon, int page) =>
      InkWell(
        onTap: () => _navigate(page),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(icon, color: StaffStyle.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 11,
                        color: StaffStyle.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: StaffStyle.muted,
              ),
            ],
          ),
        ),
      );

  Widget _accounts(BuildContext context, {bool staffOnly = false}) {
    if (c.errors.containsKey('Accounts')) {
      return StaffCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(
              staffOnly ? 'Staff directory' : 'Account directory',
              subtitle: 'Account data could not be loaded',
            ),
            const EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Directory unavailable',
              detail: 'Restore authorized Firebase access and retry to load accounts.',
            ),
          ],
        ),
      );
    }
    final source = staffOnly ? c.staff : c.accounts;
    final query = _search.text.toLowerCase().trim();
    final list = source
        .where(
          (a) =>
              '${a.name} ${a.email} ${a.id} ${a.nic}'.toLowerCase().contains(
                query,
              ) &&
              (_roleFilter == 'All roles' || a.roleLabel == _roleFilter) &&
              (_statusFilter == 'All statuses' ||
                  switch (a.status) {
                        AccountStatus.active => 'Active',
                        AccountStatus.pending => 'Needs review',
                        AccountStatus.rejected => 'Rejected',
                        AccountStatus.inactive => 'Inactive',
                      } ==
                      _statusFilter),
        )
        .toList();
    return StaffCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(
            staffOnly ? 'Staff directory' : 'Account directory',
            subtitle:
                '${c.accountsFromCache ? 'Cached records · ' : ''}${list.length} ${list.length == 1 ? 'account' : 'accounts'}${query.isNotEmpty ? ' matching your search' : ' in this view'}',
          ),
          LayoutBuilder(
            builder: (context, size) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: size.maxWidth < 650
                      ? size.maxWidth
                      : size.maxWidth - (staffOnly ? 192 : 368),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search name, email or account ID',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () => setState(() => _search.clear()),
                              icon: const Icon(Icons.close_rounded, size: 18),
                            ),
                    ),
                  ),
                ),
                if (!staffOnly)
                  SizedBox(
                    width: size.maxWidth < 650 ? (size.maxWidth - 12) / 2 : 164,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(_roleFilter),
                      initialValue: _roleFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items:
                          const [
                                'All roles',
                                'Patient',
                                'Doctor',
                                'Hospital staff',
                              ]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _roleFilter = v!),
                    ),
                  ),
                SizedBox(
                  width: size.maxWidth < 650
                      ? (staffOnly ? size.maxWidth : (size.maxWidth - 12) / 2)
                      : 180,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_statusFilter),
                    initialValue: _statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items:
                        const [
                              'All statuses',
                              'Active',
                              'Needs review',
                              'Rejected',
                              'Inactive',
                            ]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _statusFilter = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (list.isEmpty)
            EmptyState(
              title: source.isEmpty
                  ? 'No accounts available'
                  : 'No matching accounts',
              detail: source.isEmpty
                  ? 'Accounts will appear when they are available to your workspace.'
                  : 'Try another name or clear your filters.',
              action: source.isEmpty
                  ? null
                  : OutlinedButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _roleFilter = 'All roles';
                        _statusFilter = 'All statuses';
                      }),
                      child: const Text('Clear filters'),
                    ),
            )
          else
            LayoutBuilder(
              builder: (context, size) {
                final wide = size.maxWidth >= 780;
                return Column(
                  children: [
                    if (wide)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: StaffStyle.canvas,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _tableLabel('NAME / CONTACT'),
                            ),
                            Expanded(
                              flex: 3,
                              child: _tableLabel(
                                staffOnly ? 'STAFF ROLE' : 'ROLE / DEPARTMENT',
                              ),
                            ),
                            Expanded(flex: 2, child: _tableLabel('STATUS')),
                            SizedBox(width: 82, child: _tableLabel('ACTION')),
                          ],
                        ),
                      ),
                    for (final a in list) _accountRow(a, wide, staffOnly),
                  ],
                );
              },
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: StaffStyle.muted,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Account changes are recorded. Deactivation preserves the history.',
                  style: TextStyle(fontSize: 11, color: StaffStyle.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: StaffStyle.muted,
    ),
  );

  Widget _accountRow(StaffAccount a, bool wide, bool staffOnly) {
    final identity = Row(
      children: [
        AccountAvatar(a),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                a.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: StaffStyle.muted),
              ),
            ],
          ),
        ),
      ],
    );
    final role = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          staffOnly ? a.staffRole : a.roleLabel,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          a.department.isEmpty ? '—' : a.department,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: StaffStyle.muted),
        ),
      ],
    );
    final actions = PopupMenuButton<String>(
      tooltip: 'Actions for ${a.name}',
      onSelected: (action) {
        if (action == 'details') {
          _account(a, AccountDialogMode.details);
        } else if (action == 'edit') {
          _account(a, AccountDialogMode.edit);
        } else if (action == 'review') {
          _account(a, AccountDialogMode.review);
        } else {
          _toggleActive(a);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'details', child: Text('View details')),
        if (c.canManage &&
            c.canWrite &&
            (a.role != 'admin' || c.canManageStaff)) ...[
          const PopupMenuItem(value: 'edit', child: Text('Edit details')),
          if (a.status == AccountStatus.pending)
            const PopupMenuItem(
              value: 'review',
              child: Text('Review registration'),
            ),
          if (a.id != c.actorId)
            PopupMenuItem(
              value: 'active',
              child: Text(
                a.active ? 'Deactivate account' : 'Reactivate account',
              ),
            ),
        ],
      ],
      icon: const Icon(Icons.more_horiz_rounded, color: StaffStyle.muted),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 17),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: StaffStyle.line)),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(flex: 5, child: identity),
                Expanded(flex: 3, child: role),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: StatusPill.account(a),
                  ),
                ),
                SizedBox(width: 82, child: actions),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: identity),
                    actions,
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: role),
                    StatusPill.account(a),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _toggleActive(StaffAccount account) async {
    final action = account.active ? 'Deactivate' : 'Reactivate';
    final reason = await reasonDialog(
      context,
      '$action account',
      account.active
          ? '${account.name} will lose access to the app. Their profile and history will be preserved.'
          : '${account.name} will regain access, subject to any outstanding doctor approval.',
      '$action account',
    );
    if (reason == null || !mounted) return;
    try {
      await c.setActive(account, active: !account.active, reason: reason);
      if (mounted) {
        _notify('Account ${account.active ? 'deactivated' : 'reactivated'}.');
      }
    } catch (error) {
      if (mounted) {
        _notify(error.toString().replaceFirst('Bad state: ', ''), error: true);
      }
    }
  }

  Widget _verifications(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InfoBanner(
        'Check identity, medical registration and hospital assignment before approving. Rejected registrations stay on record with the reason.',
      ),
      const SizedBox(height: 22),
      if (!c.canManage &&
          !c.loading &&
          !c.accountsFromCache &&
          !c.errors.containsKey('Accounts')) ...[
        InfoBanner(c.reviewUnavailableReason!, warning: true),
        const SizedBox(height: 18),
      ],
      StaffCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              'Doctor review queue',
              subtitle: c.errors.containsKey('Accounts')
                  ? 'Queue data could not be loaded'
                  : '${c.pending.length} waiting for a decision',
              trailing: StatusPill(
                c.errors.containsKey('Accounts')
                    ? 'Unavailable'
                    : '${c.pending.length} pending',
                color: StaffStyle.amber,
              ),
            ),
            if (c.pending.isEmpty)
              EmptyState(
                icon: Icons.task_alt_rounded,
                title: c.errors.containsKey('Accounts') || c.accountsFromCache
                    ? 'Review queue unavailable'
                    : 'You’re all caught up',
                detail: c.errors.containsKey('Accounts') || c.accountsFromCache
                    ? 'Reconnect with authorized access to load pending registrations.'
                    : 'New doctor registrations will appear here for review.',
              )
            else
              for (final a in c.pending)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: StaffStyle.line),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AccountAvatar(a, size: 46),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  a.department.isEmpty
                                      ? 'Hospital assignment not provided'
                                      : a.department,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: StaffStyle.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          Text(
                            'Registration: ${a.registration.isEmpty ? 'Not provided' : a.registration}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: StaffStyle.muted,
                            ),
                          ),
                          Text(
                            'Submitted: ${a.createdAt == null ? 'Not recorded' : relativeTime(a.createdAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: StaffStyle.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: c.canReview
                            ? () => _account(a, AccountDialogMode.review)
                            : null,
                        icon: const Icon(Icons.fact_check_outlined, size: 17),
                        label: const Text('Review registration'),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      TextButton(
        onPressed: () async {
          if (await _navigate(1) && mounted) {
            setState(() => _statusFilter = 'Rejected');
          }
        },
        child: const Text('View previously rejected registrations'),
      ),
    ],
  );

  Widget _staff(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _tabs(
        ['Staff profiles', 'Roles & permissions', 'Staff directory'],
        _staffTab,
        (i) => setState(() => _staffTab = i),
      ),
      if (_staffTab == 0) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                '${c.staff.where((a) => a.active).length} active staff members',
                style: const TextStyle(color: StaffStyle.muted, fontSize: 12),
              ),
            ),
            FilledButton.icon(
              onPressed: !c.preview || !c.canManageStaff
                  ? null
                  : () async {
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => Theme(
                          data: StaffStyle.theme(),
                          child: StaffInviteDialog(controller: c),
                        ),
                      );
                      if (result == true && mounted) {
                        _notify(
                          'Preview invitation prepared. No email was sent.',
                        );
                      }
                    },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
              label: const Text('Invite staff'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!c.preview) ...[
          const InfoBanner(
            'Staff invitations are not connected yet. Existing staff profiles can be managed here.',
          ),
          const SizedBox(height: 18),
        ],
        _accounts(context, staffOnly: true),
      ] else if (_staffTab == 2) ...[
        StaffRecordsPanel(controller: c, type: StaffRecordType.directory),
      ] else ...[
        const InfoBanner(
          'Role changes affect sensitive hospital information. Only a super administrator can change another staff member’s role. Your own access cannot be changed here.',
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, size) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final role in const [
                'Super administrator',
                'Hospital administrator',
                'Support coordinator',
              ])
                SizedBox(
                  width: size.maxWidth < 750
                      ? size.maxWidth
                      : (size.maxWidth - 32) / 3,
                  child: StaffCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          role == 'Super administrator'
                              ? Icons.shield_outlined
                              : role == 'Hospital administrator'
                              ? Icons.local_hospital_outlined
                              : Icons.support_agent_rounded,
                          color: StaffStyle.primary,
                          size: 27,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          role,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          role == 'Super administrator'
                              ? 'Workspace ownership and staff access.'
                              : role == 'Hospital administrator'
                              ? 'Everyday hospital administration.'
                              : 'Read access for patient support.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: StaffStyle.muted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        for (final permission in [
                          'View accounts and activity',
                          'Edit accounts and hospital details',
                          'Approve doctor registrations',
                          'Manage staff access',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 13),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  permission == 'View accounts and activity' ||
                                          role == 'Super administrator' ||
                                          (role == 'Hospital administrator' &&
                                              permission !=
                                                  'Manage staff access')
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.remove_circle_outline_rounded,
                                  size: 16,
                                  color:
                                      permission ==
                                              'View accounts and activity' ||
                                          role == 'Super administrator' ||
                                          (role == 'Hospital administrator' &&
                                              permission !=
                                                  'Manage staff access')
                                      ? StaffStyle.primary
                                      : StaffStyle.muted,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    permission,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        StatusPill(
                          '${c.staff.where((a) => a.staffRole == role).length} assigned',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'To change a staff role, open Staff profiles → account actions → Edit details.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ],
  );

  Widget _hospital(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HospitalSettingsPanel(
        controller: c,
        onDirty: (dirty) => _hospitalDirty = dirty,
        onSaved: () => _notify('Hospital information saved.'),
      ),
      const SizedBox(height: 24),
      StaffRecordsPanel(controller: c, type: StaffRecordType.notice),
    ],
  );

  Widget _activityRow(StaffActivity item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: StaffStyle.canvas,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.history_rounded,
            size: 17,
            color: StaffStyle.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                item.detail,
                style: const TextStyle(fontSize: 11, color: StaffStyle.muted),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.actor} · ${relativeTime(item.time)}',
                style: const TextStyle(fontSize: 10, color: StaffStyle.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _activity(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final items = c.activity
        .where(
          (a) =>
              '${a.title} ${a.detail} ${a.actor}'.toLowerCase().contains(query),
        )
        .toList();
    return StaffCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeading(
            'Workspace activity',
            subtitle: 'Who changed what, and when. Latest changes first.',
          ),
          if (c.errors.containsKey('Activity')) ...[
            InfoBanner(c.errors['Activity']!, warning: true),
            const SizedBox(height: 16),
          ],
          if (c.activityFromCache &&
              !c.preview &&
              !c.errors.containsKey('Activity')) ...[
            const InfoBanner(
              'Showing cached activity records. Firebase has not confirmed the latest activity.',
              warning: true,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search actions, names or staff members',
              prefixIcon: Icon(Icons.search_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 18),
          if (!c.activityLoaded || c.errors.containsKey('Activity'))
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'Activity unavailable',
              detail: 'Restore authorized Firebase access and retry to load the activity log.',
            )
          else if (items.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'No activity to show',
              detail: 'Try another search, or make a change in the workspace.',
            )
          else
            for (final item in items) ...[_activityRow(item), const Divider()],
        ],
      ),
    );
  }

  Widget _alerts(BuildContext context) => StaffCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeading(
          'Attention needed',
          subtitle: 'Review tasks and service notices in one place.',
        ),
        if (c.pending.isNotEmpty)
          _alertTile(
            Icons.fact_check_outlined,
            '${c.pending.length} doctor registrations need review',
            'Verify credentials before granting access to doctor features.',
            FilledButton(
              onPressed: () => _navigate(2),
              child: const Text('Review queue'),
            ),
          ),
        for (final alert in c.alerts)
          _alertTile(
            Icons.warning_amber_rounded,
            alert.title,
            alert.detail,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => _navigate(6),
                  child: Text(alert.action),
                ),
                OutlinedButton(
                  onPressed: alert.acknowledged || !c.canManage || !c.canWrite
                      ? null
                      : () {
                          c.acknowledge(alert);
                          _notify(
                            'Alert acknowledged and added to the activity log.',
                          );
                        },
                  child: Text(
                    alert.acknowledged ? 'Acknowledged' : 'Acknowledge',
                  ),
                ),
              ],
            ),
          ),
        if (c.errors.isNotEmpty)
          _alertTile(
            Icons.cloud_off_outlined,
            'Some workspace information is unavailable',
            'Review the connection notices and retry. Changes are not saved until they are confirmed.',
            OutlinedButton(
              onPressed: c.connect,
              child: const Text('Retry connection'),
            ),
          ),
        if (c.pending.isEmpty && c.alerts.isEmpty && c.errors.isEmpty)
          const EmptyState(
            icon: Icons.task_alt_rounded,
            title: 'No open alerts',
            detail: 'Tasks that need your attention will appear here.',
          ),
      ],
    ),
  );

  Widget _alertTile(
    IconData icon,
    String title,
    String detail,
    Widget action,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      border: Border.all(color: StaffStyle.line),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: StaffStyle.amber, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: StaffStyle.muted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        action,
      ],
    ),
  );

  Widget _health(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InfoBanner(
        c.preview
            ? 'These service states are examples for your group demonstration. No live uptime, SMS, identity-registry or backup monitoring is connected.'
            : 'Only the account connection is observed by this app. Other service integrations have not been connected.',
        warning: true,
      ),
      const SizedBox(height: 22),
      StaffCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading(
              'Service connections',
              subtitle: 'Availability without the guesswork',
            ),
            _healthRow(
              'Account database',
              Icons.cloud_outlined,
              c.connectionLabel,
              c.preview
                  ? 'An isolated preview directory; no live accounts.'
                  : c.errors['Accounts'] ??
                        (c.loading
                            ? 'Waiting for account data.'
                            : c.accountsFromCache
                            ? 'Showing cached records. Changes are disabled until Firebase reconnects.'
                            : 'User records are received from Firebase.'),
              !c.loading &&
                  !c.accountsFromCache &&
                  !c.errors.containsKey('Accounts'),
            ),
            _healthRow(
              'SMS gateway',
              Icons.sms_outlined,
              c.preview ? 'Delayed · example' : 'Not connected',
              'Appointment reminders need a connected notification provider.',
              false,
            ),
            _healthRow(
              'Identity registry',
              Icons.fingerprint_rounded,
              'Not connected',
              'Verify identity through the hospital’s approved manual process.',
              false,
            ),
            _healthRow(
              'Backup & recovery',
              Icons.backup_outlined,
              c.preview ? 'Needs attention · example' : 'Not connected',
              'Backup schedules and restore checks are managed outside this app.',
              false,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      StaffCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeading('What to do when a service is unavailable'),
            const Text(
              '1. Check the connection and retry the affected action.\n2. Confirm whether the change was saved before repeating it.\n3. Escalate persistent issues to the hospital system administrator.',
              style: TextStyle(
                color: StaffStyle.muted,
                fontSize: 13,
                height: 2,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _navigate(0),
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: const Text('Back to overview'),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _healthRow(
    String title,
    IconData icon,
    String status,
    String detail,
    bool good,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: StaffStyle.primary, size: 23),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                style: const TextStyle(fontSize: 12, color: StaffStyle.muted),
              ),
              const SizedBox(height: 8),
              StatusPill(
                status,
                color: good ? StaffStyle.primary : StaffStyle.amber,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class HospitalSettingsPanel extends StatefulWidget {
  final StaffController controller;
  final VoidCallback onSaved;
  final ValueChanged<bool> onDirty;
  const HospitalSettingsPanel({
    super.key,
    required this.controller,
    required this.onSaved,
    required this.onDirty,
  });
  @override
  State<HospitalSettingsPanel> createState() => _HospitalSettingsPanelState();
}

class _HospitalSettingsPanelState extends State<HospitalSettingsPanel> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name, _address, _phone;
  late List<Department> _departments;
  bool _dirty = false, _saving = false;
  String? _error;
  void _changed(String _) => setState(() {
    _dirty = true;
    widget.onDirty(true);
  });
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.controller.hospitalName);
    _address = TextEditingController(text: widget.controller.hospitalAddress);
    _phone = TextEditingController(text: widget.controller.hospitalPhone);
    _departments = [...widget.controller.departments];
  }

  @override
  void didUpdateWidget(covariant HospitalSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dirty && !_saving) {
      _name.text = widget.controller.hospitalName;
      _address.text = widget.controller.hospitalAddress;
      _phone.text = widget.controller.hospitalPhone;
      _departments = [...widget.controller.departments];
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty && !_saving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save or discard your hospital changes first.'),
          ),
        );
      }
    },
    child: StaffCard(
      child: Form(
        key: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeading(
              'Hospital details',
              subtitle: 'Keep contact and location information consistent.',
            ),
            if (widget.controller.errors.containsKey('Hospital settings')) ...[
              InfoBanner(
                widget.controller.errors['Hospital settings']!,
                warning: true,
              ),
              const SizedBox(height: 16),
            ],
            if (widget.controller.settingsFromCache &&
                !widget.controller.errors.containsKey('Hospital settings') &&
                !widget.controller.preview) ...[
              const InfoBanner(
                'Hospital settings are cached. Editing is disabled until Firebase reconnects.',
                warning: true,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _name,
              readOnly: !widget.controller.canEditHospital || _saving,
              onChanged: _changed,
              decoration: const InputDecoration(labelText: 'Hospital name'),
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? 'Enter a hospital name' : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _address,
              readOnly: !widget.controller.canEditHospital || _saving,
              onChanged: _changed,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => (v ?? '').trim().length < 5
                  ? 'Enter the hospital address'
                  : null,
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _phone,
              readOnly: !widget.controller.canEditHospital || _saving,
              onChanged: _changed,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Contact number'),
              validator: (v) =>
                  !RegExp(r'^\+?[\d\s()-]{7,20}$').hasMatch(v ?? '')
                  ? 'Enter a valid contact number'
                  : null,
            ),
            const SizedBox(height: 30),
            SectionHeading(
              'Departments',
              subtitle: 'Names and locations used by hospital staff.',
              trailing: TextButton.icon(
                onPressed: widget.controller.canEditHospital && !_saving
                    ? () => _editDepartment()
                    : null,
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
              ),
            ),
            if (_departments.isEmpty)
              EmptyState(
                icon: Icons.local_hospital_outlined,
                title: widget.controller.settingsLoaded
                    ? 'No departments added'
                    : 'Departments unavailable',
                detail: widget.controller.settingsLoaded
                    ? 'Add a department and its location to get started.'
                    : 'Load the hospital configuration with authorized Firebase access.',
              ),
            for (final department in _departments)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: StaffStyle.line)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      color: StaffStyle.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            department.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            department.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: StaffStyle.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!department.active)
                      const StatusPill('Inactive', color: StaffStyle.muted),
                    IconButton(
                      tooltip: 'Edit ${department.name}',
                      onPressed: widget.controller.canEditHospital && !_saving
                          ? () => _editDepartment(department)
                          : null,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Delete ${department.name}',
                      onPressed: widget.controller.canEditHospital && !_saving
                          ? () => _deleteDepartment(department)
                          : null,
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              InfoBanner(_error!, warning: true),
              const SizedBox(height: 18),
            ],
            if (_dirty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'You have unsaved changes.',
                  style: TextStyle(color: StaffStyle.amber, fontSize: 12),
                ),
              ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: !_dirty || _saving
                      ? null
                      : () => setState(() {
                          _name.text = widget.controller.hospitalName;
                          _address.text = widget.controller.hospitalAddress;
                          _phone.text = widget.controller.hospitalPhone;
                          _departments = [...widget.controller.departments];
                          _dirty = false;
                          widget.onDirty(false);
                          _error = null;
                        }),
                  child: const Text('Discard changes'),
                ),
                FilledButton.icon(
                  onPressed:
                      !_dirty || _saving || !widget.controller.canEditHospital
                      ? null
                      : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 17),
                  label: Text(_saving ? 'Saving…' : 'Save changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.saveHospital(
        _name.text.trim(),
        _address.text.trim(),
        _phone.text.trim(),
        _departments,
      );
      if (mounted) {
        setState(() => _dirty = false);
        widget.onDirty(false);
        widget.onSaved();
      }
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

  Future<void> _deleteDepartment(Department department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete department?'),
        content: Text(
          'Remove ${department.name}? Save changes to confirm the deletion. Departments assigned to accounts or staff contacts cannot be removed.',
        ),
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
    if (confirmed != true ||
        !mounted ||
        !widget.controller.canEditHospital ||
        _saving) {
      return;
    }
    setState(() {
      _departments.removeWhere((d) => d.id == department.id);
      _dirty = true;
      widget.onDirty(true);
    });
  }

  Future<void> _editDepartment([Department? department]) async {
    final result = await showDialog<Department>(
      context: context,
      builder: (_) =>
          DepartmentDialog(department: department, existing: _departments),
    );
    if (result == null ||
        !mounted ||
        !widget.controller.canEditHospital ||
        _saving) {
      return;
    }
    setState(() {
      _dirty = true;
      widget.onDirty(true);
      if (department == null) {
        _departments.add(result);
      } else {
        _departments = _departments
            .map((d) => d.id == department.id ? result : d)
            .toList();
      }
    });
  }
}

class DepartmentDialog extends StatefulWidget {
  final Department? department;
  final List<Department> existing;
  const DepartmentDialog({super.key, this.department, required this.existing});
  @override
  State<DepartmentDialog> createState() => _DepartmentDialogState();
}

class _DepartmentDialogState extends State<DepartmentDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name, _location;
  late bool _active;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.department?.name ?? '');
    _location = TextEditingController(text: widget.department?.location ?? '');
    _active = widget.department?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.department == null ? 'Add department' : 'Edit department',
    ),
    content: SizedBox(
      width: 430,
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Department name'),
              validator: (v) {
                if ((v ?? '').trim().length < 2) {
                  return 'Enter a department name';
                }
                if (widget.existing.any(
                  (d) =>
                      d.id != widget.department?.id &&
                      d.name.toLowerCase() == v!.trim().toLowerCase(),
                )) {
                  return 'This department already exists';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Block A · Ground floor',
              ),
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? 'Enter a location' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Active department',
                style: TextStyle(fontSize: 13),
              ),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
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
          if (_key.currentState!.validate()) {
            Navigator.pop(
              context,
              Department(
                widget.department?.id ??
                    'department-${DateTime.now().microsecondsSinceEpoch}',
                _name.text.trim(),
                _location.text.trim(),
                active: _active,
              ),
            );
          }
        },
        child: const Text('Apply'),
      ),
    ],
  );
}
