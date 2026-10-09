import 'package:flutter/material.dart';

import '../models/billing_line.dart';
import '../models/billing_years.dart';
import '../sync/pending_change.dart';
import '../theme/app_icons.dart';
import '../utils/billing_reference.dart';
import '../validation/billing_validation.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_icon.dart';
import '../widgets/editable_cell.dart';
import '../widgets/metric_tile.dart';
import '../widgets/status_badge.dart';

class FacturationPage extends StatefulWidget {
  const FacturationPage({
    super.key,
    required this.lines,
    required this.selectedYear,
    required this.onYearChanged,
    required this.onLinesChanged,
    required this.onPendingChanges,
    required this.onDeleteLine,
    required this.pendingOutboxCount,
    required this.offline,
    required this.syncing,
    required this.manualSaving,
    required this.remoteSyncConfigured,
    required this.onOfflineChanged,
    required this.onRetrySync,
    required this.onSaveNow,
    required this.onOpenImport,
    required this.onOpenExport,
  });

  final List<BillingLine> lines;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<List<BillingLine>> onLinesChanged;
  final ValueChanged<List<PendingChange>> onPendingChanges;
  final ValueChanged<BillingLine> onDeleteLine;
  final int pendingOutboxCount;
  final bool offline;
  final bool syncing;
  final bool manualSaving;
  final bool remoteSyncConfigured;
  final ValueChanged<bool> onOfflineChanged;
  final VoidCallback onRetrySync;
  final Future<void> Function() onSaveNow;
  final VoidCallback onOpenImport;
  final VoidCallback onOpenExport;

  @override
  State<FacturationPage> createState() => _FacturationPageState();
}

class _FacturationPageState extends State<FacturationPage> {
  late List<BillingLine> _lines;
  BillingLine? _selectedLine;
  String _query = '';
  String _activityFilter = 'Toutes';
  String _statusFilter = 'Actif';
  bool _onlyIncomplete = false;
  bool _remoteNoticeShown = false;
  late int _year;

  @override
  void initState() {
    super.initState();
    _lines = List.of(widget.lines);
    _year = widget.selectedYear;
  }

