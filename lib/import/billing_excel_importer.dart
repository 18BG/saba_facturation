import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/billing_line.dart';

class BillingExcelImportResult {
  const BillingExcelImportResult({
    required this.sourceName,
    required this.year,
    required this.lines,
    required this.rowsRead,
    required this.missingReferences,
    required this.missingSites,
    required this.duplicateReferences,
    required this.unknownActivities,
  });

  final String sourceName;
  final int year;
  final List<BillingLine> lines;
  final int rowsRead;
  final int missingReferences;
  final int missingSites;
  final Set<String> duplicateReferences;
  final Set<String> unknownActivities;

  int get importedCount => lines.length;

  int get warningCount {
    return missingReferences + missingSites + duplicateReferences.length + unknownActivities.length;
  }

  bool get hasWarnings => warningCount > 0;
}

class BillingExcelImporter {
  const BillingExcelImporter();

  BillingExcelImportResult importBytes(
    Uint8List bytes, {
    required int year,
    required String sourceName,
  }) {
    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables.values.firstWhere(
      (candidate) => candidate.rows.isNotEmpty,
      orElse: () => throw const FormatException('Aucune feuille lisible dans ce fichier.'),
    );

    final rows = [
      for (final row in sheet.rows) [for (final cell in row) cell?.value],
    ];

    return parseRows(rows, year: year, sourceName: sourceName);
  }

  BillingExcelImportResult parseRows(
    List<List<Object?>> rows, {
    required int year,
    String sourceName = 'Fichier Excel',
  }) {
    final headerIndex = _findHeaderIndex(rows);
    final dataRows = rows.skip(headerIndex + 1).toList();
    final monthIndexes = _detectMonthIndexes(
      headerIndex >= 0 && headerIndex < rows.length ? rows[headerIndex] : const [],
      year,
    );

    final lines = <BillingLine>[];
    final referenceCounts = <String, int>{};
    final unknownActivities = <String>{};
    var rowsRead = 0;
    var missingReferences = 0;
    var missingSites = 0;

    for (final row in dataRows) {
      if (_isEmptyRow(row)) continue;
      if (_isTotalRow(row)) continue;

      rowsRead++;

      final reference = _cellText(_cellAt(row, 0));
      final name = _cellText(_cellAt(row, 1));
      final activity = _normalizeActivity(_cellAt(row, 2));
      final rawActivity = _cellText(_cellAt(row, 2)).trim();
      final normalizedRawActivity = rawActivity.toUpperCase();

      if (reference.isEmpty) missingReferences++;
      if (name.isEmpty) missingSites++;
      if (activity.isNotEmpty && !activities.contains(activity)) {
        unknownActivities.add(normalizedRawActivity);
      }

      final referenceKey = reference.toUpperCase();
      if (referenceKey.isNotEmpty) {
        referenceCounts[referenceKey] = (referenceCounts[referenceKey] ?? 0) + 1;
      }

      final payments = <String, double>{
        for (var i = 0; i < months.length; i++)
          months[i]: _cellNumber(_cellAt(row, monthIndexes[i])),
      };

      lines.add(
        BillingLine(
          reference: reference,
          name: name,
          activity: activity,
          startDate: _cellDateText(_cellAt(row, 3)),
          endDate: _cellDateText(_cellAt(row, 4)),
          contractNature: _cellText(_cellAt(row, 5)),
          billedStaff: _cellInt(_cellAt(row, 6)),
          paidStaff: _cellInt(_cellAt(row, 7)),
          annualBillings: {
            year: AnnualBillingData(
              monthlyRate: 0,
              payments: payments,
            ),
          },
          status: _normalizeStatus(_cellAt(row, 8)),
          statusComment: '',
          syncState: SyncState.synced,
        ),
      );
    }

    return BillingExcelImportResult(
      sourceName: sourceName,
      year: year,
      lines: lines,
      rowsRead: rowsRead,
      missingReferences: missingReferences,
      missingSites: missingSites,
      duplicateReferences: {
        for (final entry in referenceCounts.entries)
          if (entry.value > 1) entry.key,
      },
      unknownActivities: unknownActivities,
    );
  }

  int _findHeaderIndex(List<List<Object?>> rows) {
    for (var i = 0; i < rows.length; i++) {
      final normalized = rows[i].map((cell) => _normalizeText(_cellText(cell))).toList();
      final hasSite = normalized.any((value) => value == 'SITE');
      final hasActivity = normalized.any((value) => value == 'ACTIVITE');
      final hasReference = normalized.any((value) => value.contains('REFERENCE'));
      if (hasSite && (hasActivity || hasReference)) return i;
    }
    return rows.length > 2 ? 1 : 0;
  }

  List<int> _detectMonthIndexes(List<Object?> headerRow, int year) {
    final detected = List<int?>.filled(months.length, null);

    for (var column = 0; column < headerRow.length; column++) {
      final monthIndex = _monthIndexFromHeader(headerRow[column], year);
      if (monthIndex != null) detected[monthIndex] = column;
    }

    return [
      for (var i = 0; i < months.length; i++) detected[i] ?? 9 + i,
    ];
  }

