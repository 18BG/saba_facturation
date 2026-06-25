import 'dart:math';

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

const disabledStatus = 'Desactive';

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

enum SyncState { synced, dirty, syncing, failed }

class AnnualBillingData {
  const AnnualBillingData({required this.monthlyRate, required this.payments});

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

  double expectedYearAmount(int billedStaff) =>
      expectedMonthlyAmount(billedStaff) * 12;

  double expectedDueAmount(int billedStaff, int dueMonthCount) {
    return expectedMonthlyAmount(billedStaff) * dueMonthCount.clamp(0, 12);
  }

  double get paidTotal {
    return months.fold<double>(
      0,
      (total, month) => total + (payments[month] ?? 0),
    );
  }

  double paidTotalDue(int dueMonthCount) {
    final safeCount = dueMonthCount.clamp(0, 12);
    return months
        .take(safeCount)
        .fold<double>(0, (total, month) => total + (payments[month] ?? 0));
  }

  double balance(int billedStaff) =>
      expectedYearAmount(billedStaff) - paidTotal;

  double balanceDue(int billedStaff, int dueMonthCount) {
    return expectedDueAmount(billedStaff, dueMonthCount) -
        paidTotalDue(dueMonthCount);
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
    return {'monthlyRate': monthlyRate, 'payments': payments};
  }
}

class BillingLine {
  BillingLine({
    String? id,
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
  }) : id = id == null || id.trim().isEmpty ? newBillingLineId() : id;

  factory BillingLine.fromJson(Map<String, dynamic> json) {
    final rawAnnualBillings =
        json['annualBillings'] as Map<String, dynamic>? ?? const {};
    return BillingLine(
      id: json['id'] as String?,
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

  final String id;
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
    return annualBilling(
      year,
    ).expectedDueAmount(billedStaff, billingMonthsDue(year, asOf: asOf));
  }

  double paidTotalDue(int year, {DateTime? asOf}) {
    return annualBilling(year).paidTotalDue(billingMonthsDue(year, asOf: asOf));
  }

  double balanceDue(int year, {DateTime? asOf}) {
    return annualBilling(
      year,
    ).balanceDue(billedStaff, billingMonthsDue(year, asOf: asOf));
  }

  bool get isIncomplete {
    return reference.trim().isEmpty ||
        name.trim().isEmpty ||
        activity.trim().isEmpty;
  }

  bool get countsInBillingTotals => status != disabledStatus;

  BillingLine withAnnualBilling(int year, AnnualBillingData annualBilling) {
    return copyWith(annualBillings: {...annualBillings, year: annualBilling});
  }

  BillingLine copyWith({
    String? id,
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
      id: id ?? this.id,
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
      'id': id,
      'reference': reference,
      'name': name,
      'activity': activity,
      'startDate': startDate,
      'endDate': endDate,
      'contractNature': contractNature,
      'billedStaff': billedStaff,
      'paidStaff': paidStaff,
      'annualBillings': {
        for (final entry in annualBillings.entries)
          '${entry.key}': entry.value.toJson(),
      },
      'status': status,
      'statusComment': statusComment,
      'syncState': syncState.name,
    };
  }
}

Iterable<BillingLine> linesCountedInBillingTotals(Iterable<BillingLine> lines) {
  return lines.where((line) => line.countsInBillingTotals);
}

String newBillingLineId() {
  final random = _secureRandom();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final chars = bytes.map(hex).join();

  return [
    chars.substring(0, 8),
    chars.substring(8, 12),
    chars.substring(12, 16),
    chars.substring(16, 20),
    chars.substring(20),
  ].join('-');
}

bool isGeneratedBillingLineId(String value) {
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value.trim());
}

Random _secureRandom() {
  try {
    return Random.secure();
  } on UnsupportedError {
    return Random();
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
