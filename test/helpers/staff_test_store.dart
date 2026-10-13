import 'dart:async';

import 'package:opd_connect/staff/staff_models.dart';
import 'package:opd_connect/staff/staff_store.dart';

/// Simulates stream metadata, denied reads and failed or delayed batch commits.
/// This does not claim to validate deployed Firebase rules.
class TestStaffStore implements StaffStore {
  final records =
      StreamController<StaffSnapshot<List<StaffRecord>>>.broadcast();
  @override
  Stream<StaffSnapshot<List<StaffRecord>>> watchRecords() => records.stream;
  @override
  Future<void> writeRecord(
    StaffRecord record,
    Map<String, dynamic> audit, {
    bool delete = false,
  }) => _commit({'id': record.id, ...record.toMap(), 'delete': delete}, audit);
  final actor = StreamController<StaffSnapshot<StaffAccount?>>.broadcast();
  String? _actorId;
  final accounts =
      StreamController<StaffSnapshot<List<StaffAccount>>>.broadcast();
  final activity =
      StreamController<StaffSnapshot<List<StaffActivity>>>.broadcast();
  final hospital =
      StreamController<StaffSnapshot<Map<String, dynamic>>>.broadcast();
  Object? writeError;
  Completer<void>? pendingWrite;
  int writeAttempts = 0;
  final List<Map<String, dynamic>> commits = [];

  @override
  Stream<StaffSnapshot<StaffAccount?>> watchActor(String uid) {
    _actorId = uid;
    return actor.stream;
  }

  @override
  Stream<StaffSnapshot<List<StaffAccount>>> watchAccounts() => accounts.stream;
  @override
  Stream<StaffSnapshot<List<StaffActivity>>> watchActivity() => activity.stream;
  @override
  Stream<StaffSnapshot<Map<String, dynamic>>> watchHospital() =>
      hospital.stream;

  void emit(List<StaffAccount> records, {bool cached = false}) {
    this.records.add(StaffSnapshot(const [], fromCache: cached));
    // Account-query cache metadata is independent of the own-profile stream.
    actor.add(
      StaffSnapshot(records.where((a) => a.id == _actorId).firstOrNull),
    );
    accounts.add(StaffSnapshot(records, fromCache: cached));
    activity.add(const StaffSnapshot([]));
    hospital.add(
      StaffSnapshot({
        'name': 'Test Hospital',
        'address': 'Colombo 10',
        'phone': '+94 11 269 1111',
        'departments': [
          const Department('general', 'General OPD', 'Block A').toMap(),
        ],
      }, fromCache: cached),
    );
  }

  Future<void> _commit(
    Map<String, dynamic> data,
    Map<String, dynamic> audit,
  ) async {
    writeAttempts++;
    if (pendingWrite != null) await pendingWrite!.future;
    if (writeError != null) throw writeError!;
    commits.add({'data': data, 'audit': audit});
  }

  @override
  Future<void> writeAccount(
    String id,
    Map<String, dynamic> changes,
    Map<String, dynamic> audit,
  ) => _commit({'id': id, ...changes}, audit);
  @override
  Future<void> writeHospital(
    Map<String, dynamic> data,
    Map<String, dynamic> audit,
  ) => _commit(data, audit);

  Future<void> close() async {
    await records.close();
    await actor.close();
    await accounts.close();
    await activity.close();
    await hospital.close();
  }
}
