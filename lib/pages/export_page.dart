import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../widgets/app_icon.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  int _year = 2026;
  bool _onlyActive = true;
  bool _includeBalance = true;
  bool _includeFilters = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Export Excel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'Sortir un fichier proche du classeur actuel, avec totaux et reliquats.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 520,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _year,
                      decoration: const InputDecoration(labelText: 'Annee'),
                      items: const [
                        DropdownMenuItem(value: 2024, child: Text('2024')),
                        DropdownMenuItem(value: 2025, child: Text('2025')),
                        DropdownMenuItem(value: 2026, child: Text('2026')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _year = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _onlyActive,
                      title: const Text('Exporter uniquement les lignes actives'),
                      onChanged: (value) => setState(() => _onlyActive = value),
                    ),
                    SwitchListTile(
                      value: _includeBalance,
                      title: const Text('Inclure total paye et reliquat'),
                      onChanged: (value) => setState(() => _includeBalance = value),
                    ),
                    SwitchListTile(
                      value: _includeFilters,
                      title: const Text('Activer les filtres Excel'),
                      onChanged: (value) => setState(() => _includeFilters = value),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: AppIcon(AppIcons.exportFile),
                      label: const Text('Exporter le fichier'),
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
}
