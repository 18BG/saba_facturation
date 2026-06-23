import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_change_mapper.dart';
import 'pending_change.dart';

abstract class RemoteSyncClient {
  bool get isConfigured;

  Future<void> pushChange(PendingChange change);
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
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final FirestoreChangeMapper mapper;

  @override
  bool get isConfigured => true;

  @override
  Future<void> pushChange(PendingChange change) async {
    if (_isLegacyReferenceOnlyChange(change)) return;

    final write = mapper.map(change);
    await _firestore
        .doc(write.documentPath)
        .set(write.data, SetOptions(merge: write.merge));
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
