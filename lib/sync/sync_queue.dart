import 'pending_change.dart';

class SyncQueue {
  SyncQueue([List<PendingChange>? initialChanges])
      : _changes = List.of(initialChanges ?? const []);

  final List<PendingChange> _changes;

  List<PendingChange> get changes => List.unmodifiable(_changes);

  bool get hasPendingWork {
    return _changes.any((change) {
      return change.state == ChangeState.queued ||
          change.state == ChangeState.syncing ||
          change.state == ChangeState.failed;
    });
  }

  int get pendingCount {
    return _changes.where((change) => change.state != ChangeState.synced).length;
  }

  void enqueue(PendingChange change) {
    final existingIndex = _changes.indexWhere((candidate) {
      return candidate.reference == change.reference &&
          candidate.scope == change.scope &&
          candidate.field == change.field &&
          candidate.year == change.year &&
          candidate.state != ChangeState.syncing;
    });

    if (existingIndex == -1) {
      _changes.add(change);
      return;
    }

    _changes[existingIndex] = change;
  }

  PendingChange? nextQueued() {
    for (final change in _changes) {
      if (change.state == ChangeState.queued || change.state == ChangeState.failed) {
        return change;
      }
    }
    return null;
  }

  void mark(String id, ChangeState state, {String? errorMessage}) {
    final index = _changes.indexWhere((change) => change.id == id);
    if (index == -1) return;
    _changes[index] = _changes[index].copyWith(
      state: state,
      errorMessage: errorMessage,
    );
  }

  void markPendingAsSynced() {
    for (var i = 0; i < _changes.length; i++) {
      if (_changes[i].state != ChangeState.synced) {
        _changes[i] = _changes[i].copyWith(state: ChangeState.synced);
      }
    }
  }

  void pruneSynced() {
    _changes.removeWhere((change) => change.state == ChangeState.synced);
  }
}
