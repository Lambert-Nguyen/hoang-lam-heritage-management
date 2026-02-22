import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/guest_message.dart';
import '../../providers/messaging_provider.dart';
import '../../core/theme/app_colors.dart';

/// Screen showing message history for a guest or booking
class MessageHistoryScreen extends ConsumerWidget {
  final int? guestId;
  final int? bookingId;
  final String? title;

  const MessageHistoryScreen({
    super.key,
    this.guestId,
    this.bookingId,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final displayTitle = title ?? l10n.messageHistory;
    final messagesAsync =
        guestId != null
            ? ref.watch(guestMessagesByGuestProvider(guestId!))
            : bookingId != null
            ? ref.watch(guestMessagesByBookingProvider(bookingId!))
            : ref.watch(guestMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noMessages,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (guestId != null) {
                ref.invalidate(guestMessagesByGuestProvider(guestId!));
              } else if (bookingId != null) {
                ref.invalidate(guestMessagesByBookingProvider(bookingId!));
              } else {
                ref.invalidate(guestMessagesProvider);
              }
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: messages.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final message = messages[index];
                return _MessageTile(
                  message: message,
                  onResend:
                      message.status == MessageStatus.failed
                          ? () => _resendMessage(context, ref, message)
                          : null,
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.errorLoadingData),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (guestId != null) {
                        ref.invalidate(guestMessagesByGuestProvider(guestId!));
                      } else {
                        ref.invalidate(guestMessagesProvider);
                      }
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Future<void> _resendMessage(
    BuildContext context,
    WidgetRef ref,
    GuestMessage message,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.resendMessage),
            content: Text(l10n.resendMessageConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.send),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(messagingNotifierProvider.notifier)
        .resendMessage(message.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result != null ? l10n.messageSentSuccess : l10n.messageSendFailed,
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final GuestMessage message;
  final VoidCallback? onResend;

  const _MessageTile({required this.message, this.onResend});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getChannelColor().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getChannelIcon(), color: _getChannelColor(), size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message.subject,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusBadge(status: message.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message.body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      message.channel.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getChannelColor(),
                      ),
                    ),
                    if (message.recipientAddress != null &&
                        message.recipientAddress!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '→ ${message.recipientAddress}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTime(message.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                if (message.status == MessageStatus.failed &&
                    message.sendError.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message.sendError,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.error,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (onResend != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onResend,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(AppLocalizations.of(context)!.resendBtn),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getChannelIcon() {
    switch (message.channel) {
      case MessageChannel.sms:
        return Icons.sms;
      case MessageChannel.email:
        return Icons.email;
      case MessageChannel.zalo:
        return Icons.chat;
    }
  }

  Color _getChannelColor() {
    switch (message.channel) {
      case MessageChannel.sms:
        return AppColors.success;
      case MessageChannel.email:
        return AppColors.statusBlue;
      case MessageChannel.zalo:
        return AppColors.brandZalo;
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}

class _StatusBadge extends StatelessWidget {
  final MessageStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor().withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.localizedName(context.l10n),
        style: TextStyle(
          color: _getColor(),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status) {
      case MessageStatus.draft:
        return AppColors.mutedAccent;
      case MessageStatus.pending:
        return AppColors.warning;
      case MessageStatus.sent:
        return AppColors.statusBlue;
      case MessageStatus.delivered:
        return AppColors.success;
      case MessageStatus.failed:
        return AppColors.error;
    }
  }
}
