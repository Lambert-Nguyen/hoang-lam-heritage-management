import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/core/network/api_client.dart';
import 'package:hoang_lam_app/models/report.dart';
import 'package:hoang_lam_app/repositories/report_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'report_repository_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late ReportRepository repository;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = ReportRepository(apiClient: mockApiClient);
  });

  // Helper to create occupancy report JSON
  Map<String, dynamic> _createOccupancyReportJson({
    String? date,
    String? period,
    int totalRooms = 7,
    int occupiedRooms = 5,
    int availableRooms = 2,
    double occupancyRate = 71.43,
    double revenue = 1500000,
  }) {
    return {
      'date': date,
      'period': period,
      'total_rooms': totalRooms,
      'occupied_rooms': occupiedRooms,
      'available_rooms': availableRooms,
      'occupancy_rate': occupancyRate,
      'revenue': revenue,
    };
  }

  // Helper to create revenue report JSON
  Map<String, dynamic> _createRevenueReportJson({
    String? date,
    String? period,
    double roomRevenue = 1500000,
    double additionalRevenue = 100000,
    double minibarRevenue = 50000,
    double totalRevenue = 1650000,
    double totalExpenses = 300000,
    double netProfit = 1350000,
    double profitMargin = 81.82,
  }) {
    return {
      'date': date,
      'period': period,
      'room_revenue': roomRevenue,
      'additional_revenue': additionalRevenue,
      'minibar_revenue': minibarRevenue,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'profit_margin': profitMargin,
    };
  }

  // Helper to create KPI report JSON
  Map<String, dynamic> _createKPIReportJson({
    String periodStart = '2024-01-01',
    String periodEnd = '2024-01-31',
    double revpar = 300000,
    double adr = 420000,
    double occupancyRate = 71.43,
    int totalRoomNightsAvailable = 217,
    int totalRoomNightsSold = 155,
    double totalRoomRevenue = 65100000,
    double totalRevenue = 70500000,
    double totalExpenses = 15000000,
    double netProfit = 55500000,
    double? revparChange = 5.2,
    double? adrChange = 3.1,
    double? occupancyChange = 2.5,
    double? revenueChange = 8.3,
  }) {
    return {
      'period_start': periodStart,
      'period_end': periodEnd,
      'revpar': revpar,
      'adr': adr,
      'occupancy_rate': occupancyRate,
      'total_room_nights_available': totalRoomNightsAvailable,
      'total_room_nights_sold': totalRoomNightsSold,
      'total_room_revenue': totalRoomRevenue,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'revpar_change': revparChange,
      'adr_change': adrChange,
      'occupancy_change': occupancyChange,
      'revenue_change': revenueChange,
    };
  }

  // Helper to create expense report JSON
  Map<String, dynamic> _createExpenseReportJson({
    int categoryId = 1,
    String categoryName = 'Utilities',
    String categoryIcon = 'bolt',
    String categoryColor = '#FF5722',
    double totalAmount = 500000,
    int transactionCount = 5,
    double percentage = 25.0,
  }) {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'category_color': categoryColor,
      'total_amount': totalAmount,
      'transaction_count': transactionCount,
      'percentage': percentage,
    };
  }

  // Helper to create channel performance JSON
  Map<String, dynamic> _createChannelPerformanceJson({
    String source = 'direct',
    String sourceDisplay = 'Đặt trực tiếp',
    int bookingCount = 25,
    int totalNights = 75,
    double totalRevenue = 22500000,
    double averageRate = 300000,
    int cancellationCount = 2,
    double cancellationRate = 8.0,
    double percentageOfRevenue = 35.0,
  }) {
    return {
      'source': source,
      'source_display': sourceDisplay,
      'booking_count': bookingCount,
      'total_nights': totalNights,
      'total_revenue': totalRevenue,
      'average_rate': averageRate,
      'cancellation_count': cancellationCount,
      'cancellation_rate': cancellationRate,
      'percentage_of_revenue': percentageOfRevenue,
    };
  }

  // Helper to create guest demographics JSON
  Map<String, dynamic> _createGuestDemographicsJson({
    String nationality = 'Vietnam',
    int guestCount = 50,
    int bookingCount = 30,
    int totalNights = 90,
    double totalRevenue = 27000000,
    double percentage = 60.0,
    double averageStay = 3.0,
  }) {
    return {
      'nationality': nationality,
      'guest_count': guestCount,
      'booking_count': bookingCount,
      'total_nights': totalNights,
      'total_revenue': totalRevenue,
      'percentage': percentage,
      'average_stay': averageStay,
    };
  }

  // Helper to create comparative report JSON
  Map<String, dynamic> _createComparativeReportJson({
    String metric = 'revenue',
    double currentPeriodValue = 70500000,
    double? previousPeriodValue = 65000000,
    double? changeAmount = 5500000,
    double? changePercentage = 8.46,
  }) {
    return {
      'metric': metric,
      'current_period_value': currentPeriodValue,
      'previous_period_value': previousPeriodValue,
      'change_amount': changeAmount,
      'change_percentage': changePercentage,
    };
  }

  group('ReportRepository - Occupancy Report', () {
    test('getOccupancyReport should return list of occupancy data', () async {
      final mockResponse = Response(
        data: [
          _createOccupancyReportJson(date: '2024-01-01'),
          _createOccupancyReportJson(date: '2024-01-02', occupiedRooms: 6),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/occupancy/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = OccupancyReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        groupBy: ReportGroupBy.day,
      );

      final result = await repository.getOccupancyReport(request);

      expect(result.length, 2);
      expect(result[0].date, '2024-01-01');
      expect(result[0].totalRooms, 7);
      expect(result[0].occupiedRooms, 5);
      expect(result[1].occupiedRooms, 6);
    });

    test('getOccupancyReport with weekly grouping', () async {
      final mockResponse = Response(
        data: [
          _createOccupancyReportJson(period: 'Week 1 Jan 2024'),
          _createOccupancyReportJson(period: 'Week 2 Jan 2024'),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/occupancy/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = OccupancyReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        groupBy: ReportGroupBy.week,
      );

      final result = await repository.getOccupancyReport(request);

      expect(result.length, 2);
      expect(result[0].period, 'Week 1 Jan 2024');
    });

    test('getOccupancyReport returns empty list when no data', () async {
      final mockResponse = Response(
        data: <dynamic>[],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/occupancy/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = OccupancyReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getOccupancyReport(request);

      expect(result, isEmpty);
    });
  });

  group('ReportRepository - Revenue Report', () {
    test('getRevenueReport should return list of revenue data', () async {
      final mockResponse = Response(
        data: [
          _createRevenueReportJson(date: '2024-01-01'),
          _createRevenueReportJson(date: '2024-01-02', totalRevenue: 2000000),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/revenue/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = RevenueReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getRevenueReport(request);

      expect(result.length, 2);
      expect(result[0].totalRevenue, 1650000);
      expect(result[0].netProfit, 1350000);
      expect(result[1].totalRevenue, 2000000);
    });

    test('getRevenueReport includes minibar revenue', () async {
      final mockResponse = Response(
        data: [
          _createRevenueReportJson(
            date: '2024-01-01',
            minibarRevenue: 75000,
          ),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/revenue/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = RevenueReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getRevenueReport(request);

      expect(result[0].minibarRevenue, 75000);
    });
  });

  group('ReportRepository - KPI Report', () {
    test('getKPIReport should return KPI metrics', () async {
      final mockResponse = Response(
        data: _createKPIReportJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/kpi/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = KPIReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getKPIReport(request);

      expect(result.revpar, 300000);
      expect(result.adr, 420000);
      expect(result.occupancyRate, 71.43);
      expect(result.netProfit, 55500000);
    });

    test('getKPIReport includes comparison data when requested', () async {
      final mockResponse = Response(
        data: _createKPIReportJson(
          revparChange: 5.2,
          adrChange: 3.1,
          occupancyChange: 2.5,
          revenueChange: 8.3,
        ),
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/kpi/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = KPIReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        comparePrevious: true,
      );

      final result = await repository.getKPIReport(request);

      expect(result.revparChange, 5.2);
      expect(result.adrChange, 3.1);
      expect(result.revparImproved, true);
    });

    test('KPIReport improvement helpers work correctly', () async {
      final mockResponse = Response(
        data: _createKPIReportJson(
          revparChange: -2.0,
          adrChange: 3.1,
          occupancyChange: 0,
        ),
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/kpi/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = KPIReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getKPIReport(request);

      expect(result.revparImproved, false);
      expect(result.adrImproved, true);
      expect(result.occupancyImproved, false);
    });
  });

  group('ReportRepository - Expense Report', () {
    test('getExpenseReport should return expenses by category', () async {
      final mockResponse = Response(
        data: [
          _createExpenseReportJson(categoryId: 1, categoryName: 'Utilities'),
          _createExpenseReportJson(categoryId: 2, categoryName: 'Supplies'),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/expenses/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = ExpenseReportRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getExpenseReport(request);

      expect(result.length, 2);
      expect(result[0].categoryName, 'Utilities');
      expect(result[0].percentage, 25.0);
    });
  });

  group('ReportRepository - Channel Performance', () {
    test('getChannelPerformance should return channel metrics', () async {
      final mockResponse = Response(
        data: [
          _createChannelPerformanceJson(source: 'direct'),
          _createChannelPerformanceJson(source: 'booking_com'),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/channels/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = ChannelPerformanceRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getChannelPerformance(request);

      expect(result.length, 2);
      expect(result[0].source, 'direct');
      expect(result[0].isHighPerforming, true); // 35% >= 20%
    });

    test('ChannelPerformance helpers work correctly', () async {
      final mockResponse = Response(
        data: [
          _createChannelPerformanceJson(
            percentageOfRevenue: 10.0,
            cancellationRate: 20.0,
          ),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/channels/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = ChannelPerformanceRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getChannelPerformance(request);

      expect(result[0].isHighPerforming, false); // 10% < 20%
      expect(result[0].hasHighCancellation, true); // 20% > 15%
    });

    test('getTopChannels returns sorted top channels', () async {
      final mockResponse = Response(
        data: [
          _createChannelPerformanceJson(
              source: 'direct', totalRevenue: 30000000),
          _createChannelPerformanceJson(source: 'agoda', totalRevenue: 20000000),
          _createChannelPerformanceJson(
              source: 'booking_com', totalRevenue: 25000000),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/channels/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getTopChannels(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
        limit: 2,
      );

      expect(result.length, 2);
      expect(result[0].source, 'direct'); // Highest revenue
      expect(result[1].source, 'booking_com'); // Second highest
    });
  });

  group('ReportRepository - Guest Demographics', () {
    test('getGuestDemographics should return demographics data', () async {
      final mockResponse = Response(
        data: [
          _createGuestDemographicsJson(nationality: 'Vietnam'),
          _createGuestDemographicsJson(nationality: 'USA', guestCount: 10),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/demographics/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = GuestDemographicsRequest(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
      );

      final result = await repository.getGuestDemographics(request);

      expect(result.length, 2);
      expect(result[0].nationality, 'Vietnam');
      expect(result[0].guestCount, 50);
      expect(result[1].nationality, 'USA');
    });

    test('getTopNationalities returns sorted top nationalities', () async {
      final mockResponse = Response(
        data: [
          _createGuestDemographicsJson(nationality: 'Vietnam', guestCount: 50),
          _createGuestDemographicsJson(nationality: 'USA', guestCount: 30),
          _createGuestDemographicsJson(nationality: 'Japan', guestCount: 20),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/demographics/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getTopNationalities(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
        limit: 2,
      );

      expect(result.length, 2);
      expect(result[0].nationality, 'Vietnam'); // Highest count
      expect(result[1].nationality, 'USA'); // Second highest
    });
  });

  group('ReportRepository - Comparative Report', () {
    test('getComparativeReport should return comparison metrics', () async {
      final mockResponse = Response(
        data: [
          _createComparativeReportJson(metric: 'revenue'),
          _createComparativeReportJson(metric: 'occupancy'),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/comparative/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = ComparativeReportRequest(
        currentStart: DateTime(2024, 1, 1),
        currentEnd: DateTime(2024, 1, 31),
      );

      final result = await repository.getComparativeReport(request);

      expect(result.length, 2);
      expect(result[0].metric, 'revenue');
      expect(result[0].improved, true); // changePercentage > 0
    });

    test('ComparativeReport improved helper works correctly', () async {
      final mockResponse = Response(
        data: [
          _createComparativeReportJson(metric: 'revenue', changePercentage: -5.0),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/comparative/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = ComparativeReportRequest(
        currentStart: DateTime(2024, 1, 1),
        currentEnd: DateTime(2024, 1, 31),
      );

      final result = await repository.getComparativeReport(request);

      expect(result[0].improved, false); // changePercentage < 0
    });

    test('ComparativeReport metric display names', () async {
      final mockResponse = Response(
        data: [
          _createComparativeReportJson(metric: 'revenue'),
          _createComparativeReportJson(metric: 'occupancy'),
          _createComparativeReportJson(metric: 'adr'),
          _createComparativeReportJson(metric: 'revpar'),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/comparative/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final request = ComparativeReportRequest(
        currentStart: DateTime(2024, 1, 1),
        currentEnd: DateTime(2024, 1, 31),
      );

      final result = await repository.getComparativeReport(request);

      expect(result[0].metricDisplayName, 'Doanh thu');
      expect(result[1].metricDisplayName, 'Công suất');
      expect(result[2].metricDisplayName, 'ADR');
      expect(result[3].metricDisplayName, 'RevPAR');
    });
  });

  group('ReportRepository - Convenience Methods', () {
    test('getAverageOccupancy calculates correctly', () async {
      final mockResponse = Response(
        data: [
          _createOccupancyReportJson(occupancyRate: 70.0),
          _createOccupancyReportJson(occupancyRate: 80.0),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/occupancy/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getAverageOccupancy(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      expect(result, 75.0); // (70 + 80) / 2
    });

    test('getAverageOccupancy returns 0 when no data', () async {
      final mockResponse = Response(
        data: <dynamic>[],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/occupancy/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getAverageOccupancy(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      expect(result, 0);
    });

    test('getTotalRevenue calculates correctly', () async {
      final mockResponse = Response(
        data: [
          _createRevenueReportJson(totalRevenue: 1000000),
          _createRevenueReportJson(totalRevenue: 2000000),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/revenue/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getTotalRevenue(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      expect(result, 3000000);
    });

    test('getTotalExpenses calculates correctly', () async {
      final mockResponse = Response(
        data: [
          _createExpenseReportJson(totalAmount: 500000),
          _createExpenseReportJson(totalAmount: 300000),
        ],
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/reports/expenses/'),
      );

      when(mockApiClient.get<List<dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getTotalExpenses(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      expect(result, 800000);
    });
  });

  group('Report Model Tests', () {
    test('OccupancyReportRequest generates correct query params', () {
      final request = OccupancyReportRequest(
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 2, 15),
        groupBy: ReportGroupBy.week,
        roomType: 1,
      );

      final params = request.toQueryParams();

      expect(params['start_date'], '2024-01-15');
      expect(params['end_date'], '2024-02-15');
      expect(params['group_by'], 'week');
      expect(params['room_type'], '1');
    });

    test('ExportReportRequest generates correct filename', () {
      final request = ExportReportRequest(
        reportType: ReportType.revenue,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        format: ExportFormat.xlsx,
      );

      expect(
        request.suggestedFilename,
        'revenue_report_2024-01-01_to_2024-01-31.xlsx',
      );
    });

    test('ReportType has correct display names', () {
      expect(ReportType.occupancy.displayName, 'Công suất phòng');
      expect(ReportType.revenue.displayName, 'Doanh thu');
      expect(ReportType.kpi.displayName, 'KPI');
    });

    test('ReportGroupBy has correct API values', () {
      expect(ReportGroupBy.day.toApiValue, 'day');
      expect(ReportGroupBy.week.toApiValue, 'week');
      expect(ReportGroupBy.month.toApiValue, 'month');
    });

    test('ExportFormat has correct mime types', () {
      expect(
        ExportFormat.xlsx.mimeType,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      expect(ExportFormat.csv.mimeType, 'text/csv');
    });

    test('ExpenseReport color parsing works', () {
      final json = _createExpenseReportJson(categoryColor: '#FF5722');
      final report = ExpenseReport.fromJson(json);

      expect(report.colorValue.value, 0xFFFF5722);
    });
  });
}
