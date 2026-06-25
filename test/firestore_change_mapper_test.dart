import 'package:facturation_app/sync/firestore_change_mapper.dart';
import 'package:facturation_app/sync/pending_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FirestoreChangeMapper();

  test('maps a line field to the billing line document', () {
    final write = mapper.map(
      PendingChange(
        id: '1',
        lineId: 'line-001',
        reference: 'REF/001',
        scope: ChangeScope.line,
        field: 'name',
        value: 'Client A',
        createdAt: DateTime(2026, 6, 22),
      ),
    );

    expect(write.documentPath, 'facturationLines/line-001');
    expect(write.merge, isTrue);
    expect(write.data['lineId'], 'line-001');
    expect(write.data['reference'], 'REF/001');
    expect(write.data['name'], 'Client A');
  });

  test('maps a reference edit to the stable line document', () {
    final write = mapper.map(
      PendingChange(
        id: 'ref',
        lineId: 'line-stable',
        reference: 'REF-FINALE',
        scope: ChangeScope.line,
        field: 'reference',
        value: 'REF-FINALE',
        createdAt: DateTime(2026, 6, 23),
      ),
    );

    expect(write.documentPath, 'facturationLines/line-stable');
    expect(write.data['lineId'], 'line-stable');
    expect(write.data['reference'], 'REF-FINALE');
  });

  test('maps a line snapshot to the stable line document', () {
    final write = mapper.map(
      PendingChange(
        id: 'snapshot',
        lineId: 'line-stable',
        reference: 'REF-001',
        scope: ChangeScope.line,
        field: '__lineSnapshot',
        value: {
          'reference': 'REF-001',
          'name': 'Client A',
          'activity': 'NETTOYAGE',
          'startDate': '01/01/2026',
          'endDate': '',
          'contractNature': 'CDI',
          'billedStaff': 2,
          'paidStaff': 1,
          'status': 'Actif',
          'statusComment': '',
          'annualBillings': {},
          'syncState': 'synced',
        },
        createdAt: DateTime(2026, 6, 23),
      ),
    );

    expect(write.documentPath, 'facturationLines/line-stable');
    expect(write.data['lineId'], 'line-stable');
    expect(write.data['reference'], 'REF-001');
    expect(write.data['name'], 'Client A');
    expect(write.data.containsKey('annualBillings'), isFalse);
    expect(write.data.containsKey('syncState'), isFalse);
  });

  test('maps a deleted line marker to the stable line document', () {
    final write = mapper.map(
      PendingChange(
        id: 'delete',
        lineId: 'line-to-delete',
        reference: 'REF-DEL',
        scope: ChangeScope.line,
        field: '__deleteLine',
        value: true,
        createdAt: DateTime(2026, 6, 25),
      ),
    );

    expect(write.documentPath, 'facturationLines/line-to-delete');
    expect(write.data['deleted'], isTrue);
    expect(write.data['lineId'], 'line-to-delete');
    expect(write.data['reference'], 'REF-DEL');
  });

  test('refuses to map a change without line id', () {
    expect(
      () => mapper.map(
        PendingChange(
          id: 'missing',
          lineId: '',
          reference: 'REF',
          scope: ChangeScope.line,
          field: 'name',
          value: 'Client',
          createdAt: DateTime(2026, 6, 23),
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('maps an annual field to the selected year document', () {
    final write = mapper.map(
      PendingChange(
        id: '2',
        lineId: 'line-002',
        reference: 'REF-002',
        scope: ChangeScope.annualBilling,
        field: 'monthlyRate',
        value: 150000,
        year: 2026,
        createdAt: DateTime(2026, 6, 22),
      ),
    );

    expect(write.documentPath, 'facturationLines/line-002/annees/2026');
    expect(write.data['annee'], 2026);
    expect(write.data['lineId'], 'line-002');
    expect(write.data['reference'], 'REF-002');
    expect(write.data['monthlyRate'], 150000);
  });

  test('maps an annual snapshot to the selected year document', () {
    final write = mapper.map(
      PendingChange(
        id: 'annual-snapshot',
        lineId: 'line-002',
        reference: 'REF-002',
        scope: ChangeScope.annualBilling,
        field: '__annualSnapshot',
        value: {
          'monthlyRate': 150000,
          'payments': {'Jan': 50000, 'Fev': 100000},
        },
        year: 2026,
        createdAt: DateTime(2026, 6, 23),
      ),
    );

    expect(write.documentPath, 'facturationLines/line-002/annees/2026');
    expect(write.data['annee'], 2026);
    expect(write.data['lineId'], 'line-002');
    expect(write.data['reference'], 'REF-002');
    expect(write.data['monthlyRate'], 150000);
    expect(write.data['paiements'], containsPair('Jan', 50000));
    expect(write.data['paiements'], containsPair('Mar', 0));
  });

  test('maps a payment cell to a nested payment field', () {
    final write = mapper.map(
      PendingChange(
        id: '3',
        lineId: 'line-003',
        reference: 'REF-003',
        scope: ChangeScope.paymentCell,
        field: 'Juin',
        value: 50000,
        year: 2026,
        createdAt: DateTime(2026, 6, 22),
      ),
    );

    expect(write.documentPath, 'facturationLines/line-003/annees/2026');
    expect(write.data['annee'], 2026);
    expect(write.data['lineId'], 'line-003');
    expect(write.data['reference'], 'REF-003');
    expect(write.data['paiements'], {'Juin': 50000});
  });
}
