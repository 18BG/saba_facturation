import 'dart:async';

import 'package:flutter/material.dart';

import 'models/billing_line.dart';
import 'pages/dashboard_page.dart';
import 'pages/export_page.dart';
import 'pages/facturation_page.dart';
import 'pages/import_page.dart';
import 'pages/settings_page.dart';
import 'storage/billing_local_store.dart';
import 'sync/billing_snapshot_changes.dart';
import 'sync/pending_change.dart';
import 'sync/persistent_sync_engine.dart';
import 'sync/remote_sync_client.dart';
import 'sync/remote_line_merge.dart';
import 'theme/app_icons.dart';
import 'widgets/app_icon.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialLines,
    this.persistLocalData = true,
    this.remoteSyncClient,
  });

  final List<BillingLine>? initialLines;
  final bool persistLocalData;
  final RemoteSyncClient? remoteSyncClient;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  BillingLocalStore? _localStore;
  int _selectedIndex = 0;
  int _selectedYear = DateTime.now().year;
  List<BillingLine> _lines = const [];
  bool _isLoading = true;
  String? _startupWarning;
  String? _syncInfo;
  int _pendingOutboxCount = 0;
  bool _offline = false;
  bool _isSyncing = false;
  bool _navigationCollapsed = false;
  late final RemoteSyncClient _remoteSyncClient;
  Timer? _persistTimer;
  Timer? _syncTimer;
  Timer? _remotePullTimer;
  PersistentSyncEngine? _syncEngine;

  @override
  void initState() {
    super.initState();
    _remoteSyncClient = widget.remoteSyncClient ?? FirestoreRemoteSyncClient();
    _localStore = widget.persistLocalData ? BillingLocalStore() : null;
    if (_localStore != null) {
      _syncEngine = PersistentSyncEngine(
        loadPendingChanges: (limit) {
          return _localStore!.loadPendingOutboxChanges(limit: limit);
        },
        markSyncing: _localStore!.markOutboxSyncing,
        markSynced: (change) {
          return _localStore!.markOutboxSynced(
            change.id,
            createdAt: change.createdAt,
          );
        },
        markFailed: (change, errorMessage) {
          return _localStore!.markOutboxFailed(
            change.id,
            errorMessage,
            createdAt: change.createdAt,
          );
        },
        pushChange: _pushChangeToRemote,
      );
    }
    _loadLines();
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    _syncTimer?.cancel();
    _remotePullTimer?.cancel();
    if (_localStore != null && _lines.isNotEmpty) {
      unawaited(_persistLines(List<BillingLine>.of(_lines)));
    }
    super.dispose();
  }

  Future<void> _loadLines() async {
    await Future.delayed(const Duration(seconds: 2));
    if (widget.initialLines != null) {
      setState(() {
        _lines = List.of(widget.initialLines!);
        _isLoading = false;
      });
      return;
    }

    try {
      final savedLines = await _localStore?.loadLines();
      if (!mounted) return;
      setState(() {
        _lines = savedLines ?? <BillingLine>[];
        _isLoading = false;
      });
      unawaited(
        _refreshPendingOutboxCount().then((_) {
          _queueSyncAttempt();
          _queueRemotePull();
        }),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _lines = <BillingLine>[];
        _isLoading = false;
        _startupWarning =
            'La base locale n a pas pu etre chargee. Les donnees existantes n ont pas ete supprimees. Detail : $error';
      });
    }
  }

  void _saveLines(List<BillingLine> lines) {
    setState(() => _lines = List.of(lines));
    _schedulePersist(lines);
  }

  void _schedulePersist(List<BillingLine> lines) {
    if (_localStore == null) return;
    final snapshot = List<BillingLine>.of(lines);
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistLines(snapshot));
    });
  }

  Future<void> _persistLines(List<BillingLine> lines) async {
    try {
      await _localStore?.saveLines(lines);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _startupWarning =
            'Les donnees sont gardees en memoire, mais la sauvegarde locale a echoue. Detail : $error';
      });
    }
  }

  void _savePendingChanges(List<PendingChange> changes) {
    if (changes.isEmpty || _localStore == null) return;
    _remotePullTimer?.cancel();
    unawaited(_persistPendingChanges(List<PendingChange>.of(changes)));
  }

  Future<void> _persistPendingChanges(List<PendingChange> changes) async {
    try {
      await _localStore?.enqueuePendingChanges(changes);
      await _refreshPendingOutboxCount();
      _queueSyncAttempt();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _startupWarning =
            'La modification est visible, mais la file de sync locale n a pas pu etre mise a jour. Detail : $error';
      });
    }
  }

  Future<void> _resetLocalData() async {
    _persistTimer?.cancel();
    await _localStore?.clear();
    if (!mounted) return;
    setState(() {
      _lines = <BillingLine>[];
      _pendingOutboxCount = 0;
      _isSyncing = false;
      _syncInfo = null;
      _startupWarning = null;
    });
  }

  Future<void> _resetRemoteData() async {
    if (!_remoteSyncClient.isConfigured) {
      setState(() {
        _startupWarning = 'La base distante n est pas configuree.';
      });
      return;
    }

    try {
      await _remoteSyncClient.clearRemoteData();
      if (!mounted) return;
      setState(() {
        _syncInfo = 'Base distante reinitialisee.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _startupWarning =
            'La reinitialisation distante a echoue. Detail : $error';
      });
    }
  }

  void _setOffline(bool value) {
    setState(() => _offline = value);
    if (!value) {
      _queueSyncAttempt(delay: const Duration(milliseconds: 150));
      _queueRemotePull(delay: const Duration(milliseconds: 500));
    }
  }

  void _queueSyncAttempt({Duration delay = const Duration(milliseconds: 900)}) {
    if (_syncEngine == null || _offline || !_remoteSyncClient.isConfigured) {
      return;
    }
    _syncTimer?.cancel();
    _syncTimer = Timer(delay, () {
      unawaited(_flushSyncOutbox());
    });
  }

  Future<void> _flushSyncOutbox() async {
    if (_syncEngine == null ||
        _offline ||
        _isSyncing ||
        !_remoteSyncClient.isConfigured) {
      return;
    }

    setState(() => _isSyncing = true);
    try {
      final result = await _syncEngine!.flush();
      await _refreshPendingOutboxCount();
      if (!mounted) return;

      if (result.failed == 0 && result.pushed > 0 && _pendingOutboxCount == 0) {
        final nextLines = [
          for (final line in _lines)
            if (line.syncState == SyncState.syncing ||
                line.syncState == SyncState.dirty)
              line.copyWith(syncState: SyncState.synced)
            else
              line,
        ];
        setState(() => _lines = nextLines);
        unawaited(_persistLines(nextLines));
      }

      if (_pendingOutboxCount > 0 && result.failed == 0) {
        _queueSyncAttempt(delay: const Duration(milliseconds: 250));
      }

      if (_pendingOutboxCount == 0 && result.failed == 0) {
        _queueRemotePull(delay: const Duration(milliseconds: 500));
      }

      if (result.failed > 0) {
        final nextLines = [
          for (final line in _lines)
            if (line.syncState == SyncState.syncing)
              line.copyWith(syncState: SyncState.failed)
            else
              line,
        ];
        setState(() {
          _lines = nextLines;
          _startupWarning =
              'La base distante a refuse une synchronisation. Les modifications restent conservees localement.';
        });
        unawaited(_persistLines(nextLines));
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _startupWarning =
            'La synchronisation distante a echoue. Les modifications restent conservees localement. Detail : $error';
      });
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _pushChangeToRemote(PendingChange change) async {
    if (_offline) throw const SyncOfflineException();
    await _remoteSyncClient.pushChange(change);
  }

  void _retrySyncNow() {
    if (_offline || !_remoteSyncClient.isConfigured) return;
    _syncTimer?.cancel();
    _remotePullTimer?.cancel();
    unawaited(_flushSyncOutbox().then((_) => _pullRemoteBillingLinesIfClean()));
  }

  void _queueRemotePull({Duration delay = const Duration(milliseconds: 1200)}) {
    if (_localStore == null ||
        _offline ||
        !_remoteSyncClient.isConfigured ||
        _pendingOutboxCount > 0 ||
        _hasUnsyncedLines) {
      return;
    }

    _remotePullTimer?.cancel();
    _remotePullTimer = Timer(delay, () {
      unawaited(_pullRemoteBillingLinesIfClean());
    });
  }

  Future<void> _pullRemoteBillingLinesIfClean() async {
    if (_localStore == null ||
        _offline ||
        !_remoteSyncClient.isConfigured ||
        _pendingOutboxCount > 0 ||
        _hasUnsyncedLines) {
      return;
    }

    try {
      final remoteLines = await _remoteSyncClient.fetchBillingLines();
      if (!mounted || remoteLines.isEmpty) return;
      if (_pendingOutboxCount > 0 || _hasUnsyncedLines) return;

      final result = mergeCleanLocalLinesWithRemote(
        localLines: _lines,
        remoteLines: remoteLines,
      );
      if (!result.changed) return;

      setState(() {
        _lines = result.lines;
        _syncInfo =
            'Base distante lue : ${result.added} ligne(s) ajoutee(s), ${result.updated} mise(s) a jour.';
      });
      await _persistLines(result.lines);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _startupWarning =
            'La lecture de la base distante a echoue. Les donnees locales restent disponibles. Detail : $error';
      });
    }
  }

  Future<void> _refreshPendingOutboxCount() async {
    if (_localStore == null) return;
    try {
      final count = await _localStore!.pendingOutboxCount();
      if (!mounted) return;
      setState(() => _pendingOutboxCount = count);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _startupWarning =
            'Le compteur de synchronisation locale n a pas pu etre lu. Detail : $error';
      });
    }
  }

  Future<void> _applyImportedLines(
    List<BillingLine> imported,
    ImportApplyMode mode,
  ) async {
    final nextLines = switch (mode) {
      ImportApplyMode.append => <BillingLine>[..._lines, ...imported],
      ImportApplyMode.replace => List<BillingLine>.of(imported),
    };

    _persistTimer?.cancel();
    setState(() => _lines = List<BillingLine>.of(nextLines));
    await _persistLines(nextLines);
    _savePendingChanges(
      buildBillingLineSnapshotChanges(imported, year: _selectedYear),
    );
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
  }

  void _deleteLine(BillingLine line) {
    final now = DateTime.now();
    _savePendingChanges([
      PendingChange(
        id: '${now.microsecondsSinceEpoch}_deleteLine',
        lineId: line.id,
        reference: line.reference.trim(),
        scope: ChangeScope.line,
        field: '__deleteLine',
        value: true,
        createdAt: now,
      ),
    ]);
  }

  bool get _hasUnsyncedLines {
    return _lines.any(
      (line) => line.syncState != SyncState.synced && !line.isIncomplete,
    );
  }

  Widget get _selectedPage {
    return switch (_selectedIndex) {
      0 => FacturationPage(
        lines: _lines,
        selectedYear: _selectedYear,
        onYearChanged: (year) {
          setState(() => _selectedYear = year);
        },
        onLinesChanged: _saveLines,
        onPendingChanges: _savePendingChanges,
        onDeleteLine: _deleteLine,
        pendingOutboxCount: _pendingOutboxCount,
        offline: _offline,
        syncing: _isSyncing,
        remoteSyncConfigured: _remoteSyncClient.isConfigured,
        onOfflineChanged: _setOffline,
        onRetrySync: _retrySyncNow,
        onOpenImport: () => setState(() => _selectedIndex = 2),
        onOpenExport: () => setState(() => _selectedIndex = 3),
      ),
      1 => DashboardPage(lines: _lines, selectedYear: _selectedYear),
      2 => ImportPage(
        selectedYear: _selectedYear,
        onYearChanged: (year) => setState(() => _selectedYear = year),
        onApplyImport: _applyImportedLines,
      ),
      3 => ExportPage(lines: _lines, selectedYear: _selectedYear),
      _ => SettingsPage(
        selectedYear: _selectedYear,
        pendingOutboxCount: _pendingOutboxCount,
        offline: _offline,
        syncing: _isSyncing,
        remoteSyncConfigured: _remoteSyncClient.isConfigured,
        onYearChanged: (year) => setState(() => _selectedYear = year),
        onResetLocalData: _resetLocalData,
        onResetRemoteData: _resetRemoteData,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Chargement des donnees...'),
            ],
          ),
        ),
      );
    }

    final railExtended =
        MediaQuery.sizeOf(context).width >= 1180 && !_navigationCollapsed;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            extended: railExtended,
            backgroundColor: Colors.white,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            leading: Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BrandMark(),
                  const SizedBox(height: 14),
                  Tooltip(
                    message: railExtended
                        ? 'Reduire la navigation'
                        : 'Etendre la navigation',
                    child: IconButton(
                      onPressed: () {
                        setState(() => _navigationCollapsed = railExtended);
                      },
                      icon: AppIcon(
                        railExtended ? AppIcons.close : AppIcons.table,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: AppIcon(AppIcons.table),
                selectedIcon: AppIcon(
                  AppIcons.table,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.2,
                ),
                label: const Text('Facturation'),
              ),
              NavigationRailDestination(
                icon: AppIcon(AppIcons.dashboard),
                selectedIcon: AppIcon(
                  AppIcons.dashboard,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.2,
                ),
                label: const Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: AppIcon(AppIcons.importFile),
                selectedIcon: AppIcon(
                  AppIcons.importFile,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.2,
                ),
                label: const Text('Import'),
              ),
              NavigationRailDestination(
                icon: AppIcon(AppIcons.exportFile),
                selectedIcon: AppIcon(
                  AppIcons.exportFile,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.2,
                ),
                label: const Text('Export'),
              ),
              NavigationRailDestination(
                icon: AppIcon(AppIcons.settings),
                selectedIcon: AppIcon(
                  AppIcons.settings,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2.2,
                ),
                label: const Text('Parametres'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                if (_syncInfo != null)
                  _SyncInfoBanner(
                    message: _syncInfo!,
                    onDismiss: () => setState(() => _syncInfo = null),
                  ),
                if (_startupWarning != null)
                  _StartupWarningBanner(
                    message: _startupWarning!,
                    onDismiss: () => setState(() => _startupWarning = null),
                  ),
                Expanded(child: _selectedPage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SyncOfflineException implements Exception {
  const SyncOfflineException();

  @override
  String toString() => 'hors ligne';
}

class _SyncInfoBanner extends StatelessWidget {
  const _SyncInfoBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        border: Border(bottom: BorderSide(color: Color(0xFF22C55E))),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.cloudDone, size: 18, color: const Color(0xFF15803D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF166534), fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: AppIcon(AppIcons.close, size: 18),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }
}

class _StartupWarningBanner extends StatelessWidget {
  const _StartupWarningBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBEB),
        border: Border(bottom: BorderSide(color: Color(0xFFF59E0B))),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.warning, size: 18, color: const Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF78350F), fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: AppIcon(AppIcons.close, size: 18),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: AppIcon(AppIcons.receipt, color: Colors.white, size: 22),
          ),
        ),
        if (MediaQuery.sizeOf(context).width >= 1180) ...[
          const SizedBox(width: 10),
          const Text(
            'Facturation RH',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    );
  }
}
