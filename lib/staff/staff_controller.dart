import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'staff_models.dart';
import 'staff_store.dart';

/// Preview uses an isolated, in-memory workspace. Live mode never substitutes
/// example records when a Firebase request fails.
class StaffController extends ChangeNotifier {
  final bool preview;
  final String actorId, actorName;
  StaffStore? _store;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<StaffAccount> accounts = [];
  List<Department> departments = [];
  List<StaffActivity> activity = [];
  List<OperationsAlert> alerts = [];
  List<StaffRecord> records = [];
  bool recordsLoaded = false, recordsFromCache = false;
  final Map<String, String> errors = {};
  String hospitalName = 'Hospital workspace';
  String hospitalAddress = '';
  String hospitalPhone = '';
  bool loading = false, busy = false, disposed = false;
  bool settingsLoaded = false;
  bool accountsFromCache = false, settingsFromCache = false;
  bool actorLoaded = false, actorFromCache = false;
  bool activityLoaded = false, activityFromCache = false;
  StaffAccount? _liveActor;
  String? actorErrorCode;
  String? accountsErrorCode;
  DateTime? lastSynced;

  StaffController({
    this.preview = false,
    required this.actorId,
    required this.actorName,
    StaffStore? store,
  }) {
    if (preview) {
      _seed();
    } else {
      _store = store ?? FirestoreStaffStore();
      connect();
    }
  }

  List<StaffAccount> get pending =>
      accounts.where((a) => a.status == AccountStatus.pending).toList();
  List<StaffAccount> get staff =>
      accounts.where((a) => a.role == 'admin').toList();
  int get activeCount =>
      accounts.where((a) => a.status == AccountStatus.active).length;
  int get doctorsCount => accounts
      .where((a) => a.role == 'doctor' && a.status == AccountStatus.active)
      .length;
  StaffAccount? get signedInProfile =>
      preview ? accounts.where((a) => a.id == actorId).firstOrNull : _liveActor;
  StaffAccount? get actorAccount {
    final profile = signedInProfile;
    return profile != null &&
            profile.role == 'admin' &&
            profile.active &&
            profile.verified
        ? profile
        : null;
  }

  String get actorRole => signedInProfile?.staffRole ?? 'Read-only access';
  String? get accountAccessIssue {
    if (errors.containsKey('Account access')) return errors['Account access'];
    if (!actorLoaded) return null;
    if (actorFromCache && !preview) {
      return 'Your account permissions are cached. Reconnect to Firebase to verify hospital staff access.';
    }
    final profile = signedInProfile;
    if (profile == null) {
      return 'Your account profile is missing at users/$actorId. Ask the Firebase project owner to provision your hospital staff account.';
    }
    if (!profile.active) {
      return 'Your hospital staff account is inactive. Contact your hospital administrator.';
    }
    if (!profile.verified) {
      return 'Your hospital staff account has not been verified. Contact your hospital administrator.';
    }
    if (profile.role != 'admin' ||
        !const [
          'Super administrator',
          'Hospital administrator',
          'Support coordinator',
        ].contains(profile.staffRole)) {
      return 'Your account has no supported hospital staff role. Ask the Firebase project owner to assign an explicit staffRole to users/$actorId. Hospital staff access requires role: admin and an authorized staff role.';
    }
    return null;
  }

  bool get canReadWorkspace => actorLoaded && accountAccessIssue == null;
  bool get canManage =>
      canReadWorkspace &&
      actorAccount != null &&
      const [
        'Super administrator',
        'Hospital administrator',
      ].contains(actorRole);
  bool get canManageStaff =>
      canReadWorkspace &&
      actorAccount != null &&
      actorRole == 'Super administrator';
  bool get canReview => canManage && canWrite;
  String? get reviewUnavailableReason {
    if (accountAccessIssue != null) return accountAccessIssue;
    if (errors.containsKey('Accounts')) return errors['Accounts'];
    if (loading) return 'Waiting for Firebase to load account access.';
    if (accountsFromCache) {
      return 'Showing cached account data. Changes are disabled until Firebase reconnects.';
    }
    if (!canManage) {
      return 'Doctor reviews require an active, verified administrator account with an explicit Super administrator or Hospital administrator staff role. Contact your hospital administrator.';
    }
    return null;
  }

