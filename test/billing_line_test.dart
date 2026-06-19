import 'package:facturation_app/models/billing_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computes yearly totals from the selected annual billing data', () {
    final line = BillingLine(
      reference: 'FAC-1',
      name: 'Client',
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 2,
      paidStaff: 2,
      annualBillings: {
        2025: AnnualBillingData(
          monthlyRate: 1000,
          payments: {for (final month in months) month: 2000},
        ),
        2026: AnnualBillingData(
          monthlyRate: 1500,
          payments: {for (final month in months) month: month == 'Jan' ? 3000 : 0},
        ),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.synced,
    );

    expect(line.expectedYearAmount(2025), 24000);
    expect(line.paidTotal(2025), 24000);
    expect(line.balance(2025), 0);

    expect(line.expectedYearAmount(2026), 36000);
    expect(line.paidTotal(2026), 3000);
    expect(line.balance(2026), 33000);
  });

  test('round-trips billing lines through json', () {
    final line = BillingLine(
      reference: 'FAC-JSON',
      name: 'Client JSON',
      activity: 'NETTOYAGE',
      startDate: '2026-01-01',
      endDate: '',
      contractNature: 'CDD',
      billedStaff: 3,
      paidStaff: 4,
      annualBillings: {
        2026: AnnualBillingData(
          monthlyRate: 25000,
          payments: {for (final month in months) month: month == 'Jan' ? 75000 : 0},
        ),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.dirty,
    );

    final restored = BillingLine.fromJson(line.toJson());

    expect(restored.reference, line.reference);
    expect(restored.name, line.name);
    expect(restored.annualBilling(2026).monthlyRate, 25000);
    expect(restored.paidTotal(2026), 75000);
    expect(restored.syncState, SyncState.dirty);
  });

  test('computes balance only through the last closed month for current year', () {
    final line = BillingLine(
      reference: 'FAC-CURRENT',
      name: 'Client courant',
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 1,
      paidStaff: 1,
      annualBillings: {
        2026: AnnualBillingData(
          monthlyRate: 100000,
          payments: {for (final month in months) month: 0},
        ),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.synced,
    );

    final asOfMarch = DateTime(2026, 3, 15);

    expect(line.billingMonthsDue(2026, asOf: asOfMarch), 2);
    expect(line.expectedDueAmount(2026, asOf: asOfMarch), 200000);
    expect(line.paidTotalDue(2026, asOf: asOfMarch), 0);
    expect(line.balanceDue(2026, asOf: asOfMarch), 200000);
    expect(line.expectedYearAmount(2026), 1200000);
  });

  test('does not include current unfinished month in due balance', () {
    final line = BillingLine(
      reference: 'FAC-JUNE',
      name: 'Client juin',
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 1,
      paidStaff: 1,
      annualBillings: {
        2026: AnnualBillingData(
          monthlyRate: 100000,
          payments: {for (final month in months) month: 0},
        ),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.synced,
    );

    final june19 = DateTime(2026, 6, 19);

    expect(line.billingMonthsDue(2026, asOf: june19), 5);
    expect(line.expectedDueAmount(2026, asOf: june19), 500000);
    expect(line.balanceDue(2026, asOf: june19), 500000);
  });
}
