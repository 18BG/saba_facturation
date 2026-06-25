import 'package:facturation_app/models/billing_line.dart';
import 'package:facturation_app/sync/firestore_line_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FirestoreLineMapper();

  test('rebuilds a billing line from a remote line and annual documents', () {
    final line = mapper.fromRemote(
      documentId: 'line-doc-id',
      lineData: {
        'lineId': 'line-stable-id',
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
      },
      annualDocuments: const [
        RemoteAnnualBillingDocument(
          documentId: '2026',
          data: {
            'annee': 2026,
            'monthlyRate': 1000,
            'paiements': {'Jan': 500, 'Fev': 1000},
          },
        ),
      ],
    );

    expect(line.id, 'line-stable-id');
    expect(line.reference, 'REF-001');
    expect(line.name, 'Client A');
    expect(line.activity, 'NETTOYAGE');
    expect(line.syncState, SyncState.synced);
    expect(line.annualBilling(2026).monthlyRate, 1000);
    expect(line.annualBilling(2026).payments['Jan'], 500);
    expect(line.annualBilling(2026).payments['Mar'], 0);
  });

  test('uses the document id when the remote lineId is missing', () {
    final line = mapper.fromRemote(
      documentId: 'document-id',
      lineData: const {'reference': 'REF-002'},
      annualDocuments: const [],
    );

    expect(line.id, 'document-id');
    expect(line.reference, 'REF-002');
  });

  test('detects soft deleted remote lines', () {
    expect(mapper.isDeleted(const {'deleted': true}), isTrue);
    expect(mapper.isDeleted(const {'deleted': false}), isFalse);
    expect(mapper.isDeleted(const {}), isFalse);
  });
}
