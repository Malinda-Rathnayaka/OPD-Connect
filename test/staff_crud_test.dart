import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opd_connect/staff/staff_controller.dart';
import 'package:opd_connect/staff/staff_models.dart';
import 'package:opd_connect/staff/staff_records_panel.dart';
import 'package:opd_connect/staff/staff_store.dart';

import 'helpers/staff_test_store.dart';

StaffController preview() => StaffController(
  preview: true,
  actorId: 'preview-admin',
  actorName: 'Ayesha Fernando',
);
StaffRecord record(
  StaffRecordType type, {
  int revision = 0,
  String title = 'New record',
}) => StaffRecord(
  id: 'new-record',
  type: type,
  title: title,
  detail: 'Useful details',
  category: type == StaffRecordType.directory ? 'Reception' : 'All staff',
  contact: type == StaffRecordType.directory ? '011 269 2222' : '',
  revision: revision,
);

void main() {
  for (final type in StaffRecordType.values) {
    test(
      '${type.name} creates, updates and deletes with an audit; stale changes fail',
      () async {
        final c = preview();
        addTearDown(c.dispose);
        await c.saveRecord(record(type));
        expect(c.records.last.revision, 1);
        await c.saveRecord(record(type, revision: 1, title: 'Updated record'));
        expect(c.records.last.title, 'Updated record');
        expect(c.records.last.revision, 2);
        await expectLater(
          c.saveRecord(record(type, revision: 1)),
          throwsStateError,
        );
        await expectLater(
          c.saveRecord(record(type, revision: 1), delete: true),
          throwsStateError,
        );
        await c.saveRecord(c.records.last, delete: true);
        expect(c.records.any((r) => r.id == 'new-record'), isFalse);
        expect(c.activity.take(3).map((a) => a.title.split(' ').last), [
          'deleted',
          'updated',
          'created',
        ]);
      },
    );

    for (final width in [320.0, 1440.0]) {
      testWidgets(
        '${type.name} UI create, view, search, edit, cancel and delete at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final c = preview();
          addTearDown(c.dispose);
          await tester.pumpWidget(
            MaterialApp(
              theme: StaffStyle.theme(),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StaffRecordsPanel(controller: c, type: type),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(
              type == StaffRecordType.directory
                  ? 'Add staff contact'
                  : 'Add notice',
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Enter '), findsWidgets);
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'New record');
          await tester.enterText(fields.at(1), 'Useful details');
          if (type == StaffRecordType.directory) {
            await tester.enterText(fields.at(2), 'Reception');
            await tester.enterText(fields.at(3), '011 269 2222');
          }
          await tester.ensureVisible(find.text('Save'));
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(find.byType(StaffRecordDialog), findsNothing);
          final search = find.byType(TextField).first;
          await tester.enterText(search, 'New record');
          await tester.pumpAndSettle();
          await tester.tap(find.text('View'));
          await tester.pumpAndSettle();
          expect(find.text('Useful details'), findsWidgets);
          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Edit'));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextFormField).first,
            'Updated record',
          );
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();
          expect(find.text('No matching records'), findsOneWidget);
          await tester.enterText(search, 'Updated record');
          await tester.pumpAndSettle();
          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          expect(c.records.any((r) => r.title == 'Updated record'), isTrue);
          await tester.tap(find.text('Delete'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
          await tester.pumpAndSettle();
          expect(c.records.any((r) => r.title == 'Updated record'), isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test('departments support create update delete and block deleting assigned departments', () async {
    final c = preview();
    addTearDown(c.dispose);
    Future<void> save(List<Department> list) => c.saveHospital(
      c.hospitalName,
      c.hospitalAddress,
      c.hospitalPhone,
      list,
    );
    await save([
      ...c.departments,
      const Department('lab', 'Laboratory', 'Block D'),
    ]);
    expect(c.departments.last.name, 'Laboratory');
    await save([
      ...c.departments.where((d) => d.id != 'lab'),
      const Department('lab', 'Laboratory', 'Block E'),
    ]);
    expect(c.departments.last.location, 'Block E');
    await save(c.departments.where((d) => d.id != 'lab').toList());
    expect(c.departments.any((d) => d.id == 'lab'), isFalse);
    await expectLater(
      save(c.departments.where((d) => d.id != 'general').toList()),
      throwsStateError,
    );
  });

  test('read-only, cached and invalid record writes are blocked', () async {
    final c = preview();
    addTearDown(c.dispose);
    await expectLater(
      c.saveRecord(record(StaffRecordType.notice, title: ' ')),
      throwsStateError,
    );
    c.recordsFromCache = true;
    await expectLater(
      c.saveRecord(record(StaffRecordType.notice)),
      throwsStateError,
    );
    c.recordsFromCache = false;
    c.accounts = c.accounts
        .map(
          (a) => a.id == c.actorId
              ? a.withChanges({'staffRole': 'Support coordinator'})
              : a,
        )
        .toList();
    await expectLater(
      c.saveRecord(record(StaffRecordType.directory)),
      throwsStateError,
    );
  });

  test('live saves submit atomic audit data; failures retain records and release busy state', () async {
    final store = TestStaffStore();
    final seed = preview();
    addTearDown(seed.dispose);
    final c = StaffController(
      actorId: seed.actorId,
      actorName: seed.actorName,
      store: store,
    );
    addTearDown(c.dispose);
    addTearDown(store.close);
    store.emit(seed.accounts);
    await Future<void>.delayed(Duration.zero);
    await c.saveRecord(record(StaffRecordType.notice));
    expect(store.commits.single['audit']['operation'], 'created');
    expect(store.commits.single['audit']['recordType'], 'notice');
    final existing = record(StaffRecordType.notice, revision: 1);
    store.records.add(StaffSnapshot([existing]));
    await Future<void>.delayed(Duration.zero);
    store.writeError = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    await expectLater(c.saveRecord(existing, delete: true), throwsStateError);
    expect(c.records.single, existing);
    expect(c.busy, isFalse);
    store.records.addError(
      FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    );
    await Future<void>.delayed(Duration.zero);
    expect(c.records, isEmpty);
    expect(c.canEditRecords, isFalse);
  });
}
