import 'pending_change.dart';

class FirestoreWrite {
  const FirestoreWrite({
    required this.documentPath,
    required this.data,
    this.merge = true,
  });

  final String documentPath;
  final Map<String, Object?> data;
  final bool merge;
}

class FirestoreChangeMapper {
  const FirestoreChangeMapper();

  FirestoreWrite map(PendingChange change) {
    return switch (change.scope) {
      ChangeScope.line => _lineWrite(change),
      ChangeScope.annualBilling => _annualWrite(change),
      ChangeScope.paymentCell => _paymentWrite(change),
    };
  }

  FirestoreWrite _lineWrite(PendingChange change) {
    return FirestoreWrite(
      documentPath: _linePath(change.lineId),
      data: {
        change.field: change.value,
        'lineId': change.lineId,
        'reference': change.reference,
        'updatedAtLocal': change.createdAt.toIso8601String(),
      },
    );
  }

  FirestoreWrite _annualWrite(PendingChange change) {
    return FirestoreWrite(
      documentPath: _annualPath(change),
      data: {
        'annee': change.year,
        'lineId': change.lineId,
        'reference': change.reference,
        change.field: change.value,
        'updatedAtLocal': change.createdAt.toIso8601String(),
      },
    );
  }

  FirestoreWrite _paymentWrite(PendingChange change) {
    return FirestoreWrite(
      documentPath: _annualPath(change),
      data: {
        'annee': change.year,
        'lineId': change.lineId,
        'reference': change.reference,
        'paiements': {change.field: change.value},
        'updatedAtLocal': change.createdAt.toIso8601String(),
      },
    );
  }

  String _annualPath(PendingChange change) {
    final year = change.year ?? DateTime.now().year;
    return '${_linePath(change.lineId)}/annees/$year';
  }

  String _linePath(String lineId) {
    final safeLineId = Uri.encodeComponent(lineId.trim());
    if (safeLineId.isEmpty) {
      throw UnsupportedError('lineId manquant pour la synchronisation.');
    }
    return 'facturationLines/$safeLineId';
  }
}
