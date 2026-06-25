import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/billing_line.dart';
import 'firestore_change_mapper.dart';
import 'firestore_line_mapper.dart';
import 'pending_change.dart';

abstract class RemoteSyncClient {
  bool get isConfigured;

  Future<void> pushChange(PendingChange change);

  Future<List<BillingLine>> fetchBillingLines();

  Future<void> clearRemoteData();
}

class FirebaseNotConfiguredSyncClient implements RemoteSyncClient {
  const FirebaseNotConfiguredSyncClient({
    this.mapper = const FirestoreChangeMapper(),
  });

  final FirestoreChangeMapper mapper;

  @override
  bool get isConfigured => false;

  @override
  Future<void> pushChange(PendingChange change) async {
    if (_isLegacyReferenceOnlyChange(change)) return;

    final write = mapper.map(change);
    throw FirebaseNotConfiguredException(write);
  }

  @override
  Future<List<BillingLine>> fetchBillingLines() async {
    return const <BillingLine>[];
  }

  @override
  Future<void> clearRemoteData() async {
    throw const FirebaseNotConfiguredException(
      FirestoreWrite(documentPath: 'facturationLines', data: {}),
    );
  }

  bool _isLegacyReferenceOnlyChange(PendingChange change) {
    return change.lineId.trim().isEmpty &&
        change.scope == ChangeScope.line &&
        change.field == 'reference';
  }
}

class FirestoreRemoteSyncClient implements RemoteSyncClient {
  FirestoreRemoteSyncClient({
    FirebaseFirestore? firestore,
    this.mapper = const FirestoreChangeMapper(),
    this.lineMapper = const FirestoreLineMapper(),
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final FirestoreChangeMapper mapper;
  final FirestoreLineMapper lineMapper;

  @override
  bool get isConfigured => true;

  @override
  Future<void> pushChange(PendingChange change) async {
    if (_isLegacyReferenceOnlyChange(change)) return;

    final write = mapper.map(change);
    final data = {
      ...write.data,
      'updatedAtServer': FieldValue.serverTimestamp(),
    };
    await _firestore
        .doc(write.documentPath)
        .set(data, SetOptions(merge: write.merge));
  }

  @override
  Future<List<BillingLine>> fetchBillingLines() async {
    final snapshot = await _firestore.collection('facturationLines').get();
    final lines = await Future.wait(
      snapshot.docs.map((document) async {
        if (lineMapper.isDeleted(document.data())) {
          return null;
        }

        final annualSnapshot = await document.reference
            .collection('annees')
            .get();

        return lineMapper.fromRemote(
          documentId: document.id,
          lineData: document.data(),
          annualDocuments: [
            for (final annualDocument in annualSnapshot.docs)
              RemoteAnnualBillingDocument(
                documentId: annualDocument.id,
                data: annualDocument.data(),
              ),
          ],
        );
      }),
    );

    final visibleLines = [for (final line in lines) ?line];

    visibleLines.sort((a, b) {
      final byName = a.name.compareTo(b.name);
      if (byName != 0) return byName;
      return a.reference.compareTo(b.reference);
    });
    return visibleLines;
  }

  @override
  Future<void> clearRemoteData() async {
    final snapshot = await _firestore.collection('facturationLines').get();
    var batch = _firestore.batch();
    var pendingWrites = 0;

    Future<void> queueDelete(
      DocumentReference<Map<String, dynamic>> ref,
    ) async {
      batch.delete(ref);
      pendingWrites++;
      if (pendingWrites >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        pendingWrites = 0;
      }
    }

    for (final document in snapshot.docs) {
      final annualSnapshot = await document.reference
          .collection('annees')
          .get();
      for (final annualDocument in annualSnapshot.docs) {
        await queueDelete(annualDocument.reference);
      }
      await queueDelete(document.reference);
    }

    if (pendingWrites > 0) {
      await batch.commit();
    }
  }

  bool _isLegacyReferenceOnlyChange(PendingChange change) {
    return change.lineId.trim().isEmpty &&
        change.scope == ChangeScope.line &&
        change.field == 'reference';
  }
}

class FirebaseNotConfiguredException implements Exception {
  const FirebaseNotConfiguredException(this.write);

  final FirestoreWrite write;

  @override
  String toString() {
    return 'Base distante non configuree pour ${write.documentPath}';
  }
}