  @override
  void didUpdateWidget(covariant FacturationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.lines, oldWidget.lines)) {
      _lines = List.of(widget.lines);
    }
    if (widget.selectedYear != oldWidget.selectedYear) {
      _year = widget.selectedYear;
    }
    _scheduleRemoteNotice();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleRemoteNotice();
  }

  void _scheduleRemoteNotice() {
    if (_remoteNoticeShown || widget.remoteSyncConfigured) return;
    _remoteNoticeShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showInfoDialog(
        context,
        title: 'Base distante non configuree',
        message:
            'Les modifications sont sauvegardees sur cet ordinateur. '
            'Elles resteront en attente tant que la base distante ne sera pas configuree.',
        icon: AppIcons.cloudOff,
      );
    });
  }

  List<BillingLine> _filterLines(Set<String> duplicateReferences) {
    final q = _query.trim().toLowerCase();
    return _lines.where((line) {
      final matchesQuery =
          q.isEmpty ||
          line.odooId.toLowerCase().contains(q) ||
          line.reference.toLowerCase().contains(q) ||
          line.appellationComptable.toLowerCase().contains(q) ||
          line.name.toLowerCase().contains(q) ||
          line.activity.toLowerCase().contains(q);
      final matchesActivity =
          _activityFilter == 'Toutes' || line.activity == _activityFilter;
      final matchesStatus =
          _statusFilter == 'Tous' || line.status == _statusFilter;
      final matchesIncomplete =
          !_onlyIncomplete ||
          billingLineNeedsReview(
            line,
            duplicate: duplicateReferences.contains(
              line.reference.trim().toUpperCase(),
            ),
          );
      return matchesQuery &&
          matchesActivity &&
          matchesStatus &&
          matchesIncomplete;
    }).toList();
  }

  int get _pendingChanges {
    final lineLevelPending = _lines
        .where((line) => line.syncState != SyncState.synced)
        .length;
    return widget.pendingOutboxCount > lineLevelPending
        ? widget.pendingOutboxCount
        : lineLevelPending;
  }

  Set<String> get _duplicateReferences {
    final counts = <String, int>{};
    for (final line in _lines) {
      final reference = line.reference.trim().toUpperCase();
      if (reference.isEmpty) continue;
      counts[reference] = (counts[reference] ?? 0) + 1;
    }
    return {
      for (final entry in counts.entries)
        if (entry.value > 1) entry.key,
    };
  }

  void _updateLine(BillingLine oldLine, BillingLine newLine) {
    var effectiveNewLine = newLine;
    if (oldLine.odooId.trim() != newLine.odooId.trim()) {
      final nextOdooId = newLine.odooId.trim();
      final knownAppellation = _lines
          .where(
            (line) => line.id != oldLine.id && line.odooId.trim() == nextOdooId,
          )
          .map((line) => line.appellationComptable.trim())
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      effectiveNewLine = newLine.copyWith(
        odooId: nextOdooId,
        appellationComptable: nextOdooId.isEmpty ? '' : knownAppellation,
        reference: nextOdooId.isEmpty
            ? (isGeneratedBillingReference(newLine.reference, oldLine.odooId)
                  ? ''
                  : newLine.reference)
            : nextBillingReference(
                nextOdooId,
                _lines,
                excludingLineId: oldLine.id,
              ),
      );
    }
    var pendingChanges = <PendingChange>[];
    setState(() {
      final index = _lines.indexOf(oldLine);
      if (index == -1) return;
      pendingChanges = _enqueueDiffs(oldLine, effectiveNewLine);
      final updated = effectiveNewLine.copyWith(
        syncState: widget.offline || !widget.remoteSyncConfigured
            ? SyncState.dirty
            : SyncState.syncing,
      );
      _lines[index] = updated;
      if (_selectedLine == oldLine) _selectedLine = updated;
    });
    widget.onLinesChanged(_lines);
    if (pendingChanges.isNotEmpty) {
      widget.onPendingChanges(pendingChanges);
    }
  }

  List<PendingChange> _enqueueDiffs(BillingLine oldLine, BillingLine newLine) {
    final changes = <PendingChange>[];
    final reference = newLine.reference.trim();

    void enqueueLineField(String field, Object? oldValue, Object? newValue) {
      if (oldValue == newValue) return;
      final now = DateTime.now();
      final change = PendingChange(
        id: '${now.microsecondsSinceEpoch}_$field',
        lineId: newLine.id,
        reference: reference,
        scope: ChangeScope.line,
        field: field,
        value: newValue,
        createdAt: now,
      );
      changes.add(change);
    }

    enqueueLineField('odooId', oldLine.odooId, newLine.odooId);
    enqueueLineField(
      'appellationComptable',
      oldLine.appellationComptable,
      newLine.appellationComptable,
    );
    enqueueLineField('reference', oldLine.reference, newLine.reference);
    enqueueLineField('name', oldLine.name, newLine.name);
    enqueueLineField('activity', oldLine.activity, newLine.activity);
    enqueueLineField('startDate', oldLine.startDate, newLine.startDate);
    enqueueLineField('endDate', oldLine.endDate, newLine.endDate);
    enqueueLineField(
      'contractNature',
      oldLine.contractNature,
      newLine.contractNature,
    );
    enqueueLineField('billedStaff', oldLine.billedStaff, newLine.billedStaff);
    enqueueLineField('paidStaff', oldLine.paidStaff, newLine.paidStaff);
    enqueueLineField(
      'cellComments',
      oldLine.cellComments,
      newLine.cellComments,
    );
    final oldAnnual = oldLine.annualBilling(_year);
    final newAnnual = newLine.annualBilling(_year);
    if (oldAnnual.monthlyRate != newAnnual.monthlyRate) {
      final now = DateTime.now();
      final change = PendingChange(
        id: '${now.microsecondsSinceEpoch}_monthlyRate',
        lineId: newLine.id,
        reference: reference,
        scope: ChangeScope.annualBilling,
        field: 'monthlyRate',
        value: newAnnual.monthlyRate,
        year: _year,
        createdAt: now,
      );
      changes.add(change);
    }
    enqueueLineField('status', oldLine.status, newLine.status);
    enqueueLineField(
      'statusComment',
      oldLine.statusComment,
      newLine.statusComment,
    );

    for (final month in months) {
      final oldValue = oldAnnual.payments[month] ?? 0;
      final newValue = newAnnual.payments[month] ?? 0;
      if (oldValue == newValue) continue;
      final now = DateTime.now();
      final change = PendingChange(
        id: '${now.microsecondsSinceEpoch}_$month',
        lineId: newLine.id,
        reference: reference,
        scope: ChangeScope.paymentCell,
        field: month,
        value: newValue,
        year: _year,
        createdAt: now,
      );
      changes.add(change);
    }

    final hasLineChange = changes.any(
      (change) => change.scope == ChangeScope.line,
    );
    final hasAnnualChange = changes.any(
      (change) => change.scope != ChangeScope.line,
    );
    final now = DateTime.now();
    if (hasLineChange) {
      changes.add(
        PendingChange(
          id: '${now.microsecondsSinceEpoch}_lineSnapshot',
          lineId: newLine.id,
          reference: reference,
          scope: ChangeScope.line,
          field: '__lineSnapshot',
          value: newLine.toJson(),
          createdAt: now,
        ),
      );
    }
    if (hasAnnualChange) {
      changes.add(
        PendingChange(
          id: '${now.microsecondsSinceEpoch}_annualSnapshot',
          lineId: newLine.id,
          reference: reference,
          scope: ChangeScope.annualBilling,
          field: '__annualSnapshot',
          value: newAnnual.toJson(),
          year: _year,
          createdAt: now,
        ),
      );
    }
    return changes;
  }

  void _addLine() {
    final line = BillingLine(
      odooId: '',
      reference: '',
      name: '',
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 0,
      paidStaff: 0,
      annualBillings: {_year: AnnualBillingData.empty()},
      status: 'Actif',
      statusComment: '',
      syncState: SyncState.dirty,
    );

    setState(() {
      _lines = [line, ..._lines];
      _selectedLine = line;
    });
    widget.onLinesChanged(_lines);
  }

  Future<void> _deleteLine(BillingLine line) async {
    final label = line.reference.trim().isEmpty
        ? line.name.trim()
        : line.reference.trim();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cette ligne ?',
      message: label.isEmpty
          ? 'Cette action retirera la ligne de la facturation.'
          : 'Cette action retirera "$label" de la facturation.',
      confirmLabel: 'Supprimer',
      icon: AppIcons.delete,
      tone: AppDialogTone.danger,
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _lines = _lines.where((candidate) => candidate.id != line.id).toList();
      if (_selectedLine?.id == line.id) _selectedLine = null;
    });
    widget.onLinesChanged(_lines);
    widget.onDeleteLine(line);
  }

  @override
  Widget build(BuildContext context) {
    final duplicateReferences = _duplicateReferences;
    final filtered = _filterLines(duplicateReferences);
    final countedFiltered = linesCountedInBillingTotals(filtered);
    final billedStaffTotal = countedFiltered.fold<int>(
      0,
      (sum, line) => sum + line.billedStaff,
    );
    final paidStaffTotal = countedFiltered.fold<int>(
      0,
      (sum, line) => sum + line.paidStaff,
    );
    final commentCount = filtered.fold<int>(
      0,
      (sum, line) => sum + line.cellComments.length,
    );
    final validation = validateBillingLines(_lines, year: _year);

    return Column(
      children: [
        _TopBar(
          year: _year,
          offline: widget.offline,
          syncing: widget.syncing,
          manualSaving: widget.manualSaving,
          pendingChanges: _pendingChanges,
          onYearChanged: (year) {
            setState(() => _year = year);
            widget.onYearChanged(year);
          },
          onOfflineChanged: (value) {
            widget.onOfflineChanged(value);
          },
          onQueryChanged: (value) => setState(() => _query = value),
          onSaveNow: widget.onSaveNow,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
          child: Column(
            children: [
                      _FilterBar(
                        activityFilter: _activityFilter,
                        statusFilter: _statusFilter,
                        onlyIncomplete: _onlyIncomplete,
                        onActivityChanged: (value) =>
                            setState(() => _activityFilter = value),
                        onStatusChanged: (value) =>
                            setState(() => _statusFilter = value),
                        onIncompleteChanged: (value) =>
                            setState(() => _onlyIncomplete = value),
                        onAddLine: _addLine,
                        onImport: widget.onOpenImport,
                        onExport: widget.onOpenExport,
                      ),
                      const SizedBox(height: 8),
                      _SummaryStrip(
                        lineCount: filtered.length,
                        billedStaff: billedStaffTotal,
                        paidStaff: paidStaffTotal,
                        commentCount: commentCount,
                      ),
                      const SizedBox(height: 8),
                      _ValidationStrip(summary: validation),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _BillingGrid(
                          lines: filtered,
                          selectedYear: _year,
                          duplicateReferences: duplicateReferences,
                          selectedLine: _selectedLine,
                          onSelectLine: (line) =>
                              setState(() => _selectedLine = line),
                          onUpdateLine: _updateLine,
                          onDeleteLine: _deleteLine,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SyncFooter(
                        offline: widget.offline,
                        syncing: widget.syncing,
                        remoteSyncConfigured: widget.remoteSyncConfigured,
                        pendingChanges: _pendingChanges,
                        onRetrySync: widget.onRetrySync,
                      ),
                    ],
                  ),
                ),
                _AnimatedDetailPanel(
                  child: _selectedLine == null
                      ? null
                      : Row(
                          key: ValueKey(_selectedLine!.id),
                          children: [
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 330,
                              child: _LineDetailPanel(
                                line: _selectedLine!,
                                selectedYear: _year,
                                duplicateReference: duplicateReferences
                                    .contains(
                                      _selectedLine!.reference
                                          .trim()
                                          .toUpperCase(),
                                    ),
                                onUpdate: (updated) =>
                                    _updateLine(_selectedLine!, updated),
                                onDelete: () => _deleteLine(_selectedLine!),
                                onClose: () =>
                                    setState(() => _selectedLine = null),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.year,
    required this.offline,
    required this.syncing,
    required this.manualSaving,
    required this.pendingChanges,
    required this.onYearChanged,
    required this.onOfflineChanged,
    required this.onQueryChanged,
    required this.onSaveNow,
  });

  final int year;
  final bool offline;
  final bool syncing;
  final bool manualSaving;
  final int pendingChanges;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<bool> onOfflineChanged;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function() onSaveNow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;

        return Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE1E7EF))),
          ),
          child: Row(
            children: [
              if (!compact) ...[
                const Text(
                  'Facturation annuelle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 18),
              ],
              DropdownButton<int>(
                value: year,
                underline: const SizedBox.shrink(),
                items: [
                  for (final option in billingYearOptions())
                    DropdownMenuItem(value: option, child: Text('$option')),
                ],
                onChanged: (value) {
                  if (value != null) onYearChanged(value);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: onQueryChanged,
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10),
                      child: AppIcon(AppIcons.search, size: 17),
                    ),
                    hintText: 'Rechercher',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SaveButton(
                saving: manualSaving,
                pendingChanges: pendingChanges,
                onPressed: onSaveNow,
                compact: compact,
              ),
              const SizedBox(width: 10),
              FilterChip(
                selected: offline,
                avatar: AppIcon(
                  offline ? AppIcons.cloudOff : AppIcons.cloudDone,
                  size: 16,
                ),
                label: Text(offline ? 'Hors ligne' : 'En ligne'),
                onSelected: onOfflineChanged,
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                SyncBadge(
                  state: syncing
                      ? SyncState.syncing
                      : pendingChanges == 0
                      ? SyncState.synced
                      : SyncState.dirty,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.pendingChanges,
    required this.onPressed,
    required this.compact,
  });

  final bool saving;
  final int pendingChanges;
  final Future<void> Function() onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasPendingChanges = pendingChanges > 0;
    final label = saving
        ? 'Enregistrement...'
        : hasPendingChanges
        ? 'Enregistrer'
        : 'Enregistre';
    final icon = saving
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : AppIcon(
            hasPendingChanges ? AppIcons.sync : AppIcons.cloudDone,
            size: 17,
          );

    if (compact) {
      return Tooltip(
        message: label,
        child: IconButton(onPressed: saving ? null : onPressed, icon: icon),
      );
    }

    return OutlinedButton.icon(
      onPressed: saving ? null : onPressed,
      icon: icon,
      label: Text(label),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.activityFilter,
    required this.statusFilter,
    required this.onlyIncomplete,
    required this.onActivityChanged,
    required this.onStatusChanged,
    required this.onIncompleteChanged,
    required this.onAddLine,
    required this.onImport,
    required this.onExport,
  });

  final String activityFilter;
  final String statusFilter;
  final bool onlyIncomplete;
  final ValueChanged<String> onActivityChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onIncompleteChanged;
  final VoidCallback onAddLine;
  final VoidCallback onImport;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SmallSelect(
              label: 'Activite',
              value: activityFilter,
              values: const ['Toutes', ...activities],
              onChanged: onActivityChanged,
            ),
            const SizedBox(width: 10),
            _SmallSelect(
              label: 'Statut',
              value: statusFilter,
              values: const ['Tous', ...statuses],
              onChanged: onStatusChanged,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: onlyIncomplete,
              avatar: AppIcon(AppIcons.rule, size: 16),
              label: const Text('A revoir'),
              onSelected: onIncompleteChanged,
            ),
            const SizedBox(width: 18),
            OutlinedButton.icon(
              onPressed: onImport,
              icon: AppIcon(AppIcons.importFile, size: 18),
              label: const Text('Import'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onExport,
              icon: AppIcon(AppIcons.exportFile, size: 18),
              label: const Text('Export'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAddLine,
              icon: AppIcon(AppIcons.add, size: 18),
              label: const Text('Ligne'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallSelect extends StatelessWidget {
  const _SmallSelect({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DEE8)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            items: values
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.lineCount,
    required this.billedStaff,
    required this.paidStaff,
    required this.commentCount,
  });

  final int lineCount;
  final int billedStaff;
  final int paidStaff;
  final int commentCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          MetricTile(
            label: 'Lignes',
            value: '$lineCount',
            icon: AppIcons.lines,
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Eff facture',
            value: '$billedStaff',
            icon: AppIcons.staff,
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Eff paye',
            value: '$paidStaff',
            icon: AppIcons.badge,
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Commentaires',
            value: '$commentCount',
            icon: AppIcons.edit,
            color: commentCount > 0
                ? const Color(0xFFB45309)
                : const Color(0xFF15803D),
          ),
        ],
      ),
    );
  }
}

class _ValidationStrip extends StatelessWidget {
  const _ValidationStrip({required this.summary});

  final BillingValidationSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.blockingCount == 0) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AppIcon(
              AppIcons.cloudDone,
              size: 17,
              color: const Color(0xFF15803D),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Aucune alerte metier dans la base locale.',
                style: TextStyle(
                  color: Color(0xFF166534),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppIcon(AppIcons.warning, size: 17, color: const Color(0xFFB45309)),
          const Text(
            'Alertes',
            style: TextStyle(
              color: Color(0xFF78350F),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (summary.missingReferences > 0)
            _ValidationPill('${summary.missingReferences} ref. manquante(s)'),
          if (summary.duplicateReferences > 0)
            _ValidationPill('${summary.duplicateReferences} ref. doublon(s)'),
          if (summary.missingNames > 0)
            _ValidationPill('${summary.missingNames} nom/site manquant(s)'),
          if (summary.autreWithoutComment > 0)
            _ValidationPill(
              '${summary.autreWithoutComment} commentaire(s) requis',
            ),
        ],
      ),
    );
  }
}

class _ValidationPill extends StatelessWidget {
  const _ValidationPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFCD34D)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF78350F),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BillingGrid extends StatefulWidget {
  const _BillingGrid({
    required this.lines,
    required this.selectedYear,
    required this.duplicateReferences,
    required this.selectedLine,
    required this.onSelectLine,
    required this.onUpdateLine,
    required this.onDeleteLine,
  });

  final List<BillingLine> lines;
  final int selectedYear;
  final Set<String> duplicateReferences;
  final BillingLine? selectedLine;
  final ValueChanged<BillingLine> onSelectLine;
  final void Function(BillingLine oldLine, BillingLine newLine) onUpdateLine;
  final ValueChanged<BillingLine> onDeleteLine;

  static const widths = <double>[
    100,
    126,
    220,
    132,
    250,
    150,
    144,
    144,
    110,
    88,
    88,
    122,
    96,
    96,
    96,
    96,
    96,
    96,
    96,
    96,
    96,
    96,
    96,
    96,
    130,
    116,
  ];

  @override
  State<_BillingGrid> createState() => _BillingGridState();
}

class _BillingGridState extends State<_BillingGrid> {
  late final ScrollController _horizontalController;
  late final ScrollController _verticalController;
  late final ScrollController _rowNumberController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    _rowNumberController = ScrollController();
    _verticalController.addListener(_syncRowNumbers);
  }

  @override
  void dispose() {
    _verticalController.removeListener(_syncRowNumbers);
    _horizontalController.dispose();
    _verticalController.dispose();
    _rowNumberController.dispose();
    super.dispose();
  }

  void _syncRowNumbers() {
    if (!_rowNumberController.hasClients || !_verticalController.hasClients) {
      return;
    }
    final target = _verticalController.offset.clamp(
      0.0,
      _rowNumberController.position.maxScrollExtent,
    );
    if ((_rowNumberController.offset - target).abs() > 0.5) {
      _rowNumberController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7EF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RowNumberColumn(
            width: 46,
            controller: _rowNumberController,
            itemCount: widget.lines.length,
          ),
          Expanded(
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _BillingGrid.widths.fold<double>(
                    0,
                    (sum, width) => sum + width,
                  ),
                  child: Column(
                    children: [
                      const _GridHeader(),
                      Expanded(
                        child: widget.lines.isEmpty
                            ? const _EmptyGridState()
                            : Scrollbar(
                                controller: _verticalController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: _verticalController,
                                  primary: false,
                                  itemCount: widget.lines.length,
                                  itemExtent: 54,
                                  cacheExtent: 108,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: false,
                                  itemBuilder: (context, index) {
                                    final line = widget.lines[index];
                                    return RepaintBoundary(
                                      child: _GridRow(
                                        key: ValueKey(line.id),
                                        line: line,
                                        selectedYear: widget.selectedYear,
                                        hasDuplicateReference: widget
                                            .duplicateReferences
                                            .contains(
                                              line.reference
                                                  .trim()
                                                  .toUpperCase(),
                                            ),
                                        selected: line == widget.selectedLine,
                                        onSelect: () =>
                                            widget.onSelectLine(line),
                                        onDelete: () =>
                                            widget.onDeleteLine(line),
                                        onUpdate: (updated) =>
                                            widget.onUpdateLine(line, updated),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowNumberColumn extends StatelessWidget {
  const _RowNumberColumn({
    required this.width,
    required this.controller,
    required this.itemCount,
  });

  final double width;
  final ScrollController controller;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Container(
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                right: BorderSide(color: Color(0xFFE1E7EF)),
                bottom: BorderSide(color: Color(0xFFE1E7EF)),
              ),
            ),
            child: const Text(
              '#',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: itemCount == 0
                ? const SizedBox.shrink()
                : ListView.builder(
                    controller: controller,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itemCount,
                    itemExtent: 54,
                    cacheExtent: 108,
                    itemBuilder: (context, index) => Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          right: BorderSide(color: Color(0xFFE1E7EF)),
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGridState extends StatelessWidget {
  const _EmptyGridState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 560,
        child: Center(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  AppIcons.table,
                  size: 34,
                  color: const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Aucune ligne a afficher',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ajoutez une ligne ou importez le fichier Excel annuel pour commencer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridHeader extends StatelessWidget {
  const _GridHeader();

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Actions',
      'Reference Odoo',
      'Appellation comptable',
      'Reference',
      'Nom / Site',
      'Activite',
      'Debut',
      'Fin',
      'Nature',
      'Eff fact',
      'Eff paye',
      'Tarif/mois',
      ...months,
      'Statut',
      'Sync',
    ];

    return Container(
      height: 42,
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            _HeaderCell(label: labels[i], width: _BillingGrid.widths[i]),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE1E7EF))),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GridRow extends StatelessWidget {
  const _GridRow({
    super.key,
    required this.line,
    required this.selectedYear,
    required this.hasDuplicateReference,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.onUpdate,
  });

  final BillingLine line;
  final int selectedYear;
  final bool hasDuplicateReference;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ValueChanged<BillingLine> onUpdate;

  String _comment(String key) => line.cellComments[key] ?? '';

  void _updateComment(String key, String value) {
    final nextComments = Map<String, String>.of(line.cellComments);
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      nextComments.remove(key);
    } else {
      nextComments[key] = cleaned;
    }
    onUpdate(line.copyWith(cellComments: nextComments));
  }

  @override
  Widget build(BuildContext context) {
    final annual = line.annualBilling(selectedYear);
    Widget commentable(String key, String label, double width, Widget child) {
      return _CommentableCell(
        width: width,
        label: label,
        comment: _comment(key),
        onCommentChanged: (value) => _updateComment(key, value),
        child: child,
      );
    }

    final background = selected
        ? const Color(0xFFEFF6FF)
        : line.isIncomplete
        ? const Color(0xFFFFFBEB)
        : Colors.white;

    return Container(
      color: background,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
            SizedBox(
              width: _BillingGrid.widths[0],
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Ouvrir le detail',
                      onPressed: onSelect,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      icon: AppIcon(
                        AppIcons.fileOpen,
                        size: 18,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF64748B),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Supprimer la ligne',
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      icon: AppIcon(
                        AppIcons.warning,
                        size: 17,
                        color: const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            commentable(
              'line.odooId',
              'Reference Odoo',
              _BillingGrid.widths[1],
              EditableCell(
                value: line.odooId,
                width: _BillingGrid.widths[1],
                onChanged: (value) => onUpdate(line.copyWith(odooId: value)),
              ),
            ),
            commentable(
              'line.appellationComptable',
              'Appellation comptable',
              _BillingGrid.widths[2],
              Container(
                width: _BillingGrid.widths[2],
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  line.appellationComptable,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
            commentable(
              'line.reference',
              'Reference',
              _BillingGrid.widths[3],
              EditableCell(
                value: line.reference,
                width: _BillingGrid.widths[3],
                readOnly: line.odooId.trim().isNotEmpty,
                isRequired: true,
                hasError: hasDuplicateReference,
                errorMessage: hasDuplicateReference
                    ? 'Reference deja utilisee'
                    : null,
                onChanged: (value) => onUpdate(line.copyWith(reference: value)),
              ),
            ),
            commentable(
              'line.name',
              'Nom / Site',
              _BillingGrid.widths[4],
              EditableCell(
                value: line.name,
                width: _BillingGrid.widths[4],
                isRequired: true,
                onChanged: (value) => onUpdate(line.copyWith(name: value)),
              ),
            ),
            commentable(
              'line.activity',
              'Activite',
              _BillingGrid.widths[5],
              _DropdownCell(
                value: line.activity,
                values: activities,
                width: _BillingGrid.widths[5],
                onChanged: (value) => onUpdate(line.copyWith(activity: value)),
              ),
            ),
            commentable(
              'line.startDate',
              'Debut',
              _BillingGrid.widths[6],
              _DateCell(
                value: line.startDate,
                width: _BillingGrid.widths[6],
                onChanged: (value) => onUpdate(line.copyWith(startDate: value)),
              ),
            ),
            commentable(
              'line.endDate',
              'Fin',
              _BillingGrid.widths[7],
              _DateCell(
                value: line.endDate,
                width: _BillingGrid.widths[7],
                onChanged: (value) => onUpdate(line.copyWith(endDate: value)),
              ),
            ),
            commentable(
              'line.contractNature',
              'Nature',
              _BillingGrid.widths[8],
              EditableCell(
                value: line.contractNature,
                width: _BillingGrid.widths[8],
                onChanged: (value) =>
                    onUpdate(line.copyWith(contractNature: value)),
              ),
            ),
            commentable(
              'line.billedStaff',
              'Eff facture',
              _BillingGrid.widths[9],
              EditableCell(
                value: '${line.billedStaff}',
                width: _BillingGrid.widths[9],
                textAlign: TextAlign.right,
                onChanged: (value) =>
                    onUpdate(line.copyWith(billedStaff: _parseInt(value))),
              ),
            ),
            commentable(
              'line.paidStaff',
              'Eff paye',
              _BillingGrid.widths[10],
              EditableCell(
                value: '${line.paidStaff}',
                width: _BillingGrid.widths[10],
                textAlign: TextAlign.right,
                onChanged: (value) =>
                    onUpdate(line.copyWith(paidStaff: _parseInt(value))),
              ),
            ),
            commentable(
              'annual.$selectedYear.monthlyRate',
              'Tarif/mois',
              _BillingGrid.widths[11],
              EditableCell(
                value: _number(annual.monthlyRate),
                width: _BillingGrid.widths[11],
                textAlign: TextAlign.right,
                onChanged: (value) {
                  onUpdate(
                    line.withAnnualBilling(
                      selectedYear,
                      annual.copyWith(monthlyRate: _parseMoney(value)),
                    ),
                  );
                },
              ),
            ),
            for (var i = 0; i < months.length; i++)
              commentable(
                'annual.$selectedYear.${months[i]}',
                months[i],
                _BillingGrid.widths[12 + i],
                EditableCell(
                  value: _number(annual.payments[months[i]] ?? 0),
                  width: _BillingGrid.widths[12 + i],
                  textAlign: TextAlign.right,
                  onChanged: (value) {
                    final next = Map<String, double>.of(annual.payments);
                    next[months[i]] = _parseMoney(value);
                    onUpdate(
                      line.withAnnualBilling(
                        selectedYear,
                        annual.copyWith(payments: next),
                      ),
                    );
                  },
                ),
              ),
            commentable(
              'line.status',
              'Statut',
              _BillingGrid.widths[24],
              _DropdownCell(
                value: line.status,
                values: statuses,
                width: _BillingGrid.widths[24],
                onChanged: (value) => onUpdate(line.copyWith(status: value)),
              ),
            ),
            SizedBox(
              width: _BillingGrid.widths[25],
              child: Center(child: SyncBadge(state: line.syncState)),
            ),
        ],
      ),
    );
  }
}

class _CommentableCell extends StatelessWidget {
  const _CommentableCell({
    required this.width,
    required this.label,
    required this.comment,
    required this.onCommentChanged,
    required this.child,
  });

  final double width;
  final String label;
  final String comment;
  final ValueChanged<String> onCommentChanged;
  final Widget child;

  bool get _hasComment => comment.trim().isNotEmpty;

  Future<void> _openCommentDialog(BuildContext context) async {
    final controller = TextEditingController(text: comment);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commentaire - $label'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            minLines: 4,
            maxLines: 7,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ajouter une note pour cette cellule',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    onCommentChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasComment) {
      return Listener(
        onPointerDown: (event) {
          if (event.buttons == 2) {
            _openCommentDialog(context);
          }
        },
        child: SizedBox(width: width, child: child),
      );
    }

    final content = Listener(
      onPointerDown: (event) {
        if (event.buttons == 2) {
          _openCommentDialog(context);
        }
      },
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            child,
            if (_hasComment)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x22FACC15),
                      border: Border.all(color: const Color(0xFFEAB308)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            if (_hasComment)
              Positioned(
                top: 0,
                right: 0,
                child: Tooltip(
                  message: comment,
                  child: GestureDetector(
                    onTap: () => _openCommentDialog(context),
                    child: CustomPaint(
                      size: const Size(12, 12),
                      painter: _CommentCornerPainter(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return _hasComment
        ? Tooltip(message: 'Commentaire : $comment', child: content)
        : content;
  }
}

class _CommentCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFEAB308);
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DropdownCell extends StatelessWidget {
  const _DropdownCell({
    required this.value,
    required this.values,
    required this.width,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final double width;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final menuValues = values.contains(value) ? values : [value, ...values];
    final selectedValue = menuValues.contains(value) ? value : menuValues.first;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openMenu(context, menuValues, selectedValue),
      child: SizedBox(
        width: width,
        height: 38,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE1E7EF)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedValue.isEmpty ? 'A renseigner' : selectedValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(Icons.expand_more, size: 17),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMenu(
    BuildContext context,
    List<String> menuValues,
    String selectedValue,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, box.size.width, box.size.height),
      Offset.zero & overlay.size,
    );
    final next = await showMenu<String>(
      context: context,
      position: position,
      items: menuValues.map((item) {
        final label = item.isEmpty ? 'A renseigner' : item;
        return PopupMenuItem<String>(
          value: item,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        );
      }).toList(),
    );
    if (next != null && next != selectedValue) onChanged(next);
  }
}

class _DateCell extends StatefulWidget {
  const _DateCell({
    required this.value,
    required this.width,
    required this.onChanged,
  });

  final String value;
  final double width;
  final ValueChanged<String> onChanged;

  @override
  State<_DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<_DateCell> {
  TextEditingController? _controller;
  FocusNode? _focusNode;
  String _editStartValue = '';
  bool _editing = false;

  @override
  void didUpdateWidget(covariant _DateCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing || _controller == null || _focusNode?.hasFocus == true) {
      return;
    }
    _syncControllerText();
  }

  @override
  void dispose() {
    _disposeEditor();
    super.dispose();
  }

  void _beginEditing() {
    if (_editing) return;

    _editStartValue = widget.value;
    final controller = TextEditingController(text: widget.value);
    final focusNode = FocusNode();
    focusNode.addListener(_handleFocusChanged);
    _controller = controller;
    _focusNode = focusNode;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) _focusNode?.requestFocus();
    });
  }

  void _handleFocusChanged() {
    if (_editing && _focusNode?.hasFocus == false) {
      _commit();
    }
  }

  void _syncControllerText() {
    final controller = _controller;
    if (controller == null || widget.value == controller.text) return;
    controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  void _commit() {
    if (!_editing) return;
    final value = _controller?.text ?? _editStartValue;
    final changed = value != _editStartValue;
    _disposeEditor();
    if (mounted) setState(() => _editing = false);
    if (changed) widget.onChanged(value);
  }

  void _disposeEditor() {
    _focusNode?.removeListener(_handleFocusChanged);
    _focusNode?.dispose();
    _controller?.dispose();
    _focusNode = null;
    _controller = null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = _parseDate(_controller?.text ?? widget.value);
    final initialDate = current ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    final value = _formatDate(picked);
    if (_editing) {
      _controller?.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      _commit();
    } else {
      widget.onChanged(value);
    }
  }

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) {
      final candidate = DateTime(iso.year, iso.month, iso.day);
      return _isAllowedDate(candidate) ? candidate : null;
    }

    final match = RegExp(
      r'^(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})$',
    ).firstMatch(text);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final rawYear = int.tryParse(match.group(3)!);
    if (day == null || month == null || rawYear == null) return null;

    final year = rawYear < 100 ? 2000 + rawYear : rawYear;
    if (year < 1990 || year > 2100 || month < 1 || month > 12) return null;

    final candidate = DateTime(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return _isAllowedDate(candidate) ? candidate : null;
  }

  bool _isAllowedDate(DateTime date) {
    return !date.isBefore(DateTime(1990)) &&
        !date.isAfter(DateTime(2100, 12, 31));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return SizedBox(
        width: widget.width,
        height: 38,
        child: InkWell(
          onTap: _beginEditing,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE1E7EF)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _pickDate,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 30,
                    height: 30,
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.datetime,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111827),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 9,
          ),
          suffixIcon: Tooltip(
            message: 'Choisir une date',
            child: IconButton(
              onPressed: _pickDate,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
            ),
          ),
          suffixIconConstraints: const BoxConstraints.tightFor(
            width: 34,
            height: 32,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
          ),
        ),
        onSubmitted: (_) => _commit(),
      ),
    );
  }
}

class _AnimatedDetailPanel extends StatelessWidget {
  const _AnimatedDetailPanel({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            axis: Axis.horizontal,
            alignment: Alignment.centerLeft,
            sizeFactor: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: child ?? const SizedBox.shrink(),
    );
  }
}

class _LineDetailPanel extends StatelessWidget {
  const _LineDetailPanel({
    required this.line,
    required this.selectedYear,
    required this.duplicateReference,
    required this.onUpdate,
    required this.onDelete,
    required this.onClose,
  });

  final BillingLine line;
  final int selectedYear;
  final bool duplicateReference;
  final ValueChanged<BillingLine> onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final annual = line.annualBilling(selectedYear);

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Detail ligne',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: AppIcon(AppIcons.close, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              line.odooId.isEmpty
                  ? 'Reference Odoo manquante'
                  : 'Reference Odoo : ${line.odooId}',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Text(
              line.reference.isEmpty ? 'Reference manquante' : line.reference,
            ),
            if (line.appellationComptable.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                line.appellationComptable,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              line.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(label: line.status),
                SyncBadge(state: line.syncState),
              ],
            ),
            if (billingLineIssues(line, year: selectedYear).isNotEmpty ||
                duplicateReference) ...[
              const SizedBox(height: 12),
              _LineIssueList(
                issues: [
                  if (duplicateReference) 'Reference deja utilisee.',
                  ...billingLineIssues(line, year: selectedYear),
                ],
              ),
            ],
            const Divider(height: 28),
            _DetailItem(label: 'Activite', value: line.activity),
            _DetailItem(
              label: 'Contrat',
              value:
                  '${line.startDate} -> ${line.endDate.isEmpty ? 'Actif' : line.endDate}',
            ),
            _DetailItem(
              label: 'Effectif facture',
              value: '${line.billedStaff}',
            ),
            _DetailItem(label: 'Effectif paye', value: '${line.paidStaff}'),
            _DetailItem(label: 'Annee', value: '$selectedYear'),
            _DetailItem(
              label: 'Tarif mensuel',
              value: _money(annual.monthlyRate),
            ),
            const Divider(height: 28),
            const Text(
              'Commentaire statut',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('statusComment_${line.id}'),
              initialValue: line.statusComment,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: line.status == 'Autre'
                    ? 'Commentaire requis pour le statut Autre'
                    : 'Ajouter un commentaire si necessaire',
              ),
              onChanged: (value) =>
                  onUpdate(line.copyWith(statusComment: value)),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onDelete,
              icon: AppIcon(
                AppIcons.warning,
                size: 17,
                color: const Color(0xFFB91C1C),
              ),
              label: const Text('Supprimer la ligne'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineIssueList extends StatelessWidget {
  const _LineIssueList({required this.issues});

  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final issue in issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(
                    AppIcons.warning,
                    size: 14,
                    color: const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      issue,
                      style: const TextStyle(
                        color: Color(0xFF78350F),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SyncFooter extends StatelessWidget {
  const _SyncFooter({
    required this.offline,
    required this.syncing,
    required this.remoteSyncConfigured,
    required this.pendingChanges,
    required this.onRetrySync,
  });

  final bool offline;
  final bool syncing;
  final bool remoteSyncConfigured;
  final int pendingChanges;
  final VoidCallback onRetrySync;

  @override
  Widget build(BuildContext context) {
    final message = offline
        ? 'Hors ligne - vos modifications sont conservees sur cet ordinateur.'
        : !remoteSyncConfigured && pendingChanges > 0
        ? 'Base distante non configuree - modifications conservees localement.'
        : syncing
        ? 'Synchronisation en arriere-plan...'
        : pendingChanges == 0
        ? 'Tout est enregistre.'
        : '$pendingChanges modification(s) en attente de synchronisation.';

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7EF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppIcon(
            offline ? AppIcons.cloudOff : AppIcons.cloudDone,
            size: 17,
            color: offline ? const Color(0xFFB45309) : const Color(0xFF15803D),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
          if (!offline &&
              remoteSyncConfigured &&
              !syncing &&
              pendingChanges > 0) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onRetrySync,
              icon: AppIcon(AppIcons.sync, size: 15),
              label: const Text('Reessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

String _money(double value) {
  return '${_number(value)} FCFA';
}

String _number(double value) {
  final negative = value < 0;
  final rounded = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(' ');
  }
  return negative ? '-$buffer' : buffer.toString();
}

int _parseInt(String value) {
  return _parseMoney(value).round();
}

double _parseMoney(String value) {
  var cleaned = value.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (cleaned.isEmpty || cleaned == '-') return 0;

  if (cleaned.contains('.') && cleaned.contains(',')) {
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
  } else if (cleaned.contains(',')) {
    cleaned = _normalizeSingleSeparator(cleaned, ',');
  } else if (cleaned.contains('.')) {
    cleaned = _normalizeSingleSeparator(cleaned, '.');
  }

  return double.tryParse(cleaned) ?? 0;
}

String _normalizeSingleSeparator(String value, String separator) {
  final parts = value.split(separator);
  if (parts.length == 1) return value;

  final last = parts.last;
  final separatorLooksLikeThousands =
      last.length == 3 &&
      parts.take(parts.length - 1).every((part) => part.isNotEmpty);

  if (separatorLooksLikeThousands) {
    return parts.join();
  }

  return separator == ',' ? value.replaceAll(',', '.') : value;
}
