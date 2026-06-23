import 'pending_change.dart';
import 'sync_queue.dart';

typedef PushChange = Future<void> Function(PendingChange change);

class SyncEngine {
  SyncEngine({required this.queue, required this.pushChange});

  final SyncQueue queue;
  final PushChange pushChange;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> flush() async {
    if (_running) return;
    _running = true;

    try {
      PendingChange? change;
      while ((change = queue.nextQueued()) != null) {
        final current = change!;
        queue.mark(current.id, ChangeState.syncing);

        try {
          await pushChange(current);
          queue.mark(current.id, ChangeState.synced);
        } catch (error) {
          queue.mark(
            current.id,
            ChangeState.failed,
            errorMessage: error.toString(),
          );
          break;
        }
      }
    } finally {
      _running = false;
    }
  }
}
