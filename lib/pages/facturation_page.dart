import 'dart:async';

import 'package:flutter/material.dart';

import '../models/billing_line.dart';
import '../sync/pending_change.dart';
import '../sync/sync_queue.dart';
import '../theme/app_icons.dart';
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
    required this.onOpenImport,
  });

  final List<BillingLine> lines;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<List<BillingLine>> onLinesChanged;
  final VoidCallback onOpenImport;

  @override
  State<FacturationPage> createState() => _FacturationPageState();
}

class _FacturationPageState extends State<FacturationPage> {
  late List<BillingLine> _lines;
  final SyncQueue _syncQueue = SyncQueue();
  BillingLine? _selectedLine;
  String _query = '';
  String _activityFilter = 'Toutes';
  String _statusFilter = 'Actif';
  bool _onlyWithBalance = false;
  bool _onlyIncomplete = false;
  late int _year;
  bool _offline = false;
  Timer? _syncTimer;

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
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  List<BillingLine> get _filteredLines {
    final q = _query.trim().toLowerCase();
    return _lines.where((line) {
      final matchesQuery = q.isEmpty ||
          line.reference.toLowerCase().contains(q) ||
          line.name.toLowerCase().contains(q) ||
          line.activity.toLowerCase().contains(q);
      final matchesActivity = _activityFilter == 'Toutes' || line.activity == _activityFilter;
      final matchesStatus = _statusFilter == 'Tous' || line.status == _statusFilter;
      final matchesBalance = !_onlyWithBalance || line.balanceDue(_year) > 0;
      final matchesIncomplete = !_onlyIncomplete || line.isIncomplete;
      return matchesQuery &&
          matchesActivity &&
          matchesStatus &&
          matchesBalance &&
          matchesIncomplete;
    }).toList();
  }

  int get _pendingChanges {
    final lineLevelPending = _lines.where((line) => line.syncState != SyncState.synced).length;
    return _syncQueue.pendingCount > lineLevelPending ? _syncQueue.pendingCount : lineLevelPending;
  }

  double get _expectedTotal {
    return _filteredLines.fold<double>(0, (sum, line) => sum + line.expectedDueAmount(_year));
  }

  double get _paidTotal {
    return _filteredLines.fold<double>(0, (sum, line) => sum + line.paidTotalDue(_year));
  }

  double get _balanceTotal {
    return _filteredLines.fold<double>(0, (sum, line) => sum + line.balanceDue(_year));
  }

  int get _billedStaffTotal {
    return _filteredLines.fold<int>(0, (sum, line) => sum + line.billedStaff);
  }

