import 'package:facturation_app/import/billing_excel_importer.dart';
import 'package:facturation_app/models/billing_line.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the current billing worksheet shape', () {
    const importer = BillingExcelImporter();

    final result = importer.parseRows(
      [
        [
          'Ref',
          'SITE',
          '',
          'CONTRAT',
          '',
          '',
          'EFFECTIF',
          '',
          'Position client',
          'MONTANT/MOIS',
        ],
        [
          'Reference, identique a celle de la comptabilite',
          'SITE',
          'ACTIVITE',
          'Debut',
          'Fin',
          'Nature du Contrat CDD/CDI',
          'Eff facture',
          'Eff paye',
          'Position, active ou desactive',
          DateTime(2026),
          DateTime(2026, 2),
          DateTime(2026, 3),
          DateTime(2026, 4),
          DateTime(2026, 5),
          DateTime(2026, 6),
          DateTime(2026, 7),
          DateTime(2026, 8),
          DateTime(2026, 9),
          DateTime(2026, 10),
          DateTime(2026, 11),
          DateTime(2026, 12),
          'Total',
        ],
        [
          'REF-001',
          'AK TRANSPORT',
          'NETTOYAGE',
          DateTime(2021),
          '',
          'CDD',
          2,
          2,
          '',
          10000,
          20000,
        ],
        [
          '',
          'AES',
          'Gardiennage',
          44197,
          44561,
          '',
          '3',
          '2',
          'desactive',
        ],
        [
          'TOTAUX',
          '',
          '',
        ],
      ],
      year: 2026,
      sourceName: 'test.xlsx',
    );

    expect(result.importedCount, 2);
    expect(result.rowsRead, 2);
    expect(result.missingReferences, 1);
    expect(result.lines.first.reference, 'REF-001');
    expect(result.lines.first.name, 'AK TRANSPORT');
    expect(result.lines.first.activity, 'NETTOYAGE');
    expect(result.lines.first.startDate, '2021-01-01');
    expect(result.lines.first.annualBilling(2026).payments['Jan'], 10000);
    expect(result.lines.first.annualBilling(2026).payments['Fev'], 20000);
    expect(result.lines.last.activity, 'GARDIENNAGE');
    expect(result.lines.last.startDate, '2021-01-01');
    expect(result.lines.last.endDate, '2021-12-31');
    expect(result.lines.last.status, 'Desactive');
    expect(result.lines.last.syncState, SyncState.synced);
  });

  test('reports duplicate references and unknown activities', () {
    const importer = BillingExcelImporter();

    final result = importer.parseRows(
      [
        ['Reference', 'SITE', 'ACTIVITE'],
        ['REF-001', 'Client A', 'Inconnue'],
        ['ref-001', 'Client B', 'CAMERA'],
      ],
      year: 2026,
    );

    expect(result.duplicateReferences, {'REF-001'});
    expect(result.unknownActivities, {'INCONNUE'});
    expect(result.hasWarnings, isTrue);
  });
}
