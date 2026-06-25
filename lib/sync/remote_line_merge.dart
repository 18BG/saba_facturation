import 'dart:convert';

import '../models/billing_line.dart';

class RemoteLineMergeResult {
  const RemoteLineMergeResult({
    required this.lines,
    required this.added,
    required this.updated,
    required this.preservedLocalOnly,
  });

  final List<BillingLine> lines;
  final int added;
  final int updated;
  final int preservedLocalOnly;

  bool get changed => added > 0 || updated > 0;
}

RemoteLineMergeResult mergeCleanLocalLinesWithRemote({
  required List<BillingLine> localLines,
  required List<BillingLine> remoteLines,
}) {
  final remoteById = {for (final line in remoteLines) line.id: line};
  final consumedRemoteIds = <String>{};
  final merged = <BillingLine>[];
  var updated = 0;
  var preservedLocalOnly = 0;

  for (final localLine in localLines) {
    final remoteLine = remoteById[localLine.id];
    if (remoteLine == null) {
      preservedLocalOnly++;
      merged.add(localLine);
      continue;
    }

    consumedRemoteIds.add(localLine.id);
    if (_sameLine(localLine, remoteLine)) {
      merged.add(localLine);
    } else {
      updated++;
      merged.add(remoteLine.copyWith(syncState: SyncState.synced));
    }
  }

  final addedLines = [
    for (final remoteLine in remoteLines)
      if (!consumedRemoteIds.contains(remoteLine.id))
        remoteLine.copyWith(syncState: SyncState.synced),
  ];

  return RemoteLineMergeResult(
    lines: [...merged, ...addedLines],
    added: addedLines.length,
    updated: updated,
    preservedLocalOnly: preservedLocalOnly,
  );
}

bool _sameLine(BillingLine a, BillingLine b) {
  return jsonEncode(a.copyWith(syncState: SyncState.synced).toJson()) ==
      jsonEncode(b.copyWith(syncState: SyncState.synced).toJson());
}
