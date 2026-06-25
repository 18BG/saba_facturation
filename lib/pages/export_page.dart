import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../export/billing_excel_exporter.dart';
import '../models/billing_line.dart';
import '../models/billing_years.dart';
import '../theme/app_icons.dart';
import '../widgets/app_icon.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({
    super.key,
    required this.lines,
    required this.selectedYear,
  });

  final List<BillingLine> lines;
  final int selectedYear;

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final BillingExcelExporter _exporter = const BillingExcelExporter();
  late int _year;
  bool _onlyActive = true;
  bool _includeBalance = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _year = widget.selectedYear;
  }

  @override
  void didUpdateWidget(covariant ExportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedYear != oldWidget.selectedYear) {
      _year = widget.selectedYear;
    }
  }

  int get _exportableCount {
    return widget.lines
        .where((line) => !_onlyActive || line.status == 'Actif')
        .length;
  }

  Future<void> _exportFile() async {
    if (_exportableCount == 0) return;

    setState(() => _isExporting = true);

    try {
      final bytes = _exporter.exportLines(
        widget.lines,
        options: BillingExcelExportOptions(
          year: _year,
          onlyActive: _onlyActive,
          includeBalanceColumns: _includeBalance,
        ),
      );

      final fileName = 'facturation_${_year}_${_dateStamp()}.xlsx';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Exporter la facturation',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: bytes,
        lockParentWindow: true,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null ? 'Export prepare.' : 'Export enregistre : $path',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export impossible : $error')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Excel',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sortir un fichier proche du classeur actuel, avec totaux et reliquats.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 560,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _year,
                      decoration: const InputDecoration(labelText: 'Annee'),
                      items: [
                        for (final option in billingYearOptions())
                          DropdownMenuItem(
                            value: option,
                            child: Text('$option'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _year = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _onlyActive,
                      title: const Text(
                        'Exporter uniquement les lignes actives',
                      ),
                      subtitle: Text(
                        '$_exportableCount ligne(s) seront exportees',
                      ),
                      onChanged: (value) => setState(() => _onlyActive = value),
                    ),
                    SwitchListTile(
                      value: _includeBalance,
                      title: const Text('Inclure attendu, paye et reliquat'),
                      subtitle: const Text(
                        'Ajoute les colonnes de suivi a date et annuel',
                      ),
                      onChanged: (value) =>
                          setState(() => _includeBalance = value),
                    ),
                    if (_exportableCount == 0) ...[
                      const SizedBox(height: 8),
                      _InfoLine(
                        icon: AppIcons.warning,
                        text:
                            'Aucune ligne ne correspond aux options choisies.',
                      ),
                    ],
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: AppIcons.rule,
                      text:
                          'Les filtres Excel automatiques seront ajoutes dans une iteration suivante.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isExporting || _exportableCount == 0
                          ? null
                          : _exportFile,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : AppIcon(AppIcons.exportFile),
                      label: Text(
                        _isExporting ? 'Export...' : 'Exporter le fichier',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateStamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final List<List> icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 17, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
      ],
    );
  }
}
