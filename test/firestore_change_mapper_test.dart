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
