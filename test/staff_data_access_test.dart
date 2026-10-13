import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opd_connect/staff/staff_controller.dart';
import 'package:opd_connect/staff/staff_models.dart';
import 'package:opd_connect/staff/staff_store.dart';
import 'package:opd_connect/staff/staff_workspace.dart';

import 'helpers/staff_test_store.dart';

const actorId = 'signed-in-admin';
const pendingDoctor = StaffAccount(
  id: 'doctor',
  name: 'Pending Doctor',
  email: 'doctor@example.test',
  role: 'doctor',
  approved: false,
  verified: false,
);
StaffAccount actor([String? role = 'Hospital administrator']) =>
    StaffAccount.fromMap(actorId, {
      'name': 'Hospital Admin',
      'role': 'admin',
      'isVerified': true,
      'staffRole': ?role,
    });
FirebaseException denied() =>
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
Future<void> flush() => Future<void>.delayed(Duration.zero);

void viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

StaffController controller(TestStaffStore store) {
  final c = StaffController(
    actorId: actorId,
    actorName: 'Hospital Admin',
    store: store,
  );
  addTearDown(c.dispose);
  addTearDown(store.close);
  return c;
}

void main() {
  testWidgets(
    'own profile missing staffRole is diagnosed even while directories are denied',
    (tester) async {
      viewport(tester);
      final store = TestStaffStore();
      final c = controller(store);
      await tester.pumpWidget(
        MaterialApp(home: HospitalStaffWorkspace(controller: c)),
      );
      // Exact live failure: own profile readable, role=admin/isVerified=true,
      // missing staffRole/isActive, and all three administration reads denied.
      store.actor.add(StaffSnapshot(actor(null)));
      store.accounts.addError(denied());
      store.activity.addError(denied());
      store.hospital.addError(denied());
      await tester.pumpAndSettle();
      expect(c.signedInProfile?.role, 'admin');
      expect(c.connectionLabel, 'Staff access required');
      expect(c.accountAccessIssue, contains('explicit staffRole'));
      expect(c.canReadWorkspace, isFalse);
      expect(
        c.errors.keys,
        containsAll(['Accounts', 'Activity', 'Hospital settings']),
      );
      for (final section in [
        'User accounts',
        'Verifications',
        'Staff & roles',
        'Hospital setup',
        'Activity log',
      ]) {
        await tester.tap(find.text(section));
        await tester.pumpAndSettle();
        expect(find.text('Staff access unavailable'), findsOneWidget);
        expect(find.textContaining('explicit staffRole'), findsOneWidget);
        expect(find.textContaining('0 accounts'), findsNothing);
        expect(find.text('No activity to show'), findsNothing);
        expect(find.text('No departments added'), findsNothing);
      }
      expect(store.writeAttempts, 0);
    },
  );

  for (final role in [
    'Hospital administrator',
    'Super administrator',
    'Support coordinator',
  ]) {
    test(
      '$role loads all single-hospital data with the intended write permission',
      () async {
        final store = TestStaffStore();
        final c = controller(store);
        store.emit([actor(role), pendingDoctor]);
        store.activity.add(
          StaffSnapshot([
            StaffActivity(
              'Doctor registration approved',
              'A decision',
              'Hospital Admin',
              DateTime(2026, 10, 8),
            ),
          ]),
        );
        await flush();
        expect(c.canReadWorkspace, isTrue);
        expect(c.staff.single.id, actorId);
        expect(c.pending.single.id, 'doctor');
        expect(c.hospitalName, 'Test Hospital');
        expect(c.departments.single.name, 'General OPD');
        expect(c.activity.single.title, 'Doctor registration approved');
        expect(c.actorRole, role);
        expect(c.canWrite, role != 'Support coordinator');
        expect(c.canEditHospital, role != 'Support coordinator');
        if (role == 'Support coordinator') {
          await expectLater(
            c.review(
              pendingDoctor,
              approve: false,
              reason: 'Unconfirmed credentials',
            ),
            throwsStateError,
          );
          await expectLater(
            c.saveHospital(
              'Another Hospital',
              'Colombo 10',
              '+94 11 269 1111',
              c.departments,
            ),
            throwsStateError,
          );
          expect(store.writeAttempts, 0);
        }
      },
    );
  }

  test('own role remains known when the users query fails; denial does not become missing role', () async {
    final store = TestStaffStore();
    final c = controller(store);
    store.actor.add(StaffSnapshot(actor()));
    store.accounts.addError(denied());
    await flush();
    expect(c.actorRole, 'Hospital administrator');
    expect(c.accountAccessIssue, isNull);
    expect(c.connectionLabel, 'Access denied');
    expect(c.canWrite, isFalse);
    expect(c.reviewUnavailableReason, contains('do not have access'));
  });

  test('cached actor permissions block access even when account records came from the server', () async {
    final store = TestStaffStore();
    final c = controller(store);
    store.emit([actor(), pendingDoctor]);
    await flush();
    store.actor.add(StaffSnapshot(actor(), fromCache: true));
    await flush();
    expect(c.canReadWorkspace, isFalse);
    expect(c.canWrite, isFalse);
    expect(c.connectionLabel, 'Offline / cached permissions');
    expect(c.accountAccessIssue, contains('permissions are cached'));
    store.actor.add(StaffSnapshot(actor()));
    await flush();
    expect(c.canWrite, isTrue);
    store.actor.add(StaffSnapshot(actor(null)));
    await flush();
    expect(c.canReadWorkspace, isFalse);
  });

  test('profile connection failure, expired session, denial, and missing profile stay distinct', () async {
    final store = TestStaffStore();
    final c = controller(store);
    for (final failure in {
      'unavailable': ['Connection issue', 'Firebase is unavailable'],
      'permission-denied': ['Access denied', 'do not have access'],
      'unauthenticated': ['Sign-in required', 'session has expired'],
    }.entries) {
      store.actor.addError(
        FirebaseException(plugin: 'cloud_firestore', code: failure.key),
      );
      await flush();
      expect(c.connectionLabel, failure.value[0]);
      expect(c.accountAccessIssue, contains(failure.value[1]));
      expect(c.canReadWorkspace, isFalse);
    }
    store.actor.add(const StaffSnapshot(null));
    await flush();
    expect(c.connectionLabel, 'Staff access required');
    expect(c.accountAccessIssue, contains('profile is missing'));
    expect(c.accountAccessIssue, isNot(contains('do not have access')));
  });

  testWidgets(
    'denied data sources show unavailable states instead of zero or empty records',
    (tester) async {
      viewport(tester);
      final store = TestStaffStore();
      final c = controller(store);
      await tester.pumpWidget(
        MaterialApp(home: HospitalStaffWorkspace(controller: c)),
      );
      store.emit([actor(), pendingDoctor]);
      await tester.pumpAndSettle();
      store.accounts.addError(denied());
      store.activity.addError(denied());
      store.hospital.addError(denied());
      await tester.pumpAndSettle();
      for (final section in ['User accounts', 'Staff & roles']) {
        await tester.tap(find.text(section));
        await tester.pumpAndSettle();
        expect(find.text('Directory unavailable'), findsOneWidget);
        expect(find.textContaining('0 accounts'), findsNothing);
      }
      await tester.tap(find.text('Verifications'));
      await tester.pumpAndSettle();
      expect(find.text('Queue data could not be loaded'), findsOneWidget);
      expect(find.text('0 pending'), findsNothing);
      await tester.tap(find.text('Hospital setup'));
      await tester.pumpAndSettle();
      expect(find.text('Departments unavailable'), findsOneWidget);
      expect(find.text('General OPD'), findsNothing);
      await tester.tap(find.text('Activity log'));
      await tester.pumpAndSettle();
      expect(find.text('Activity unavailable'), findsOneWidget);
      expect(find.text('No activity to show'), findsNothing);
    },
  );

  test('missing configuration is reported and denied reads clear cached activity and settings', () async {
    final store = TestStaffStore();
    final c = controller(store);
    store.emit([actor(), pendingDoctor], cached: true);
    store.activity.add(
      StaffSnapshot([
        StaffActivity('Cached decision', '', 'Admin', DateTime(2026)),
      ], fromCache: true),
    );
    await flush();
    expect(c.activityFromCache, isTrue);
    expect(c.settingsFromCache, isTrue);
    store.activity.addError(denied());
    store.hospital.addError(denied());
    await flush();
    expect(c.activity, isEmpty);
    expect(c.activityFromCache, isFalse);
    expect(c.departments, isEmpty);
    expect(c.settingsFromCache, isFalse);
    store.hospital.add(const StaffSnapshot({}, fromCache: true));
    await flush();
    expect(c.errors['Hospital settings'], contains('local cache'));
    store.hospital.add(const StaffSnapshot({}));
    await flush();
    expect(
      c.errors['Hospital settings'],
      contains('missing at hospital_settings/default'),
    );
    expect(c.settingsLoaded, isFalse);
  });
}
