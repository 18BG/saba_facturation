import '../models/billing_line.dart';
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
    if (change.field == '__deleteLine') {
      return FirestoreWrite(
        documentPath: _linePath(change.lineId),
        data: {
          'deleted': true,
          'deletedAtLocal': change.createdAt.toIso8601String(),
          'lineId': change.lineId,
          'reference': change.reference,
          'updatedAtLocal': change.createdAt.toIso8601String(),
        },
      );
    }

    if (change.field == '__lineSnapshot') {
      return FirestoreWrite(
        documentPath: _linePath(change.lineId),
        data: {
          ..._lineSnapshotData(change.value),
          'deleted': false,
          'lineId': change.lineId,
          'reference': change.reference,
          'updatedAtLocal': change.createdAt.toIso8601String(),
        },
      );
    }

    return FirestoreWrite(
      documentPath: _linePath(change.lineId),
      data: {
        change.field: change.value,
        'deleted': false,
        'lineId': change.lineId,
        'reference': change.reference,
        'updatedAtLocal': change.createdAt.toIso8601String(),
      },
    );
  }

  FirestoreWrite _annualWrite(PendingChange change) {
    if (change.field == '__annualSnapshot') {
      return FirestoreWrite(
        documentPath: _annualPath(change),
        data: {
          ..._annualSnapshotData(change.value),
          'annee': change.year,
          'lineId': change.lineId,
          'reference': change.reference,
          'updatedAtLocal': change.createdAt.toIso8601String(),
        },
      );
    }

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

  Map<String, Object?> _lineSnapshotData(Object? value) {
    final raw = value is Map ? value : const <Object?, Object?>{};
    return {
      'reference': raw['reference'],
      'name': raw['name'],
      'activity': raw['activity'],
      'startDate': raw['startDate'],
      'endDate': raw['endDate'],
      'contractNature': raw['contractNature'],
      'billedStaff': raw['billedStaff'],
      'paidStaff': raw['paidStaff'],
      'status': raw['status'],
      'statusComment': raw['statusComment'],
    };
  }

  Map<String, Object?> _annualSnapshotData(Object? value) {
    final raw = value is Map ? value : const <Object?, Object?>{};
    final rawPayments = raw['payments'];
    final payments = rawPayments is Map
        ? rawPayments
        : const <Object?, Object?>{};
    return {
      'monthlyRate': raw['monthlyRate'],
      'paiements': {for (final month in months) month: payments[month] ?? 0},
    };
  }
}
