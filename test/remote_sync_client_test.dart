import 'package:facturation_app/sync/pending_change.dart';
import 'package:facturation_app/sync/remote_sync_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('not configured client ignores legacy reference-only changes', () async {
    const client = FirebaseNotConfiguredSyncClient();

    await client.pushChange(
      PendingChange(
        id: 'legacy-ref',
        lineId: '',
        reference: 'R',
        scope: ChangeScope.line,
        field: 'reference',
        value: 'R',
        createdAt: DateTime(2026, 6, 23),
      ),
    );
  });

  test(
    'not configured remote database client refuses to push changes',
    () async {
      const client = FirebaseNotConfiguredSyncClient();

      expect(client.isConfigured, isFalse);

      await expectLater(
        client.pushChange(
          PendingChange(
            id: '1',
            lineId: 'line-001',
            reference: 'REF-001',
            scope: ChangeScope.paymentCell,
            field: 'Jan',
            value: 1000,
            year: 2026,
            createdAt: DateTime(2026, 6, 23),
          ),
        ),
        throwsA(
          isA<FirebaseNotConfiguredException>().having(
            (error) => error.write.documentPath,
            'documentPath',
            'facturationLines/line-001/annees/2026',
          ),
        ),
      );
    },
  );
}
