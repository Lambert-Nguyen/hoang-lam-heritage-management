import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/guest_message.dart';
import '../../providers/messaging_provider.dart';
import '../../core/theme/app_colors.dart';

/// Screen for selecting and previewing message templates before sending
class MessageTemplateScreen extends ConsumerStatefulWidget {
  final int guestId;
  final String guestName;
  final int? bookingId;

  const MessageTemplateScreen({
    super.key,
    required this.guestId,
    required this.guestName,
    this.bookingId,
  });

  @override
  ConsumerState<MessageTemplateScreen> createState() =>
      _MessageTemplateScreenState();
}

class _MessageTemplateScreenState extends ConsumerState<MessageTemplateScreen> {
  MessageChannel _selectedChannel = MessageChannel.sms;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final templatesAsync = ref.watch(
      templatesByChannelProvider(_selectedChannel.apiValue),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendMessage),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Guest info header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.guestName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.bookingId != null)
                  Chip(
                    label: Text('#${widget.bookingId}'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Channel selector
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Text(
                  l10n.channel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 12),
                ...MessageChannel.values.map((channel) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(channel.displayName),
                      selected: _selectedChannel == channel,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedChannel = channel);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1),

          // Template list
          Expanded(
            child: templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: AppColors.mutedAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.noMessagingTemplates),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCustomMessageDialog(context),
                          icon: const Icon(Icons.edit),
                          label: Text(l10n.writeCustomMessage),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount:
                      templates.length + 1, // +1 for custom message option
                  itemBuilder: (context, index) {
                    if (index == templates.length) {
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.edit)),
                        title: Text(l10n.writeCustomMessage),
                        subtitle: Text(l10n.writeCustomMessageDescription),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showCustomMessageDialog(context),
                      );
                    }

                    final template = templates[index];
                    return _TemplateTile(
                      template: template,
                      onTap: () => _onTemplateSelected(template),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTemplateSelected(MessageTemplate template) async {
    // Preview the template
    final preview = await ref
        .read(messagingNotifierProvider.notifier)
        .previewTemplate(
          templateId: template.id,
          guestId: widget.guestId,
          bookingId: widget.bookingId,
        );

    if (!mounted || preview == null) return;

    // Show preview dialog
    _showPreviewAndSendDialog(
      context,
      subject: preview.subject,
      body: preview.body,
      channel: _selectedChannel,
      templateId: template.id,
      recipientAddress: preview.recipientAddress,
    );
  }

  void _showCustomMessageDialog(BuildContext context) {
    _showPreviewAndSendDialog(
      context,
      subject: '',
      body: '',
      channel: _selectedChannel,
      isCustom: true,
    );
  }

  void _showPreviewAndSendDialog(
    BuildContext context, {
    required String subject,
    required String body,
    required MessageChannel channel,
    int? templateId,
    String? recipientAddress,
    bool isCustom = false,
  }) {
    final l10n = context.l10n;
    final subjectController = TextEditingController(text: subject);
    final bodyController = TextEditingController(text: body);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isCustom ? l10n.writeCustomMessage : l10n.messagePreview),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recipientAddress != null &&
                    recipientAddress.isNotEmpty) ...[
                  Text(
                    '${l10n.recipient}: $recipientAddress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: l10n.subject,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  decoration: InputDecoration(
                    labelText: l10n.messageContent,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 8,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _sendMessage(
                subject: subjectController.text,
                body: bodyController.text,
                channel: channel,
                templateId: templateId,
              );
            },
            icon: const Icon(Icons.send, size: 18),
            label: Text(l10n.send),
          ),
        ],
      ),
    ).then((_) {
      subjectController.dispose();
      bodyController.dispose();
    });
  }

  Future<void> _sendMessage({
    required String subject,
    required String body,
    required MessageChannel channel,
    int? templateId,
  }) async {
    final l10n = context.l10n;

    GuestMessage? result;
    if (templateId != null) {
      result = await ref
          .read(messagingNotifierProvider.notifier)
          .sendFromTemplate(
            templateId: templateId,
            guestId: widget.guestId,
            bookingId: widget.bookingId,
            subject: subject,
            body: body,
            channel: channel.apiValue,
          );
    } else {
      result = await ref
          .read(messagingNotifierProvider.notifier)
          .sendCustomMessage(
            guestId: widget.guestId,
            bookingId: widget.bookingId,
            channel: channel.apiValue,
            subject: subject,
            body: body,
          );
    }

    if (!mounted) return;

    if (result != null) {
      final isSuccess =
          result.status == MessageStatus.sent ||
          result.status == MessageStatus.delivered;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess ? l10n.messageSentSuccess : l10n.messageSentPending,
          ),
          backgroundColor: isSuccess ? AppColors.success : AppColors.warning,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.messageSendFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _TemplateTile extends StatelessWidget {
  final MessageTemplate template;
  final VoidCallback onTap;

  const _TemplateTile({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getTemplateColor().withValues(alpha: 0.12),
        child: Icon(_getTemplateIcon(), color: _getTemplateColor(), size: 20),
      ),
      title: Text(template.name),
      subtitle: Text(
        template.templateType.localizedName(context.l10n),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  IconData _getTemplateIcon() {
    switch (template.templateType) {
      case MessageTemplateType.bookingConfirmation:
        return Icons.check_circle_outline;
      case MessageTemplateType.preArrival:
        return Icons.flight_land;
      case MessageTemplateType.checkoutReminder:
        return Icons.alarm;
      case MessageTemplateType.reviewRequest:
        return Icons.rate_review;
      case MessageTemplateType.custom:
        return Icons.message;
    }
  }

  Color _getTemplateColor() {
    switch (template.templateType) {
      case MessageTemplateType.bookingConfirmation:
        return AppColors.success;
      case MessageTemplateType.preArrival:
        return AppColors.statusBlue;
      case MessageTemplateType.checkoutReminder:
        return AppColors.warning;
      case MessageTemplateType.reviewRequest:
        return AppColors.statusPurple;
      case MessageTemplateType.custom:
        return AppColors.statusBlueGrey;
    }
  }
}
