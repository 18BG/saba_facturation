import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../import/billing_excel_importer.dart';
import '../models/billing_line.dart';
import '../theme/app_icons.dart';
import '../widgets/app_icon.dart';

enum ImportApplyMode { append, replace }

class ImportPage extends StatefulWidget {
  const ImportPage({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
    required this.onApplyImport,
  });

  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  final Future<void> Function(List<BillingLine> lines, ImportApplyMode mode)
  onApplyImport;

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  final BillingExcelImporter _importer = const BillingExcelImporter();
  BillingExcelImportResult? _result;
  String? _error;
  bool _isPicking = false;
  bool _isApplying = false;

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _error = null;
    });

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final file = picked.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Le fichier choisi est vide ou illisible.');
      }

      final result = _importer.importBytes(
        Uint8List.fromList(bytes),
        year: widget.selectedYear,
        sourceName: file.name,
      );

      if (!mounted) return;
      setState(() => _result = result);
    } on Object catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.toString().replaceFirst('FormatException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _apply(ImportApplyMode mode) async {
    final result = _result;
    if (result == null || result.lines.isEmpty) return;

    setState(() => _isApplying = true);
    try {
      await widget.onApplyImport(result.lines, mode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == ImportApplyMode.replace
                ? '${result.importedCount} ligne(s) importee(s) et base locale remplacee.'
                : '${result.importedCount} ligne(s) ajoutee(s) a la base locale.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            year: widget.selectedYear,
            isPicking: _isPicking,
            onYearChanged: widget.onYearChanged,
            onPickFile: _pickFile,
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 14),
          ],
          Expanded(
            child: result == null
                ? const _EmptyImportState()
                : _ImportReport(
                    result: result,
                    isApplying: _isApplying,
                    onAppend: () => _apply(ImportApplyMode.append),
                    onReplace: () => _confirmReplace(result),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReplace(BillingExcelImportResult result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remplacer les donnees locales ?'),
          content: Text(
            '${result.importedCount} ligne(s) vont remplacer les lignes actuellement stockees sur cet ordinateur.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remplacer'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) await _apply(ImportApplyMode.replace);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.year,
    required this.isPicking,
    required this.onYearChanged,
    required this.onPickFile,
  });

  final int year;
  final bool isPicking;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import Excel',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 4),
              Text(
                'Importer le fichier annuel, verifier les alertes, puis appliquer.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD7DEE8)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButton<int>(
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
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: isPicking ? null : onPickFile,
          icon: isPicking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : AppIcon(AppIcons.fileOpen, size: 18),
          label: Text(isPicking ? 'Lecture...' : 'Choisir Excel'),
        ),
      ],
    );
  }
}

