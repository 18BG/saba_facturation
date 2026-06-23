import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../db/app_database.dart';
import '../models/billing_line.dart';
import '../sync/pending_change.dart';

class BillingLocalStore {
  BillingLocalStore({
    AppDatabase? database,
    SharedPreferencesAsync? legacyPreferences,
  }) : _database = database ?? AppDatabase.defaults(),
       _legacyPreferences = legacyPreferences ?? SharedPreferencesAsync();

  static const _linesKey = 'facturation.lines.v1';
  static const _backupLinesKey = 'facturation.lines.backup.v1';

  final AppDatabase _database;
  final SharedPreferencesAsync _legacyPreferences;

  Future<List<BillingLine>?> loadLines() async {
    final dbLines = await _database.loadBillingLines();
    if (dbLines.isNotEmpty) {
      final migrated = _withGeneratedLineIds(dbLines);
      if (!identical(migrated, dbLines)) await saveLines(migrated);
      return migrated;
    }

    final legacyLines = await _loadLegacyLines();
    if (legacyLines != null && legacyLines.isNotEmpty) {
      await saveLines(legacyLines);
      return legacyLines;
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
    await _legacyPreferences.remove(_linesKey);
    await _legacyPreferences.remove(_backupLinesKey);
  }

  Future<List<BillingLine>?> _loadLegacyLines() async {
    final raw = await _legacyPreferences.getString(_linesKey);
    final lines = _decodeLines(raw);
    if (lines != null) return lines;

    final backupRaw = await _legacyPreferences.getString(_backupLinesKey);
    return _decodeLines(backupRaw);
  }

  List<BillingLine>? _decodeLines(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      return decoded
          .whereType<Map>()
          .map((item) => BillingLine.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on Object {
      return null;
    }
  }
}
