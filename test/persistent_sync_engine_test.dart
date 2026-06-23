import 'package:facturation_app/sync/pending_change.dart';
import 'package:facturation_app/sync/persistent_sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flush pushes changes and marks them synced', () async {
    final events = <String>[];
    final changes = [
      PendingChange(
        id: 'one',
        reference: 'REF-001',
        scope: ChangeScope.line,
        field: 'name',
        value: 'Client A',
        createdAt: DateTime(2026),
      ),
      PendingChange(
        id: 'two',
        reference: 'REF-002',
        scope: ChangeScope.line,
        field: 'name',
        value: 'Client B',
        createdAt: DateTime(2026),
      ),
    ];

    final engine = PersistentSyncEngine(
      loadPendingChanges: (limit) async => changes.take(limit).toList(),
      markSyncing: (id) async => events.add('syncing:$id'),
      markSynced: (change) async => events.add('synced:${change.id}'),
      markFailed: (change, error) async =>
          events.add('failed:${change.id}:$error'),
      pushChange: (change) async => events.add('push:${change.id}'),
    );

    final result = await engine.flush();

    expect(result.loaded, 2);
    expect(result.pushed, 2);
    expect(result.failed, 0);
    expect(events, [
      'syncing:one',
      'push:one',
      'synced:one',
      'syncing:two',
      'push:two',
      'synced:two',
    ]);
  });

  test('flush stops on first failure and keeps the item failed', () async {
    final events = <String>[];
    final changes = [
      PendingChange(
        id: 'one',
        reference: 'REF-001',
        scope: ChangeScope.line,
        field: 'name',
        value: 'Client A',
        createdAt: DateTime(2026),
      ),
      PendingChange(
        id: 'two',
        reference: 'REF-002',
        scope: ChangeScope.line,
        field: 'name',
        value: 'Client B',
        createdAt: DateTime(2026),
      ),
    ];

    final engine = PersistentSyncEngine(
      loadPendingChanges: (limit) async => changes.take(limit).toList(),
      markSyncing: (id) async => events.add('syncing:$id'),
      markSynced: (change) async => events.add('synced:${change.id}'),
      markFailed: (change, error) async =>
          events.add('failed:${change.id}:$error'),
      pushChange: (change) async {
        events.add('push:${change.id}');
        throw StateError('offline');
      },
    );

    final result = await engine.flush();

    expect(result.loaded, 2);
    expect(result.pushed, 0);
    expect(result.failed, 1);
    expect(events, [
      'syncing:one',
      'push:one',
      'failed:one:Bad state: offline',
    ]);
  });
}
