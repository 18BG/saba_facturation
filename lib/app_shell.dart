import 'package:flutter/material.dart';

import 'models/billing_line.dart';
import 'pages/dashboard_page.dart';
import 'pages/export_page.dart';
import 'pages/facturation_page.dart';
import 'pages/import_page.dart';
import 'pages/settings_page.dart';
import 'storage/billing_local_store.dart';
import 'theme/app_icons.dart';
import 'widgets/app_icon.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.initialLines,
    this.persistLocalData = true,
  });

  final List<BillingLine>? initialLines;
  final bool persistLocalData;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  BillingLocalStore? _localStore;
  int _selectedIndex = 0;
  int _selectedYear = 2026;
  List<BillingLine> _lines = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _localStore = widget.persistLocalData ? BillingLocalStore() : null;
    _loadLines();
  }

  Future<void> _loadLines() async {
    if (widget.initialLines != null) {
      setState(() {
        _lines = List.of(widget.initialLines!);
        _isLoading = false;
      });
      return;
    }

    final savedLines = await _localStore?.loadLines();
    if (!mounted) return;
    setState(() {
      _lines = savedLines ?? <BillingLine>[];
      _isLoading = false;
    });
  }

  Future<void> _saveLines(List<BillingLine> lines) async {
    setState(() => _lines = List.of(lines));
    await _localStore?.saveLines(lines);
  }

  Future<void> _resetLocalData() async {
    await _localStore?.clear();
    if (!mounted) return;
    setState(() => _lines = <BillingLine>[]);
  }

  Future<void> _applyImportedLines(List<BillingLine> imported, ImportApplyMode mode) async {
    final nextLines = switch (mode) {
      ImportApplyMode.append => <BillingLine>[..._lines, ...imported],
      ImportApplyMode.replace => List<BillingLine>.of(imported),
    };

    await _saveLines(nextLines);
    if (!mounted) return;
    setState(() => _selectedIndex = 0);
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
          onOpenImport: () => setState(() => _selectedIndex = 2),
        ),
      1 => DashboardPage(lines: _lines, selectedYear: _selectedYear),
      2 => ImportPage(
          selectedYear: _selectedYear,
          onYearChanged: (year) => setState(() => _selectedYear = year),
          onApplyImport: _applyImportedLines,
        ),
      3 => const ExportPage(),
      _ => SettingsPage(onResetLocalData: _resetLocalData),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            extended: MediaQuery.sizeOf(context).width >= 1180,
            backgroundColor: Colors.white,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            leading: const Padding(
              padding: EdgeInsets.only(top: 18, bottom: 18),
              child: _BrandMark(),
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
          Expanded(child: _selectedPage),
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
