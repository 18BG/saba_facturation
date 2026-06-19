import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/billing_line.dart';
import '../theme/app_icons.dart';
import '../widgets/app_icon.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.onResetLocalData});

  final Future<void> Function() onResetLocalData;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parametres', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
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
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Activites', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final activity in activities) Chip(label: Text(activity)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statuts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final status in statuses) Chip(label: Text(status)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Annee par defaut', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(10),
                                child: AppIcon(AppIcons.calendar, size: 17),
                              ),
                              hintText: '2026',
                            ),
                          ),
                          if (kDebugMode) ...[
                            const SizedBox(height: 28),
                            const Divider(),
                            const SizedBox(height: 14),
                            const Text(
                              'Debug',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Visible uniquement en mode debug. Permet de repartir sur une base locale vide.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _confirmReset(context),
                              icon: AppIcon(AppIcons.warning, size: 18),
                              label: const Text('Reinitialiser les donnees locales'),
                            ),
                          ],
                        ],
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
}
