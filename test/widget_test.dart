import 'package:facturation_app/data/sample_billing_data.dart';
import 'package:facturation_app/main.dart';
import 'package:facturation_app/sync/remote_sync_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the facturation workspace', (tester) async {
    await tester.pumpWidget(
      FacturationApp(
        initialLines: buildSampleBillingLines(),
        persistLocalData: false,
        remoteSyncClient: const FirebaseNotConfiguredSyncClient(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reference'), findsOneWidget);
    expect(find.text('Rechercher'), findsOneWidget);
    expect(find.text('NETTOYAGE'), findsWidgets);
  });
}