class _EmptyImportState extends StatelessWidget {
  const _EmptyImportState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parcours MVP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _StepTile(
              icon: AppIcons.fileOpen,
              title: '1. Choisir un fichier .xlsx',
              description:
                  'Le format actuel avec deux lignes d en-tete est reconnu automatiquement.',
            ),
            _StepTile(
              icon: AppIcons.rule,
              title: '2. Verifier le rapport',
              description:
                  'References manquantes, doublons et activites inconnues sont signales.',
            ),
            _StepTile(
              icon: AppIcons.warning,
              title: '3. Completer les brouillons',
              description:
                  'Les lignes sans reference restent importables mais seront visibles comme incompletes.',
            ),
            _StepTile(
              icon: AppIcons.cloudDone,
              title: '4. Appliquer',
              description:
                  'Ajouter aux donnees locales ou remplacer la base locale apres confirmation.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportReport extends StatelessWidget {
  const _ImportReport({
    required this.result,
    required this.isApplying,
    required this.onAppend,
    required this.onReplace,
  });

  final BillingExcelImportResult result;
  final bool isApplying;
  final VoidCallback onAppend;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReportTile(
                label: 'Fichier',
                value: result.sourceName,
                icon: AppIcons.fileOpen,
              ),
            ),
            const SizedBox(width: 10),
            _ReportTile(
              label: 'Annee',
              value: '${result.year}',
              icon: AppIcons.calendar,
              compact: true,
            ),
            const SizedBox(width: 10),
            _ReportTile(
              label: 'Lignes',
              value: '${result.importedCount}',
              icon: AppIcons.lines,
              compact: true,
            ),
            const SizedBox(width: 10),
            _ReportTile(
              label: 'Alertes',
              value: '${result.warningCount}',
              icon: AppIcons.warning,
              color: result.hasWarnings
                  ? const Color(0xFFB45309)
                  : const Color(0xFF15803D),
              compact: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _WarningsPanel(result: result)),
              const SizedBox(width: 12),
              SizedBox(width: 390, child: _PreviewPanel(lines: result.lines)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                result.hasWarnings
                    ? 'Import possible en brouillon. Les cellules incompletes restent visibles dans la grille.'
                    : 'Aucune alerte majeure detectee sur ce fichier.',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: isApplying || result.lines.isEmpty ? null : onReplace,
              icon: AppIcon(AppIcons.sync, size: 18),
              label: const Text('Remplacer local'),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: isApplying || result.lines.isEmpty ? null : onAppend,
              icon: isApplying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : AppIcon(AppIcons.add, size: 18),
              label: const Text('Ajouter les lignes'),
            ),
          ],
        ),
      ],
    );
  }
}

class _WarningsPanel extends StatelessWidget {
  const _WarningsPanel({required this.result});

  final BillingExcelImportResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rapport d import',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _WarningRow(
              label: 'References manquantes',
              value: result.missingReferences,
              active: result.missingReferences > 0,
            ),
            _WarningRow(
              label: 'Sites manquants',
              value: result.missingSites,
              active: result.missingSites > 0,
            ),
            _WarningRow(
              label: 'References en doublon',
              value: result.duplicateReferences.length,
              active: result.duplicateReferences.isNotEmpty,
            ),
            _WarningRow(
              label: 'Activites inconnues',
              value: result.unknownActivities.length,
              active: result.unknownActivities.isNotEmpty,
            ),
            const Divider(height: 28),
            _SetPreview(
              title: 'Doublons',
              values: result.duplicateReferences,
              emptyText: 'Aucun doublon de reference detecte.',
            ),
            const SizedBox(height: 14),
            _SetPreview(
              title: 'Activites a verifier',
              values: result.unknownActivities,
              emptyText: 'Toutes les activites reconnues.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.lines});

  final List<BillingLine> lines;

  @override
  Widget build(BuildContext context) {
    final preview = lines.take(8).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apercu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: preview.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final line = preview[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          line.name.isEmpty ? 'Site manquant' : line.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            line.reference.isEmpty
                                ? 'Ref manquante'
                                : line.reference,
                            line.activity.isEmpty
                                ? 'Activite manquante'
                                : line.activity,
                            'Eff ${line.billedStaff}/${line.paidStaff}',
                          ].join('  |  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Text(
              lines.length > preview.length
                  ? '+ ${lines.length - preview.length} autre(s) ligne(s)'
                  : '${lines.length} ligne(s)',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.compact = false,
  });

  final String label;
  final String value;
  final List<List> icon;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: compact ? 140 : null,
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE1E7EF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppIcon(icon, color: effectiveColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({
    required this.label,
    required this.value,
    required this.active,
  });

  final String label;
  final int value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFB45309) : const Color(0xFF15803D);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AppIcon(
            active ? AppIcons.warning : AppIcons.cloudDone,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}

class _SetPreview extends StatelessWidget {
  const _SetPreview({
    required this.title,
    required this.values,
    required this.emptyText,
  });

  final String title;
  final Set<String> values;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (values.isEmpty)
          Text(emptyText, style: const TextStyle(color: Color(0xFF64748B)))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in values.take(8))
                Chip(
                  label: Text(value, overflow: TextOverflow.ellipsis),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFF59E0B)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AppIcon(AppIcons.warning, color: const Color(0xFFB45309)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final List<List> icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
