import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/guest_message.dart';

/// Repository for guest messaging operations
class MessagingRepository {
  final ApiClient _apiClient;

  MessagingRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Message Templates ====================

  /// Get all message templates
  Future<List<MessageTemplate>> getTemplates({
    String? templateType,
    String? channel,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};
    if (templateType != null) queryParams['template_type'] = templateType;
    if (channel != null) queryParams['channel'] = channel;
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final response = await _apiClient.get<dynamic>(
      AppConstants.messageTemplatesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) return [];

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = MessageTemplateListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => MessageTemplate.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single template
  Future<MessageTemplate> getTemplate(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.messageTemplatesEndpoint}$id/',
    );
    if (response.data == null) throw Exception('Template not found');
    return MessageTemplate.fromJson(response.data!);
  }

  /// Create a new template
  Future<MessageTemplate> createTemplate(Map<String, dynamic> data) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.messageTemplatesEndpoint,
      data: data,
    );
    if (response.data == null) throw Exception('Failed to create template');
    return MessageTemplate.fromJson(response.data!);
  }

  /// Update a template
  Future<MessageTemplate> updateTemplate(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.messageTemplatesEndpoint}$id/',
      data: data,
    );
    if (response.data == null) throw Exception('Failed to update template');
    return MessageTemplate.fromJson(response.data!);
  }

  /// Delete a template
  Future<void> deleteTemplate(int id) async {
    await _apiClient.delete<void>(
      '${AppConstants.messageTemplatesEndpoint}$id/',
    );
  }

  /// Preview a rendered template
  Future<PreviewMessageResponse> previewTemplate({
    required int templateId,
    required int guestId,
    int? bookingId,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.messageTemplatesEndpoint}preview/',
      data: {
        'template': templateId,
        'guest': guestId,
        if (bookingId != null) 'booking': bookingId,
      },
    );
    if (response.data == null) throw Exception('Failed to preview template');
    return PreviewMessageResponse.fromJson(response.data!);
  }

  // ==================== Guest Messages ====================

  /// Get all guest messages
  Future<List<GuestMessage>> getMessages({
    int? guestId,
    int? bookingId,
    String? channel,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (guestId != null) queryParams['guest'] = guestId.toString();
    if (bookingId != null) queryParams['booking'] = bookingId.toString();
    if (channel != null) queryParams['channel'] = channel;
    if (status != null) queryParams['status'] = status;

    final response = await _apiClient.get<dynamic>(
      AppConstants.guestMessagesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) return [];

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final listResponse = GuestMessageListResponse.fromJson(dataMap);
        return listResponse.results;
      }
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => GuestMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get a single message
  Future<GuestMessage> getMessage(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.guestMessagesEndpoint}$id/',
    );
    if (response.data == null) throw Exception('Message not found');
    return GuestMessage.fromJson(response.data!);
  }

  /// Send a message to a guest
  Future<GuestMessage> sendMessage({
    required int guestId,
    int? bookingId,
    int? templateId,
    required String channel,
    required String subject,
    required String body,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.guestMessagesEndpoint}send/',
      data: {
        'guest': guestId,
        if (bookingId != null) 'booking': bookingId,
        if (templateId != null) 'template': templateId,
        'channel': channel,
        'subject': subject,
        'body': body,
      },
    );
    if (response.data == null) throw Exception('Failed to send message');
    return GuestMessage.fromJson(response.data!);
  }

  /// Resend a failed message
  Future<GuestMessage> resendMessage(int id) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.guestMessagesEndpoint}$id/resend/',
    );
    if (response.data == null) throw Exception('Failed to resend message');
    return GuestMessage.fromJson(response.data!);
  }
}
