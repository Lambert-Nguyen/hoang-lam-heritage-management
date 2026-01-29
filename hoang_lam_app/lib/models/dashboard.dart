import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard.freezed.dart';
part 'dashboard.g.dart';

/// Dashboard summary data
@freezed
sealed class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    @JsonKey(name: 'room_status') required RoomStatusSummary roomStatus,
    required TodaySummary today,
    required OccupancySummary occupancy,
    required BookingsSummary bookings,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}

/// Room status summary
@freezed
sealed class RoomStatusSummary with _$RoomStatusSummary {
  const factory RoomStatusSummary({
    required int total,
    required int available,
    required int occupied,
    required int cleaning,
    required int maintenance,
    required int blocked,
  }) = _RoomStatusSummary;

  factory RoomStatusSummary.fromJson(Map<String, dynamic> json) =>
      _$RoomStatusSummaryFromJson(json);
}

/// Today's summary
@freezed
sealed class TodaySummary with _$TodaySummary {
  const factory TodaySummary({
    required String date,
    @JsonKey(name: 'check_ins') required int checkIns,
    @JsonKey(name: 'check_outs') required int checkOuts,
    @JsonKey(name: 'pending_arrivals') required int pendingArrivals,
    @JsonKey(name: 'pending_departures') required int pendingDepartures,
  }) = _TodaySummary;

  factory TodaySummary.fromJson(Map<String, dynamic> json) =>
      _$TodaySummaryFromJson(json);
}

/// Occupancy summary
@freezed
sealed class OccupancySummary with _$OccupancySummary {
  const factory OccupancySummary({
    required double rate,
    @JsonKey(name: 'occupied_rooms') required int occupiedRooms,
    @JsonKey(name: 'total_rooms') required int totalRooms,
  }) = _OccupancySummary;

  factory OccupancySummary.fromJson(Map<String, dynamic> json) =>
      _$OccupancySummaryFromJson(json);
}

/// Bookings summary
@freezed
sealed class BookingsSummary with _$BookingsSummary {
  const factory BookingsSummary({
    required int pending,
    required int confirmed,
    @JsonKey(name: 'checked_in') required int checkedIn,
  }) = _BookingsSummary;

  factory BookingsSummary.fromJson(Map<String, dynamic> json) =>
      _$BookingsSummaryFromJson(json);
}
