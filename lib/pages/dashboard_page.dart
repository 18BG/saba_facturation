import 'package:flutter/material.dart';

import '../models/billing_line.dart';
import '../theme/app_icons.dart';
import '../widgets/metric_tile.dart';
import '../widgets/status_badge.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.lines,
    required this.selectedYear,
  });

  final List<BillingLine> lines;
  final int selectedYear;

  @override
  Widget build(BuildContext context) {
    final expected = lines.fold<double>(0, (sum, line) => sum + line.expectedDueAmount(selectedYear));
    final paid = lines.fold<double>(0, (sum, line) => sum + line.paidTotalDue(selectedYear));
    final balance = lines.fold<double>(0, (sum, line) => sum + line.balanceDue(selectedYear));
    final activeLines = lines.where((line) => line.status == 'Actif').length;
    final topBalances = [...lines]
      ..sort((a, b) => b.balanceDue(selectedYear).compareTo(a.balanceDue(selectedYear)));
    final monthsDue = lines.isEmpty ? 0 : lines.first.billingMonthsDue(selectedYear);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageTitle(
            title: 'Dashboard',
            subtitle: "Vue rapide de l'annee $selectedYear - suivi jusqu'au dernier mois clos ($monthsDue/12).",
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricTile(
                label: 'Lignes actives',
                value: '$activeLines',
                icon: AppIcons.lines,
                caption: 'toute l’année',
              ),
              MetricTile(
                label: 'Attendu à date',
                value: _money(expected),
                icon: AppIcons.receipt,
                caption: 'toute l’année',
              ),
              MetricTile(
                label: 'Payé à date',
                value: _money(paid),
                icon: AppIcons.paid,
                caption: 'toute l’année',
              ),
              MetricTile(
                label: 'Reliquat',
                value: _money(balance),
                icon: AppIcons.warning,
                caption: 'toute l’année',
                color: const Color(0xFFB45309),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Plus gros reliquats',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.separated(
                              itemCount: topBalances.length,
                              separatorBuilder: (_, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final line = topBalances[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(line.name),
                                  subtitle: Text('${line.reference} - ${line.activity}'),
                                  trailing: Text(
                                    _money(line.balanceDue(selectedYear)),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Repartition par activite',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          for (final activity in activities)
                            if (lines.any((line) => line.activity == activity))
                              _ActivityRow(
                                activity: activity,
                                count: lines.where((line) => line.activity == activity).length,
                              ),
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
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.count});

  final String activity;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(activity, style: const TextStyle(fontWeight: FontWeight.w700))),
          StatusBadge(label: '$count ligne(s)', compact: true),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }
}

String _money(double value) {
  final negative = value < 0;
  final rounded = value.abs().round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final fromEnd = rounded.length - i;
    buffer.write(rounded[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(' ');
  }
  return '${negative ? '-' : ''}$buffer FCFA';
}
