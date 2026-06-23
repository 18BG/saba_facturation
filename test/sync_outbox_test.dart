import 'package:drift/native.dart';
import 'package:facturation_app/db/app_database.dart';
import 'package:facturation_app/models/billing_line.dart';
import 'package:facturation_app/storage/billing_local_store.dart';
import 'package:facturation_app/sync/pending_change.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database preserves stable billing line ids', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final line = BillingLine(
      id: 'stable-line-id',
      reference: 'REF-001',
      name: 'Client',
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

    await database.replaceBillingLines([line]);

    final loaded = await database.loadBillingLines();

    expect(loaded.single.id, 'stable-line-id');
    expect(loaded.single.reference, 'REF-001');
  });

  test('local store migrates legacy reference-based line ids', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = BillingLocalStore(database: database);

    final line = BillingLine(
      id: 'ref_REF_001',
      reference: 'REF-001',
      name: 'Client',
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

    await database.replaceBillingLines([line]);

    final loaded = await store.loadLines();

    expect(loaded, isNotNull);
    expect(loaded!.single.id, isNot('ref_REF_001'));
    expect(isGeneratedBillingLineId(loaded.single.id), isTrue);
    expect(loaded.single.reference, 'REF-001');
  });

  test('outbox replaces repeated changes on the same field', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'first',
        reference: 'REF-001',
        scope: ChangeScope.paymentCell,
        field: 'Jan',
        value: 1000,
        year: 2026,
        createdAt: DateTime(2026),
      ),
    ]);
    expect(await database.pendingOutboxCount(), 1);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'second',
        reference: 'REF-001',
        scope: ChangeScope.paymentCell,
        field: 'Jan',
        value: 2500,
        year: 2026,
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);
    expect(await database.pendingOutboxCount(), 1);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'third',
        reference: 'REF-001',
        scope: ChangeScope.paymentCell,
        field: 'Fev',
        value: 3000,
        year: 2026,
        createdAt: DateTime(2026, 1, 3),
      ),
    ]);
    expect(await database.pendingOutboxCount(), 2);
  });

  test('loads pending changes with deterministic outbox ids', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'typed-change',
        lineId: 'line-001',
        reference: 'REF-001',
        scope: ChangeScope.annualBilling,
        field: 'monthlyRate',
        value: 150000.0,
        year: 2026,
        createdAt: DateTime(2026),
      ),
    ]);

    final changes = await database.loadPendingOutboxChanges();

    expect(changes, hasLength(1));
    expect(changes.single.id, 'line_001__annualBilling__2026__monthlyRate');
    expect(changes.single.lineId, 'line-001');
    expect(changes.single.reference, 'REF-001');
    expect(changes.single.scope, ChangeScope.annualBilling);
    expect(changes.single.field, 'monthlyRate');
    expect(changes.single.value, 150000.0);
    expect(changes.single.year, 2026);
  });

  test('outbox uses stable line id when reference changes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'first',
        lineId: 'stable-line',
        reference: 'R',
        scope: ChangeScope.line,
        field: 'reference',
        value: 'R',
        createdAt: DateTime(2026),
      ),
    ]);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'second',
        lineId: 'stable-line',
        reference: 'REF-FINALE',
        scope: ChangeScope.line,
        field: 'reference',
        value: 'REF-FINALE',
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);

    final changes = await database.loadPendingOutboxChanges();

    expect(changes, hasLength(1));
    expect(changes.single.lineId, 'stable-line');
    expect(changes.single.reference, 'REF-FINALE');
    expect(changes.single.value, 'REF-FINALE');
  });

  test('synced outbox item is removed from pending count', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'change',
        reference: 'REF-002',
        scope: ChangeScope.line,
        field: 'name',
        value: 'Client A',
        createdAt: DateTime(2026),
      ),
    ]);

    final change = (await database.loadPendingOutboxChanges()).single;
    await database.markOutboxSyncing(change.id);
    expect(await database.pendingOutboxCount(), 1);

    await database.markOutboxSynced(change.id, createdAt: change.createdAt);
    expect(await database.pendingOutboxCount(), 0);
    expect(await database.loadPendingOutboxChanges(), isEmpty);
  });

  test('failed outbox item remains pending and keeps the error', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'change',
        reference: 'REF-003',
        scope: ChangeScope.paymentCell,
        field: 'Mar',
        value: 800,
        year: 2026,
        createdAt: DateTime(2026),
      ),
    ]);

    final change = (await database.loadPendingOutboxChanges()).single;
    await database.markOutboxSyncing(change.id);
    await database.markOutboxFailed(
      change.id,
      'network unavailable',
      createdAt: change.createdAt,
    );

    expect(await database.pendingOutboxCount(), 1);
    final failed = (await database.loadPendingOutboxChanges()).single;
    expect(failed.state, ChangeState.failed);
    expect(failed.errorMessage, 'network unavailable');
  });

  test('sync confirmation does not delete a newer same-cell edit', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'old',
        reference: 'REF-004',
        scope: ChangeScope.paymentCell,
        field: 'Avr',
        value: 100,
        year: 2026,
        createdAt: DateTime(2026, 1),
      ),
    ]);

    final oldChange = (await database.loadPendingOutboxChanges()).single;
    await database.markOutboxSyncing(oldChange.id);

    await database.enqueuePendingChanges([
      PendingChange(
        id: 'new',
        reference: 'REF-004',
        scope: ChangeScope.paymentCell,
        field: 'Avr',
        value: 300,
        year: 2026,
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);

    await database.markOutboxSynced(
      oldChange.id,
      createdAt: oldChange.createdAt,
    );

    final remaining = (await database.loadPendingOutboxChanges()).single;
    expect(remaining.value, 300);
    expect(await database.pendingOutboxCount(), 1);
  });
}
