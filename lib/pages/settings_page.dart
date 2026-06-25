import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/billing_line.dart';
import '../models/billing_years.dart';
import '../theme/app_icons.dart';
import '../widgets/app_icon.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.selectedYear,
    required this.pendingOutboxCount,
    required this.offline,
    required this.syncing,
    required this.remoteSyncConfigured,
    required this.onYearChanged,
    required this.onResetLocalData,
    required this.onResetRemoteData,
  });

  final int selectedYear;
  final int pendingOutboxCount;
  final bool offline;
  final bool syncing;
  final bool remoteSyncConfigured;
  final ValueChanged<int> onYearChanged;
  final Future<void> Function() onResetLocalData;
  final Future<void> Function() onResetRemoteData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parametres',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Listes et preferences simples du MVP.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Card(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Activites',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final activity in activities)
                                  Chip(label: Text(activity)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Card(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statuts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final status in statuses)
                                  Chip(label: Text(status)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Annee active',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              initialValue: selectedYear,
                              decoration: InputDecoration(
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: AppIcon(AppIcons.calendar, size: 17),
                                ),
                              ),
                              items: [
                                for (final option in billingYearOptions())
                                  DropdownMenuItem(
                                    value: option,
                                    child: Text('$option'),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) onYearChanged(value);
                              },
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Synchronisation',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            _SettingsStatusLine(
                              label: 'Base distante',
                              value: remoteSyncConfigured
                                  ? 'Configuree'
                                  : 'Non configuree',
                              ok: remoteSyncConfigured,
                            ),
                            _SettingsStatusLine(
                              label: 'Mode',
                              value: offline ? 'Hors ligne' : 'En ligne',
                              ok: !offline,
                            ),
                            _SettingsStatusLine(
                              label: 'Etat',
                              value: syncing
                                  ? 'Synchronisation'
                                  : pendingOutboxCount == 0
                                  ? 'A jour'
                                  : '$pendingOutboxCount en attente',
                              ok: pendingOutboxCount == 0 && !syncing,
                            ),
                            if (kDebugMode) ...[
                              const SizedBox(height: 28),
                              const Divider(),
                              const SizedBox(height: 14),
                              const Text(
                                'Debug',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Visible uniquement en mode debug. La base locale est stockee dans les donnees applicatives de Windows, pas dans le dossier du projet.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _confirmReset(context),
                                icon: AppIcon(AppIcons.warning, size: 18),
                                label: const Text(
                                  'Reinitialiser les donnees locales',
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: remoteSyncConfigured
                                    ? () => _confirmResetRemote(context)
                                    : null,
                                icon: AppIcon(AppIcons.cloudOff, size: 18),
                                label: const Text(
                                  'Reinitialiser la base distante',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reinitialiser les donnees locales ?'),
          content: const Text(
            'Cette action vide les donnees sauvegardees sur cet ordinateur. Elle est reservee au debug.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reinitialiser'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await onResetLocalData();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donnees locales reinitialisees.')),
    );
  }

  Future<void> _confirmResetRemote(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reinitialiser la base distante ?'),
          content: const Text(
            'Cette action vide les donnees Firestore de facturation. Elle est reservee au debug.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reinitialiser'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    await onResetRemoteData();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Base distante reinitialisee.')),
    );
  }
}

class _SettingsStatusLine extends StatelessWidget {
  const _SettingsStatusLine({
    required this.label,
    required this.value,
    required this.ok,
  });

  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF15803D) : const Color(0xFFB45309);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              border: Border.all(color: color.withValues(alpha: 0.24)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
