import 'package:facturation_app/data/sample_billing_data.dart';
import 'package:facturation_app/pages/quick_payments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the payments grid virtualized and searchable', (
    tester,
  ) async {
    final seed = buildSampleBillingLines().first;
    final lines = [
      for (var index = 0; index < 2000; index++)
        seed.copyWith(
          odooId: 'ORYX-$index',
          appellationComptable: 'Client $index',
          reference: 'REF-$index',
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickPaymentsPage(
            lines: lines,
            selectedYear: 2026,
            onYearChanged: (_) {},
            onLinesChanged: (_) {},
            onPendingChanges: <PendingChange>(_) {},
            onOpenExport: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Paiements clients'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'ORYX-1999');
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('ORYX-1999'), findsNWidgets(2));

    await tester.tap(find.text('ORYX-1999').last);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('TOTAL'), findsOneWidget);
  });
}
