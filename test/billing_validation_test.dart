import 'package:facturation_app/models/billing_line.dart';
import 'package:facturation_app/validation/billing_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts blocking validation issues and soft warnings', () {
    final summary = validateBillingLines([
      _line(reference: '', name: ''),
      _line(reference: 'REF-001', name: 'Client A'),
      _line(reference: 'REF-001', name: 'Client B'),
      _line(reference: 'REF-002', name: 'Client C', status: 'Autre'),
    ], year: 2026);

    expect(summary.missingReferences, 1);
    expect(summary.duplicateReferences, 2);
    expect(summary.missingNames, 1);
    expect(summary.autreWithoutComment, 1);
    expect(summary.zeroBilledStaff, 4);
    expect(summary.zeroMonthlyRate, 4);
    expect(summary.blockingCount, 5);
    expect(summary.warningCount, 8);
  });

  test('line issues include required comment for Autre status', () {
    final issues = billingLineIssues(
      _line(reference: '', name: '', status: 'Autre'),
      year: 2026,
    );

    expect(issues, contains('Reference comptable manquante.'));
    expect(issues, contains('Nom / site manquant.'));
    expect(issues, contains('Statut Autre : commentaire requis.'));
  });
}

BillingLine _line({
  required String reference,
  required String name,
  String status = 'Actif',
}) {
  return BillingLine(
    reference: reference,
    name: name,
    activity: 'GARDIENNAGE',
    startDate: '',
    endDate: '',
    contractNature: '',
    billedStaff: 0,
    paidStaff: 0,
    annualBillings: {2026: AnnualBillingData.empty()},
    status: status,
    statusComment: '',
    syncState: SyncState.synced,
  );
}
