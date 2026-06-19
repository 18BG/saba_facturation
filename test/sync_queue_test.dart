import 'package:facturation_app/sync/pending_change.dart';
import 'package:facturation_app/sync/sync_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replaces queued changes on the same cell', () {
    final queue = SyncQueue();

    queue.enqueue(
      PendingChange(
        id: '1',
        reference: 'FAC-1',
        scope: ChangeScope.paymentCell,
        field: 'Jan',
        value: 1000,
        year: 2026,
        createdAt: DateTime(2026),
      ),
    );
    queue.enqueue(
      PendingChange(
        id: '2',
        reference: 'FAC-1',
        scope: ChangeScope.paymentCell,
        field: 'Jan',
        value: 2000,
        year: 2026,
        createdAt: DateTime(2026, 1, 2),
      ),
    );

    expect(queue.changes, hasLength(1));
    expect(queue.changes.single.id, '2');
    expect(queue.changes.single.value, 2000);
  });
}