  int? _monthIndexFromHeader(Object? value, int year) {
    value = _unwrapCellValue(value);
    if (value is DateTime && value.year == year) return value.month - 1;
    if (value is num) {
      final date = _excelDateFromSerial(value.toDouble());
      if (date != null && date.year == year) return date.month - 1;
    }

    final text = _cellText(value).trim();
    final parsedDate = DateTime.tryParse(text);
    if (parsedDate != null && parsedDate.year == year) return parsedDate.month - 1;

    final normalized = _normalizeText(text);
    const monthWords = [
      ['JAN', 'JANVIER'],
      ['FEV', 'FEVRIER', 'FEB', 'FEBRUARY'],
      ['MAR', 'MARS', 'MARCH'],
      ['AVR', 'AVRIL', 'APR', 'APRIL'],
      ['MAI', 'MAY'],
      ['JUIN', 'JUN', 'JUNE'],
      ['JUIL', 'JUILLET', 'JUL', 'JULY'],
      ['AOUT', 'AUG', 'AUGUST'],
      ['SEP', 'SEPT', 'SEPTEMBRE', 'SEPTEMBER'],
      ['OCT', 'OCTOBRE', 'OCTOBER'],
      ['NOV', 'NOVEMBRE', 'NOVEMBER'],
      ['DEC', 'DECEMBRE', 'DECEMBER'],
    ];

    for (var i = 0; i < monthWords.length; i++) {
      if (monthWords[i].any(normalized.contains)) return i;
    }

    return null;
  }

  bool _isEmptyRow(List<Object?> row) {
    return row.take(22).every((cell) => _cellText(cell).isEmpty);
  }

  bool _isTotalRow(List<Object?> row) {
    final firstCells = [
      _cellText(_cellAt(row, 0)),
      _cellText(_cellAt(row, 1)),
      _cellText(_cellAt(row, 2)),
    ].map(_normalizeText).join(' ');
    return firstCells.contains('TOTAUX') || firstCells.contains('TOTAL');
  }

  Object? _cellAt(List<Object?> row, int index) {
    return index >= 0 && index < row.length ? row[index] : null;
  }

  String _normalizeActivity(Object? value) {
    final text = _cellText(value).trim();
    if (text.isEmpty) return '';

    final normalized = _normalizeText(text);
    for (final activity in activities) {
      if (_normalizeText(activity) == normalized) return activity;
    }
    return normalized;
  }

  String _normalizeStatus(Object? value) {
    final normalized = _normalizeText(_cellText(value));
    if (normalized.contains('DESACT') ||
        normalized.contains('INACT') ||
        normalized.contains('RESIL') ||
        normalized.contains('ARRET')) {
      return 'Desactive';
    }
    if (normalized.contains('AUTRE')) return 'Autre';
    return 'Actif';
  }

  String _cellDateText(Object? value) {
    value = _unwrapCellValue(value);
    if (value == null) return '';
    if (value is DateTime) return _formatDate(value);
    if (value is num) {
      final date = _excelDateFromSerial(value.toDouble());
      return date == null ? '' : _formatDate(date);
    }

    final text = _cellText(value);
    if (text.isEmpty) return '';

    final parsed = DateTime.tryParse(text);
    if (parsed != null) return _formatDate(parsed);

    final number = double.tryParse(text.replaceAll(',', '.'));
    if (number != null) {
      final date = _excelDateFromSerial(number);
      if (date != null) return _formatDate(date);
    }

    return text;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _excelDateFromSerial(double value) {
    if (value < 20000 || value > 90000) return null;
    return DateTime(1899, 12, 30).add(Duration(days: value.floor()));
  }

  int _cellInt(Object? value) => _cellNumber(value).round();

  double _cellNumber(Object? value) {
    value = _unwrapCellValue(value);
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final text = _cellText(value)
        .replaceAll('\u00A0', ' ')
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(text) ?? 0;
  }

  String _cellText(Object? value) {
    value = _unwrapCellValue(value);
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    final text = value.toString().trim();
    return text == 'null' ? '' : text;
  }

  Object? _unwrapCellValue(Object? value) {
    if (value == null || value is String || value is num || value is bool || value is DateTime) {
      return value;
    }

    final dynamic dynamicValue = value;

    try {
      final Object? innerValue = dynamicValue.value as Object?;
      if (!identical(innerValue, value)) return _unwrapCellValue(innerValue);
    } on Object {
      // Fall through to typed date/time extraction below.
    }

    try {
      final int year = dynamicValue.year as int;
      final int month = dynamicValue.month as int;
      final int day = dynamicValue.day as int;
      final int hour = _optionalInt(() => dynamicValue.hour as int);
      final int minute = _optionalInt(() => dynamicValue.minute as int);
      final int second = _optionalInt(() => dynamicValue.second as int);
      return DateTime(year, month, day, hour, minute, second);
    } on Object {
      // Fall through to toString fallback.
    }

    return value;
  }

  int _optionalInt(int Function() read) {
    try {
      return read();
    } on Object {
      return 0;
    }
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Ä', 'A')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ô', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('Ù', 'U')
        .replaceAll('Û', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ç', 'C');
  }
}
