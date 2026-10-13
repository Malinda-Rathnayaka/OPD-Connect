import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opd_connect/staff/staff_controller.dart';
import 'package:opd_connect/staff/staff_models.dart';
import 'package:opd_connect/staff/staff_workspace.dart';

import 'helpers/staff_test_store.dart';

StaffAccount admin({
  String? role = 'Hospital administrator',
  bool active = true,
  bool verified = true,
}) => StaffAccount.fromMap('admin-uid', {
  'name': 'Hospital Admin',
  'role': 'admin',
  'isActive': active,
  'isVerified': verified,
  'staffRole': ?role,
});

StaffAccount get doctor => StaffAccount.fromMap('doctor-uid', {
  'name': 'Pending Doctor',
  'role': 'doctor',
  'isActive': true,
  'isApproved': false,
  'isVerified': false,
  'registrationNumber': 'SLMC-1234',
});

void main() {
  for (final role in ['Super administrator', 'Hospital administrator']) {
    test(
      '$role can save a validated decision with reviewer identity',
      () async {
        final store = TestStaffStore();
        final c = StaffController(
          actorId: 'admin-uid',
          actorName: 'Hospital Admin',
          store: store,
        );
        addTearDown(c.dispose);
        addTearDown(store.close);
        store.emit([admin(role: role), doctor]);
        await Future<void>.delayed(Duration.zero);
        expect(c.canReview, isTrue);
        for (final checks in [
          [false, false],
          [false, true],
          [true, false],
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
        await expectLater(
          c.review(doctor, approve: false, reason: '   '),
          throwsStateError,
        );
        expect(store.writeAttempts, 0);
        await c.review(
          doctor,
          approve: true,
          identityChecked: true,
          credentialsChecked: true,
        );
        final approved = store.commits.single;
        expect(approved['data']['reviewedBy'], 'admin-uid');
        expect(approved['data']['identityChecked'], isTrue);
        expect(approved['data']['credentialsChecked'], isTrue);
        expect(approved['audit']['actorId'], 'admin-uid');
        expect(approved['audit']['actor'], 'Hospital Admin');
        const secondDoctor = StaffAccount(
          id: 'second-doctor',
          name: 'Another Pending Doctor',
          email: '',
          role: 'doctor',
          approved: false,
          verified: false,
        );
        store.emit([
          admin(role: role),
          doctor.withChanges({'isApproved': true, 'isVerified': true}),
          secondDoctor,
        ]);
        await Future<void>.delayed(Duration.zero);
        await expectLater(
          c.review(
            doctor,
            approve: false,
            reason: 'A stale decision must not replace approval',
          ),
          throwsStateError,
        );
        await c.review(
          secondDoctor,
          approve: false,
          reason: '  Credentials could not be confirmed  ',
        );
        expect(
          store.commits.last['data']['reviewReason'],
          'Credentials could not be confirmed',
        );
        expect(store.commits.last['data']['isApproved'], isFalse);
        expect(
          store.commits.last['audit']['title'],
          'Doctor registration rejected',
        );
      },
    );
  }

  test(
    'missing, unknown, support, inactive and unverified roles cannot review',
    () async {
      final store = TestStaffStore();
      final c = StaffController(
        actorId: 'admin-uid',
        actorName: 'Hospital Admin',
        store: store,
      );
      addTearDown(c.dispose);
      addTearDown(store.close);
      for (final actor in [
        admin(role: null),
        admin(role: 'admin'),
        admin(role: 'Support coordinator'),
        admin(active: false),
        admin(verified: false),
        const StaffAccount(
          id: 'admin-uid',
          name: 'Patient',
          email: '',
          role: 'patient',
          staffRole: 'Super administrator',
        ),
      ]) {
        store.emit([actor, doctor]);
        await Future<void>.delayed(Duration.zero);
        expect(c.canReview, isFalse);
        expect(c.reviewUnavailableReason, isNotEmpty);
        await expectLater(
          c.review(
            doctor,
            approve: true,
            identityChecked: true,
            credentialsChecked: true,
          ),
          throwsStateError,
        );
      }
      expect(store.writeAttempts, 0);
    },
  );

  testWidgets(
    'cached then denied query clears records and recovers after authorized retry',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = TestStaffStore();
      final c = StaffController(
        actorId: 'admin-uid',
        actorName: 'Hospital Admin',
        store: store,
      );
      addTearDown(c.dispose);
      addTearDown(store.close);
      await tester.pumpWidget(
        MaterialApp(home: HospitalStaffWorkspace(controller: c)),
      );
      store.emit([admin(), doctor], cached: true);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verifications'));
      await tester.pumpAndSettle();
      final review = find.widgetWithText(FilledButton, 'Review registration');
      expect(tester.widget<FilledButton>(review).onPressed, isNull);
      expect(
        find.textContaining('Showing cached account data'),
        findsOneWidget,
      );
      store.accounts.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await tester.pumpAndSettle();
      expect(c.connectionLabel, 'Access denied');
      expect(c.accounts, isEmpty);
      expect(find.textContaining('do not have access'), findsOneWidget);
      expect(find.textContaining('Showing cached account data'), findsNothing);
      expect(find.text('Review queue unavailable'), findsOneWidget);
      expect(find.text('You’re all caught up'), findsNothing);
      c.connect();
      store.emit([admin(), doctor]);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(review).onPressed, isNotNull);
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(find.text('SLMC-1234'), findsOneWidget);
      await tester.tap(find.byType(CheckboxListTile).first);
      await tester.tap(find.byType(CheckboxListTile).last);
      await tester.pumpAndSettle();
      final approve = find.widgetWithText(FilledButton, 'Approve doctor');
      final reject = find.widgetWithText(OutlinedButton, 'Reject');
      expect(tester.widget<FilledButton>(approve).onPressed, isNotNull);
      store.emit([admin(), doctor], cached: true);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(approve).onPressed, isNull);
      expect(tester.widget<OutlinedButton>(reject).onPressed, isNull);
      store.emit([admin(role: 'Support coordinator'), doctor]);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(approve).onPressed, isNull);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.textContaining('Doctor reviews require'),
        ),
        findsOneWidget,
      );
      expect(store.writeAttempts, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test('a real unavailable Firebase request preserves records but blocks decisions', () async {
    final store = TestStaffStore();
    final c = StaffController(
      actorId: 'admin-uid',
      actorName: 'Hospital Admin',
      store: store,
    );
    addTearDown(c.dispose);
    addTearDown(store.close);
    store.emit([admin(), doctor]);
    await Future<void>.delayed(Duration.zero);
    store.accounts.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(c.pending.single.id, 'doctor-uid');
    expect(c.canReview, isFalse);
    expect(c.reviewUnavailableReason, contains('Firebase is unavailable'));
    await expectLater(
      c.review(doctor, approve: false, reason: 'Credentials not confirmed'),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('unavailable'),
        ),
      ),
    );
    expect(store.writeAttempts, 0);
  });
}
