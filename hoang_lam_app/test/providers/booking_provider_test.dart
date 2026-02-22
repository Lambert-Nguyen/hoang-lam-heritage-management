import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoang_lam_app/models/booking.dart';
import 'package:hoang_lam_app/providers/booking_provider.dart';
import 'package:hoang_lam_app/repositories/booking_repository.dart';

import 'booking_provider_test.mocks.dart';

class MockRef extends Mock implements Ref {}

@GenerateMocks([BookingRepository])
void main() {
  late MockBookingRepository mockRepository;
  late MockRef mockRef;
  late ProviderContainer container;

  BookingNotifier createNotifier() {
    container = ProviderContainer(
      overrides: [bookingRepositoryProvider.overrideWithValue(mockRepository)],
    );
    return BookingNotifier(mockRepository, mockRef);
  }

  // Provide dummy values for Freezed types that Mockito can't auto-generate
  setUpAll(() {
    provideDummy<Booking>(
      Booking(
        id: 0,
        room: 0,
        guest: 0,
        checkInDate: DateTime(2020),
        checkOutDate: DateTime(2020),
        nightlyRate: 0,
        totalAmount: 0,
      ),
    );
  });

  final testBookings = [
    Booking(
      id: 1,
      room: 101,
      guest: 1,
      roomNumber: '101',
      checkInDate: DateTime(2026, 2, 15),
      checkOutDate: DateTime(2026, 2, 17),
      status: BookingStatus.confirmed,
      source: BookingSource.walkIn,
      nightlyRate: 1000000,
      totalAmount: 2000000,
    ),
    Booking(
      id: 2,
      room: 102,
      guest: 2,
      roomNumber: '102',
      checkInDate: DateTime(2026, 2, 16),
      checkOutDate: DateTime(2026, 2, 18),
      status: BookingStatus.checkedIn,
      source: BookingSource.bookingCom,
      nightlyRate: 1500000,
      totalAmount: 3000000,
    ),
  ];

  setUp(() {
    mockRepository = MockBookingRepository();
    mockRef = MockRef();
  });

  group('BookingNotifier', () {
    group('loadBookings', () {
      test('should load bookings successfully', () async {
        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        final notifier = BookingNotifier(mockRepository, mockRef);
        // Constructor calls loadBookings, wait for it
        await Future.delayed(Duration.zero);

        expect(notifier.state.hasValue, true);
        expect(notifier.state.value!.length, 2);
        expect(notifier.state.value![0].roomNumber, '101');
        expect(notifier.state.value![1].status, BookingStatus.checkedIn);
      });

      test('should set error state on failure', () async {
        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenThrow(Exception('Network error'));

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        expect(notifier.state.hasError, true);
      });
    });

    group('applyFilter', () {
      test('should reload bookings with filter params', () async {
        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        final filter = BookingFilter(
          status: BookingStatus.confirmed,
          source: BookingSource.walkIn,
        );
        await notifier.applyFilter(filter);

        // Should have called getBookings twice (initial + filter)
        verify(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).called(2);
      });
    });

    group('clearFilter', () {
      test('should reload bookings without filter', () async {
        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        await notifier.clearFilter();

        // initial + clearFilter = 2 calls
        verify(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).called(2);
      });
    });

    group('createBooking', () {
      test('should create booking and reload list', () async {
        final newBooking = testBookings.first;
        final createData = BookingCreate(
          room: 101,
          guest: 1,
          checkInDate: DateTime(2026, 2, 15),
          checkOutDate: DateTime(2026, 2, 17),
          nightlyRate: 1000000,
        );

        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        when(
          mockRepository.createBooking(any),
        ).thenAnswer((_) async => newBooking);

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        final result = await notifier.createBooking(createData);

        expect(result.id, 1);
        verify(mockRepository.createBooking(any)).called(1);
      });

      test('should rethrow on creation failure', () async {
        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        when(
          mockRepository.createBooking(any),
        ).thenThrow(Exception('Validation error'));

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        expect(
          () => notifier.createBooking(
            BookingCreate(
              room: 101,
              guest: 1,
              checkInDate: DateTime(2026, 2, 15),
              checkOutDate: DateTime(2026, 2, 17),
              nightlyRate: 1000000,
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('checkIn', () {
      test('should check in booking and reload list', () async {
        final checkedInBooking = Booking(
          id: 1,
          room: 101,
          guest: 1,
          roomNumber: '101',
          checkInDate: DateTime(2026, 2, 15),
          checkOutDate: DateTime(2026, 2, 17),
          status: BookingStatus.checkedIn,
          source: BookingSource.walkIn,
          nightlyRate: 1000000,
          totalAmount: 2000000,
        );

        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => [checkedInBooking]);

        when(
          mockRepository.checkIn(
            any,
            actualCheckInNotes: anyNamed('actualCheckInNotes'),
          ),
        ).thenAnswer((_) async => checkedInBooking);

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        final result = await notifier.checkIn(1, notes: 'Early check-in');

        expect(result.status, BookingStatus.checkedIn);
        verify(
          mockRepository.checkIn(1, actualCheckInNotes: 'Early check-in'),
        ).called(1);
      });
    });

    group('checkOut', () {
      test('should check out booking and reload list', () async {
        final checkedOutBooking = Booking(
          id: 1,
          room: 101,
          guest: 1,
          checkInDate: DateTime(2026, 2, 15),
          checkOutDate: DateTime(2026, 2, 17),
          status: BookingStatus.checkedOut,
          nightlyRate: 1000000,
          totalAmount: 2000000,
        );

        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        when(
          mockRepository.checkOut(
            any,
            actualCheckOutNotes: anyNamed('actualCheckOutNotes'),
            finalAmount: anyNamed('finalAmount'),
          ),
        ).thenAnswer((_) async => checkedOutBooking);

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        final result = await notifier.checkOut(1, notes: 'Normal checkout');

        expect(result.status, BookingStatus.checkedOut);
      });
    });

    group('cancelBooking', () {
      test('should cancel booking and reload list', () async {
        final cancelledBooking = Booking(
          id: 1,
          room: 101,
          guest: 1,
          checkInDate: DateTime(2026, 2, 15),
          checkOutDate: DateTime(2026, 2, 17),
          status: BookingStatus.cancelled,
          nightlyRate: 1000000,
          totalAmount: 2000000,
        );

        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        when(
          mockRepository.cancelBooking(
            any,
            cancellationReason: anyNamed('cancellationReason'),
          ),
        ).thenAnswer((_) async => cancelledBooking);

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        final result = await notifier.cancelBooking(1, reason: 'Guest request');

        expect(result.status, BookingStatus.cancelled);
        verify(
          mockRepository.cancelBooking(1, cancellationReason: 'Guest request'),
        ).called(1);
      });
    });

    group('deleteBooking', () {
      test('should delete booking and reload list', () async {
        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        when(mockRepository.deleteBooking(any)).thenAnswer((_) async {});

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        await notifier.deleteBooking(1);

        verify(mockRepository.deleteBooking(1)).called(1);
      });

      test('should rethrow on delete failure', () async {
        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        when(
          mockRepository.deleteBooking(any),
        ).thenThrow(Exception('Cannot delete'));

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        expect(() => notifier.deleteBooking(1), throwsA(isA<Exception>()));
      });
    });

    group('markAsNoShow', () {
      test('should mark as no-show and reload', () async {
        final noShowBooking = Booking(
          id: 1,
          room: 101,
          guest: 1,
          checkInDate: DateTime(2026, 2, 15),
          checkOutDate: DateTime(2026, 2, 17),
          status: BookingStatus.noShow,
          nightlyRate: 1000000,
          totalAmount: 2000000,
        );

        when(
          mockRepository.getBookings(
            status: anyNamed('status'),
            roomId: anyNamed('roomId'),
            guestId: anyNamed('guestId'),
            source: anyNamed('source'),
            checkInFrom: anyNamed('checkInFrom'),
            checkInTo: anyNamed('checkInTo'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testBookings);

        when(
          mockRepository.markAsNoShow(any, notes: anyNamed('notes')),
        ).thenAnswer((_) async => noShowBooking);

        final notifier = BookingNotifier(mockRepository, mockRef);
        await Future.delayed(Duration.zero);

        final result = await notifier.markAsNoShow(1, notes: 'No contact');

        expect(result.status, BookingStatus.noShow);
      });
    });
  });

  group('Booking providers with container', () {
    setUp(() {
      mockRepository = MockBookingRepository();
    });

    test('bookingsProvider fetches bookings', () async {
      when(
        mockRepository.getBookings(ordering: anyNamed('ordering')),
      ).thenAnswer((_) async => testBookings);

      final container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final bookings = await container.read(bookingsProvider.future);
      expect(bookings.length, 2);
    });

    test('activeBookingsProvider fetches active bookings', () async {
      when(
        mockRepository.getActiveBookings(),
      ).thenAnswer((_) async => [testBookings[1]]);

      final container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final bookings = await container.read(activeBookingsProvider.future);
      expect(bookings.length, 1);
      expect(bookings.first.status, BookingStatus.checkedIn);
    });

    test('bookingByIdProvider fetches single booking', () async {
      when(
        mockRepository.getBooking(1),
      ).thenAnswer((_) async => testBookings.first);

      final container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final booking = await container.read(bookingByIdProvider(1).future);
      expect(booking.id, 1);
      expect(booking.roomNumber, '101');
    });

    test('bookingNotifierProvider creates notifier', () async {
      when(
        mockRepository.getBookings(
          status: anyNamed('status'),
          roomId: anyNamed('roomId'),
          guestId: anyNamed('guestId'),
          source: anyNamed('source'),
          checkInFrom: anyNamed('checkInFrom'),
          checkInTo: anyNamed('checkInTo'),
          ordering: anyNamed('ordering'),
        ),
      ).thenAnswer((_) async => testBookings);

      final container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // Force creation of notifier (lazy provider)
      container.read(bookingNotifierProvider);

      // Wait for initial load to complete
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(bookingNotifierProvider);
      expect(state.hasValue, true);
      expect(state.value!.length, 2);
    });
  });
}