  bool get canWrite =>
      !disposed &&
      !busy &&
      !loading &&
      canManage &&
      !accountsFromCache &&
      !errors.containsKey('Accounts');
  bool get canEditHospital =>
      canManage &&
      canWrite &&
      settingsLoaded &&
      !settingsFromCache &&
      !errors.containsKey('Hospital settings');
  bool get canEditRecords =>
      !disposed &&
      !busy &&
      canManage &&
      recordsLoaded &&
      !recordsFromCache &&
      !errors.containsKey('Staff records');

  String get connectionLabel {
    if (preview) return 'Preview';
    if (errors.containsKey('Account access')) {
      return _failureLabel(actorErrorCode);
    }
    if (actorLoaded && actorFromCache) return 'Offline / cached permissions';
    if (actorLoaded && accountAccessIssue != null) {
      return 'Staff access required';
    }
    if (errors.containsKey('Accounts')) return _failureLabel(accountsErrorCode);
    if (loading || !actorLoaded) return 'Connecting';
    return accountsFromCache ? 'Offline / cached data' : 'Connected';
  }

  String _failureLabel(String? code) => switch (code) {
    'permission-denied' => 'Access denied',
    'unauthenticated' => 'Sign-in required',
    _ => 'Connection issue',
  };

  void _emit() {
    if (!disposed) notifyListeners();
  }

  void connect() {
    if (preview || disposed) return;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    loading = true;
    settingsLoaded = false;
    actorLoaded = false;
    activityLoaded = false;
    recordsLoaded = false;
    errors.clear();
    accountsErrorCode = null;
    actorErrorCode = null;
    _subscriptions.add(
      _store!
          .watchActor(actorId)
          .listen(
            (snapshot) {
              _liveActor = snapshot.data;
              actorLoaded = true;
              actorFromCache = snapshot.fromCache;
              actorErrorCode = null;
              errors.remove('Account access');
              _emit();
            },
            onError: (Object error) {
              actorLoaded = true;
              _liveActor = null;
              actorFromCache = false;
              actorErrorCode = error is FirebaseException ? error.code : null;
              errors['Account access'] = _friendly(error);
              _emit();
            },
          ),
    );
    _emit();
    _subscriptions.add(
      _store!.watchRecords().listen(
        (snapshot) {
          records = snapshot.data;
          recordsLoaded = true;
          recordsFromCache = snapshot.fromCache;
          errors.remove('Staff records');
          _emit();
        },
        onError: (Object error) {
          records = [];
          recordsLoaded = false;
          errors['Staff records'] = _friendly(error);
          _emit();
        },
      ),
    );
    _subscriptions.add(
      _store!.watchAccounts().listen(
        (snapshot) {
          accounts = [...snapshot.data]
            ..sort((a, b) => a.name.compareTo(b.name));
          loading = false;
          errors.remove('Accounts');
          accountsErrorCode = null;
          accountsFromCache = snapshot.fromCache;
          if (!accountsFromCache) lastSynced = DateTime.now();
          _emit();
        },
        onError: (Object error) {
          loading = false;
          accountsErrorCode = error is FirebaseException ? error.code : null;
          if (accountsErrorCode == 'permission-denied' ||
              accountsErrorCode == 'unauthenticated') {
            // A denied query must not keep exposing previously cached profiles.
            accounts = [];
            accountsFromCache = false;
          }
          errors['Accounts'] = _friendly(error);
          _emit();
        },
      ),
    );
    _subscriptions.add(
      _store!.watchActivity().listen(
        (snapshot) {
          activity = snapshot.data;
          activityLoaded = true;
          activityFromCache = snapshot.fromCache;
          errors.remove('Activity');
          _emit();
        },
        onError: (Object error) {
          activityLoaded = false;
          if (error is FirebaseException &&
              const [
                'permission-denied',
                'unauthenticated',
              ].contains(error.code)) {
            activity = [];
            activityFromCache = false;
          }
          errors['Activity'] = _friendly(error);
          _emit();
        },
      ),
    );
    _subscriptions.add(
      _store!.watchHospital().listen(
        (snapshot) {
          try {
            final data = snapshot.data;
            if (data.isEmpty) {
              _clearHospital();
              settingsFromCache = snapshot.fromCache;
              errors['Hospital settings'] = snapshot.fromCache
                  ? 'Hospital configuration is not available in the local cache. Reconnect to Firebase to load hospital_settings/default.'
                  : 'Hospital configuration is missing at hospital_settings/default. Ask the Firebase project owner to configure this hospital.';
              _emit();
              return;
            }
            final loadedDepartments = (data['departments'] as List? ?? [])
                .map((d) => Department.fromMap(Map<String, dynamic>.from(d)))
                .toList();
            hospitalName = data['name'] ?? 'Hospital workspace';
            hospitalAddress = data['address'] ?? '';
            hospitalPhone = data['phone'] ?? '';
            departments = loadedDepartments;
            settingsLoaded = true;
            settingsFromCache = snapshot.fromCache;
            errors.remove('Hospital settings');
          } catch (_) {
            _clearHospital();
            errors['Hospital settings'] = 'Hospital settings contain invalid data. Ask the administrator to check the configuration.';
          }
          _emit();
        },
        onError: (Object error) {
          settingsLoaded = false;
          if (error is FirebaseException &&
              const [
                'permission-denied',
                'unauthenticated',
              ].contains(error.code)) {
            _clearHospital();
          }
          errors['Hospital settings'] = _friendly(error);
          _emit();
        },
      ),
    );
  }

