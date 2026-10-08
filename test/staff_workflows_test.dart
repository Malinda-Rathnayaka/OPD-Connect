import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opd_connect/staff/staff_controller.dart';
import 'package:opd_connect/staff/staff_models.dart';
import 'package:opd_connect/staff/staff_workspace.dart';

StaffController preview({String actor = 'preview-admin'}) => StaffController(
  preview: true,
  actorId: actor,
  actorName: 'Ayesha Fernando',
);

void main() {
  for (final width in [390.0, 800.0, 1440.0]) {
    testWidgets('all staff sections fit at $width pixels', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: HospitalStaffWorkspace(preview: true)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overview at $width');
      for (final section in [
        'Staff & roles',
        'Hospital setup',
        'Activity log',
        'System health',
      ]) {
        if (width < 1050) {
          await tester.tap(find.text('More'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(section).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$section at $width');
      }
    });
  }

  testWidgets('hospital edits cannot be silently discarded by navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: HospitalStaffWorkspace(preview: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hospital setup'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'An unsaved hospital',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('User accounts'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('An unsaved hospital'), findsOneWidget);
    await tester.tap(find.text('User accounts'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard changes'));
    await tester.pumpAndSettle();
    expect(find.text('Account directory'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('approval updates the queue and records the decision', () async {
    final c = preview();
    addTearDown(c.dispose);
    final doctor = c.pending.first;
    await c.review(doctor, approve: true);
    expect(c.pending.length, 1);
    expect(
      c.accounts.firstWhere((a) => a.id == doctor.id).status,
      AccountStatus.active,
    );
    expect(c.activity.first.title, 'Doctor registration approved');
  });

  test(
    'rejection needs a reason, preserves the record and survives reactivation',
    () async {
      final c = preview();
      addTearDown(c.dispose);
      final doctor = c.pending.first;
      await expectLater(
        c.review(doctor, approve: false, reason: 'No'),
        throwsStateError,
      );
      expect(c.pending.length, 2);
      await c.review(
        doctor,
        approve: false,
        reason: 'Medical registration could not be confirmed.',
      );
      var rejected = c.accounts.firstWhere((a) => a.id == doctor.id);
      expect(rejected.status, AccountStatus.rejected);
      await c.updateAccount(
        rejected,
        {'isActive': false},
        'Deactivated',
        'Test',
      );
      rejected = c.accounts.firstWhere((a) => a.id == doctor.id);
      await c.updateAccount(
        rejected,
        {
          'isActive': true,
          'reviewNote': 'Reactivated: Credentials remain unapproved',
        },
        'Reactivated',
        'Test',
      );
      expect(
        c.accounts.firstWhere((a) => a.id == doctor.id).status,
        AccountStatus.rejected,
      );
      expect(c.accounts.length, 11);
    },
  );

  test('support role cannot approve accounts and users cannot remove their own access', () async {
    final support = preview(actor: 'staff-3');
    final owner = preview();
    addTearDown(support.dispose);
    addTearDown(owner.dispose);
    await expectLater(
      support.review(support.pending.first, approve: true),
      throwsStateError,
    );
    final self = owner.accounts.firstWhere((a) => a.id == owner.actorId);
    await expectLater(
      owner.updateAccount(self, {'isActive': false}, 'Deactivate', 'Test'),
      throwsStateError,
    );
    await expectLater(
      owner.updateAccount(
        self,
        {'staffRole': 'Support coordinator'},
        'Role',
        'Test',
      ),
      throwsStateError,
    );
  });

  test('hospital updates and alert acknowledgements are recorded without touching another session', () async {
    final c = preview(), other = preview();
    addTearDown(c.dispose);
    addTearDown(other.dispose);
    await c.saveHospital('Updated Hospital', 'Colombo 10', '+94 11 269 1111', [
      ...c.departments,
      const Department('new', 'Dental clinic', 'Block D'),
    ]);
    expect(c.departments.length, 4);
    expect(other.departments.length, 3);
    c.acknowledge(c.alerts.first);
    final logCount = c.activity.length;
    c.acknowledge(c.alerts.first);
    expect(c.activity.length, logCount);
    expect(other.alerts.first.acknowledged, isFalse);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('staff workspace and account directory fit at $width pixels', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(home: HospitalStaffWorkspace(preview: true)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hospital overview'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(
        width < 1050 ? find.text('Accounts') : find.text('User accounts'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Account directory'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Kamal');
      await tester.pumpAndSettle();
      expect(find.text('Dr. Kamal Perera'), findsOneWidget);
      expect(find.text('Nimal Rathnayake'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'approval button stays disabled until both review checks are completed',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = preview();
      addTearDown(c.dispose);
      await tester.pumpWidget(
        MaterialApp(home: HospitalStaffWorkspace(controller: c)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review registration').first);
      await tester.pumpAndSettle();
      final approve = find.widgetWithText(FilledButton, 'Approve doctor');
      expect(tester.widget<FilledButton>(approve).onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(approve).onPressed, isNull);
      await tester.tap(find.byType(CheckboxListTile).last);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(approve).onPressed, isNotNull);
      await tester.tap(approve);
      await tester.pumpAndSettle();
      expect(c.pending.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
