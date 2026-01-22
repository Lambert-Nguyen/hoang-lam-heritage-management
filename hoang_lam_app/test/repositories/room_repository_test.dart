import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/core/network/api_client.dart';
import 'package:hoang_lam_app/models/room.dart';
import 'package:hoang_lam_app/repositories/room_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'room_repository_test.mocks.dart';

@GenerateMocks([ApiClient])
void main() {
  late RoomRepository repository;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = RoomRepository(apiClient: mockApiClient);
  });

  // Helper to create room type JSON matching backend RoomTypeSerializer
  Map<String, dynamic> _createRoomTypeJson({
    required int id,
    required String name,
    required int baseRate,
    int maxGuests = 2,
    bool isActive = true,
  }) {
    return {
      'id': id,
      'name': name,
      'name_en': name,
      'base_rate': baseRate,
      'max_guests': maxGuests,
      'description': '$name room',
      'amenities': [],
      'is_active': isActive,
      'room_count': 0,
      'available_room_count': 0,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
  }

  // Helper to create room JSON matching backend RoomSerializer
  Map<String, dynamic> _createRoomJson({
    required int id,
    required String number,
    required int roomTypeId,
    int floor = 1,
    String status = 'available',
    bool isActive = true,
  }) {
    return {
      'id': id,
      'number': number,
      'name': 'Room $number',
      'room_type': roomTypeId,
      'room_type_name': 'Single',
      'room_type_details': _createRoomTypeJson(
        id: roomTypeId,
        name: 'Single',
        baseRate: 300000,
      ),
      'floor': floor,
      'status': status,
      'status_display': status.toUpperCase(),
      'amenities': [],
      'notes': '',
      'is_active': isActive,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
  }

  group('RoomRepository - RoomTypes', () {
    test('getRoomTypes should return list of room types', () async {
      final mockResponse = Response(
        data: {
          'count': 2,
          'next': null,
          'previous': null,
          'results': [
            _createRoomTypeJson(id: 1, name: 'Single', baseRate: 300000),
            _createRoomTypeJson(id: 2, name: 'Double', baseRate: 400000),
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/room-types/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getRoomTypes();

      expect(result.length, 2);
      expect(result[0].name, 'Single');
      expect(result[1].name, 'Double');
      verify(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).called(1);
    });

    test('getRoomTypes with isActive filter should pass query parameter',
        () async {
      final mockResponse = Response(
        data: {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            _createRoomTypeJson(id: 1, name: 'Single', baseRate: 300000),
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/room-types/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getRoomTypes(isActive: true);

      expect(result.length, 1);
      verify(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: {'is_active': 'true'},
      )).called(1);
    });

    test('getRoomType should return single room type', () async {
      final mockResponse = Response(
        data: _createRoomTypeJson(id: 1, name: 'Single', baseRate: 300000),
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/room-types/1/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(any))
          .thenAnswer((_) async => mockResponse);

      final result = await repository.getRoomType(1);

      expect(result.id, 1);
      expect(result.name, 'Single');
      verify(mockApiClient.get<Map<String, dynamic>>(any)).called(1);
    });

    test('createRoomType should post data and return room type', () async {
      final mockResponse = Response(
        data: _createRoomTypeJson(id: 1, name: 'Single', baseRate: 300000),
        statusCode: 201,
        requestOptions: RequestOptions(path: '/api/v1/room-types/'),
      );

      when(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      final roomType = RoomType(
        id: 1,
        name: 'Single',
        baseRate: 300000,
      );
      final result = await repository.createRoomType(roomType);

      expect(result.name, 'Single');
      verify(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).called(1);
    });
  });

  group('RoomRepository - Rooms', () {
    test('getRooms should return list of rooms', () async {
      final mockResponse = Response(
        data: {
          'count': 2,
          'next': null,
          'previous': null,
          'results': [
            _createRoomJson(id: 1, number: '101', roomTypeId: 1),
            _createRoomJson(id: 2, number: '102', roomTypeId: 1),
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/rooms/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getRooms();

      expect(result.length, 2);
      expect(result[0].number, '101');
      expect(result[1].number, '102');
      verify(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).called(1);
    });

    test('getRooms with filters should pass query parameters', () async {
      final mockResponse = Response(
        data: {
          'count': 1,
          'next': null,
          'previous': null,
          'results': [
            _createRoomJson(id: 1, number: '101', roomTypeId: 1, floor: 1),
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/rooms/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getRooms(
        status: RoomStatus.available,
        roomTypeId: 1,
        floor: 1,
      );

      expect(result.length, 1);
      verify(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: {
          'status': 'available',
          'room_type': '1',
          'floor': '1',
        },
      )).called(1);
    });

    test('getRoom should return single room', () async {
      final mockResponse = Response(
        data: _createRoomJson(id: 1, number: '101', roomTypeId: 1),
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/rooms/1/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(any))
          .thenAnswer((_) async => mockResponse);

      final result = await repository.getRoom(1);

      expect(result.id, 1);
      expect(result.number, '101');
      verify(mockApiClient.get<Map<String, dynamic>>(any)).called(1);
    });

    test('createRoom should post data and return room', () async {
      final mockResponse = Response(
        data: _createRoomJson(id: 1, number: '101', roomTypeId: 1),
        statusCode: 201,
        requestOptions: RequestOptions(path: '/api/v1/rooms/'),
      );

      when(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      final room = Room(
        id: 1,
        number: '101',
        roomTypeId: 1,
        floor: 1,
      );
      final result = await repository.createRoom(room);

      expect(result.number, '101');
      verify(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).called(1);
    });

    test('updateRoomStatus should call update-status endpoint', () async {
      final mockResponse = Response(
        data: _createRoomJson(
          id: 1,
          number: '101',
          roomTypeId: 1,
          status: 'cleaning',
        ),
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/rooms/1/update-status/'),
      );

      when(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      final request = RoomStatusUpdateRequest(
        status: RoomStatus.cleaning,
        notes: 'Daily cleaning',
      );
      final result = await repository.updateRoomStatus(1, request);

      expect(result.status, RoomStatus.cleaning);
      verify(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).called(1);
    });

    test('checkAvailability should call check-availability endpoint',
        () async {
      final mockResponse = Response(
        data: {
          'available_rooms': [
            _createRoomJson(id: 1, number: '101', roomTypeId: 1),
          ],
          'total_available': 1,
          'check_in': '2024-01-01',
          'check_out': '2024-01-05',
        },
        statusCode: 200,
        requestOptions:
            RequestOptions(path: '/api/v1/rooms/check-availability/'),
      );

      when(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      final request = RoomAvailabilityRequest(
        checkIn: DateTime(2024, 1, 1),
        checkOut: DateTime(2024, 1, 5),
      );
      final result = await repository.checkAvailability(request);

      expect(result.totalAvailable, 1);
      expect(result.availableRooms.length, 1);
      verify(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).called(1);
    });

    test('getAvailableRooms should return available rooms', () async {
      final mockResponse = Response(
        data: {
          'available_rooms': [
            _createRoomJson(id: 1, number: '101', roomTypeId: 1),
            _createRoomJson(id: 2, number: '102', roomTypeId: 1),
          ],
          'total_available': 2,
          'check_in': '2024-01-01',
          'check_out': '2024-01-05',
        },
        statusCode: 200,
        requestOptions:
            RequestOptions(path: '/api/v1/rooms/check-availability/'),
      );

      when(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getAvailableRooms(
        checkIn: DateTime(2024, 1, 1),
        checkOut: DateTime(2024, 1, 5),
      );

      expect(result.length, 2);
      verify(mockApiClient.post<Map<String, dynamic>>(
        any,
        data: anyNamed('data'),
      )).called(1);
    });

    test('deleteRoom should call delete endpoint', () async {
      final mockResponse = Response(
        data: null,
        statusCode: 204,
        requestOptions: RequestOptions(path: '/api/v1/rooms/1/'),
      );

      when(mockApiClient.delete(any)).thenAnswer((_) async => mockResponse);

      await repository.deleteRoom(1);

      verify(mockApiClient.delete(any)).called(1);
    });
  });

  group('RoomRepository - Grouping and Aggregation', () {
    test('getRoomsGroupedByFloor should return rooms grouped by floor',
        () async {
      final mockResponse = Response(
        data: {
          'count': 2,
          'next': null,
          'previous': null,
          'results': [
            _createRoomJson(id: 1, number: '101', roomTypeId: 1, floor: 1),
            _createRoomJson(id: 2, number: '201', roomTypeId: 2, floor: 2),
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/rooms/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getRoomsGroupedByFloor();

      expect(result.length, 2); // 2 floors
      expect(result[1]!.length, 1); // 1 room on floor 1
      expect(result[2]!.length, 1); // 1 room on floor 2
      verify(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).called(1);
    });

    test('getRoomStatusCounts should return counts by status', () async {
      final mockResponse = Response(
        data: {
          'count': 3,
          'next': null,
          'previous': null,
          'results': [
            _createRoomJson(
              id: 1,
              number: '101',
              roomTypeId: 1,
              status: 'available',
            ),
            _createRoomJson(
              id: 2,
              number: '102',
              roomTypeId: 1,
              status: 'available',
            ),
            _createRoomJson(
              id: 3,
              number: '201',
              roomTypeId: 2,
              status: 'occupied',
            ),
          ],
        },
        statusCode: 200,
        requestOptions: RequestOptions(path: '/api/v1/rooms/'),
      );

      when(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).thenAnswer((_) async => mockResponse);

      final result = await repository.getRoomStatusCounts();

      expect(result[RoomStatus.available], 2); // 2 available rooms
      expect(result[RoomStatus.occupied], 1); // 1 occupied room
      verify(mockApiClient.get<Map<String, dynamic>>(
        any,
        queryParameters: anyNamed('queryParameters'),
      )).called(1);
    });
  });
}
