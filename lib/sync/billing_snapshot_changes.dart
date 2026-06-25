import '../models/billing_line.dart';
import 'pending_change.dart';

List<PendingChange> buildBillingLineSnapshotChanges(
  Iterable<BillingLine> lines, {
  required int year,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.now();
  final changes = <PendingChange>[];

  for (final line in lines) {
    final reference = line.reference.trim();
    changes.add(
      PendingChange(
        id: '${now.microsecondsSinceEpoch}_${line.id}_lineSnapshot',
        lineId: line.id,
        reference: reference,
        scope: ChangeScope.line,
        field: '__lineSnapshot',
        value: line.toJson(),
        createdAt: now,
      ),
    );

    changes.add(
      PendingChange(
        id: '${now.microsecondsSinceEpoch}_${line.id}_${year}_annualSnapshot',
        lineId: line.id,
        reference: reference,
        scope: ChangeScope.annualBilling,
        field: '__annualSnapshot',
        value: line.annualBilling(year).toJson(),
        year: year,
        createdAt: now,
      ),
    );
  }

  return changes;
}
