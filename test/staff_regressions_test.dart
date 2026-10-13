import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opd_connect/staff/staff_controller.dart';
import 'package:opd_connect/staff/staff_dialogs.dart';
import 'package:opd_connect/staff/staff_workspace.dart';
import 'package:opd_connect/staff/staff_store.dart';

import 'helpers/staff_test_store.dart';

StaffController preview({String actor = 'preview-admin'}) => StaffController(
  preview: true,
  actorId: actor,
  actorName: 'Ayesha Fernando',
);

Future<void> flush() => Future<void>.delayed(Duration.zero);

void viewport(WidgetTester tester, [double width = 1440]) {
  tester.view.physicalSize = Size(width, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  test(
    'controller approval requires both checks and rejects stale decisions',
    () async {
      final c = preview();
      addTearDown(c.dispose);
      final doctor = c.pending.first;
      for (final checks in [
        [false, false],
        [true, false],
        [false, true],
      ]) {
        await expectLater(
          c.review(
            doctor,
            approve: true,
            identityChecked: checks[0],
            credentialsChecked: checks[1],
          ),
          throwsStateError,
        );
      }
      expect(c.pending.length, 2);
      await c.review(
        doctor,
        approve: true,
        identityChecked: true,
        credentialsChecked: true,
      );
      final activityCount = c.activity.length;
      await expectLater(
        c.review(
          doctor,
          approve: false,
          reason: 'A stale decision must not replace approval',
        ),
        throwsStateError,
      );
      expect(c.activity.length, activityCount);
      await expectLater(
        c.updateAccount(
          c.pending.first,
          {'isApproved': true},
          'Bypass',
          'Bypass',
        ),
        throwsStateError,
      );
    },
  );

  test('role changes, account edits and status changes respect the permission matrix', () async {
    final owner = preview(),
        admin = preview(actor: 'staff-2'),
        support = preview(actor: 'staff-3');
    addTearDown(owner.dispose);
    addTearDown(admin.dispose);
    addTearDown(support.dispose);
    final patient = owner.accounts.firstWhere((a) => a.role == 'patient');
    await expectLater(
      support.updateAccount(patient, {'name': 'Changed'}, 'Edit', patient.name),
      throwsStateError,
    );
    await expectLater(
      support.saveHospital(
        'Hospital',
        'Colombo 10',
        '+94 11 269 1111',
        support.departments,
      ),
      throwsStateError,
    );
    expect(() => support.acknowledge(support.alerts.first), throwsStateError);
    expect(
      () => admin.invitePreviewStaff(
        'New Person',
        'new@example.com',
        'Support coordinator',
      ),
      throwsStateError,
    );
    await expectLater(
      admin.updateAccount(
        admin.staff.first,
        {'staffRole': 'Support coordinator'},
        'Role',
        'Changed role',
      ),
      throwsStateError,
    );
    await owner.updateAccount(
      owner.staff[1],
      {'staffRole': 'Support coordinator'},
      'Staff role updated',
      'Ruwan: Support coordinator',
    );
    expect(owner.staff[1].staffRole, 'Support coordinator');
    await admin.updateAccount(
      patient,
      {'name': 'Updated Patient', 'phone': '+94 77 123 4567'},
      'Account details updated',
      patient.name,
    );
    expect(
      admin.accounts.firstWhere((a) => a.id == patient.id).name,
      'Updated Patient',
    );
    await expectLater(
      admin.setActive(patient, active: false, reason: 'No'),
      throwsStateError,
    );
    await admin.setActive(
      patient,
      active: false,
      reason: 'Duplicate registration',
    );
    await expectLater(
      admin.setActive(patient, active: false, reason: 'Duplicate registration'),
      throwsStateError,
    );
    expect(admin.activity.first.detail, contains('Duplicate registration'));
  });

  test(
    'prepared invitations are inactive examples and cannot be activated',
    () async {
      final c = preview();
      addTearDown(c.dispose);
      c.invitePreviewStaff(
        'New Coordinator',
        'new@example.com',
        'Support coordinator',
      );
      final invited = c.accounts.last;
      expect(invited.active, isFalse);
      expect(c.activity.first.detail, contains('no email sent'));
      expect(
        () => c.invitePreviewStaff(
          'Duplicate',
          'NEW@example.com',
          'Support coordinator',
        ),
        throwsStateError,
      );
      await expectLater(
        c.setActive(
          invited,
          active: true,
          reason: 'Activate example invitation',
        ),
        throwsStateError,
      );
    },
  );

  test('cached or denied live reads block writes and never substitute demo records', () async {
    final store = TestStaffStore();
    final seed = preview();
    final records = [...seed.accounts];
    seed.dispose();
    final c = StaffController(
      actorId: 'preview-admin',
      actorName: 'Admin',
      store: store,
    );
    addTearDown(c.dispose);
    addTearDown(store.close);
    expect(c.connectionLabel, 'Connecting');
    expect(c.accounts, isEmpty);
    store.emit(records, cached: true);
    await flush();
    expect(c.connectionLabel, 'Offline / cached data');
    expect(c.canWrite, isFalse);
    await expectLater(
      c.saveHospital(
        'Hospital',
        'Colombo 10',
        '+94 11 269 1111',
        c.departments,
      ),
      throwsStateError,
    );
    expect(store.writeAttempts, 0);
    store.emit(records);
    await flush();
    expect(c.canWrite, isTrue);
    store.accounts.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await flush();
    expect(c.errors['Accounts'], contains('do not have access'));
    expect(c.canWrite, isFalse);
    await expectLater(
      c.saveHospital(
        'Hospital',
        'Colombo 10',
        '+94 11 269 1111',
        c.departments,
      ),
      throwsStateError,
    );
    store.activity.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    store.hospital.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await flush();
    expect(
      c.errors.keys,
      containsAll(['Accounts', 'Activity', 'Hospital settings']),
    );
    c.connect();
    expect(c.canWrite, isFalse);
    store.emit(records);
    await flush();
    expect(c.errors, isEmpty);
    store.hospital.add(
      const StaffSnapshot({
        'departments': ['bad record'],
      }),
    );
    await flush();
    expect(c.canEditHospital, isFalse);
    expect(c.errors['Hospital settings'], contains('invalid data'));
    for (final failure in {
      'unauthenticated': 'session has expired',
      'failed-precondition': 'configuration needs attention',
    }.entries) {
      store.accounts.addError(
        FirebaseException(plugin: 'cloud_firestore', code: failure.key),
      );
      await flush();
      expect(c.errors['Accounts'], contains(failure.value));
      expect(c.canWrite, isFalse);
    }
  });

  test('denied live writes preserve data and successful requests include audit decisions', () async {
    final store = TestStaffStore();
    final seed = preview();
    final records = [...seed.accounts];
    seed.dispose();
    final c = StaffController(
      actorId: 'preview-admin',
      actorName: 'Admin',
      store: store,
    );
    addTearDown(c.dispose);
    addTearDown(store.close);
    store.emit(records);
    await flush();
    store.writeError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    final doctor = c.pending.first;
    await expectLater(
      c.review(
        doctor,
        approve: false,
        reason: 'Credentials cannot be confirmed',
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('do not have access'),
        ),
      ),
    );
    expect(c.pending.length, 2);
    expect(c.activity, isEmpty);
    expect(c.busy, isFalse);
    expect(store.commits, isEmpty);
    await expectLater(
      c.saveHospital(
        'Updated Hospital',
        'Colombo 10',
        '+94 11 269 1111',
        c.departments,
      ),
      throwsStateError,
    );
    expect(c.hospitalName, 'Test Hospital');
    expect(c.busy, isFalse);
    store.writeError = null;
    await c.review(
      doctor,
      approve: false,
      reason: 'Credentials cannot be confirmed',
    );
    final request = store.commits.single;
    expect(request['data']['approvalStatus'], 'rejected');
    expect(request['data']['reviewedBy'], c.actorId);
    expect(
      request['audit']['detail'],
      contains('Credentials cannot be confirmed'),
    );
    expect(request['audit']['actorId'], c.actorId);
  });

  testWidgets(
    'hospital save freezes inputs and navigation; a denied save retains the draft',
    (tester) async {
      viewport(tester);
      final store = TestStaffStore();
      final seed = preview();
      final records = [...seed.accounts];
      seed.dispose();
      final c = StaffController(
        actorId: 'preview-admin',
        actorName: 'Admin',
        store: store,
      );
      addTearDown(c.dispose);
      addTearDown(store.close);
      store.emit(records);
      await tester.pumpWidget(
        MaterialApp(home: HospitalStaffWorkspace(controller: c)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hospital setup'));
      await tester.pumpAndSettle();
      // Server refreshes do not create unsaved drafts.
      store.emit(records);
      await tester.pumpAndSettle();
      expect(find.text('You have unsaved changes.'), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Unsaved Hospital',
      );
      await tester.pumpAndSettle();
      store.pendingWrite = Completer<void>();
      store.writeError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      final save = find.widgetWithText(FilledButton, 'Save changes');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).first).readOnly,
        isTrue,
      );
      await tester.tap(find.text('User accounts'));
      await tester.pump();
      expect(find.text('Hospital details'), findsOneWidget);
      expect(find.text('Account directory'), findsNothing);
      store.pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('do not have access'), findsOneWidget);
      expect(find.text('Unsaved Hospital'), findsOneWidget);
      expect(find.text('You have unsaved changes.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving preview protects hospital drafts', (tester) async {
    viewport(tester);
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HospitalStaffWorkspace(preview: true, onSignOut: () => exits++),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hospital setup'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Unsaved Hospital',
    );
    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave preview'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(exits, 0);
    await tester.tap(find.byTooltip('Your account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave preview'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard changes'));
    await tester.pumpAndSettle();
    expect(exits, 1);
  });

  for (final width in [320.0, 800.0, 1440.0]) {
    testWidgets(
      'doctor rejection dialog at $width validates and records the reason',
      (tester) async {
        viewport(tester, width);
        final c = preview();
        addTearDown(c.dispose);
        final doctor = c.pending.first;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AccountDialog(
                      controller: c,
                      account: doctor,
                      mode: AccountDialogMode.review,
                    ),
                  ),
                  child: const Text('Open review'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open review'));
        await tester.pumpAndSettle();
        final reject = find.widgetWithText(OutlinedButton, 'Reject');
        await tester.ensureVisible(reject);
        await tester.tap(reject);
        await tester.pumpAndSettle();
        final submit = find.widgetWithText(FilledButton, 'Reject registration');
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(c.pending.length, 2);
        await tester.enterText(
          find.byType(TextFormField).last,
          'Medical registration cannot be confirmed',
        );
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(c.pending.length, 1);
        expect(c.activity.first.title, 'Doctor registration rejected');
        expect(
          c.accounts.firstWhere((a) => a.id == doctor.id).reviewNote,
          contains('cannot be confirmed'),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'account profile edits and hospital department edits save and appear in activity',
    (tester) async {
      viewport(tester);
      final c = preview();
      addTearDown(c.dispose);
      final patient = c.accounts.firstWhere((a) => a.role == 'patient');
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AccountDialog(
                    controller: c,
                    account: patient,
                    mode: AccountDialogMode.edit,
                  ),
                ),
                child: const Text('Edit patient'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit patient'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Updated Patient',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();
      expect(
        c.accounts.firstWhere((a) => a.id == patient.id).name,
        'Updated Patient',
      );
      expect(c.activity.first.title, 'Account details updated');
      await tester.pumpWidget(
        MaterialApp(home: HospitalStaffWorkspace(controller: c)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hospital setup'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit General OPD'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'Block Z');
      await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Save changes');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(c.departments.first.location, 'Block Z');
      expect(c.activity.first.title, 'Hospital information updated');
      await tester.tap(find.text('Activity log'));
      await tester.pumpAndSettle();
      expect(find.text('Hospital information updated'), findsOneWidget);
      expect(find.text('Account details updated'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
