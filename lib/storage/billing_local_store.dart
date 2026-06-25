import '../db/app_database.dart';
import '../models/billing_line.dart';
import '../sync/pending_change.dart';

class BillingLocalStore {
  BillingLocalStore({AppDatabase? database})
    : _database = database ?? AppDatabase.defaults();

  final AppDatabase _database;

  Future<List<BillingLine>?> loadLines() async {
    final dbLines = await _database.loadBillingLines();
    if (dbLines.isNotEmpty) {
      final migrated = _withGeneratedLineIds(dbLines);
      if (!identical(migrated, dbLines)) await saveLines(migrated);
      return migrated;
    }

    return dbLines;
  }

  List<BillingLine> _withGeneratedLineIds(List<BillingLine> lines) {
    var changed = false;
    final migrated = [
      for (final line in lines)
        if (isGeneratedBillingLineId(line.id))
          line
        else
          line.copyWith(id: newBillingLineId()),
    ];

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].id != migrated[i].id) {
        changed = true;
        break;
      }
    }

    return changed ? migrated : lines;
  }

  Future<void> saveLines(List<BillingLine> lines) async {
    await _database.replaceBillingLines(lines);
  }

  Future<void> enqueuePendingChanges(List<PendingChange> changes) async {
    await _database.enqueuePendingChanges(changes);
  }

  Future<int> pendingOutboxCount() async {
    return _database.pendingOutboxCount();
  }

  Future<List<PendingChange>> loadPendingOutboxChanges({
    int limit = 100,
  }) async {
    return _database.loadPendingOutboxChanges(limit: limit);
  }

  Future<void> markOutboxSyncing(String id) async {
    await _database.markOutboxSyncing(id);
  }

  Future<void> markOutboxSynced(String id, {DateTime? createdAt}) async {
    await _database.markOutboxSynced(id, createdAt: createdAt);
  }

  Future<void> markOutboxFailed(
    String id,
    String errorMessage, {
    DateTime? createdAt,
  }) async {
    await _database.markOutboxFailed(id, errorMessage, createdAt: createdAt);
  }

  Future<void> markOutboxConflict(
    String id,
    String errorMessage, {
    DateTime? createdAt,
  }) async {
    await _database.markOutboxConflict(id, errorMessage, createdAt: createdAt);
  }

  Future<void> clear() async {
    await _database.clearBillingData();
  }
}
