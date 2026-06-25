import '../models/billing_line.dart';

class RemoteAnnualBillingDocument {
  const RemoteAnnualBillingDocument({
    required this.documentId,
    required this.data,
  });

  final String documentId;
  final Map<String, dynamic> data;
}

class FirestoreLineMapper {
  const FirestoreLineMapper();

  bool isDeleted(Map<String, dynamic> lineData) {
    return lineData['deleted'] == true;
  }

  BillingLine fromRemote({
    required String documentId,
    required Map<String, dynamic> lineData,
    required Iterable<RemoteAnnualBillingDocument> annualDocuments,
  }) {
    final lineId = _string(lineData['lineId']).trim();

    return BillingLine(
      id: lineId.isEmpty ? documentId : lineId,
      reference: _string(lineData['reference']),
      name: _string(lineData['name']),
      activity: _activity(lineData['activity']),
      startDate: _string(lineData['startDate']),
      endDate: _string(lineData['endDate']),
      contractNature: _string(lineData['contractNature']),
      billedStaff: _int(lineData['billedStaff']),
      paidStaff: _int(lineData['paidStaff']),
      annualBillings: {
        for (final annual in annualDocuments)
          if (_year(annual) case final int year)
            year: AnnualBillingData(
              monthlyRate: _double(annual.data['monthlyRate']),
              payments: _payments(annual.data['paiements']),
            ),
      },
      status: _status(lineData['status']),
      statusComment: _string(lineData['statusComment']),
      syncState: SyncState.synced,
    );
  }

  String _activity(Object? value) {
    final text = _string(value).trim().toUpperCase();
    return text.isEmpty ? 'GARDIENNAGE' : text;
  }

  String _status(Object? value) {
    final text = _string(value).trim();
    return statuses.contains(text) ? text : 'Actif';
  }

  int? _year(RemoteAnnualBillingDocument annual) {
    final explicitYear = _intOrNull(annual.data['annee']);
    if (explicitYear != null) return explicitYear;
    return int.tryParse(annual.documentId);
  }

  Map<String, double> _payments(Object? value) {
    final raw = value is Map ? value : const <Object?, Object?>{};
    return {for (final month in months) month: _double(raw[month])};
  }

  String _string(Object? value) => value is String ? value : '';

  int _int(Object? value) => _intOrNull(value) ?? 0;

  int? _intOrNull(Object? value) {
    return switch (value) {
      final int number => number,
      final num number => number.toInt(),
      final String text => int.tryParse(text.trim()),
      _ => null,
    };
  }

  double _double(Object? value) {
    return switch (value) {
      final double number => number,
      final num number => number.toDouble(),
      final String text => double.tryParse(text.replaceAll(',', '.')) ?? 0,
      _ => 0,
    };
  }
}
