import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/core/theme/app_colors.dart';
import 'package:hoang_lam_app/models/room.dart';

void main() {
  group('RoomStatus', () {
    test('has correct display names in Vietnamese', () {
      expect(RoomStatus.available.displayName, 'Trống');
      expect(RoomStatus.occupied.displayName, 'Có khách');
      expect(RoomStatus.cleaning.displayName, 'Đang dọn');
      expect(RoomStatus.maintenance.displayName, 'Bảo trì');
      expect(RoomStatus.blocked.displayName, 'Khóa');
    });

    test('has correct display names in English', () {
      expect(RoomStatus.available.displayNameEn, 'Available');
      expect(RoomStatus.occupied.displayNameEn, 'Occupied');
      expect(RoomStatus.cleaning.displayNameEn, 'Cleaning');
      expect(RoomStatus.maintenance.displayNameEn, 'Maintenance');
      expect(RoomStatus.blocked.displayNameEn, 'Blocked');
    });

    test('has correct colors', () {
      expect(RoomStatus.available.color, AppColors.available);
      expect(RoomStatus.occupied.color, AppColors.occupied);
      expect(RoomStatus.cleaning.color, AppColors.cleaning);
      expect(RoomStatus.maintenance.color, AppColors.maintenance);
      expect(RoomStatus.blocked.color, AppColors.blocked);
    });

    test('has correct icons', () {
      expect(RoomStatus.available.icon, Icons.check_circle);
      expect(RoomStatus.occupied.icon, Icons.person);
      expect(RoomStatus.cleaning.icon, Icons.cleaning_services);
      expect(RoomStatus.maintenance.icon, Icons.build);
      expect(RoomStatus.blocked.icon, Icons.block);
    });

    test('isBookable returns true only for available status', () {
      expect(RoomStatus.available.isBookable, isTrue);
      expect(RoomStatus.occupied.isBookable, isFalse);
      expect(RoomStatus.cleaning.isBookable, isFalse);
      expect(RoomStatus.maintenance.isBookable, isFalse);
      expect(RoomStatus.blocked.isBookable, isFalse);
    });

    test('canMarkAvailable returns true for cleaning and blocked', () {
      expect(RoomStatus.available.canMarkAvailable, isFalse);
      expect(RoomStatus.occupied.canMarkAvailable, isFalse);
      expect(RoomStatus.cleaning.canMarkAvailable, isTrue);
      expect(RoomStatus.maintenance.canMarkAvailable, isFalse);
      expect(RoomStatus.blocked.canMarkAvailable, isTrue);
    });
  });

  group('RoomType', () {
    test('creates from constructor', () {
      const roomType = RoomType(
        id: 1,
        name: 'Phòng đơn',
        nameEn: 'Single Room',
        baseRate: 300000,
        maxGuests: 1,
      );

      expect(roomType.id, 1);
      expect(roomType.name, 'Phòng đơn');
      expect(roomType.nameEn, 'Single Room');
      expect(roomType.baseRate, 300000);
      expect(roomType.maxGuests, 1);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 1,
        'name': 'Phòng đơn',
        'name_en': 'Single Room',
        'base_rate': 300000,
        'max_guests': 2,
        'is_active': true,
        'room_count': 3,
        'available_room_count': 2,
      };

      final roomType = RoomType.fromJson(json);
      expect(roomType.id, 1);
      expect(roomType.name, 'Phòng đơn');
      expect(roomType.nameEn, 'Single Room');
      expect(roomType.baseRate, 300000);
      expect(roomType.maxGuests, 2);
      expect(roomType.isActive, isTrue);
      expect(roomType.roomCount, 3);
      expect(roomType.availableRoomCount, 2);
    });

    test('displayName returns Vietnamese by default', () {
      const roomType = RoomType(
        id: 1,
        name: 'Phòng đơn',
        nameEn: 'Single Room',
        baseRate: 300000,
      );

      expect(roomType.displayName(false), 'Phòng đơn');
      expect(roomType.displayName(true), 'Single Room');
    });

    test('displayName falls back to Vietnamese when English is null', () {
      const roomType = RoomType(id: 1, name: 'Phòng đơn', baseRate: 300000);

      expect(roomType.displayName(true), 'Phòng đơn');
    });

    test('formattedBaseRate formats correctly', () {
      const roomType = RoomType(id: 1, name: 'Test', baseRate: 300000);

      expect(roomType.formattedBaseRate, '300.000đ');
    });
  });

  group('Room', () {
    test('creates from constructor', () {
      const room = Room(
        id: 1,
        number: '101',
        roomTypeId: 1,
        floor: 1,
        status: RoomStatus.available,
      );

      expect(room.id, 1);
      expect(room.number, '101');
      expect(room.roomTypeId, 1);
      expect(room.floor, 1);
      expect(room.status, RoomStatus.available);
    });

    test('deserializes from JSON', () {
      final json = {
        'id': 1,
        'number': '101',
        'room_type': 1,
        'room_type_name': 'Phòng đơn',
        'floor': 1,
        'status': 'available',
        'status_display': 'Trống',
        'amenities': ['wifi', 'tv'],
        'notes': 'Test note',
        'is_active': true,
        'base_rate': 300000,
      };

      final room = Room.fromJson(json);
      expect(room.id, 1);
      expect(room.number, '101');
      expect(room.roomTypeId, 1);
      expect(room.roomTypeName, 'Phòng đơn');
      expect(room.floor, 1);
      expect(room.status, RoomStatus.available);
      expect(room.statusDisplay, 'Trống');
      expect(room.amenities, ['wifi', 'tv']);
      expect(room.notes, 'Test note');
      expect(room.isActive, isTrue);
      expect(room.baseRate, 300000);
    });

    test('displayName returns number when name is null', () {
      const room = Room(id: 1, number: '101', roomTypeId: 1);

      expect(room.displayName, '101');
    });

    test('displayName returns number and name when both present', () {
      const room = Room(id: 1, number: '101', name: 'VIP Suite', roomTypeId: 1);

      expect(room.displayName, '101 - VIP Suite');
    });

    test('statusColor returns correct color', () {
      const room = Room(
        id: 1,
        number: '101',
        roomTypeId: 1,
        status: RoomStatus.occupied,
      );

      expect(room.statusColor, RoomStatus.occupied.color);
    });

    test('isAvailable returns true only for available status', () {
      const availableRoom = Room(
        id: 1,
        number: '101',
        roomTypeId: 1,
        status: RoomStatus.available,
      );

      const occupiedRoom = Room(
        id: 2,
        number: '102',
        roomTypeId: 1,
        status: RoomStatus.occupied,
      );

      expect(availableRoom.isAvailable, isTrue);
      expect(occupiedRoom.isAvailable, isFalse);
    });

    test('formattedRate formats baseRate correctly', () {
      const room = Room(id: 1, number: '101', roomTypeId: 1, baseRate: 500000);

      expect(room.formattedRate, '500.000đ');
    });
  });

  group('RoomListResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'count': 2,
        'next': 'http://api.com/rooms?page=2',
        'previous': null,
        'results': [
          {
            'id': 1,
            'number': '101',
            'room_type': 1,
            'floor': 1,
            'status': 'available',
          },
          {
            'id': 2,
            'number': '102',
            'room_type': 1,
            'floor': 1,
            'status': 'occupied',
          },
        ],
      };

      final response = RoomListResponse.fromJson(json);
      expect(response.count, 2);
      expect(response.next, 'http://api.com/rooms?page=2');
      expect(response.previous, isNull);
      expect(response.results.length, 2);
      expect(response.results[0].number, '101');
      expect(response.results[1].number, '102');
    });
  });

  group('RoomStatusUpdateRequest', () {
    test('creates from constructor', () {
      const request = RoomStatusUpdateRequest(
        status: RoomStatus.cleaning,
        notes: 'Cleaning in progress',
      );

      expect(request.status, RoomStatus.cleaning);
      expect(request.notes, 'Cleaning in progress');
    });

    test('serializes to JSON', () {
      const request = RoomStatusUpdateRequest(
        status: RoomStatus.maintenance,
        notes: 'AC needs repair',
      );

      final json = request.toJson();
      expect(json['status'], 'maintenance');
      expect(json['notes'], 'AC needs repair');
    });
  });

  group('RoomAvailabilityRequest', () {
    test('serializes to JSON', () {
      final request = RoomAvailabilityRequest(
        checkIn: DateTime(2024, 1, 15),
        checkOut: DateTime(2024, 1, 17),
        roomTypeId: 1,
      );

      final json = request.toJson();
      expect(json['check_in'], '2024-01-15T00:00:00.000');
      expect(json['check_out'], '2024-01-17T00:00:00.000');
      expect(json['room_type'], 1);
    });
  });

  group('RoomAvailabilityResponse', () {
    test('deserializes from JSON', () {
      final json = {
        'available_rooms': [
          {
            'id': 1,
            'number': '101',
            'room_type': 1,
            'floor': 1,
            'status': 'available',
          },
        ],
        'total_available': 1,
        'check_in': '2024-01-15',
        'check_out': '2024-01-17',
        'room_type': 1,
      };

      final response = RoomAvailabilityResponse.fromJson(json);
      expect(response.availableRooms.length, 1);
      expect(response.totalAvailable, 1);
      expect(response.checkIn, '2024-01-15');
      expect(response.checkOut, '2024-01-17');
      expect(response.roomTypeId, 1);
    });
  });
}
