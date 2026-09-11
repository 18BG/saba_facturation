import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
    return missingReferences +
        missingSites +
        duplicateReferences.length +
        unknownActivities.length;
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
    final workbook = Excel.decodeBytes(_makeExcelParserCompatible(bytes));
    final sheet = workbook.tables.values.firstWhere(
      (candidate) => candidate.rows.isNotEmpty,
      orElse: () => throw const FormatException(
        'Aucune feuille lisible dans ce fichier.',
      ),
    );

    final rows = [
      for (final row in sheet.rows) [for (final cell in row) cell?.value],
    ];

    return parseRows(rows, year: year, sourceName: sourceName);
  }

  /// Normalizes valid XLSX variants that the `excel` package does not parse:
  /// prefixed SpreadsheetML elements, absolute relationship targets, and
  /// built-in number formats incorrectly declared as custom formats.
  Uint8List _makeExcelParserCompatible(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    var changed = false;

    // The artifact-tool exporter may prefix every SpreadsheetML element with
    // `x:`. The `excel` package searches by unprefixed element names, so strip
    // that cosmetic prefix from the XML parts before parsing.
    for (final file
        in archive.files
            .where(
              (candidate) =>
                  candidate.name.startsWith('xl/') &&
                  candidate.name.endsWith('.xml'),
            )
            .toList()) {
      final xml = utf8.decode(file.content as List<int>);
      final normalizedXml = xml.replaceAllMapped(
        RegExp(r'</?x:'),
        (match) => match.group(0)!.replaceFirst('x:', ''),
      );
      if (normalizedXml == xml) continue;
      changed = true;
      final encoded = utf8.encode(normalizedXml);
      archive.addFile(
        ArchiveFile(file.name, encoded.length, encoded)
          ..mode = file.mode
          ..lastModTime = file.lastModTime
          ..comment = file.comment
          ..compress = file.compress,
      );
    }

    // Some XLSX writers emit absolute package targets such as
    // `/xl/styles.xml` in workbook.xml.rels. The `excel` package resolves
    // targets relative to `xl/`, so normalize those targets before parsing.
    final workbookRelationships = archive.findFile(
      'xl/_rels/workbook.xml.rels',
    );
    if (workbookRelationships != null) {
      final relationshipsXml = utf8.decode(
        workbookRelationships.content as List<int>,
      );
      final normalizedRelationshipsXml = relationshipsXml.replaceAllMapped(
        RegExp(r'(Target\s*=\s*")/xl/([^"]+)(")', caseSensitive: false),
        (match) => '${match.group(1)}${match.group(2)}${match.group(3)}',
      );
      if (normalizedRelationshipsXml != relationshipsXml) {
        changed = true;
        archive.addFile(
          ArchiveFile(
              workbookRelationships.name,
              utf8.encode(normalizedRelationshipsXml).length,
              utf8.encode(normalizedRelationshipsXml),
            )
            ..mode = workbookRelationships.mode
            ..lastModTime = workbookRelationships.lastModTime
            ..comment = workbookRelationships.comment
            ..compress = workbookRelationships.compress,
        );
      }
    }

    final stylesFile = archive.findFile('xl/styles.xml');
    if (stylesFile == null) {
      if (!changed) return bytes;
      return Uint8List.fromList(ZipEncoder().encode(archive)!);
    }

    final stylesXml = utf8.decode(stylesFile.content as List<int>);
    final invalidFormat = RegExp(
      r'<(?:[A-Za-z_][\w.-]*:)?numFmt\b[^>]*\bnumFmtId\s*=\s*"(\d+)"[^>]*(?:/>|>.*?</(?:[A-Za-z_][\w.-]*:)?numFmt>)',
      caseSensitive: false,
      dotAll: true,
    );
    final sanitizedXml = stylesXml.replaceAllMapped(invalidFormat, (match) {
      final id = int.tryParse(match.group(1)!);
      if (id != null && id < 164) {
        changed = true;
        return '';
      }
      return match.group(0)!;
    });

    if (!changed) return bytes;

    final numFmts = RegExp(
      r'(<(?:[A-Za-z_][\w.-]*:)?numFmts\b[^>]*\bcount\s*=\s*")(\d+)(")',
      caseSensitive: false,
    );
    final validCount = RegExp(
      r'<(?:[A-Za-z_][\w.-]*:)?numFmt\b',
      caseSensitive: false,
    ).allMatches(sanitizedXml).length;
    final normalizedXml = sanitizedXml.replaceFirstMapped(numFmts, (match) {
      return '${match.group(1)}$validCount${match.group(3)}';
    });

    if (changed) {
      archive.addFile(
        ArchiveFile(
            stylesFile.name,
            utf8.encode(normalizedXml).length,
            utf8.encode(normalizedXml),
          )
          ..mode = stylesFile.mode
          ..lastModTime = stylesFile.lastModTime
          ..comment = stylesFile.comment
          ..compress = stylesFile.compress,
      );
      return Uint8List.fromList(ZipEncoder().encode(archive)!);
    }

    return bytes;
  }

  BillingExcelImportResult parseRows(
    List<List<Object?>> rows, {
    required int year,
    String sourceName = 'Fichier Excel',
  }) {
    final headerIndex = _findHeaderIndex(rows);
    final dataRows = rows.skip(headerIndex + 1).toList();
    final headers = headerIndex >= 0 && headerIndex < rows.length
        ? rows[headerIndex]
              .map((cell) => _normalizeText(_cellText(cell)))
              .toList()
        : const <String>[];
    final referenceIndex = _findReferenceIndex(headers);
    final odooIdIndex = _findOdooIdIndex(headers);
    final appellationIndex = _findAppellationIndex(headers);
    final siteIndex = _siteIndex(headers);
    final activityIndex = _activityIndex(headers);
    final startDateIndex = _findHeaderContaining(headers, 'DEBUT', 3);
    final endDateIndex = _findHeaderContaining(headers, 'FIN', 4);
    final contractNatureIndex = _findHeaderContaining(headers, 'NATURE', 5);
    final billedStaffIndex = _findHeaderContaining(headers, 'EFF FACTURE', 6);
    final paidStaffIndex = _findHeaderContaining(headers, 'EFF PAYE', 7);
    final statusIndex = _findHeaderContaining(headers, 'POSITION', 8);
    final monthIndexes = _detectMonthIndexes(
      headerIndex >= 0 && headerIndex < rows.length
          ? rows[headerIndex]
          : const [],
      year,
    );

    final lines = <BillingLine>[];
    final referenceCounts = <String, int>{};
    final unknownActivities = <String>{};
    var rowsRead = 0;
    var missingReferences = 0;
    var missingSites = 0;

    final usedReferences = <String>{};
    for (final row in dataRows) {
      if (_isEmptyRow(row) || _isTotalRow(row)) continue;
      final odooId = _cellText(_cellAt(row, odooIdIndex));
      final reference = _normalizeProvidedReference(
        _cellText(_cellAt(row, referenceIndex)),
        odooId,
      );
      if (reference.isNotEmpty) usedReferences.add(reference.toUpperCase());
    }

    for (final row in dataRows) {
      if (_isEmptyRow(row)) continue;
      if (_isTotalRow(row)) continue;

      rowsRead++;

      final odooId = _cellText(_cellAt(row, odooIdIndex));
      var reference = _normalizeProvidedReference(
        _cellText(_cellAt(row, referenceIndex)),
        odooId,
      );
      if (reference.isEmpty && odooId.trim().isNotEmpty) {
        reference = _nextImportedReference(odooId, usedReferences);
      }
      final name = _cellText(_cellAt(row, siteIndex));
      final appellationComptable = _cellText(_cellAt(row, appellationIndex));
      final activity = _normalizeActivity(_cellAt(row, activityIndex));
      final rawActivity = _cellText(_cellAt(row, activityIndex)).trim();
      final normalizedRawActivity = rawActivity.toUpperCase();

      if (reference.isEmpty) missingReferences++;
      if (name.isEmpty) missingSites++;
      if (activity.isNotEmpty && !activities.contains(activity)) {
        unknownActivities.add(normalizedRawActivity);
      }

      final referenceKey = reference.toUpperCase();
      if (referenceKey.isNotEmpty) {
        referenceCounts[referenceKey] =
            (referenceCounts[referenceKey] ?? 0) + 1;
      }

      final payments = <String, double>{
        for (var i = 0; i < months.length; i++)
          months[i]: _cellNumber(_cellAt(row, monthIndexes[i])),
      };

      lines.add(
        BillingLine(
          reference: reference,
          odooId: odooId,
          appellationComptable: appellationComptable,
          name: name,
          activity: activity,
          startDate: _cellDateText(_cellAt(row, startDateIndex)),
          endDate: _cellDateText(_cellAt(row, endDateIndex)),
          contractNature: _cellText(_cellAt(row, contractNatureIndex)),
          billedStaff: _cellInt(_cellAt(row, billedStaffIndex)),
          paidStaff: _cellInt(_cellAt(row, paidStaffIndex)),
          annualBillings: {
            year: AnnualBillingData(monthlyRate: 0, payments: payments),
          },
          status: _normalizeStatus(_cellAt(row, statusIndex)),
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
    // Prefer the actual column header row when a workbook has a decorative
    // pre-header that also happens to contain "SITE" or "REFERENCE".
    for (var i = 0; i < rows.length; i++) {
      final normalized = rows[i]
          .map((cell) => _normalizeText(_cellText(cell)))
          .toList();
      final hasSite = normalized.any((value) => value == 'SITE');
      final hasActivity = normalized.any((value) => value == 'ACTIVITE');
      if (hasSite && hasActivity) return i;
    }

    for (var i = 0; i < rows.length; i++) {
      final normalized = rows[i]
          .map((cell) => _normalizeText(_cellText(cell)))
          .toList();
      final hasSite = normalized.any((value) => value == 'SITE');
      final hasActivity = normalized.any((value) => value == 'ACTIVITE');
      final hasReference = normalized.any(
        (value) => value.contains('REFERENCE'),
      );
      if (hasSite && (hasActivity || hasReference)) return i;
    }
    return rows.length > 2 ? 1 : 0;
  }

  int _findReferenceIndex(List<String> headers) {
    const preferred = [
      'REFERENCE DE FACTURATION',
      'REFERENCE COMPTABLE',
      'REFERENCE',
      'REF',
    ];
    for (final name in preferred) {
      final index = headers.indexOf(name);
      if (index >= 0) return index;
    }
    return 0;
  }

  int _findOdooIdIndex(List<String> headers) {
    const preferred = ['REFERENCE ODOO', 'ID ODOO', 'ODOO ID', 'CLIENT ODOO'];
    for (final name in preferred) {
      final index = headers.indexOf(name);
      if (index >= 0) return index;
    }
    final index = headers.indexWhere((header) => header.contains('ODOO'));
    return index >= 0 ? index : -1;
  }

  int _findAppellationIndex(List<String> headers) {
    const preferred = [
      'APPELLATION COMPTABLE',
      'CLIENT ODOO',
      'NOM CLIENT ODOO',
    ];
    for (final name in preferred) {
      final index = headers.indexOf(name);
      if (index >= 0) return index;
    }
    return -1;
  }

  int _siteIndex(List<String> headers) {
    final index = headers.indexOf('SITE');
    return index >= 0 ? index : 1;
  }

  int _activityIndex(List<String> headers) {
    final index = headers.indexOf('ACTIVITE');
    return index >= 0 ? index : 2;
  }

  int _findHeaderContaining(
    List<String> headers,
    String fragment,
    int fallback,
  ) {
    final index = headers.indexWhere((header) => header.contains(fragment));
    return index >= 0 ? index : fallback;
  }

  String _normalizeProvidedReference(String reference, String odooId) {
    final normalizedReference = reference.trim();
    final normalizedOdooId = odooId.trim();
    if (normalizedReference.isEmpty || normalizedOdooId.isEmpty) {
      return normalizedReference;
    }

    final legacy = RegExp(
      '^${RegExp.escape(normalizedOdooId)}(\\d+)\$',
      caseSensitive: false,
    ).firstMatch(normalizedReference);
    if (legacy != null) {
      return '$normalizedOdooId-${legacy.group(1)}';
    }
    return normalizedReference;
  }

  String _nextImportedReference(String odooId, Set<String> usedReferences) {
    final normalizedOdooId = odooId.trim();
    var suffix = 1;
    String candidate;
    do {
      candidate = '$normalizedOdooId-$suffix';
      suffix++;
    } while (usedReferences.contains(candidate.toUpperCase()));
    usedReferences.add(candidate.toUpperCase());
    return candidate;
  }

  List<int> _detectMonthIndexes(List<Object?> headerRow, int year) {
    final detected = List<int?>.filled(months.length, null);

    for (var column = 0; column < headerRow.length; column++) {
      final monthIndex = _monthIndexFromHeader(headerRow[column], year);
      if (monthIndex != null) detected[monthIndex] = column;
    }

    return [for (var i = 0; i < months.length; i++) detected[i] ?? 9 + i];
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
    if (parsedDate != null && parsedDate.year == year) {
      return parsedDate.month - 1;
    }

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
    final text = _cellText(
      value,
    ).replaceAll('\u00A0', ' ').replaceAll(' ', '').replaceAll(',', '.').trim();
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
    if (value == null ||
        value is String ||
        value is num ||
        value is bool ||
        value is DateTime) {
      return value;
    }

    return switch (value) {
      final TextCellValue cell => cell.value.toString(),
      final IntCellValue cell => cell.value,
      final DoubleCellValue cell => cell.value,
      final BoolCellValue cell => cell.value,
      final DateCellValue cell => cell.asDateTimeLocal(),
      final DateTimeCellValue cell => cell.asDateTimeLocal(),
      final TimeCellValue cell => cell.toString(),
      final FormulaCellValue cell => cell.formula,
      _ => value,
    };
  }

  String _normalizeText(String value) {
    return value
        .trim()
        .toUpperCase()
        .replaceAll('\u00C9', 'E')
        .replaceAll('\u00C8', 'E')
        .replaceAll('\u00CA', 'E')
        .replaceAll('\u00CB', 'E')
        .replaceAll('\u00C0', 'A')
        .replaceAll('\u00C2', 'A')
        .replaceAll('\u00C4', 'A')
        .replaceAll('\u00CE', 'I')
        .replaceAll('\u00CF', 'I')
        .replaceAll('\u00D4', 'O')
        .replaceAll('\u00D6', 'O')
        .replaceAll('\u00D9', 'U')
        .replaceAll('\u00DB', 'U')
        .replaceAll('\u00DC', 'U')
        .replaceAll('\u00C7', 'C');
  }
}
