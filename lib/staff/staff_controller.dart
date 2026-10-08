import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'staff_models.dart';

/// Preview uses an isolated, in-memory workspace. Live mode never substitutes
/// example records when a Firebase request fails.
class StaffController extends ChangeNotifier {
  final bool preview;
  final String actorId, actorName;
  FirebaseFirestore? _db;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  List<StaffAccount> accounts = [];
  List<Department> departments = [];
  List<StaffActivity> activity = [];
  List<OperationsAlert> alerts = [];
  final Map<String, String> errors = {};
  String hospitalName = 'Hospital workspace';
  String hospitalAddress = '';
  String hospitalPhone = '';
  bool loading = false, busy = false, disposed = false;
  bool settingsLoaded = false;
  DateTime? lastSynced;

  StaffController({
    this.preview = false,
    required this.actorId,
    required this.actorName,
  }) {
    if (preview) {
      _seed();
    } else {
      _db = FirebaseFirestore.instance;
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
  StaffAccount? get actorAccount => accounts
      .where((a) => a.id == actorId && a.role == 'admin' && a.active)
      .firstOrNull;
  String get actorRole => actorAccount?.staffRole ?? 'Read-only access';
  bool get canManage =>
      actorAccount != null &&
      const [
        'Super administrator',
        'Hospital administrator',
      ].contains(actorRole);
  bool get canManageStaff =>
      actorAccount != null && actorRole == 'Super administrator';
  bool get canWrite => !busy && !loading && !errors.containsKey('Accounts');

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
    errors.clear();
    _emit();
    _subscriptions.add(
      _db!
          .collection('users')
          .snapshots()
          .listen(
            (snapshot) {
              accounts =
                  snapshot.docs
                      .map((doc) => StaffAccount.fromMap(doc.id, doc.data()))
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));
              loading = false;
              errors.remove('Accounts');
              lastSynced = DateTime.now();
              _emit();
            },
            onError: (Object error) {
              loading = false;
              errors['Accounts'] = _friendly(error);
              _emit();
            },
          ),
    );
    _subscriptions.add(
      _db!
          .collection('staff_activity')
          .orderBy('time', descending: true)
          .limit(80)
          .snapshots()
          .listen(
            (snapshot) {
              activity = snapshot.docs.map((doc) {
                final d = doc.data();
                return StaffActivity(
                  d['title'] ?? '',
                  d['detail'] ?? '',
                  d['actor'] ?? '',
                  (d['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
                );
              }).toList();
              errors.remove('Activity');
              _emit();
            },
            onError: (Object error) {
              errors['Activity'] = _friendly(error);
              _emit();
            },
          ),
    );
    _subscriptions.add(
      _db!
          .collection('hospital_settings')
          .doc('default')
          .snapshots()
          .listen(
            (snapshot) {
              final data = snapshot.data() ?? {};
              hospitalName = data['name'] ?? 'Hospital workspace';
              hospitalAddress = data['address'] ?? '';
              hospitalPhone = data['phone'] ?? '';
              departments = (data['departments'] as List? ?? [])
                  .map((d) => Department.fromMap(Map<String, dynamic>.from(d)))
                  .toList();
              settingsLoaded = true;
              errors.remove('Hospital settings');
              _emit();
            },
            onError: (Object error) {
              errors['Hospital settings'] = _friendly(error);
              _emit();
            },
          ),
    );
  }

  String _friendly(Object error) =>
      error is FirebaseException && error.code == 'permission-denied'
      ? 'You do not have access to this information. Contact your hospital administrator.'
      : 'Unable to connect. Check your internet connection and try again.';

  void _record(String title, String detail) {
    activity.insert(0, StaffActivity(title, detail, actorName, DateTime.now()));
  }

  void _auditBatch(WriteBatch batch, String title, String detail) {
    batch.set(_db!.collection('staff_activity').doc(), {
      'title': title,
      'detail': detail,
      'actor': actorName,
      'actorId': actorId,
      'time': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAccount(
    StaffAccount account,
    Map<String, dynamic> changes,
    String title,
    String detail,
  ) async {
    if (!canWrite) {
      throw StateError(
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
        final batch = _db!.batch();
        batch.update(_db!.collection('users').doc(account.id), changes);
        _auditBatch(batch, title, detail);
        await batch.commit();
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
  }) async {
    if (account.status != AccountStatus.pending) {
      throw StateError('This registration is no longer waiting for review.');
    }
    if (!approve && reason.trim().length < 8) {
      throw StateError('Please give a clear reason for the decision.');
    }
    await updateAccount(
      account,
      {
        'isApproved': approve,
        'isVerified': approve,
        'approvalStatus': approve ? 'approved' : 'rejected',
        'reviewNote': approve
            ? 'Credentials reviewed by $actorName'
            : 'Rejected: ${reason.trim()}',
        if (!preview) 'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': actorId,
      },
      approve ? 'Doctor registration approved' : 'Doctor registration rejected',
      '${account.name}${approve ? ' · Credentials checked' : ' · ${reason.trim()}'}',
    );
  }

  Future<void> saveHospital(
    String name,
    String address,
    String phone,
    List<Department> updatedDepartments,
  ) async {
    if (!canManage || busy) {
      throw StateError(
        'You cannot change hospital settings with your current access.',
      );
    }
    if (!preview &&
        (!settingsLoaded || errors.containsKey('Hospital settings'))) {
      throw StateError(
        'Wait for hospital settings to reconnect before saving.',
      );
    }
    busy = true;
    _emit();
    try {
      if (!preview) {
        final batch = _db!.batch();
        batch.set(_db!.collection('hospital_settings').doc('default'), {
          'name': name,
          'address': address,
          'phone': phone,
          'departments': updatedDepartments.map((d) => d.toMap()).toList(),
        }, SetOptions(merge: true));
        _auditBatch(batch, 'Hospital information updated', name);
        await batch.commit();
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

  void acknowledge(OperationsAlert alert) {
    if (!preview || alert.acknowledged) return;
    alert.acknowledged = true;
    _record('Alert acknowledged', alert.title);
    _emit();
  }

  void invitePreviewStaff(String name, String email, String role) {
    if (!preview || !canManageStaff) {
      throw StateError(
        'Staff invitations are not available with your current access.',
      );
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
        reviewNote: 'Deactivated: Duplicate patient registration',
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
