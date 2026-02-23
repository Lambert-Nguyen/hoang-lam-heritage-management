import '../core/config/app_constants.dart';
import '../core/network/api_client.dart';
import '../models/finance.dart';

/// Repository for financial management operations
class FinanceRepository {
  final ApiClient _apiClient;

  FinanceRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  // ==================== Financial Categories ====================

  /// Get all financial categories with optional filters
  Future<List<FinancialCategory>> getCategories({
    EntryType? categoryType,
    bool? isActive,
  }) async {
    final queryParams = <String, dynamic>{};

    if (categoryType != null) {
      queryParams['category_type'] = categoryType.toApiValue;
    }
    if (isActive != null) {
      queryParams['is_active'] = isActive.toString();
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.categoriesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both list and paginated responses
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => FinancialCategory.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map(
              (json) =>
                  FinancialCategory.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    }

    return [];
  }

  /// Get income categories
  Future<List<FinancialCategory>> getIncomeCategories() async {
    return getCategories(categoryType: EntryType.income, isActive: true);
  }

  /// Get expense categories
  Future<List<FinancialCategory>> getExpenseCategories() async {
    return getCategories(categoryType: EntryType.expense, isActive: true);
  }

  /// Get a single category by ID
  Future<FinancialCategory> getCategory(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.categoriesEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Category not found');
    }
    return FinancialCategory.fromJson(response.data!);
  }

  /// Create a new financial category
  Future<FinancialCategory> createCategory({
    required String name,
    required EntryType categoryType,
    String? nameEn,
    String icon = 'category',
    String color = '#808080',
    bool isDefault = false,
    bool isActive = true,
    int sortOrder = 0,
  }) async {
    final data = {
      'name': name,
      'category_type': categoryType.toApiValue,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
      'is_active': isActive,
      'sort_order': sortOrder,
      if (nameEn != null) 'name_en': nameEn,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.categoriesEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create category');
    }
    return FinancialCategory.fromJson(response.data!);
  }

  /// Update a financial category
  Future<FinancialCategory> updateCategory(
    int id, {
    String? name,
    String? nameEn,
    String? icon,
    String? color,
    bool? isDefault,
    bool? isActive,
    int? sortOrder,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (nameEn != null) data['name_en'] = nameEn;
    if (icon != null) data['icon'] = icon;
    if (color != null) data['color'] = color;
    if (isDefault != null) data['is_default'] = isDefault;
    if (isActive != null) data['is_active'] = isActive;
    if (sortOrder != null) data['sort_order'] = sortOrder;

    final response = await _apiClient.patch<Map<String, dynamic>>(
      '${AppConstants.categoriesEndpoint}$id/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to update category');
    }
    return FinancialCategory.fromJson(response.data!);
  }

  /// Toggle category active status
  Future<FinancialCategory> toggleCategoryActive(
    int id, {
    required bool isActive,
  }) async {
    return updateCategory(id, isActive: isActive);
  }

  /// Delete a financial category
  Future<void> deleteCategory(int id) async {
    await _apiClient.delete('${AppConstants.categoriesEndpoint}$id/');
  }

  // ==================== Financial Entries ====================

  /// Get all financial entries with optional filters
  Future<List<FinancialEntryListItem>> getEntries({
    EntryType? entryType,
    int? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    PaymentMethod? paymentMethod,
  }) async {
    final queryParams = <String, dynamic>{};

    if (entryType != null) {
      queryParams['entry_type'] = entryType.toApiValue;
    }
    if (category != null) {
      queryParams['category'] = category.toString();
    }
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
    }
    if (paymentMethod != null) {
      queryParams['payment_method'] = paymentMethod.toApiValue;
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.financesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both list and paginated responses
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) =>
                FinancialEntryListItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map(
              (json) =>
                  FinancialEntryListItem.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
    }