  void _clearHospital() {
    settingsLoaded = false;
    settingsFromCache = false;
    hospitalName = 'Hospital workspace';
    hospitalAddress = '';
    hospitalPhone = '';
    departments = [];
  }

  String _friendly(Object error) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => 'You do not have access to this information. Contact your hospital administrator.',
        'unauthenticated' => 'Your Firebase session has expired. Sign in again before making changes.',
        'unavailable' => 'Firebase is unavailable. Check your internet connection and try again.',
        'failed-precondition' => 'Firebase configuration needs attention. Ask the project owner to check the required indexes and settings.',
        _ =>
          'Firebase request failed (${error.code}). Contact your hospital administrator.',
      };
    }
    return 'Unable to load workspace data. Check your connection or ask the administrator to check the records.';
  }

  void _record(String title, String detail) {
    activity.insert(0, StaffActivity(title, detail, actorName, DateTime.now()));
  }

  Map<String, dynamic> _audit(String title, String detail) => {
    'title': title,
    'detail': detail,
    'actor': actorAccount?.name ?? actorName,
    'actorId': actorId,
  };

  Future<void> updateAccount(
    StaffAccount account,
    Map<String, dynamic> changes,
    String title,
    String detail,
  ) async {
    const fields = {'name', 'phone', 'department', 'staffRole'};
    if (changes.isEmpty || changes.keys.any((key) => !fields.contains(key))) {
      throw StateError(
        'Use the account status or doctor review action for this change.',
      );
    }
    if (changes.containsKey('name') &&
        (changes['name'] is! String ||
            (changes['name'] as String).trim().length < 2)) {
      throw StateError('Enter a valid account name.');
    }
    if (changes.containsKey('staffRole') &&
        !const [
          'Super administrator',
          'Hospital administrator',
          'Support coordinator',
        ].contains(changes['staffRole'])) {
      throw StateError('Choose a valid staff role.');
    }
    await _writeAccount(_current(account.id), changes, title, detail);
  }

  StaffAccount _current(String id) =>
      accounts.where((a) => a.id == id).firstOrNull ??
      (throw StateError(
        'This account is no longer available. Refresh the workspace.',
      ));

  Future<void> _writeAccount(
    StaffAccount account,
    Map<String, dynamic> changes,
    String title,
    String detail,
  ) async {
    if (!canWrite) {
      throw StateError(
        reviewUnavailableReason ??
            'Wait for the workspace to reconnect before making changes.',
      );
    }
    if (!canManage) {
      throw StateError('Your role can view accounts but cannot change them.');
    }
    if (account.role == 'admin' && !canManageStaff) {
      throw StateError('Only a super administrator can change staff accounts.');
    }
    if (account.id == actorId &&
        (changes['isActive'] == false || changes.containsKey('staffRole'))) {
      throw StateError(
        'You cannot deactivate your own account or change your own access.',
      );
    }
    if (account.role == 'admin' &&
        account.active &&
        changes['isActive'] == false &&
        staff.where((s) => s.active).length <= 1) {
      throw StateError(
        'At least one hospital administrator must remain active.',
      );
    }
    busy = true;
    _emit();
    try {
      if (preview) {
        accounts = accounts
            .map((a) => a.id == account.id ? a.withChanges(changes) : a)
            .toList();
        _record(title, detail);
      } else {
        await _store!.writeAccount(account.id, changes, _audit(title, detail));
      }
    } on FirebaseException catch (error) {
      throw StateError(_friendly(error));
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> review(
    StaffAccount account, {
    required bool approve,
    String reason = '',
    bool identityChecked = false,
    bool credentialsChecked = false,
  }) async {
    account = _current(account.id);
    if (account.status != AccountStatus.pending) {
      throw StateError('This registration is no longer waiting for review.');
    }
    if (approve && (!identityChecked || !credentialsChecked)) {
      throw StateError(
        'Confirm both identity and credentials before approving.',
      );
    }
    if (!approve && reason.trim().length < 8) {
      throw StateError('Please give a clear reason for the decision.');
    }
    await _writeAccount(
      account,
      {
        'isApproved': approve,
        'isVerified': approve,
        'approvalStatus': approve ? 'approved' : 'rejected',
        'reviewNote': approve
            ? 'Identity and credentials reviewed by $actorName'
            : 'Rejected: ${reason.trim()}',
        'reviewedBy': actorId,
        'identityChecked': approve && identityChecked,
        'credentialsChecked': approve && credentialsChecked,
        'reviewReason': approve ? '' : reason.trim(),
      },
      approve ? 'Doctor registration approved' : 'Doctor registration rejected',
      '${account.name}${approve ? ' · Identity and credentials checked' : ' · ${reason.trim()}'}',
    );
  }

  Future<void> setActive(
    StaffAccount account, {
    required bool active,
    required String reason,
  }) async {
    account = _current(account.id);
    if (reason.trim().length < 8) {
      throw StateError('Please give a clear reason for the account change.');
    }
    if (account.active == active) {
      throw StateError(
        'This account status has already changed. Refresh the workspace.',
      );
    }
    if (active && account.invitationPrepared) {
      throw StateError(
        'A prepared invitation is not a registered account. No invitation has been delivered.',
      );
    }
    await _writeAccount(
      account,
      {'isActive': active, 'accountStatusReason': reason.trim()},
      '${account.role == 'admin'
          ? 'Staff'
          : account.role == 'doctor'
          ? 'Doctor'
          : 'Patient'} account ${active ? 'reactivated' : 'deactivated'}',
      '${account.name} · ${reason.trim()}',
    );
  }

  Future<void> saveHospital(
    String name,
    String address,
    String phone,
    List<Department> updatedDepartments,
  ) async {
    if (!canManage) {
      throw StateError(
        'You cannot change hospital settings with your current access.',
      );
    }
    if (!canEditHospital) {
      throw StateError(
        'Wait for hospital settings to reconnect before saving.',
      );
    }
    if (name.trim().length < 3 ||
        address.trim().length < 5 ||
        !RegExp(r'^\+?[0-9\s()-]{7,20}$').hasMatch(phone.trim()) ||
        updatedDepartments.any(
          (d) => d.name.trim().isEmpty || d.location.trim().isEmpty,
        ) ||
        updatedDepartments.map((d) => d.id).toSet().length !=
            updatedDepartments.length) {
      throw StateError('Enter valid hospital contact details and departments.');
    }
    final removed = departments.where(
      (d) => !updatedDepartments.any((next) => next.id == d.id),
    );
    if (removed.isNotEmpty &&
        (!recordsLoaded ||
            recordsFromCache ||
            errors.containsKey('Staff records'))) {
      throw StateError('Load staff contacts before deleting a department.');
    }
    for (final department in removed) {
      final keys = {
        department.id.toLowerCase(),
        department.name.trim().toLowerCase(),
      };
      if (accounts.any(
            (a) => keys.contains(a.department.trim().toLowerCase()),
          ) ||
          records.any(
            (r) =>
                r.type == StaffRecordType.directory &&
                keys.contains(r.category.trim().toLowerCase()),
          )) {
        throw StateError(
          '${department.name} is assigned to an account or staff contact. Reassign them before deleting it.',
        );
      }
    }
    if (updatedDepartments
            .map((d) => d.name.trim().toLowerCase())
            .toSet()
            .length !=
        updatedDepartments.length) {
      throw StateError('Department names must be unique.');
    }
    busy = true;
    _emit();
    try {
      if (!preview) {
        await _store!.writeHospital({
          'name': name,
          'address': address,
          'phone': phone,
          'departments': updatedDepartments.map((d) => d.toMap()).toList(),
        }, _audit('Hospital information updated', name));
      } else {
        hospitalName = name;
        hospitalAddress = address;
        hospitalPhone = phone;
        departments = updatedDepartments;
        _record('Hospital information updated', name);
      }
    } on FirebaseException catch (error) {
      throw StateError(_friendly(error));
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> saveRecord(StaffRecord record, {bool delete = false}) async {
    if (!canEditRecords) {
      throw StateError(
        'Reconnect with administrator access before making changes.',
      );
    }
    final current = records.where((r) => r.id == record.id).firstOrNull;
    if ((record.revision == 0 && (delete || current != null)) ||
        (record.revision > 0 &&
            (current == null ||
                current.revision != record.revision ||
                current.type != record.type))) {
      throw StateError(
        'This record changed. Close the form and reopen the latest record.',
      );
    }
    final normalized = StaffRecord(
      id: record.id,
      type: record.type,
      title: record.title.trim(),
      detail: record.detail.trim(),
      category: record.category.trim(),
      contact: record.contact.trim(),
      active: record.active,
      revision: record.revision,
    );
    if (!delete &&
        (normalized.title.length < 2 ||
            normalized.title.length > 100 ||
            normalized.detail.length < 2 ||
            normalized.detail.length > 1000 ||
            normalized.category.isEmpty ||
            normalized.category.length > 100 ||
            (normalized.type == StaffRecordType.directory &&
                !RegExp(r'^\+?[0-9\s()-]{7,20}$')
                    .hasMatch(normalized.contact)) ||
            (normalized.type == StaffRecordType.notice &&
                (!const [
                      'All staff',
                      'Doctors',
                      'Reception',
                      'Administration',
                    ].contains(normalized.category) ||
                    normalized.contact.isNotEmpty)))) {
      throw StateError(
        'Enter a valid title, details, category and contact number.',
      );
    }
    final label = record.type == StaffRecordType.directory
        ? 'Staff contact'
        : 'Hospital notice';
    final action = delete
        ? 'deleted'
        : record.revision == 0
        ? 'created'
        : 'updated';
    busy = true;
    _emit();
    try {
      if (preview) {
        records = records.where((r) => r.id != record.id).toList();
        if (!delete) records.add(normalized.nextRevision);
        _record('$label $action', normalized.title);
      } else {
        await _store!.writeRecord(normalized, {
          ..._audit('$label $action', normalized.title),
          'recordId': record.id,
          'recordType': record.type.name,
          'operation': action,
        }, delete: delete);
      }
    } on FirebaseException catch (error) {
      throw StateError(_friendly(error));
    } finally {
      busy = false;
      _emit();
    }
  }

  void acknowledge(OperationsAlert alert) {
    if (!preview || alert.acknowledged) return;
    if (!canManage || !canWrite) {
      throw StateError(
        'Your role can view alerts but cannot acknowledge them.',
      );
    }
    alert.acknowledged = true;
    _record('Alert acknowledged', alert.title);
    _emit();
  }

  void invitePreviewStaff(String name, String email, String role) {
    if (!preview || !canManageStaff || !canWrite) {
      throw StateError(
        'Staff invitations are not available with your current access.',
      );
    }
    name = name.trim();
    email = email.trim();
    if (name.length < 2 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email) ||
        !const [
          'Hospital administrator',
          'Support coordinator',
        ].contains(role)) {
      throw StateError('Enter a valid name, email and invitation role.');
    }
    if (accounts.any((a) => a.email.toLowerCase() == email.toLowerCase())) {
      throw StateError('This email is already in the workspace.');
    }
    accounts.add(
      StaffAccount(
        id: 'invited-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        email: email,
        role: 'admin',
        staffRole: role,
        active: false,
        createdAt: DateTime.now(),
        reviewNote: 'Invitation prepared (preview only)',
      ),
    );
    _record(
      'Staff invitation prepared',
      '$name · $role · Preview only; no email sent',
    );
    _emit();
  }

  void _seed() {
    recordsLoaded = true;
    records = const [
      StaffRecord(
        id: 'contact-reception',
        type: StaffRecordType.directory,
        title: 'Nimali Perera',
        detail: 'Reception coordinator',
        category: 'General OPD',
        contact: '011 269 1111',
        revision: 1,
      ),
      StaffRecord(
        id: 'notice-briefing',
        type: StaffRecordType.notice,
        title: 'Morning staff briefing',
        detail: 'Meet at the reception desk at 7:45 AM before the morning OPD session.',
        category: 'All staff',
        revision: 1,
      ),
    ];
    actorLoaded = true;
    activityLoaded = true;
    final now = DateTime.now();
    hospitalName = 'National Hospital of Sri Lanka';
    hospitalAddress = 'Regent Street, Colombo 10';
    hospitalPhone = '+94 11 269 1111';
    settingsLoaded = true;
    lastSynced = now;
    accounts = [
      StaffAccount(
        id: 'preview-admin',
        name: 'Ayesha Fernando',
        email: 'ayesha@example.com',
        role: 'admin',
        staffRole: 'Super administrator',
        department: 'Hospital administration',
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      StaffAccount(
        id: 'staff-2',
        name: 'Ruwan Senanayake',
        email: 'ruwan@example.com',
        role: 'admin',
        staffRole: 'Hospital administrator',
        department: 'OPD operations',
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      StaffAccount(
        id: 'staff-3',
        name: 'Nadeesha Perera',
        email: 'nadeesha@example.com',
        role: 'admin',
        staffRole: 'Support coordinator',
        department: 'Patient services',
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      StaffAccount(
        id: 'doctor-1',
        name: 'Dr. Kamal Perera',
        email: 'kamal@example.com',
        phone: '+94 77 123 4567',
        role: 'doctor',
        department: 'General OPD',
        registration: 'SLMC-DEMO-10482',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      StaffAccount(
        id: 'doctor-2',
        name: 'Dr. Malini Silva',
        email: 'malini@example.com',
        phone: '+94 71 234 5678',
        role: 'doctor',
        department: 'Paediatrics',
        registration: 'SLMC-DEMO-12864',
        approved: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      StaffAccount(
        id: 'doctor-3',
        name: 'Dr. Dinesh Jayawardena',
        email: 'dinesh@example.com',
        phone: '+94 76 345 6789',
        role: 'doctor',
        department: 'General OPD',
        registration: 'SLMC-DEMO-15309',
        approved: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      StaffAccount(
        id: 'doctor-4',
        name: 'Dr. Tharushi De Silva',
        email: 'tharushi@example.com',
        role: 'doctor',
        department: 'Eye clinic',
        registration: 'SLMC-DEMO-13675',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      StaffAccount(
        id: 'patient-1',
        name: 'Nimal Rathnayake',
        email: 'nimal@example.com',
        phone: '+94 77 456 7890',
        role: 'patient',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      StaffAccount(
        id: 'patient-2',
        name: 'Sanduni Wijesinghe',
        email: 'sanduni@example.com',
        role: 'patient',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      StaffAccount(
        id: 'patient-3',
        name: 'Mohamed Rizwan',
        email: 'rizwan@example.com',
        role: 'patient',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      StaffAccount(
        id: 'patient-4',
        name: 'Kavindi Fernando',
        email: 'kavindi@example.com',
        role: 'patient',
        active: false,
        accountStatusReason: 'Duplicate patient registration',
        createdAt: now.subtract(const Duration(days: 16)),
      ),
    ];
    departments = const [
      Department('general', 'General OPD', 'Block A · Ground floor'),
      Department('paediatrics', 'Paediatrics', 'Block B · First floor'),
      Department('eye', 'Eye clinic', 'Block C · Ground floor'),
    ];
    activity = [
      StaffActivity(
        'Doctor account updated',
        'Dr. Kamal Perera · General OPD',
        'Ruwan Senanayake',
        now.subtract(const Duration(minutes: 18)),
      ),
      StaffActivity(
        'Department information updated',
        'Paediatrics · Block B, First floor',
        actorName,
        now.subtract(const Duration(minutes: 42)),
      ),
      StaffActivity(
        'Patient account deactivated',
        'Kavindi Fernando · Duplicate registration',
        actorName,
        now.subtract(const Duration(hours: 1)),
      ),
    ];
    alerts = [
      OperationsAlert(
        'sms',
        'SMS delivery is delayed',
        'The example SMS gateway is responding slowly. Monitor delivery before sending appointment reminders.',
        'Check service',
      ),
      OperationsAlert(
        'backup',
        'Daily backup needs attention',
        'The example backup has not completed. Ask the system administrator to check the backup schedule.',
        'View details',
      ),
    ];
  }

  @override
  void dispose() {
    disposed = true;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
