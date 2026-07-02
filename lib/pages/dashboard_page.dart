import 'package:flutter/material.dart';

import '../models/billing_line.dart';
import '../theme/app_icons.dart';
import '../validation/billing_validation.dart';
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
    final countedLines = linesCountedInBillingTotals(lines).toList();
    final activeLines = lines.where((line) => line.status == 'Actif').length;
    final commentCount = lines.fold<int>(
      0,
      (sum, line) => sum + line.cellComments.length,
    );
    final commentedLines = lines
        .where((line) => line.cellComments.isNotEmpty)
        .toList();
    final validation = validateBillingLines(lines, year: selectedYear);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PageTitle(
            title: 'Dashboard',
            subtitle:
                "Vue rapide de l'annee $selectedYear - lignes, alertes et commentaires.",
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricTile(
                label: 'Lignes',
                value: '${lines.length}',
                icon: AppIcons.table,
                caption: 'base locale',
              ),
              MetricTile(
                label: 'Lignes actives',
                value: '$activeLines',
                icon: AppIcons.lines,
                caption: 'base locale',
              ),
              MetricTile(
                label: 'Commentaires',
                value: '$commentCount',
                icon: AppIcons.edit,
                caption: 'cellules annotees',
                color: commentCount > 0
                    ? const Color(0xFFB45309)
                    : const Color(0xFF15803D),
              ),
              MetricTile(
                label: 'Alertes',
                value: '${validation.blockingCount}',
                icon: AppIcons.rule,
                caption: validation.blockingCount > 0
                    ? '${validation.blockingCount} a corriger'
                    : 'controle metier',
                color: validation.blockingCount > 0
                    ? const Color(0xFFB45309)
                    : const Color(0xFF15803D),
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
                            'Lignes commentees',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: commentedLines.isEmpty
                                ? const _DashboardEmptyState(
                                    message:
                                        'Aucun commentaire de cellule pour cette annee.',
                                  )
                                : ListView.separated(
                                    itemCount: commentedLines.length,
                                    separatorBuilder: (_, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final line = commentedLines[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(line.name),
                                        subtitle: Text(
                                          '${line.reference} - ${line.activity}',
                                        ),
                                        trailing: Text(
                                          '${line.cellComments.length}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
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
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (countedLines.isEmpty)
                            const Expanded(
                              child: _DashboardEmptyState(
                                message: 'Aucune activite a afficher.',
                              ),
                            )
                          else
                            for (final activity in activities)
                              if (countedLines.any(
                                (line) => line.activity == activity,
                              ))
                                _ActivityRow(
                                  activity: activity,
                                  count: countedLines
                                      .where(
                                        (line) => line.activity == activity,
                                      )
                                      .length,
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

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
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
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }
}
