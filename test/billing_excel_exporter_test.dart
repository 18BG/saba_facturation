import 'package:excel/excel.dart';
import 'package:facturation_app/export/billing_excel_exporter.dart';
import 'package:facturation_app/models/billing_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports billing lines to an xlsx workbook with totals', () {
    const exporter = BillingExcelExporter();
    final bytes = exporter.exportLines(
      [
        BillingLine(
          reference: 'REF-001',
          name: 'Client A',
          activity: 'GARDIENNAGE',
          startDate: '2026-01-01',
          endDate: '',
          contractNature: 'CDD',
          billedStaff: 2,
          paidStaff: 1,
          annualBillings: {
            2026: AnnualBillingData(
              monthlyRate: 1000,
              payments: {
                for (final month in months) month: month == 'Jan' ? 2000 : 0,
              },
            ),
          },
          status: 'Actif',
          statusComment: '',
          syncState: SyncState.synced,
        ),
        BillingLine(
          reference: 'REF-002',
          name: 'Client B',
          activity: 'NETTOYAGE',
          startDate: '',
          endDate: '',
          contractNature: '',
          billedStaff: 1,
          paidStaff: 1,
          annualBillings: {
            2026: AnnualBillingData(
              monthlyRate: 500,
              payments: {
                for (final month in months) month: month == 'Fev' ? 500 : 0,
              },
            ),
          },
          status: 'Desactive',
          statusComment: '',
          syncState: SyncState.synced,
        ),
      ],
      options: const BillingExcelExportOptions(
        year: 2026,
        onlyActive: true,
        includeBalanceColumns: true,
      ),
    );

    final workbook = Excel.decodeBytes(bytes);
    final sheet = workbook.tables['Facturation 2026'];

    expect(sheet, isNotNull);
    expect(sheet!.rows.length, 3);
    expect(sheet.rows[0][0]?.value.toString(), 'Reference');
    expect(sheet.rows[1][0]?.value.toString(), 'REF-001');
    expect(sheet.rows[1][1]?.value.toString(), 'Client A');
    expect(sheet.rows[2][0]?.value.toString(), 'TOTAUX');
    expect(sheet.rows[2][6]?.value.toString(), '2');
    expect(sheet.rows[2][7]?.value.toString(), '1');
    expect(_numberValue(sheet.rows[2][10]?.value), 2000);
  });
}

num _numberValue(Object? value) {
  final raw = value.toString();
  return num.parse(raw);
}
