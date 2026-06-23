import '../models/billing_line.dart';

List<BillingLine> buildSampleBillingLines() {
  final basePayments2026 = <String, double>{
    'Jan': 200000,
    'Fev': 180000,
    'Mar': 200000,
    'Avr': 200000,
    'Mai': 150000,
    'Juin': 0,
    'Juil': 0,
    'Aout': 0,
    'Sep': 0,
    'Oct': 0,
    'Nov': 0,
    'Dec': 0,
  };

  AnnualBillingData annual(double monthlyRate, Map<String, double> payments) {
    return AnnualBillingData(
      monthlyRate: monthlyRate,
      payments: {for (final month in months) month: payments[month] ?? 0},
    );
  }

  AnnualBillingData sameEveryMonth(
    double monthlyRate,
    double amount, {
    int paidMonths = 12,
  }) {
    return annual(monthlyRate, {
      for (var i = 0; i < months.length; i++)
        months[i]: i < paidMonths ? amount : 0,
    });
  }

  return [
    BillingLine(
      reference: 'FAC-2026-0001',
      name: 'AMIFA SIEGE',
      activity: 'GARDIENNAGE',
      startDate: '2021-01-01',
      endDate: '',
      contractNature: '',
      billedStaff: 4,
      paidStaff: 5,
      annualBillings: {
        2025: sameEveryMonth(45000, 180000, paidMonths: 10),
        2026: annual(50000, basePayments2026),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.synced,
    ),
    BillingLine(
      reference: 'FAC-2026-0002',
      name: 'AMIFA SIEGE',
      activity: 'NETTOYAGE',
      startDate: '2021-01-01',
      endDate: '',
      contractNature: '',
      billedStaff: 2,
      paidStaff: 2,
      annualBillings: {
        2025: sameEveryMonth(42000, 84000, paidMonths: 12),
        2026: annual(45000, {
          for (final month in months)
            month: month == 'Jan' || month == 'Fev' ? 90000 : 0,
        }),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.dirty,
    ),
    BillingLine(
      reference: 'FAC-2026-0003',
      name: 'TONINO GOLF AGENT ARME',
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: 'CDI',
      billedStaff: 3,
      paidStaff: 4,
      annualBillings: {
        2025: sameEveryMonth(70000, 210000, paidMonths: 9),
        2026: annual(75000, {
          for (final month in months) month: month == 'Jan' ? 225000 : 0,
        }),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.syncing,
    ),
    BillingLine(
      reference: 'FAC-2026-0004',
      name: 'WAVE INTERIM',
      activity: 'INTERIM',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 10,
      paidStaff: 157,
      annualBillings: {
        2025: sameEveryMonth(12000, 120000, paidMonths: 8),
        2026: AnnualBillingData.empty().copyWith(monthlyRate: 15000),
      },
      status: 'Autre',
      statusComment: 'A verifier avec RH',
      syncState: SyncState.failed,
    ),
    BillingLine(
      reference: 'FAC-2026-0005',
      name: 'CIMAF KATI EXTENTION AGENT SIMPLE',
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 2,
      paidStaff: 2,
      annualBillings: {
        2025: sameEveryMonth(55000, 110000, paidMonths: 12),
        2026: annual(60000, {
          for (final month in months) month: month == 'Jan' ? 120000 : 0,
        }),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.synced,
    ),
    BillingLine(
      reference: '',
      name: 'ZHONGFU SUPERMARCHE',
      activity: 'NETTOYAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 1,
      paidStaff: 1,
      annualBillings: {
        2025: AnnualBillingData.empty().copyWith(monthlyRate: 30000),
        2026: AnnualBillingData.empty().copyWith(monthlyRate: 35000),
      },
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.dirty,
    ),
  ];
}
