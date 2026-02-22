import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoang_lam_app/models/room.dart';
import 'package:hoang_lam_app/providers/room_provider.dart';
import 'package:hoang_lam_app/repositories/room_repository.dart';

import 'room_provider_test.mocks.dart';

@GenerateMocks([RoomRepository])
void main() {
  late MockRoomRepository mockRepository;

  // Provide dummy values for Freezed types that Mockito can't auto-generate
  setUpAll(() {
    provideDummy<Room>(Room(id: 0, number: '000', roomTypeId: 0));
    provideDummy<RoomType>(RoomType(id: 0, name: 'dummy', baseRate: 0));
  });

  final testRooms = [
    Room(
      id: 1,
      number: '101',
      roomTypeId: 1,
      roomTypeName: 'Standard',
      floor: 1,
      status: RoomStatus.available,
      isActive: true,
    ),
    Room(
      id: 2,
      number: '201',
      roomTypeId: 2,
      roomTypeName: 'Deluxe',
      floor: 2,
      status: RoomStatus.occupied,
      isActive: true,
    ),
    Room(
      id: 3,
      number: '301',
      roomTypeId: 1,
      roomTypeName: 'Standard',
      floor: 3,
      status: RoomStatus.maintenance,
      isActive: true,
    ),
  ];

  setUp(() {
    mockRepository = MockRoomRepository();
  });

  group('RoomNotifier via ProviderContainer', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [roomRepositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('loadRooms', () {
      test('should load rooms successfully', () async {
        when(
          mockRepository.getRooms(
            status: anyNamed('status'),
            roomTypeId: anyNamed('roomTypeId'),
            floor: anyNamed('floor'),
            isActive: true,
          ),
        ).thenAnswer((_) async => testRooms);

        final notifier = container.read(roomStateProvider.notifier);
        await notifier.loadRooms();

        final state = container.read(roomStateProvider);
        state.when(
          initial: () => fail('Expected loaded state'),
          loading: () => fail('Expected loaded state'),
          loaded: (rooms) {
            expect(rooms.length, 3);
            expect(rooms[0].number, '101');
            expect(rooms[1].status, RoomStatus.occupied);
          },
          error:
              (message) => fail('Expected loaded state, got error: $message'),
        );
      });

      test('should filter rooms by status', () async {
        when(
          mockRepository.getRooms(
            status: RoomStatus.available,
            roomTypeId: anyNamed('roomTypeId'),
            floor: anyNamed('floor'),
            isActive: true,
          ),
        ).thenAnswer((_) async => [testRooms[0]]);

        final notifier = container.read(roomStateProvider.notifier);
        await notifier.loadRooms(status: RoomStatus.available);

        final state = container.read(roomStateProvider);
        state.when(
          initial: () => fail('Expected loaded state'),
          loading: () => fail('Expected loaded state'),
          loaded: (rooms) {
            expect(rooms.length, 1);
            expect(rooms.first.status, RoomStatus.available);
          },
          error:
              (message) => fail('Expected loaded state, got error: $message'),
        );
      });

      test('should set error state on failure', () async {
        when(
          mockRepository.getRooms(
            status: anyNamed('status'),
            roomTypeId: anyNamed('roomTypeId'),
            floor: anyNamed('floor'),
            isActive: true,
          ),
        ).thenThrow(Exception('Network error'));

        final notifier = container.read(roomStateProvider.notifier);
        await notifier.loadRooms();

        final state = container.read(roomStateProvider);
        state.when(
          initial: () => fail('Expected error state'),
          loading: () => fail('Expected error state'),
          loaded: (_) => fail('Expected error state'),
          error: (message) {
            expect(message, isNotEmpty);
          },
        );
      });
    });

    group('updateRoomStatus', () {
      test('should update room status and return true', () async {
        when(mockRepository.updateRoomStatus(any, any)).thenAnswer(
          (_) async => Room(
            id: 1,
            number: '101',
            roomTypeId: 1,
            status: RoomStatus.maintenance,
          ),
        );

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.updateRoomStatus(
          1,
          RoomStatus.maintenance,
          notes: 'Fixing AC',
        );

        expect(result, true);
        verify(mockRepository.updateRoomStatus(1, any)).called(1);
      });

      test('should return false and set error on failure', () async {
        when(
          mockRepository.updateRoomStatus(any, any),
        ).thenThrow(Exception('Server error'));

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.updateRoomStatus(
          1,
          RoomStatus.maintenance,
        );

        expect(result, false);

        final state = container.read(roomStateProvider);
        state.when(
          initial: () => fail('Expected error state'),
          loading: () => fail('Expected error state'),
          loaded: (_) => fail('Expected error state'),
          error: (message) {
            expect(message, isNotEmpty);
          },
        );
      });
    });

    group('createRoom', () {
      test('should create room and return it', () async {
        final newRoom = Room(
          id: 4,
          number: '401',
          roomTypeId: 1,
          floor: 4,
          status: RoomStatus.available,
        );

        when(mockRepository.createRoom(any)).thenAnswer((_) async => newRoom);

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.createRoom(newRoom);

        expect(result, isNotNull);
        expect(result!.number, '401');
        verify(mockRepository.createRoom(any)).called(1);
      });

      test('should return null on duplicate room error', () async {
        when(
          mockRepository.createRoom(any),
        ).thenThrow(Exception('Room đã tồn tại'));

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.createRoom(
          Room(id: 0, number: '101', roomTypeId: 1),
        );

        expect(result, isNull);

        final state = container.read(roomStateProvider);
        state.when(
          initial: () => fail('Expected error state'),
          loading: () => fail('Expected error state'),
          loaded: (_) => fail('Expected error state'),
          error: (message) {
            expect(message, isNotEmpty);
          },
        );
      });
    });

    group('updateRoom', () {
      test('should update room and return it', () async {
        final updatedRoom = Room(
          id: 1,
          number: '101A',
          roomTypeId: 2,
          floor: 1,
          status: RoomStatus.available,
        );

        when(
          mockRepository.updateRoom(any),
        ).thenAnswer((_) async => updatedRoom);

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.updateRoom(updatedRoom);

        expect(result, isNotNull);
        expect(result!.number, '101A');
        verify(mockRepository.updateRoom(any)).called(1);
      });

      test('should return null on update failure', () async {
        when(
          mockRepository.updateRoom(any),
        ).thenThrow(Exception('Validation error'));

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.updateRoom(
          Room(id: 1, number: '101', roomTypeId: 1),
        );

        expect(result, isNull);
      });
    });

    group('deleteRoom', () {
      test('should delete room and return true', () async {
        when(mockRepository.deleteRoom(1)).thenAnswer((_) async {});

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.deleteRoom(1);

        expect(result, true);
        verify(mockRepository.deleteRoom(1)).called(1);
      });

      test('should return false when room cannot be deleted', () async {
        when(
          mockRepository.deleteRoom(1),
        ).thenThrow(Exception('không thể xóa room with bookings'));

        final notifier = container.read(roomStateProvider.notifier);
        final result = await notifier.deleteRoom(1);

        expect(result, false);
      });
    });
  });

  group('Room FutureProviders', () {
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockRoomRepository();
      container = ProviderContainer(
        overrides: [roomRepositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('roomsProvider fetches active rooms', () async {
      when(
        mockRepository.getRooms(isActive: true),
      ).thenAnswer((_) async => testRooms);

      final rooms = await container.read(roomsProvider.future);
      expect(rooms.length, 3);
    });

    test('allRoomsProvider fetches all rooms', () async {
      when(mockRepository.getRooms()).thenAnswer((_) async => testRooms);

      final rooms = await container.read(allRoomsProvider.future);
      expect(rooms.length, 3);
    });

    test('roomByIdProvider fetches single room', () async {
      when(mockRepository.getRoom(1)).thenAnswer((_) async => testRooms.first);

      final room = await container.read(roomByIdProvider(1).future);
      expect(room.id, 1);
      expect(room.number, '101');
    });

    test('roomsByFloorProvider groups rooms by floor', () async {
      when(mockRepository.getRoomsGroupedByFloor()).thenAnswer(
        (_) async => {
          1: [testRooms[0]],
          2: [testRooms[1]],
          3: [testRooms[2]],
        },
      );

      final grouped = await container.read(roomsByFloorProvider.future);
      expect(grouped.keys.length, 3);
      expect(grouped[1]!.first.number, '101');
      expect(grouped[2]!.first.number, '201');
    });

    test('roomStatusCountsProvider returns status counts', () async {
      when(mockRepository.getRoomStatusCounts()).thenAnswer(
        (_) async => {
          RoomStatus.available: 5,
          RoomStatus.occupied: 3,
          RoomStatus.maintenance: 1,
        },
      );

      final counts = await container.read(roomStatusCountsProvider.future);
      expect(counts[RoomStatus.available], 5);
      expect(counts[RoomStatus.occupied], 3);
      expect(counts[RoomStatus.maintenance], 1);
    });

    test('roomTypesProvider fetches room types', () async {
      final roomTypes = [
        RoomType(id: 1, name: 'Standard', baseRate: 500000),
        RoomType(id: 2, name: 'Deluxe', baseRate: 1000000),
      ];

      when(
        mockRepository.getRoomTypes(isActive: true),
      ).thenAnswer((_) async => roomTypes);

      final types = await container.read(roomTypesProvider.future);
      expect(types.length, 2);
      expect(types[0].name, 'Standard');
      expect(types[1].baseRate, 1000000);
    });

    test('filteredRoomsProvider applies filter', () async {
      final filter = RoomFilter(status: RoomStatus.available, floor: 1);

      when(
        mockRepository.getRooms(
          status: RoomStatus.available,
          roomTypeId: null,
          floor: 1,
          isActive: null,
          search: null,
        ),
      ).thenAnswer((_) async => [testRooms[0]]);

      final rooms = await container.read(filteredRoomsProvider(filter).future);
      expect(rooms.length, 1);
      expect(rooms.first.number, '101');
    });

    test('availableRoomsProvider checks availability', () async {
      final filter = AvailabilityFilter(
        checkIn: DateTime(2026, 3, 1),
        checkOut: DateTime(2026, 3, 3),
      );

      when(
        mockRepository.getAvailableRooms(
          checkIn: DateTime(2026, 3, 1),
          checkOut: DateTime(2026, 3, 3),
          roomTypeId: null,
        ),
      ).thenAnswer((_) async => [testRooms[0]]);

      final rooms = await container.read(availableRoomsProvider(filter).future);
      expect(rooms.length, 1);
    });
  });
}
