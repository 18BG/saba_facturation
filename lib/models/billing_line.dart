const activities = <String>[
  'GARDIENNAGE',
  'NETTOYAGE',
  'INTERIM',
  'AUTRE',
  'LOCATION',
  'CAMERA',
  'ADMINISTRATION',
  'RECRUTEMENT',
];

const statuses = <String>['Actif', 'Desactive', 'Autre'];

const months = <String>[
  'Jan',
  'Fev',
  'Mar',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Aout',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

enum SyncState {
  synced,
  dirty,
  syncing,
  failed,
}

class AnnualBillingData {
  const AnnualBillingData({
    required this.monthlyRate,
    required this.payments,
  });

  factory AnnualBillingData.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['payments'] as Map<String, dynamic>? ?? const {};
    return AnnualBillingData(
      monthlyRate: _toDouble(json['monthlyRate']),
      payments: {
        for (final month in months) month: _toDouble(rawPayments[month]),
      },
    );
  }

  factory AnnualBillingData.empty() {
    return AnnualBillingData(
      monthlyRate: 0,
      payments: {for (final month in months) month: 0},
    );
  }

  final double monthlyRate;
  final Map<String, double> payments;

  double expectedMonthlyAmount(int billedStaff) => billedStaff * monthlyRate;

  double expectedYearAmount(int billedStaff) => expectedMonthlyAmount(billedStaff) * 12;

  double expectedDueAmount(int billedStaff, int dueMonthCount) {
    return expectedMonthlyAmount(billedStaff) * dueMonthCount.clamp(0, 12);
  }

  double get paidTotal {
    return months.fold<double>(0, (total, month) => total + (payments[month] ?? 0));
  }

  double paidTotalDue(int dueMonthCount) {
    final safeCount = dueMonthCount.clamp(0, 12);
    return months.take(safeCount).fold<double>(
          0,
          (total, month) => total + (payments[month] ?? 0),
        );
  }

  double balance(int billedStaff) => expectedYearAmount(billedStaff) - paidTotal;

  double balanceDue(int billedStaff, int dueMonthCount) {
    return expectedDueAmount(billedStaff, dueMonthCount) - paidTotalDue(dueMonthCount);
  }

  AnnualBillingData copyWith({
    double? monthlyRate,
    Map<String, double>? payments,
  }) {
    return AnnualBillingData(
      monthlyRate: monthlyRate ?? this.monthlyRate,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthlyRate': monthlyRate,
      'payments': payments,
    };
  }
}

class BillingLine {
  BillingLine({
    required this.reference,
    required this.name,
    required this.activity,
    required this.startDate,
    required this.endDate,
    required this.contractNature,
    required this.billedStaff,
    required this.paidStaff,
    required this.annualBillings,
    required this.status,
    required this.statusComment,
    required this.syncState,
  });

  factory BillingLine.fromJson(Map<String, dynamic> json) {
    final rawAnnualBillings = json['annualBillings'] as Map<String, dynamic>? ?? const {};
    return BillingLine(
      reference: json['reference'] as String? ?? '',
      name: json['name'] as String? ?? '',
      activity: json['activity'] as String? ?? 'GARDIENNAGE',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      contractNature: json['contractNature'] as String? ?? '',
      billedStaff: _toInt(json['billedStaff']),
      paidStaff: _toInt(json['paidStaff']),
      annualBillings: {
        for (final entry in rawAnnualBillings.entries)
          int.tryParse(entry.key) ?? 0: AnnualBillingData.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          ),
      }..removeWhere((year, value) => year == 0),
      status: json['status'] as String? ?? 'Actif',
      statusComment: json['statusComment'] as String? ?? '',
      syncState: _syncStateFromName(json['syncState'] as String?),
    );
  }

  final String reference;
  final String name;
  final String activity;
  final String startDate;
  final String endDate;
  final String contractNature;
  final int billedStaff;
  final int paidStaff;
  final Map<int, AnnualBillingData> annualBillings;
  final String status;
  final String statusComment;
  final SyncState syncState;

  AnnualBillingData annualBilling(int year) {
    return annualBillings[year] ?? AnnualBillingData.empty();
  }

  double expectedMonthlyAmount(int year) {
    return annualBilling(year).expectedMonthlyAmount(billedStaff);
  }

  double expectedYearAmount(int year) {
    return annualBilling(year).expectedYearAmount(billedStaff);
  }

  double paidTotal(int year) => annualBilling(year).paidTotal;

  double balance(int year) => annualBilling(year).balance(billedStaff);

  int billingMonthsDue(int year, {DateTime? asOf}) {
    final today = asOf ?? DateTime.now();
    if (year < today.year) return 12;
    if (year > today.year) return 0;
    return (today.month - 1).clamp(0, 12);
  }

  double expectedDueAmount(int year, {DateTime? asOf}) {
    return annualBilling(year).expectedDueAmount(
      billedStaff,
      billingMonthsDue(year, asOf: asOf),
    );
  }

  double paidTotalDue(int year, {DateTime? asOf}) {
    return annualBilling(year).paidTotalDue(billingMonthsDue(year, asOf: asOf));
  }

  double balanceDue(int year, {DateTime? asOf}) {
    return annualBilling(year).balanceDue(
      billedStaff,
      billingMonthsDue(year, asOf: asOf),
    );
  }

  bool get isIncomplete {
    return reference.trim().isEmpty || name.trim().isEmpty || activity.trim().isEmpty;
  }

  BillingLine withAnnualBilling(int year, AnnualBillingData annualBilling) {
    return copyWith(
      annualBillings: {
        ...annualBillings,
        year: annualBilling,
      },
    );
  }

  BillingLine copyWith({
    String? reference,
    String? name,
    String? activity,
    String? startDate,
    String? endDate,
    String? contractNature,
    int? billedStaff,
    int? paidStaff,
    Map<int, AnnualBillingData>? annualBillings,
    String? status,
    String? statusComment,
    SyncState? syncState,
  }) {
    return BillingLine(
      reference: reference ?? this.reference,
      name: name ?? this.name,
      activity: activity ?? this.activity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      contractNature: contractNature ?? this.contractNature,
      billedStaff: billedStaff ?? this.billedStaff,
      paidStaff: paidStaff ?? this.paidStaff,
      annualBillings: annualBillings ?? this.annualBillings,
      status: status ?? this.status,
      statusComment: statusComment ?? this.statusComment,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'name': name,
      'activity': activity,
      'startDate': startDate,
      'endDate': endDate,
      'contractNature': contractNature,
      'billedStaff': billedStaff,
      'paidStaff': paidStaff,
      'annualBillings': {
        for (final entry in annualBillings.entries) '${entry.key}': entry.value.toJson(),
      },
      'status': status,
      'statusComment': statusComment,
      'syncState': syncState.name,
    };
  }
}

double _toDouble(Object? value) {
  return switch (value) {
    final num number => number.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0,
  };
}

int _toInt(Object? value) {
  return switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0,
  };
}

SyncState _syncStateFromName(String? value) {
  return SyncState.values.firstWhere(
    (state) => state.name == value,
    orElse: () => SyncState.synced,
  );
}
