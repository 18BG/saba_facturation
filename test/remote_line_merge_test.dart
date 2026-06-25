import 'package:facturation_app/models/billing_line.dart';
import 'package:facturation_app/sync/remote_line_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adds remote lines when local storage is empty', () {
    final remoteLine = _line(id: 'line-001', reference: 'REF-001');

    final result = mergeCleanLocalLinesWithRemote(
      localLines: const [],
      remoteLines: [remoteLine],
    );

    expect(result.changed, isTrue);
    expect(result.added, 1);
    expect(result.updated, 0);
    expect(result.lines.single.id, 'line-001');
  });

  test('updates an existing clean local line from remote', () {
    final result = mergeCleanLocalLinesWithRemote(
      localLines: [_line(id: 'line-001', reference: 'REF-001', name: 'Old')],
      remoteLines: [_line(id: 'line-001', reference: 'REF-001', name: 'New')],
    );

    expect(result.changed, isTrue);
    expect(result.added, 0);
    expect(result.updated, 1);
    expect(result.lines.single.name, 'New');
    expect(result.lines.single.syncState, SyncState.synced);
  });

  test('preserves local-only lines because deletion is outside the MVP', () {
    final result = mergeCleanLocalLinesWithRemote(
      localLines: [_line(id: 'local-only', reference: 'REF-LOCAL')],
      remoteLines: const [],
    );

    expect(result.changed, isFalse);
    expect(result.preservedLocalOnly, 1);
    expect(result.lines.single.id, 'local-only');
  });

  test('keeps local order and appends new remote lines', () {
    final result = mergeCleanLocalLinesWithRemote(
      localLines: [
        _line(id: 'line-001', reference: 'REF-001'),
        _line(id: 'line-002', reference: 'REF-002'),
      ],
      remoteLines: [
        _line(id: 'line-002', reference: 'REF-002'),
        _line(id: 'line-003', reference: 'REF-003'),
        _line(id: 'line-001', reference: 'REF-001'),
      ],
    );

    expect(result.changed, isTrue);
    expect(result.added, 1);
    expect(result.updated, 0);
    expect(result.lines.map((line) => line.id), [
      'line-001',
      'line-002',
      'line-003',
    ]);
  });
}

BillingLine _line({
  required String id,
  required String reference,
  String name = 'Client',
}) {
  return BillingLine(
    id: id,
    reference: reference,
    name: name,
    activity: 'GARDIENNAGE',
    startDate: '',
    endDate: '',
    contractNature: '',
    billedStaff: 1,
    paidStaff: 1,
    annualBillings: {2026: AnnualBillingData.empty()},
    status: 'Actif',
    statusComment: '',
    syncState: SyncState.synced,
  );
}
