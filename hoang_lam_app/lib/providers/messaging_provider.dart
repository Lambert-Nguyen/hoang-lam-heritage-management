import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guest_message.dart';
import '../repositories/messaging_repository.dart';

/// Provider for MessagingRepository
final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository();
});

// ============================================================
// Message Template Providers
// ============================================================

/// Provider for all message templates
final messageTemplatesProvider =
    FutureProvider.autoDispose<List<MessageTemplate>>((ref) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getTemplates();
});

/// Provider for active templates only
final activeTemplatesProvider =
    FutureProvider.autoDispose<List<MessageTemplate>>((ref) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getTemplates(isActive: true);
});

/// Provider for templates filtered by channel
final templatesByChannelProvider =
    FutureProvider.autoDispose.family<List<MessageTemplate>, String>(
        (ref, channel) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getTemplates(channel: channel, isActive: true);
});

/// Provider for a single template
final templateByIdProvider =
    FutureProvider.autoDispose.family<MessageTemplate, int>((ref, id) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getTemplate(id);
});

// ============================================================
// Guest Message Providers
// ============================================================

/// Provider for all guest messages
final guestMessagesProvider =
    FutureProvider.autoDispose<List<GuestMessage>>((ref) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getMessages();
});

/// Provider for messages for a specific guest
final guestMessagesByGuestProvider =
    FutureProvider.autoDispose.family<List<GuestMessage>, int>(
        (ref, guestId) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getMessages(guestId: guestId);
});

/// Provider for messages for a specific booking
final guestMessagesByBookingProvider =
    FutureProvider.autoDispose.family<List<GuestMessage>, int>(
        (ref, bookingId) async {
  final repository = ref.watch(messagingRepositoryProvider);
  return repository.getMessages(bookingId: bookingId);
});

// ============================================================
// Messaging Notifier (for mutations)
// ============================================================

/// StateNotifier for messaging actions
class MessagingNotifier extends StateNotifier<AsyncValue<void>> {
  final MessagingRepository _repository;
  final Ref _ref;

  MessagingNotifier(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  /// Send a message using a template
  Future<GuestMessage?> sendFromTemplate({
    required int templateId,
    required int guestId,
    int? bookingId,
    required String subject,
    required String body,
    required String channel,
  }) async {
    state = const AsyncValue.loading();
    try {
      final message = await _repository.sendMessage(
        guestId: guestId,
        bookingId: bookingId,
        templateId: templateId,
        channel: channel,
        subject: subject,
        body: body,
      );
      state = const AsyncValue.data(null);
      // Refresh message lists
      _ref.invalidate(guestMessagesProvider);
      if (guestId > 0) _ref.invalidate(guestMessagesByGuestProvider(guestId));
      if (bookingId != null) {
        _ref.invalidate(guestMessagesByBookingProvider(bookingId));
      }
      return message;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Send a custom message (no template)
  Future<GuestMessage?> sendCustomMessage({
    required int guestId,
    int? bookingId,
    required String channel,
    required String subject,
    required String body,
  }) async {
    state = const AsyncValue.loading();
    try {
      final message = await _repository.sendMessage(
        guestId: guestId,
        bookingId: bookingId,
        channel: channel,
        subject: subject,
        body: body,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(guestMessagesProvider);
      return message;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Resend a failed message
  Future<GuestMessage?> resendMessage(int messageId) async {
    state = const AsyncValue.loading();
    try {
      final message = await _repository.resendMessage(messageId);
      state = const AsyncValue.data(null);
      _ref.invalidate(guestMessagesProvider);
      return message;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Preview a template
  Future<PreviewMessageResponse?> previewTemplate({
    required int templateId,
    required int guestId,
    int? bookingId,
  }) async {
    try {
      return await _repository.previewTemplate(
        templateId: templateId,
        guestId: guestId,
        bookingId: bookingId,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Provider for MessagingNotifier
final messagingNotifierProvider =
    StateNotifierProvider.autoDispose<MessagingNotifier, AsyncValue<void>>(
        (ref) {
  final repository = ref.watch(messagingRepositoryProvider);
  return MessagingNotifier(repository, ref);
});