  int get _paidStaffTotal {
    return _filteredLines.fold<int>(0, (sum, line) => sum + line.paidStaff);
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
    setState(() {
      final index = _lines.indexOf(oldLine);
      if (index == -1) return;
      _enqueueDiffs(oldLine, newLine, index);
      final updated = newLine.copyWith(syncState: _offline ? SyncState.dirty : SyncState.syncing);
      _lines[index] = updated;
      if (_selectedLine == oldLine) _selectedLine = updated;
    });
    widget.onLinesChanged(_lines);

    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(milliseconds: 900), _markPendingAsSynced);
  }

  void _markPendingAsSynced() {
    if (_offline) return;
    setState(() {
      _syncQueue.markPendingAsSynced();
      _syncQueue.pruneSynced();
      _lines = [
        for (final line in _lines)
          if (line.syncState == SyncState.syncing || line.syncState == SyncState.dirty)
            line.copyWith(syncState: SyncState.synced)
          else
            line,
      ];
      if (_selectedLine != null) {
        _selectedLine = _lines.firstWhere(
          (line) => line.reference == _selectedLine!.reference,
          orElse: () => _selectedLine!,
        );
      }
    });
    widget.onLinesChanged(_lines);
  }

  void _enqueueDiffs(BillingLine oldLine, BillingLine newLine, int lineIndex) {
    final reference = newLine.reference.trim().isEmpty
        ? '__draft_line_$lineIndex'
        : newLine.reference.trim();

    void enqueueLineField(String field, Object? oldValue, Object? newValue) {
      if (oldValue == newValue) return;
      _syncQueue.enqueue(
        PendingChange(
          id: '${DateTime.now().microsecondsSinceEpoch}_$field',
          reference: reference,
          scope: ChangeScope.line,
          field: field,
          value: newValue,
          createdAt: DateTime.now(),
        ),
      );
    }

    enqueueLineField('reference', oldLine.reference, newLine.reference);
    enqueueLineField('name', oldLine.name, newLine.name);
    enqueueLineField('activity', oldLine.activity, newLine.activity);
    enqueueLineField('startDate', oldLine.startDate, newLine.startDate);
    enqueueLineField('endDate', oldLine.endDate, newLine.endDate);
    enqueueLineField('contractNature', oldLine.contractNature, newLine.contractNature);
    enqueueLineField('billedStaff', oldLine.billedStaff, newLine.billedStaff);
    enqueueLineField('paidStaff', oldLine.paidStaff, newLine.paidStaff);
    final oldAnnual = oldLine.annualBilling(_year);
    final newAnnual = newLine.annualBilling(_year);
    if (oldAnnual.monthlyRate != newAnnual.monthlyRate) {
      _syncQueue.enqueue(
        PendingChange(
          id: '${DateTime.now().microsecondsSinceEpoch}_monthlyRate',
          reference: reference,
          scope: ChangeScope.annualBilling,
          field: 'monthlyRate',
          value: newAnnual.monthlyRate,
          year: _year,
          createdAt: DateTime.now(),
        ),
      );
    }
    enqueueLineField('status', oldLine.status, newLine.status);
    enqueueLineField('statusComment', oldLine.statusComment, newLine.statusComment);

    for (final month in months) {
      final oldValue = oldAnnual.payments[month] ?? 0;
      final newValue = newAnnual.payments[month] ?? 0;
      if (oldValue == newValue) continue;
      _syncQueue.enqueue(
        PendingChange(
          id: '${DateTime.now().microsecondsSinceEpoch}_$month',
          reference: reference,
          scope: ChangeScope.paymentCell,
          field: month,
          value: newValue,
          year: _year,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  void _addLine() {
    final line = BillingLine(
      reference: '',
      name: '',
      activity: 'GARDIENNAGE',
      startDate: '',
      endDate: '',
      contractNature: '',
      billedStaff: 0,
      paidStaff: 0,
      annualBillings: {
        _year: AnnualBillingData.empty(),
      },
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLines;

    return Column(
      children: [
        _TopBar(
          year: _year,
          offline: _offline,
          pendingChanges: _pendingChanges,
          onYearChanged: (year) {
            setState(() => _year = year);
            widget.onYearChanged(year);
          },
          onOfflineChanged: (value) {
            setState(() => _offline = value);
            if (!value) _markPendingAsSynced();
          },
          onQueryChanged: (value) => setState(() => _query = value),
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
                        onlyWithBalance: _onlyWithBalance,
                        onlyIncomplete: _onlyIncomplete,
                        onActivityChanged: (value) => setState(() => _activityFilter = value),
                        onStatusChanged: (value) => setState(() => _statusFilter = value),
                        onBalanceChanged: (value) => setState(() => _onlyWithBalance = value),
                        onIncompleteChanged: (value) => setState(() => _onlyIncomplete = value),
                        onAddLine: _addLine,
                        onImport: widget.onOpenImport,
                      ),
                      const SizedBox(height: 12),
                      _SummaryStrip(
                        lineCount: filtered.length,
                        billedStaff: _billedStaffTotal,
                        paidStaff: _paidStaffTotal,
                        expectedTotal: _expectedTotal,
                        paidTotal: _paidTotal,
                        balanceTotal: _balanceTotal,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _BillingGrid(
                          lines: filtered,
                          selectedYear: _year,
                          duplicateReferences: _duplicateReferences,
                          selectedLine: _selectedLine,
                          onSelectLine: (line) => setState(() => _selectedLine = line),
                          onUpdateLine: _updateLine,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _SyncFooter(offline: _offline, pendingChanges: _pendingChanges),
                    ],
                  ),
                ),
                if (_selectedLine != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 330,
                    child: _LineDetailPanel(
                      line: _selectedLine!,
                      selectedYear: _year,
                      onClose: () => setState(() => _selectedLine = null),
                    ),
                  ),
                ],
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
    required this.pendingChanges,
    required this.onYearChanged,
    required this.onOfflineChanged,
    required this.onQueryChanged,
  });

  final int year;
  final bool offline;
  final int pendingChanges;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<bool> onOfflineChanged;
  final ValueChanged<String> onQueryChanged;

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
                items: const [
                  DropdownMenuItem(value: 2024, child: Text('2024')),
                  DropdownMenuItem(value: 2025, child: Text('2025')),
                  DropdownMenuItem(value: 2026, child: Text('2026')),
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
                SyncBadge(state: pendingChanges == 0 ? SyncState.synced : SyncState.dirty),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.activityFilter,
    required this.statusFilter,
    required this.onlyWithBalance,
    required this.onlyIncomplete,
    required this.onActivityChanged,
    required this.onStatusChanged,
    required this.onBalanceChanged,
    required this.onIncompleteChanged,
    required this.onAddLine,
    required this.onImport,
  });

  final String activityFilter;
  final String statusFilter;
  final bool onlyWithBalance;
  final bool onlyIncomplete;
  final ValueChanged<String> onActivityChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onBalanceChanged;
  final ValueChanged<bool> onIncompleteChanged;
  final VoidCallback onAddLine;
  final VoidCallback onImport;

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
              selected: onlyWithBalance,
              avatar: AppIcon(AppIcons.warning, size: 16),
              label: const Text('Avec reliquat'),
              onSelected: onBalanceChanged,
            ),
            const SizedBox(width: 8),
            FilterChip(
              selected: onlyIncomplete,
              avatar: AppIcon(AppIcons.rule, size: 16),
              label: const Text('Incompletes'),
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
              onPressed: () {},
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
          Text('$label : ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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
    required this.expectedTotal,
    required this.paidTotal,
    required this.balanceTotal,
  });

  final int lineCount;
  final int billedStaff;
  final int paidStaff;
  final double expectedTotal;
  final double paidTotal;
  final double balanceTotal;

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
            caption: 'vue filtrée',
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Eff facture',
            value: '$billedStaff',
            icon: AppIcons.staff,
            caption: 'vue filtrée',
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Eff paye',
            value: '$paidStaff',
            icon: AppIcons.badge,
            caption: 'vue filtrée',
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Attendu à date',
            value: _money(expectedTotal),
            icon: AppIcons.receipt,
            caption: 'vue filtrée',
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Payé à date',
            value: _money(paidTotal),
            icon: AppIcons.paid,
            caption: 'vue filtrée',
          ),
          const SizedBox(width: 8),
          MetricTile(
            label: 'Reliquat',
            value: _money(balanceTotal),
            icon: AppIcons.trend,
            caption: 'vue filtrée',
            color: balanceTotal > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D),
          ),
        ],
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
  });

  final List<BillingLine> lines;
  final int selectedYear;
  final Set<String> duplicateReferences;
  final BillingLine? selectedLine;
  final ValueChanged<BillingLine> onSelectLine;
  final void Function(BillingLine oldLine, BillingLine newLine) onUpdateLine;

  static const widths = <double>[
    132,
    250,
    150,
    112,
    112,
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
    126,
    126,
    130,
    116,
  ];

  @override
  State<_BillingGrid> createState() => _BillingGridState();
}

