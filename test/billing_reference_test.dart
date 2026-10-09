import 'package:facturation_app/models/billing_line.dart';
import 'package:facturation_app/utils/billing_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingReference', () {
    test('returns empty string if odooId is empty', () {
      expect(nextBillingReference('', []), '');
      expect(nextBillingReference('   ', []), '');
    });

    test('generates suffix 1 for first line of an odooId', () {
      expect(nextBillingReference('1867', []), '1867-1');
    });

    test('increments suffix based on existing lines', () {
      final lines = [
        _line(id: '1', odooId: '1867', reference: '1867-1'),
        _line(id: '2', odooId: '1867', reference: '1867-2'),
        _line(id: '3', odooId: '9999', reference: '9999-5'),
      ];

      expect(nextBillingReference('1867', lines), '1867-3');
    });

    test('skips excludingLineId when updating an existing line', () {
      final lines = [
        _line(id: 'line-1', odooId: '1867', reference: '1867-1'),
        _line(id: 'line-2', odooId: '1867', reference: '1867-2'),
      ];

      expect(
        nextBillingReference('1867', lines, excludingLineId: 'line-2'),
        '1867-2',
      );
    });

    test('validates generated reference pattern', () {
      expect(isGeneratedBillingReference('1867-1', '1867'), isTrue);
      expect(isGeneratedBillingReference('1867-42', '1867'), isTrue);
      expect(isGeneratedBillingReference('18671', '1867'), isFalse);
      expect(isGeneratedBillingReference('1868-1', '1867'), isFalse);
      expect(isGeneratedBillingReference('', '1867'), isFalse);
    });
  });
}

BillingLine _line({
  required String id,
  required String odooId,
  required String reference,
}) {
  return BillingLine(
    id: id,
    odooId: odooId,
    reference: reference,
    name: 'Test',
    activity: 'GARDIENNAGE',
    startDate: '',
    endDate: '',
    contractNature: '',
    billedStaff: 0,
    paidStaff: 0,
    annualBillings: const {},
    status: 'Actif',
    statusComment: '',
    syncState: SyncState.synced,
  );
}
