import 'package:flutter/material.dart';

import '../models/billing_line.dart';
import '../theme/app_icons.dart';
import 'app_icon.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Actif' => const Color(0xFF15803D),
      'Desactive' => const Color(0xFF64748B),
      _ => const Color(0xFFB45309),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key, required this.state});

  final SyncState state;

  @override
  Widget build(BuildContext context) {
    final data = switch (state) {
      SyncState.synced => ('Enregistre', AppIcons.cloudDone, const Color(0xFF15803D)),
      SyncState.dirty => ('En attente', AppIcons.edit, const Color(0xFFB45309)),
      SyncState.syncing => ('Sync...', AppIcons.sync, const Color(0xFF2563EB)),
      SyncState.failed => ('Erreur', AppIcons.warning, const Color(0xFFDC2626)),
    };

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(data.$2, size: 14, color: data.$3),
          const SizedBox(width: 5),
          Text(
            data.$1,
            style: TextStyle(
              color: data.$3,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