class _BillingGridState extends State<_BillingGrid> {
  late final ScrollController _horizontalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
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
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _BillingGrid.widths.fold<double>(0, (sum, width) => sum + width),
            child: Column(
              children: [
                const _GridHeader(),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.lines.length,
                    itemExtent: 54,
                    itemBuilder: (context, index) {
                      final line = widget.lines[index];
                      return _GridRow(
                        line: line,
                        selectedYear: widget.selectedYear,
                        hasDuplicateReference: widget.duplicateReferences.contains(
                          line.reference.trim().toUpperCase(),
                        ),
                        selected: line == widget.selectedLine,
                        onSelect: () => widget.onSelectLine(line),
                        onUpdate: (updated) => widget.onUpdateLine(line, updated),
                      );
                    },
                  ),
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
      'Total paye',
      'Reliquat',
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
    required this.line,
    required this.selectedYear,
    required this.hasDuplicateReference,
    required this.selected,
    required this.onSelect,
    required this.onUpdate,
  });

  final BillingLine line;
  final int selectedYear;
  final bool hasDuplicateReference;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<BillingLine> onUpdate;

  @override
  Widget build(BuildContext context) {
    final annual = line.annualBilling(selectedYear);
    final background = selected
        ? const Color(0xFFEFF6FF)
        : line.isIncomplete
            ? const Color(0xFFFFFBEB)
            : Colors.white;

    return InkWell(
      onTap: onSelect,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            EditableCell(
              value: line.reference,
              width: _BillingGrid.widths[0],
              isRequired: true,
              hasError: hasDuplicateReference,
              errorMessage: hasDuplicateReference ? 'Reference deja utilisee' : null,
              onChanged: (value) => onUpdate(line.copyWith(reference: value)),
            ),
            EditableCell(
              value: line.name,
              width: _BillingGrid.widths[1],
              isRequired: true,
              onChanged: (value) => onUpdate(line.copyWith(name: value)),
            ),
            _DropdownCell(
              value: line.activity,
              values: activities,
              width: _BillingGrid.widths[2],
              onChanged: (value) => onUpdate(line.copyWith(activity: value)),
            ),
            EditableCell(
              value: line.startDate,
              width: _BillingGrid.widths[3],
              onChanged: (value) => onUpdate(line.copyWith(startDate: value)),
            ),
            EditableCell(
              value: line.endDate,
              width: _BillingGrid.widths[4],
              onChanged: (value) => onUpdate(line.copyWith(endDate: value)),
            ),
            EditableCell(
              value: line.contractNature,
              width: _BillingGrid.widths[5],
              onChanged: (value) => onUpdate(line.copyWith(contractNature: value)),
            ),
            EditableCell(
              value: '${line.billedStaff}',
              width: _BillingGrid.widths[6],
              textAlign: TextAlign.right,
              onChanged: (value) => onUpdate(line.copyWith(billedStaff: _parseInt(value))),
            ),
            EditableCell(
              value: '${line.paidStaff}',
              width: _BillingGrid.widths[7],
              textAlign: TextAlign.right,
              onChanged: (value) => onUpdate(line.copyWith(paidStaff: _parseInt(value))),
            ),
            EditableCell(
              value: _number(annual.monthlyRate),
              width: _BillingGrid.widths[8],
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
            for (var i = 0; i < months.length; i++)
              EditableCell(
                value: _number(annual.payments[months[i]] ?? 0),
                width: _BillingGrid.widths[9 + i],
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
            EditableCell(
              value: _money(line.paidTotalDue(selectedYear)),
              width: _BillingGrid.widths[21],
              textAlign: TextAlign.right,
              readOnly: true,
              onChanged: (_) {},
            ),
            EditableCell(
              value: _money(line.balanceDue(selectedYear)),
              width: _BillingGrid.widths[22],
              textAlign: TextAlign.right,
              readOnly: true,
              onChanged: (_) {},
            ),
            _DropdownCell(
              value: line.status,
              values: statuses,
              width: _BillingGrid.widths[23],
              onChanged: (value) => onUpdate(line.copyWith(status: value)),
            ),
            SizedBox(
              width: _BillingGrid.widths[24],
              child: Center(child: SyncBadge(state: line.syncState)),
            ),
          ],
        ),
      ),
    );
  }
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

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: DropdownButtonFormField<String>(
          initialValue: menuValues.first,
          isExpanded: true,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
          items: menuValues.map((item) {
            final label = item.isEmpty ? 'A renseigner' : item;
            return DropdownMenuItem(value: item, child: Text(label));
          }).toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _LineDetailPanel extends StatelessWidget {
  const _LineDetailPanel({
    required this.line,
    required this.selectedYear,
    required this.onClose,
  });

  final BillingLine line;
  final int selectedYear;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final annual = line.annualBilling(selectedYear);

    return Card(
      child: Padding(
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
            Text(line.reference.isEmpty ? 'Reference manquante' : line.reference),
            const SizedBox(height: 6),
            Text(line.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(label: line.status),
                SyncBadge(state: line.syncState),
              ],
            ),
            const Divider(height: 28),
            _DetailItem(label: 'Activite', value: line.activity),
            _DetailItem(label: 'Contrat', value: '${line.startDate} -> ${line.endDate.isEmpty ? 'Actif' : line.endDate}'),
            _DetailItem(label: 'Effectif facture', value: '${line.billedStaff}'),
            _DetailItem(label: 'Effectif paye', value: '${line.paidStaff}'),
            _DetailItem(label: 'Annee', value: '$selectedYear'),
            _DetailItem(label: 'Tarif mensuel', value: _money(annual.monthlyRate)),
            const Divider(height: 28),
            _DetailItem(
              label: 'Mois dus',
              value: '${line.billingMonthsDue(selectedYear)} / 12',
            ),
            _DetailItem(label: 'Attendu a date', value: _money(line.expectedDueAmount(selectedYear))),
            _DetailItem(label: 'Total paye a date', value: _money(line.paidTotalDue(selectedYear))),
            _DetailItem(label: 'Reliquat', value: _money(line.balanceDue(selectedYear))),
            _DetailItem(label: 'Attendu annuel', value: _money(line.expectedYearAmount(selectedYear))),
            if (line.statusComment.isNotEmpty) ...[
              const Divider(height: 28),
              const Text('Commentaire', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(line.statusComment),
            ],
          ],
        ),
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
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SyncFooter extends StatelessWidget {
  const _SyncFooter({required this.offline, required this.pendingChanges});

  final bool offline;
  final int pendingChanges;

  @override
  Widget build(BuildContext context) {
    final message = offline
        ? 'Hors ligne - vos modifications sont conservees sur cet ordinateur.'
        : pendingChanges == 0
            ? 'Tout est enregistre.'
            : '$pendingChanges modification(s) en attente de synchronisation.';

    return Container(
      height: 34,
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
  return int.tryParse(value.replaceAll(' ', '').replaceAll(',', '').trim()) ?? 0;
}

double _parseMoney(String value) {
  return double.tryParse(value.replaceAll(' ', '').replaceAll(',', '.').trim()) ?? 0;
}