    return [];
  }

  /// Get entries with filter object
  Future<List<FinancialEntryListItem>> getEntriesWithFilter(
    FinancialEntryFilter filter,
  ) async {
    return getEntries(
      entryType: filter.entryType,
      category: filter.category,
      dateFrom: filter.dateFrom,
      dateTo: filter.dateTo,
      paymentMethod: filter.paymentMethod,
    );
  }

  /// Get a single entry by ID
  Future<FinancialEntry> getEntry(int id) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}$id/',
    );
    if (response.data == null) {
      throw Exception('Entry not found');
    }
    return FinancialEntry.fromJson(response.data!);
  }

  /// Create a new financial entry
  Future<FinancialEntry> createEntry(FinancialEntryRequest entry) async {
    final data = {
      'entry_type': entry.entryType.toApiValue,
      'category': entry.category,
      'amount': entry.amount
          .truncate(), // Send as integer (backend decimal_places=0)
      'currency': entry.currency,
      'exchange_rate': entry.exchangeRate,
      'date': entry.date.toIso8601String().split('T')[0],
      'description': entry.description,
      'payment_method': entry.paymentMethod.toApiValue,
      if (entry.booking != null) 'booking': entry.booking,
      if (entry.receiptNumber != null) 'receipt_number': entry.receiptNumber,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.financesEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create entry');
    }
    return FinancialEntry.fromJson(response.data!);
  }

  /// Create income entry (convenience method)
  Future<FinancialEntry> createIncome({
    required int category,
    required double amount,
    required DateTime date,
    required String description,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    int? booking,
    String? receiptNumber,
  }) async {
    return createEntry(
      FinancialEntryRequest(
        entryType: EntryType.income,
        category: category,
        amount: amount,
        date: date,
        description: description,
        paymentMethod: paymentMethod,
        booking: booking,
        receiptNumber: receiptNumber,
      ),
    );
  }

  /// Create expense entry (convenience method)
  Future<FinancialEntry> createExpense({
    required int category,
    required double amount,
    required DateTime date,
    required String description,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? receiptNumber,
  }) async {
    return createEntry(
      FinancialEntryRequest(
        entryType: EntryType.expense,
        category: category,
        amount: amount,
        date: date,
        description: description,
        paymentMethod: paymentMethod,
        receiptNumber: receiptNumber,
      ),
    );
  }

  /// Update a financial entry
  Future<FinancialEntry> updateEntry(
    int id,
    FinancialEntryRequest entry,
  ) async {
    final data = {
      'entry_type': entry.entryType.toApiValue,
      'category': entry.category,
      'amount': entry.amount
          .truncate(), // Send as integer (backend decimal_places=0)
      'currency': entry.currency,
      'exchange_rate': entry.exchangeRate,
      'date': entry.date.toIso8601String().split('T')[0],
      'description': entry.description,
      'payment_method': entry.paymentMethod.toApiValue,
      if (entry.booking != null) 'booking': entry.booking,
      if (entry.receiptNumber != null) 'receipt_number': entry.receiptNumber,
    };

    final response = await _apiClient.put<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}$id/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to update entry');
    }
    return FinancialEntry.fromJson(response.data!);
  }

  /// Delete a financial entry
  Future<void> deleteEntry(int id) async {
    await _apiClient.delete('${AppConstants.financesEndpoint}$id/');
  }

  // ==================== Summaries ====================

  /// Get daily financial summary
  Future<DailyFinancialSummary> getDailySummary({DateTime? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}daily-summary/',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      throw Exception('Failed to get daily summary');
    }

    // Parse date from string if needed
    final data = Map<String, dynamic>.from(response.data!);
    if (data['date'] is String) {
      data['date'] = DateTime.parse(data['date'] as String);
    }

    return DailyFinancialSummary.fromJson(data);
  }

  /// Get today's summary (convenience method)
  Future<DailyFinancialSummary> getTodaySummary() async {
    return getDailySummary(date: DateTime.now());
  }

  /// Get monthly financial summary
  Future<MonthlyFinancialSummary> getMonthlySummary({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final queryParams = <String, dynamic>{
      'year': (year ?? now.year).toString(),
      'month': (month ?? now.month).toString(),
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.financesEndpoint}monthly-summary/',
      queryParameters: queryParams,
    );

    if (response.data == null) {
      throw Exception('Failed to get monthly summary');
    }

    return MonthlyFinancialSummary.fromJson(response.data!);
  }

  /// Get current month summary (convenience method)
  Future<MonthlyFinancialSummary> getCurrentMonthSummary() async {
    final now = DateTime.now();
    return getMonthlySummary(year: now.year, month: now.month);
  }

  // ==================== Helper Methods ====================

  /// Get recent entries (last N days)
  Future<List<FinancialEntryListItem>> getRecentEntries({int days = 7}) async {
    final now = DateTime.now();
    final fromDate = now.subtract(Duration(days: days));
    return getEntries(dateFrom: fromDate, dateTo: now);
  }

  /// Get income entries for a date range
  Future<List<FinancialEntryListItem>> getIncomeEntries({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return getEntries(
      entryType: EntryType.income,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  /// Get expense entries for a date range
  Future<List<FinancialEntryListItem>> getExpenseEntries({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return getEntries(
      entryType: EntryType.expense,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  // ==================== Payments (Phase 2.4) ====================

  /// Get all payments with optional filters
  Future<List<Payment>> getPayments({
    int? bookingId,
    PaymentType? paymentType,
    PaymentStatus? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParams = <String, dynamic>{};

    if (bookingId != null) {
      queryParams['booking'] = bookingId.toString();
    }
    if (paymentType != null) {
      queryParams['payment_type'] = paymentType.toApiValue;
    }
    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (dateFrom != null) {
      queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
    }
    if (dateTo != null) {
      queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.paymentsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both list and paginated responses
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => Payment.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map((json) => Payment.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  /// Create a new payment
  Future<Payment> createPayment(PaymentCreateRequest request) async {
    final data = {
      'booking': request.booking,
      'payment_type': request.paymentType.toApiValue,
      'amount': request.amount,
      'payment_method': request.paymentMethod.toApiValue,
      'status': request.status.name,
      if (request.notes != null) 'notes': request.notes,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.paymentsEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create payment');
    }
    return Payment.fromJson(response.data!);
  }

  /// Record a deposit payment for a booking
  Future<Payment> recordDeposit(DepositRecordRequest request) async {
    final data = {
      'booking': request.booking,
      'amount': request.amount,
      'payment_method': request.paymentMethod.toApiValue,
      if (request.notes != null) 'notes': request.notes,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.paymentsEndpoint}record-deposit/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to record deposit');
    }
    return Payment.fromJson(response.data!);
  }

  /// Get deposits for a specific booking
  Future<List<Payment>> getBookingDeposits(int bookingId) async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.paymentsEndpoint}bookings/$bookingId/deposits/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => Payment.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Get outstanding deposits report
  Future<List<OutstandingDeposit>> getOutstandingDeposits() async {
    final response = await _apiClient.get<dynamic>(
      '${AppConstants.paymentsEndpoint}outstanding-deposits/',
    );

    if (response.data == null) {
      return [];
    }

    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map(
            (json) => OutstandingDeposit.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }

    return [];
  }

  // ==================== Folio Items (Phase 2.4) ====================

  /// Get all folio items with optional filters
  Future<List<FolioItem>> getFolioItems({
    int? bookingId,
    FolioItemType? itemType,
    bool includeVoided = false,
  }) async {
    final queryParams = <String, dynamic>{};

    if (bookingId != null) {
      queryParams['booking'] = bookingId.toString();
    }
    if (itemType != null) {
      queryParams['item_type'] = itemType.toApiValue;
    }
    if (includeVoided) {
      queryParams['include_voided'] = 'true';
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.folioItemsEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both list and paginated responses
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => FolioItem.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map((json) => FolioItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  /// Create a new folio item
  Future<FolioItem> createFolioItem(FolioItemCreateRequest request) async {
    final data = {
      'booking': request.booking,
      'item_type': request.itemType.toApiValue,
      'description': request.description,
      'quantity': request.quantity,
      'unit_price': request.unitPrice,
      'date': request.date.toIso8601String().split('T')[0],
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.folioItemsEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create folio item');
    }
    return FolioItem.fromJson(response.data!);
  }

  /// Void a folio item
  Future<FolioItem> voidFolioItem(int id, String reason) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.folioItemsEndpoint}$id/void/',
      data: {'reason': reason},
    );
    if (response.data == null) {
      throw Exception('Failed to void folio item');
    }
    return FolioItem.fromJson(response.data!);
  }

  /// Get booking folio summary
  Future<BookingFolioSummary> getBookingFolio(int bookingId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.folioItemsEndpoint}bookings/$bookingId/folio/',
    );
    if (response.data == null) {
      throw Exception('Failed to get booking folio');
    }
    return BookingFolioSummary.fromJson(response.data!);
  }

  // ==================== Exchange Rates (Phase 2.6) ====================

  /// Get all exchange rates
  Future<List<ExchangeRate>> getExchangeRates({
    String? fromCurrency,
    String? toCurrency,
    DateTime? date,
  }) async {
    final queryParams = <String, dynamic>{};

    if (fromCurrency != null) {
      queryParams['from_currency'] = fromCurrency;
    }
    if (toCurrency != null) {
      queryParams['to_currency'] = toCurrency;
    }
    if (date != null) {
      queryParams['date'] = date.toIso8601String().split('T')[0];
    }

    final response = await _apiClient.get<dynamic>(
      AppConstants.exchangeRatesEndpoint,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data == null) {
      return [];
    }

    // Handle both list and paginated responses
    if (response.data is List) {
      final list = response.data as List<dynamic>;
      return list
          .map((json) => ExchangeRate.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    if (response.data is Map<String, dynamic>) {
      final dataMap = response.data as Map<String, dynamic>;
      if (dataMap.containsKey('results')) {
        final results = dataMap['results'] as List<dynamic>;
        return results
            .map((json) => ExchangeRate.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  /// Create a new exchange rate
  Future<ExchangeRate> createExchangeRate(
    ExchangeRateCreateRequest request,
  ) async {
    final data = {
      'from_currency': request.fromCurrency,
      'to_currency': request.toCurrency,
      'rate': request.rate,
      'date': request.date.toIso8601String().split('T')[0],
      'source': request.source,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      AppConstants.exchangeRatesEndpoint,
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to create exchange rate');
    }
    return ExchangeRate.fromJson(response.data!);
  }

  /// Get latest exchange rates
  Future<Map<String, double>> getLatestRates() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '${AppConstants.exchangeRatesEndpoint}latest/',
    );

    if (response.data == null) {
      return {};
    }

    final rates = response.data!['rates'] as Map<String, dynamic>?;
    if (rates == null) {
      return {};
    }

    return rates.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  /// Convert currency amount
  Future<CurrencyConversionResult> convertCurrency(
    CurrencyConversionRequest request,
  ) async {
    final data = {
      'amount': request.amount,
      'from_currency': request.fromCurrency,
      'to_currency': request.toCurrency,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.exchangeRatesEndpoint}convert/',
      data: data,
    );
    if (response.data == null) {
      throw Exception('Failed to convert currency');
    }
    return CurrencyConversionResult.fromJson(response.data!);
  }

  // ==================== Receipts (Phase 2.8) ====================

  /// Generate receipt data for a booking
  Future<ReceiptData> generateReceipt(
    int bookingId, {
    String currency = 'VND',
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.receiptsEndpoint}generate/',
      data: {'booking_id': bookingId, 'currency': currency},
    );
    if (response.data == null) {
      throw Exception('Failed to generate receipt');
    }
    return ReceiptData.fromJson(response.data!);
  }

  /// Get receipt download URL
  String getReceiptDownloadUrl(int bookingId, {String currency = 'VND'}) {
    return '${AppConstants.receiptsEndpoint}$bookingId/download/?currency=$currency';
  }
}
