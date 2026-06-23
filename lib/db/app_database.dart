import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/billing_line.dart';
import '../sync/pending_change.dart';

part 'app_database.g.dart';

class BillingLineRecords extends Table {
  TextColumn get localId => text()();
  TextColumn get reference => text().withDefault(const Constant(''))();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get activity => text().withDefault(const Constant(''))();
  TextColumn get startDate => text().withDefault(const Constant(''))();
  TextColumn get endDate => text().withDefault(const Constant(''))();
  TextColumn get contractNature => text().withDefault(const Constant(''))();
  IntColumn get billedStaff => integer().withDefault(const Constant(0))();
  IntColumn get paidStaff => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('Actif'))();
  TextColumn get statusComment => text().withDefault(const Constant(''))();
  TextColumn get syncState => text().withDefault(const Constant('synced'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};
}

class AnnualBillingRecords extends Table {
  TextColumn get lineLocalId => text()();
  IntColumn get year => integer()();
  RealColumn get monthlyRate => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {lineLocalId, year};
}

class MonthlyPaymentRecords extends Table {
  TextColumn get lineLocalId => text()();
  IntColumn get year => integer()();
  IntColumn get monthIndex => integer()();
  TextColumn get monthKey => text()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {lineLocalId, year, monthIndex};
}

