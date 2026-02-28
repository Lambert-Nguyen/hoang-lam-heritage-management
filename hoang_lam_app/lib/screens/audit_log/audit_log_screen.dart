import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/audit_log.dart';
import '../../providers/audit_log_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';

/// Screen showing audit trail / activity log
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String? _selectedEntityType;

  static const _entityTypes = [
    null, // All
    'booking',
    'room',
    'guest',
    'finance',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logsAsync = ref.watch(auditLogsProvider(_selectedEntityType));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auditLog)),
      body: Column(
        children: [
          _buildFilterChips(l10n),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(auditLogsProvider(_selectedEntityType));
              },
              child: logsAsync.when(
                data: (logs) {
                  if (logs.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: EmptyState(
                            icon: Icons.history,
                            title: l10n.noActivities,
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppSpacing.paddingScreen,
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildLogEntry(logs[index]),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (e, _) => Center(child: Text('${l10n.error}: $e')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final labels = {
      null: l10n.allActivities,
      'booking': l10n.bookings,
      'room': l10n.room,
      'guest': l10n.guests,
      'finance': l10n.finance,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: _entityTypes.map((type) {
          final isSelected = _selectedEntityType == type;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(labels[type] ?? type ?? ''),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedEntityType = type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogEntry(AuditLogEntry entry) {
    final icon = _getActionIcon(entry.action);
    final color = _getActionColor(entry.action);
    final time = _formatTime(entry.createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        entry.details.isNotEmpty ? entry.details : entry.action,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${entry.userName} · ${entry.entityType}',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
    );
  }

  IconData _getActionIcon(String action) {
    if (action.contains('create') || action.contains('add')) {
      return Icons.add_circle_outline;
    }
    if (action.contains('update') || action.contains('edit')) {
      return Icons.edit_outlined;
    }
    if (action.contains('delete') || action.contains('remove')) {
      return Icons.delete_outline;
    }
    if (action.contains('check_in') || action.contains('checkin')) {
      return Icons.login;
    }
    if (action.contains('check_out') || action.contains('checkout')) {
      return Icons.logout;
    }
    if (action.contains('payment') || action.contains('pay')) {
      return Icons.payments_outlined;
    }
    if (action.contains('cancel')) return Icons.cancel_outlined;
    if (action.contains('swap')) return Icons.swap_horiz;
    if (action.contains('refund')) return Icons.money_off;
    return Icons.info_outline;
  }

  Color _getActionColor(String action) {
    if (action.contains('create') || action.contains('add')) {
      return AppColors.success;
    }
    if (action.contains('delete') || action.contains('cancel')) {
      return AppColors.error;
    }
    if (action.contains('check_in')) return AppColors.success;
    if (action.contains('check_out')) return AppColors.info;
    if (action.contains('payment') || action.contains('pay')) {
      return AppColors.primary;
    }
    if (action.contains('refund')) return AppColors.warning;
    return AppColors.textSecondary;
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
