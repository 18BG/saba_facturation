import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/billing_line.dart';
import '../validation/billing_validation.dart';

class BillingExcelExportOptions {
  const BillingExcelExportOptions({
    required this.year,
    required this.onlyActive,
    required this.includeBalanceColumns,
  });

  final int year;
  final bool onlyActive;
  final bool includeBalanceColumns;
}

class BillingExcelExporter {
  const BillingExcelExporter();

  Uint8List exportLines(
    List<BillingLine> lines, {
    required BillingExcelExportOptions options,
  }) {
    final workbook = Excel.createExcel();
    const defaultSheet = 'Sheet1';
    final sheetName = 'Facturation ${options.year}';
    workbook.rename(defaultSheet, sheetName);
    workbook.setDefaultSheet(sheetName);
    final sheet = workbook[sheetName];

    final filteredLines = [
      for (final line in lines)
        if (!options.onlyActive || line.status == 'Actif') line,
    ];

    _writeHeader(sheet, options);
    for (var i = 0; i < filteredLines.length; i++) {
      _writeLine(sheet, filteredLines[i], options);
    }
    _writeTotals(sheet, filteredLines, options);
    _writeAlerts(workbook, filteredLines, options);
    _setColumnWidths(sheet, options);

    final bytes = workbook.encode();
    if (bytes == null) {
      throw const FormatException('Impossible de generer le fichier Excel.');
    }
    return Uint8List.fromList(bytes);
  }

  void _writeAlerts(
    Excel workbook,
    List<BillingLine> lines,
    BillingExcelExportOptions options,
  ) {
    final duplicateReferences = _duplicateReferences(lines);
    final alertRows = <List<CellValue?>>[];

    for (final line in lines) {
      final issues = [
        if (duplicateReferences.contains(line.reference.trim().toUpperCase()))
          'Reference deja utilisee.',
        ...billingLineIssues(line, year: options.year),
      ];
      for (final issue in issues) {
        alertRows.add([
          TextCellValue(line.reference),
          TextCellValue(line.name),
          TextCellValue(line.activity),
          TextCellValue(issue),
        ]);
      }
    }

    if (alertRows.isEmpty) return;

    final sheet = workbook['Alertes'];
    sheet.appendRow([
      TextCellValue('Reference'),
      TextCellValue('SITE'),
      TextCellValue('ACTIVITE'),
      TextCellValue('Alerte'),
    ]);
    for (final row in alertRows) {
      sheet.appendRow(row);
    }
    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 42);
  }

  void _writeHeader(Sheet sheet, BillingExcelExportOptions options) {
    final headers = [
      'Reference',
      'SITE',
      'ACTIVITE',
      'Debut',
      'Fin',
      'Nature du Contrat CDD/CDI',
      'Eff facture',
      'Eff paye',
      'Position client',
      'Tarif mensuel',
      ...months,
      'Total paye',
      if (options.includeBalanceColumns) ...[
        'Attendu a date',
        'Paye a date',
        'Reliquat a date',
        'Attendu annuel',
        'Reliquat annuel',
      ],
    ];

    sheet.appendRow([for (final header in headers) TextCellValue(header)]);
  }

  void _writeLine(
    Sheet sheet,
    BillingLine line,
    BillingExcelExportOptions options,
  ) {
    final annual = line.annualBilling(options.year);
    final values = <CellValue?>[
      TextCellValue(line.reference),
      TextCellValue(line.name),
      TextCellValue(line.activity),
      TextCellValue(line.startDate),
      TextCellValue(line.endDate),
      TextCellValue(line.contractNature),
      IntCellValue(line.billedStaff),
      IntCellValue(line.paidStaff),
      TextCellValue(line.status),
      DoubleCellValue(annual.monthlyRate),
      for (final month in months) DoubleCellValue(annual.payments[month] ?? 0),
      DoubleCellValue(line.paidTotal(options.year)),
      if (options.includeBalanceColumns) ...[
        DoubleCellValue(line.expectedDueAmount(options.year)),
        DoubleCellValue(line.paidTotalDue(options.year)),
        DoubleCellValue(line.balanceDue(options.year)),
        DoubleCellValue(line.expectedYearAmount(options.year)),
        DoubleCellValue(line.balance(options.year)),
      ],
    ];

    sheet.appendRow(values);
  }

  void _writeTotals(
    Sheet sheet,
    List<BillingLine> lines,
    BillingExcelExportOptions options,
  ) {
    final countedLines = linesCountedInBillingTotals(lines).toList();
    final totalPaid = countedLines.fold<double>(
      0,
      (sum, line) => sum + line.paidTotal(options.year),
    );
    final totalDueExpected = countedLines.fold<double>(
      0,
      (sum, line) => sum + line.expectedDueAmount(options.year),
    );
    final totalDuePaid = countedLines.fold<double>(
      0,
      (sum, line) => sum + line.paidTotalDue(options.year),
    );
    final totalDueBalance = countedLines.fold<double>(
      0,
      (sum, line) => sum + line.balanceDue(options.year),
    );
    final totalYearExpected = countedLines.fold<double>(
      0,
      (sum, line) => sum + line.expectedYearAmount(options.year),
    );
    final totalYearBalance = countedLines.fold<double>(
      0,
      (sum, line) => sum + line.balance(options.year),
    );

    final values = <CellValue?>[
      TextCellValue('TOTAUX'),
      null,
      null,
      null,
      null,
      null,
      IntCellValue(
        countedLines.fold<int>(0, (sum, line) => sum + line.billedStaff),
      ),
      IntCellValue(
        countedLines.fold<int>(0, (sum, line) => sum + line.paidStaff),
      ),
      null,
      null,
      for (final month in months)
        DoubleCellValue(
          countedLines.fold<double>(
            0,
            (sum, line) =>
                sum + (line.annualBilling(options.year).payments[month] ?? 0),
          ),
        ),
      DoubleCellValue(totalPaid),
      if (options.includeBalanceColumns) ...[
        DoubleCellValue(totalDueExpected),
        DoubleCellValue(totalDuePaid),
        DoubleCellValue(totalDueBalance),
        DoubleCellValue(totalYearExpected),
        DoubleCellValue(totalYearBalance),
      ],
    ];

    sheet.appendRow(values);
  }

  void _setColumnWidths(Sheet sheet, BillingExcelExportOptions options) {
    const widths = <double>[
      18,
      30,
      18,
      13,
      13,
      24,
      12,
      12,
      16,
      15,
      12,
      12,
      12,
      12,
      12,
      12,
      12,
      12,
      12,
      12,
      12,
      12,
      15,
      16,
      14,
      16,
      16,
      16,
    ];

    final columnCount = options.includeBalanceColumns ? widths.length : 23;
    for (var i = 0; i < columnCount; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  Set<String> _duplicateReferences(List<BillingLine> lines) {
    final counts = <String, int>{};
    for (final line in lines) {
      final reference = line.reference.trim().toUpperCase();
      if (reference.isEmpty) continue;
      counts[reference] = (counts[reference] ?? 0) + 1;
    }
    return {
      for (final entry in counts.entries)
        if (entry.value > 1) entry.key,
    };
  }
}
