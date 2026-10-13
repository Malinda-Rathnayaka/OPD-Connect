import 'package:cloud_firestore/cloud_firestore.dart';

import 'staff_models.dart';

/// Metadata prevents cached Firestore records from being presented as a live
/// connection. The interface also allows failure paths to be tested offline.
class StaffSnapshot<T> {
  final T data;
  final bool fromCache;
  const StaffSnapshot(this.data, {this.fromCache = false});
}

abstract interface class StaffStore {
  Stream<StaffSnapshot<List<StaffRecord>>> watchRecords();
  Future<void> writeRecord(
    StaffRecord record,
    Map<String, dynamic> audit, {
    bool delete = false,
  });
  Stream<StaffSnapshot<StaffAccount?>> watchActor(String uid);
  Stream<StaffSnapshot<List<StaffAccount>>> watchAccounts();
  Stream<StaffSnapshot<List<StaffActivity>>> watchActivity();
  Stream<StaffSnapshot<Map<String, dynamic>>> watchHospital();
  Future<void> writeAccount(
    String id,
    Map<String, dynamic> changes,
    Map<String, dynamic> audit,
  );
  Future<void> writeHospital(
    Map<String, dynamic> data,
    Map<String, dynamic> audit,
  );
}

class FirestoreStaffStore implements StaffStore {
  final FirebaseFirestore db;
  FirestoreStaffStore([FirebaseFirestore? firestore])
    : db = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<StaffSnapshot<List<StaffRecord>>> watchRecords() => db
      .collection('staff_records')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => StaffSnapshot(
          snapshot.docs
              .map((doc) => StaffRecord.fromMap(doc.id, doc.data()))
              .toList(),
          fromCache: snapshot.metadata.isFromCache,
        ),
      );

  @override
  Future<void> writeRecord(
    StaffRecord record,
    Map<String, dynamic> audit, {
    bool delete = false,
  }) async {
    final ref = db.collection('staff_records').doc(record.id);
    final auditRef = db.collection('staff_activity').doc();
    await db.runTransaction((tx) async {
      final current = await tx.get(ref);
      if ((record.revision == 0 && current.exists) ||
          (record.revision > 0 &&
              (!current.exists ||
                  current.data()!['revision'] != record.revision ||
                  current.data()!['type'] != record.type.name))) {
        throw StateError(
          'This record changed. Close the form and reopen the latest record.',
        );
      }
      if (delete) {
        if (!current.exists) {
          throw StateError('This record has already been deleted.');
        }
        tx.delete(ref);
      } else {
        tx.set(ref, record.nextRevision.toMap());
      }
      tx.set(auditRef, {...audit, 'time': FieldValue.serverTimestamp()});
    });
  }

  @override
  Stream<StaffSnapshot<StaffAccount?>> watchActor(String uid) => db
      .collection('users')
      .doc(uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => StaffSnapshot(
          snapshot.exists ? StaffAccount.fromMap(uid, snapshot.data()!) : null,
          fromCache: snapshot.metadata.isFromCache,
        ),
      );

  @override
  Stream<StaffSnapshot<List<StaffAccount>>> watchAccounts() => db
      .collection('users')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => StaffSnapshot(
          snapshot.docs
              .map((doc) => StaffAccount.fromMap(doc.id, doc.data()))
              .toList(),
          fromCache: snapshot.metadata.isFromCache,
        ),
      );

  @override
  Stream<StaffSnapshot<List<StaffActivity>>> watchActivity() => db
      .collection('staff_activity')
      .orderBy('time', descending: true)
      .limit(80)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => StaffSnapshot(
          snapshot.docs.map((doc) {
            final data = doc.data();
            return StaffActivity(
              data['title'] ?? '',
              data['detail'] ?? '',
              data['actor'] ?? '',
              (data['time'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList(),
          fromCache: snapshot.metadata.isFromCache,
        ),
      );

  @override
  Stream<StaffSnapshot<Map<String, dynamic>>> watchHospital() => db
      .collection('hospital_settings')
      .doc('default')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => StaffSnapshot(
          snapshot.data() ?? {},
          fromCache: snapshot.metadata.isFromCache,
        ),
      );

  void _audit(WriteBatch batch, Map<String, dynamic> audit) => batch.set(
    db.collection('staff_activity').doc(),
    {...audit, 'time': FieldValue.serverTimestamp()},
  );

  @override
  Future<void> writeAccount(
    String id,
    Map<String, dynamic> changes,
    Map<String, dynamic> audit,
  ) async {
    if (changes.containsKey('reviewedBy')) {
      final accountRef = db.collection('users').doc(id);
      final auditRef = db.collection('staff_activity').doc();
      // Server reads and retry semantics prevent two reviewers from replacing
      // each other's decision; transactions fail instead of queuing offline.
      await db.runTransaction((transaction) async {
        final snapshot = await transaction.get(accountRef);
        if (!snapshot.exists ||
            StaffAccount.fromMap(id, snapshot.data()!).status !=
                AccountStatus.pending) {
          throw StateError(
            'This registration is no longer waiting for review.',
          );
        }
        transaction.update(accountRef, {
          ...changes,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewActivityId': auditRef.id,
        });
        transaction.set(auditRef, {
          ...audit,
          'targetId': id,
          'decision': changes['approvalStatus'],
          'reason': changes['reviewReason'],
          'time': FieldValue.serverTimestamp(),
        });
      });
      return;
    }
    final batch = db.batch();
    batch.update(db.collection('users').doc(id), changes);
    _audit(batch, audit);
    await batch.commit();
  }

  @override
  Future<void> writeHospital(
    Map<String, dynamic> data,
    Map<String, dynamic> audit,
  ) async {
    final batch = db.batch();
    batch.set(
      db.collection('hospital_settings').doc('default'),
      data,
      SetOptions(merge: true),
    );
    _audit(batch, {
      ...audit,
      'recordType': 'hospital',
      'recordId': 'default',
      'operation': 'updated',
    });
    await batch.commit();
  }
}