class SyncOutboxRecords extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get scope => text()();
  TextColumn get field => text()();
  TextColumn get operation => text().withDefault(const Constant('upsert'))();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  IntColumn get year => integer().nullable()();
  IntColumn get monthIndex => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    BillingLineRecords,
    AnnualBillingRecords,
    MonthlyPaymentRecords,
    SyncOutboxRecords,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
    : super(
        driftDatabase(
          name: 'facturation_app',
          native: const DriftNativeOptions(),
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;

  Future<List<BillingLine>> loadBillingLines() async {
    final lineRows =
        await (select(billingLineRecords)..orderBy([
              (table) => OrderingTerm(expression: table.name),
              (table) => OrderingTerm(expression: table.reference),
            ]))
            .get();
    final annualRows = await select(annualBillingRecords).get();
    final paymentRows = await select(monthlyPaymentRecords).get();

    final annualByLine = <String, List<AnnualBillingRecord>>{};
    for (final annual in annualRows) {
      annualByLine.putIfAbsent(annual.lineLocalId, () => []).add(annual);
    }

    final paymentsByLineYear = <String, List<MonthlyPaymentRecord>>{};
    for (final payment in paymentRows) {
      final key = _lineYearKey(payment.lineLocalId, payment.year);
      paymentsByLineYear.putIfAbsent(key, () => []).add(payment);
    }

    return [
      for (final row in lineRows)
        BillingLine(
          id: row.localId,
          reference: row.reference,
          name: row.name,
          activity: row.activity,
          startDate: row.startDate,
          endDate: row.endDate,
          contractNature: row.contractNature,
          billedStaff: row.billedStaff,
          paidStaff: row.paidStaff,
          annualBillings: {
            for (final annual
                in annualByLine[row.localId] ?? const <AnnualBillingRecord>[])
              annual.year: AnnualBillingData(
                monthlyRate: annual.monthlyRate,
                payments: _paymentsFor(
                  row.localId,
                  annual.year,
                  paymentsByLineYear,
                ),
              ),
          },
          status: row.status,
          statusComment: row.statusComment,
          syncState: _syncStateFromName(row.syncState),
        ),
    ];
  }

  Future<void> replaceBillingLines(List<BillingLine> lines) async {
    final now = DateTime.now();
    final usedIds = <String>{};

    await transaction(() async {
      await delete(monthlyPaymentRecords).go();
      await delete(annualBillingRecords).go();
      await delete(billingLineRecords).go();

      await batch((batch) {
        for (var index = 0; index < lines.length; index++) {
          final line = lines[index];
          final lineId = _stableLineId(line, index, usedIds);

          batch.insert(
            billingLineRecords,
            BillingLineRecordsCompanion.insert(
              localId: lineId,
              reference: Value(line.reference),
              name: Value(line.name),
              activity: Value(line.activity),
              startDate: Value(line.startDate),
              endDate: Value(line.endDate),
              contractNature: Value(line.contractNature),
              billedStaff: Value(line.billedStaff),
              paidStaff: Value(line.paidStaff),
              status: Value(line.status),
              statusComment: Value(line.statusComment),
              syncState: Value(line.syncState.name),
              updatedAt: now,
            ),
          );

          for (final entry in line.annualBillings.entries) {
            batch.insert(
              annualBillingRecords,
              AnnualBillingRecordsCompanion.insert(
                lineLocalId: lineId,
                year: entry.key,
                monthlyRate: Value(entry.value.monthlyRate),
                updatedAt: now,
              ),
            );

            for (var monthIndex = 0; monthIndex < months.length; monthIndex++) {
              final monthKey = months[monthIndex];
              batch.insert(
                monthlyPaymentRecords,
                MonthlyPaymentRecordsCompanion.insert(
                  lineLocalId: lineId,
                  year: entry.key,
                  monthIndex: monthIndex + 1,
                  monthKey: monthKey,
                  amount: Value(entry.value.payments[monthKey] ?? 0),
                  updatedAt: now,
                ),
              );
            }
          }
        }
      });
    });
  }

  Future<void> clearBillingData() async {
    await transaction(() async {
      await delete(monthlyPaymentRecords).go();
      await delete(annualBillingRecords).go();
      await delete(syncOutboxRecords).go();
      await delete(billingLineRecords).go();
    });
  }

  Future<void> enqueuePendingChanges(List<PendingChange> changes) async {
    if (changes.isEmpty) return;

    final now = DateTime.now();
    await batch((batch) {
      for (final change in changes) {
        final monthIndex = change.scope == ChangeScope.paymentCell
            ? months.indexOf(change.field) + 1
            : null;
        final outboxId = _outboxId(change);

        batch.insert(
          syncOutboxRecords,
          SyncOutboxRecordsCompanion.insert(
            id: outboxId,
            entityType: 'billingLine',
            entityId: change.lineId,
            scope: change.scope.name,
            field: change.field,
            operation: const Value('upsert'),
            payloadJson: Value(
              jsonEncode({
                'value': change.value,
                'lineId': change.lineId,
                'reference': change.reference,
              }),
            ),
            year: Value(change.year),
            monthIndex: Value(monthIndex == 0 ? null : monthIndex),
            status: Value(_outboxStatus(change.state)),
            attempts: const Value(0),
            lastError: Value(change.errorMessage),
            createdAt: change.createdAt,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<int> pendingOutboxCount() async {
    final rows =
        await (select(syncOutboxRecords)..where(
              (row) =>
                  row.status.equals('pending') |
                  row.status.equals('syncing') |
                  row.status.equals('failed') |
                  row.status.equals('conflict'),
            ))
            .get();
    return rows.length;
  }

  Future<List<PendingChange>> loadPendingOutboxChanges({
    int limit = 100,
  }) async {
    final rows =
        await (select(syncOutboxRecords)
              ..where(
                (row) =>
                    row.status.equals('pending') | row.status.equals('failed'),
              )
              ..orderBy([(row) => OrderingTerm(expression: row.updatedAt)])
              ..limit(limit))
            .get();

    return rows.map(_pendingChangeFromOutbox).toList();
  }

  Future<void> markOutboxSyncing(String id) async {
    final existing = await (select(
      syncOutboxRecords,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (existing == null) return;

    await (update(syncOutboxRecords)..where((row) => row.id.equals(id))).write(
      SyncOutboxRecordsCompanion(
        status: const Value('syncing'),
        attempts: Value(existing.attempts + 1),
        lastError: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markOutboxSynced(String id, {DateTime? createdAt}) async {
    await (delete(syncOutboxRecords)..where((row) {
          final matchesId = row.id.equals(id);
          if (createdAt == null) return matchesId;
          return matchesId & row.createdAt.equals(createdAt);
        }))
        .go();
  }

  Future<void> markOutboxFailed(
    String id,
    String errorMessage, {
    DateTime? createdAt,
  }) async {
    await (update(syncOutboxRecords)..where((row) {
          final matchesId = row.id.equals(id);
          if (createdAt == null) return matchesId;
          return matchesId & row.createdAt.equals(createdAt);
        }))
        .write(
          SyncOutboxRecordsCompanion(
            status: const Value('failed'),
            lastError: Value(errorMessage),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> markOutboxConflict(
    String id,
    String errorMessage, {
    DateTime? createdAt,
  }) async {
    await (update(syncOutboxRecords)..where((row) {
          final matchesId = row.id.equals(id);
          if (createdAt == null) return matchesId;
          return matchesId & row.createdAt.equals(createdAt);
        }))
        .write(
          SyncOutboxRecordsCompanion(
            status: const Value('conflict'),
            lastError: Value(errorMessage),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Map<String, double> _paymentsFor(
    String lineId,
    int year,
    Map<String, List<MonthlyPaymentRecord>> paymentsByLineYear,
  ) {
    final result = {for (final month in months) month: 0.0};
    for (final payment
        in paymentsByLineYear[_lineYearKey(lineId, year)] ??
            const <MonthlyPaymentRecord>[]) {
      if (payment.monthIndex < 1 || payment.monthIndex > months.length) {
        continue;
      }
      result[months[payment.monthIndex - 1]] = payment.amount;
    }
    return result;
  }

  String _lineYearKey(String lineId, int year) => '$lineId::$year';

  String _outboxId(PendingChange change) {
    final raw = [
      change.lineId,
      change.scope.name,
      change.year?.toString() ?? 'line',
      change.field,
    ].join('__');
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
  }

  String _outboxStatus(ChangeState state) {
    return switch (state) {
      ChangeState.queued => 'pending',
      ChangeState.syncing => 'syncing',
      ChangeState.synced => 'synced',
      ChangeState.failed => 'failed',
      ChangeState.conflict => 'conflict',
    };
  }

  PendingChange _pendingChangeFromOutbox(SyncOutboxRecord row) {
    final payloadLineId = _outboxPayloadLineId(row.payloadJson);
    final payloadReference = _outboxPayloadReference(row.payloadJson);
    final isLegacyReferenceOnly =
        row.field == 'reference' && payloadLineId == null;

    return PendingChange(
      id: row.id,
      lineId: isLegacyReferenceOnly ? '' : payloadLineId ?? row.entityId,
      reference: payloadReference ?? row.entityId,
      scope: _changeScopeFromName(row.scope),
      field: row.field,
      value: _outboxPayloadValue(row.payloadJson),
      createdAt: row.createdAt,
      year: row.year,
      state: _changeStateFromStatus(row.status),
      errorMessage: row.lastError,
    );
  }

  Object? _outboxPayloadValue(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) return decoded['value'];
      if (decoded is Map) return decoded['value'];
      return decoded;
    } on Object {
      return null;
    }
  }

  String? _outboxPayloadReference(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) {
        final reference = decoded['reference'];
        return reference is String ? reference : null;
      }
      if (decoded is Map) {
        final reference = decoded['reference'];
        return reference is String ? reference : null;
      }
      return null;
    } on Object {
      return null;
    }
  }

  String? _outboxPayloadLineId(String payloadJson) {
    try {
      final decoded = jsonDecode(payloadJson);
      if (decoded is Map<String, dynamic>) {
        final lineId = decoded['lineId'];
        return lineId is String ? lineId : null;
      }
      if (decoded is Map) {
        final lineId = decoded['lineId'];
        return lineId is String ? lineId : null;
      }
      return null;
    } on Object {
      return null;
    }
  }

  ChangeScope _changeScopeFromName(String value) {
    return ChangeScope.values.firstWhere(
      (scope) => scope.name == value,
      orElse: () => ChangeScope.line,
    );
  }

  ChangeState _changeStateFromStatus(String value) {
    return switch (value) {
      'syncing' => ChangeState.syncing,
      'synced' => ChangeState.synced,
      'failed' => ChangeState.failed,
      'conflict' => ChangeState.conflict,
      _ => ChangeState.queued,
    };
  }

  String _stableLineId(BillingLine line, int index, Set<String> usedIds) {
    final base = line.id.trim().isNotEmpty ? line.id : 'line_$index';
    var candidate = base.isEmpty ? 'line_$index' : base;
    var suffix = 2;
    while (usedIds.contains(candidate)) {
      candidate = '${base}_$suffix';
      suffix++;
    }
    usedIds.add(candidate);
    return candidate;
  }

  SyncState _syncStateFromName(String value) {
    return SyncState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => SyncState.synced,
    );
  }
}
