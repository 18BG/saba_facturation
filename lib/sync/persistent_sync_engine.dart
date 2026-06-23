import 'pending_change.dart';

typedef LoadPendingChanges = Future<List<PendingChange>> Function(int limit);
typedef MarkOutboxChange = Future<void> Function(String id);
typedef MarkOutboxFailure =
    Future<void> Function(PendingChange change, String errorMessage);
typedef MarkOutboxSynced = Future<void> Function(PendingChange change);
typedef PushPersistentChange = Future<void> Function(PendingChange change);

class PersistentSyncEngine {
  PersistentSyncEngine({
    required this.loadPendingChanges,
    required this.markSyncing,
    required this.markSynced,
    required this.markFailed,
    required this.pushChange,
  });

  final LoadPendingChanges loadPendingChanges;
  final MarkOutboxChange markSyncing;
  final MarkOutboxSynced markSynced;
  final MarkOutboxFailure markFailed;
  final PushPersistentChange pushChange;

  bool _running = false;

  bool get isRunning => _running;

  Future<SyncFlushResult> flush({int limit = 50}) async {
    if (_running) return const SyncFlushResult(skipped: true);
    _running = true;

    var pushed = 0;
    var failed = 0;

    try {
      final changes = await loadPendingChanges(limit);
      for (final change in changes) {
        await markSyncing(change.id);

        try {
          await pushChange(change);
          await markSynced(change);
          pushed++;
        } on Object catch (error) {
          failed++;
          await markFailed(change, error.toString());
          break;
        }
      }

      return SyncFlushResult(
        loaded: changes.length,
        pushed: pushed,
        failed: failed,
      );
    } finally {
      _running = false;
    }
  }
}

class SyncFlushResult {
  const SyncFlushResult({
    this.loaded = 0,
    this.pushed = 0,
    this.failed = 0,
    this.skipped = false,
  });

  final int loaded;
  final int pushed;
  final int failed;
  final bool skipped;
}
