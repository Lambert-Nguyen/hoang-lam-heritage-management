import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoang_lam_app/models/guest.dart';
import 'package:hoang_lam_app/providers/guest_provider.dart';
import 'package:hoang_lam_app/repositories/guest_repository.dart';

import 'guest_provider_test.mocks.dart';

@GenerateMocks([GuestRepository])
void main() {
  late MockGuestRepository mockRepository;

  // Provide dummy values for Freezed types that Mockito can't auto-generate
  setUpAll(() {
    provideDummy<Guest>(Guest(id: 0, fullName: 'dummy', phone: '0000000000'));
  });

  final testGuests = [
    Guest(
      id: 1,
      fullName: 'Nguyen Van A',
      phone: '0901234567',
      email: 'a@test.com',
      nationality: 'Vietnam',
      isVip: false,
      totalStays: 3,
    ),
    Guest(
      id: 2,
      fullName: 'John Smith',
      phone: '0907654321',
      email: 'john@test.com',
      nationality: 'USA',
      isVip: true,
      totalStays: 10,
    ),
    Guest(
      id: 3,
      fullName: 'Tran Thi B',
      phone: '0912345678',
      email: 'b@test.com',
      nationality: 'Vietnam',
      isVip: false,
      totalStays: 1,
    ),
  ];

  setUp(() {
    mockRepository = MockGuestRepository();
  });

  group('GuestNotifier via ProviderContainer', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [guestRepositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('loadGuests', () {
      test('should load guests successfully', () async {
        when(
          mockRepository.getGuests(
            search: anyNamed('search'),
            isVip: anyNamed('isVip'),
            nationality: anyNamed('nationality'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => testGuests);

        final notifier = container.read(guestStateProvider.notifier);
        await notifier.loadGuests();

        final state = container.read(guestStateProvider);
        state.when(
          initial: () => fail('Expected loaded'),
          loading: () => fail('Expected loaded'),
          loaded: (guests) {
            expect(guests.length, 3);
            expect(guests[0].fullName, 'Nguyen Van A');
            expect(guests[1].isVip, true);
          },
          success: (_, __) => fail('Expected loaded'),
          error: (msg) => fail('Expected loaded, got error: $msg'),
        );
      });

      test('should filter by VIP status', () async {
        when(
          mockRepository.getGuests(
            search: anyNamed('search'),
            isVip: true,
            nationality: anyNamed('nationality'),
            ordering: anyNamed('ordering'),
          ),
        ).thenAnswer((_) async => [testGuests[1]]);

        final notifier = container.read(guestStateProvider.notifier);
        await notifier.loadGuests(isVip: true);

        final state = container.read(guestStateProvider);
        state.when(
          initial: () => fail('Expected loaded'),
          loading: () => fail('Expected loaded'),
          loaded: (guests) {
            expect(guests.length, 1);
            expect(guests.first.isVip, true);
          },
          success: (_, __) => fail('Expected loaded'),
          error: (msg) => fail('Expected loaded, got error: $msg'),
        );
      });

      test('should set error state on failure', () async {
        when(
          mockRepository.getGuests(
            search: anyNamed('search'),
            isVip: anyNamed('isVip'),
            nationality: anyNamed('nationality'),
            ordering: anyNamed('ordering'),
          ),
        ).thenThrow(Exception('Network error'));

        final notifier = container.read(guestStateProvider.notifier);
        await notifier.loadGuests();

        final state = container.read(guestStateProvider);
        state.when(
          initial: () => fail('Expected error'),
          loading: () => fail('Expected error'),
          loaded: (_) => fail('Expected error'),
          success: (_, __) => fail('Expected error'),
          error: (message) {
            expect(message, isNotEmpty);
          },
        );
      });
    });

    group('searchGuests', () {
      test('should search guests successfully', () async {
        when(
          mockRepository.searchGuests(query: 'Nguyen', searchBy: 'all'),
        ).thenAnswer((_) async => [testGuests[0]]);

        final notifier = container.read(guestStateProvider.notifier);
        await notifier.searchGuests('Nguyen');

        final state = container.read(guestStateProvider);
        state.when(
          initial: () => fail('Expected loaded'),
          loading: () => fail('Expected loaded'),
          loaded: (guests) {
            expect(guests.length, 1);
            expect(guests.first.fullName, 'Nguyen Van A');
          },
          success: (_, __) => fail('Expected loaded'),
          error: (msg) => fail('Expected loaded, got error: $msg'),
        );
      });

      test('should reject too-short search query', () async {
        final notifier = container.read(guestStateProvider.notifier);
        await notifier.searchGuests('a');

        final state = container.read(guestStateProvider);
        state.when(
          initial: () => fail('Expected error'),
          loading: () => fail('Expected error'),
          loaded: (_) => fail('Expected error'),
          success: (_, __) => fail('Expected error'),
          error: (message) {
            expect(message, isNotEmpty);
          },
        );

        // Should NOT call repository
        verifyNever(
          mockRepository.searchGuests(
            query: anyNamed('query'),
            searchBy: anyNamed('searchBy'),
          ),
        );
      });
    });

    group('createGuest', () {
      test('should create guest and return it', () async {
        final newGuest = Guest(
          id: 4,
          fullName: 'Le Van C',
          phone: '0923456789',
        );

        when(mockRepository.createGuest(any)).thenAnswer((_) async => newGuest);

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.createGuest(newGuest);

        expect(result, isNotNull);
        expect(result!.fullName, 'Le Van C');
        verify(mockRepository.createGuest(any)).called(1);

        // Should be in success state
        final state = container.read(guestStateProvider);
        state.when(
          initial: () => fail('Expected success'),
          loading: () => fail('Expected success'),
          loaded: (_) => fail('Expected success'),
          success: (guest, message) {
            expect(guest.id, 4);
            expect(message, isNotNull);
          },
          error: (msg) => fail('Expected success, got error: $msg'),
        );
      });

      test('should return null on duplicate phone', () async {
        when(
          mockRepository.createGuest(any),
        ).thenThrow(Exception('phone already exists'));

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.createGuest(
          Guest(id: 0, fullName: 'Test', phone: '0901234567'),
        );

        expect(result, isNull);
      });
    });

    group('updateGuest', () {
      test('should update guest and return it', () async {
        final updatedGuest = Guest(
          id: 1,
          fullName: 'Nguyen Van A Updated',
          phone: '0901234567',
          isVip: true,
        );

        when(
          mockRepository.updateGuest(any),
        ).thenAnswer((_) async => updatedGuest);

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.updateGuest(updatedGuest);

        expect(result, isNotNull);
        expect(result!.fullName, 'Nguyen Van A Updated');
        expect(result.isVip, true);
      });

      test('should return null on update failure', () async {
        when(
          mockRepository.updateGuest(any),
        ).thenThrow(Exception('Validation error'));

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.updateGuest(
          Guest(id: 1, fullName: '', phone: '0901234567'),
        );

        expect(result, isNull);
      });
    });

    group('deleteGuest', () {
      test('should delete guest and return true', () async {
        when(mockRepository.deleteGuest(1)).thenAnswer((_) async {});

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.deleteGuest(1);

        expect(result, true);
        verify(mockRepository.deleteGuest(1)).called(1);
      });

      test('should return false when guest cannot be deleted', () async {
        when(
          mockRepository.deleteGuest(1),
        ).thenThrow(Exception('cannot delete guest with bookings'));

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.deleteGuest(1);

        expect(result, false);
      });
    });

    group('toggleVipStatus', () {
      test('should toggle VIP and return updated guest', () async {
        final vipGuest = Guest(
          id: 1,
          fullName: 'Nguyen Van A',
          phone: '0901234567',
          isVip: true,
        );

        when(
          mockRepository.toggleVipStatus(1),
        ).thenAnswer((_) async => vipGuest);

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.toggleVipStatus(1);

        expect(result, isNotNull);
        expect(result!.isVip, true);
        verify(mockRepository.toggleVipStatus(1)).called(1);
      });

      test('should return null on toggle failure', () async {
        when(
          mockRepository.toggleVipStatus(1),
        ).thenThrow(Exception('Server error'));

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.toggleVipStatus(1);

        expect(result, isNull);
      });
    });

    group('findByPhone', () {
      test('should find guest by phone', () async {
        when(
          mockRepository.findByPhone('0901234567'),
        ).thenAnswer((_) async => testGuests[0]);

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.findByPhone('0901234567');

        expect(result, isNotNull);
        expect(result!.fullName, 'Nguyen Van A');
      });

      test('should return null if not found', () async {
        when(
          mockRepository.findByPhone('0999999999'),
        ).thenThrow(Exception('Not found'));

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.findByPhone('0999999999');

        expect(result, isNull);
      });
    });

    group('findByIdNumber', () {
      test('should find guest by ID number', () async {
        when(
          mockRepository.findByIdNumber('123456789'),
        ).thenAnswer((_) async => testGuests[0]);

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.findByIdNumber('123456789');

        expect(result, isNotNull);
        expect(result!.fullName, 'Nguyen Van A');
      });

      test('should return null if not found', () async {
        when(
          mockRepository.findByIdNumber('000000000'),
        ).thenThrow(Exception('Not found'));

        final notifier = container.read(guestStateProvider.notifier);
        final result = await notifier.findByIdNumber('000000000');

        expect(result, isNull);
      });
    });
  });

  group('Guest FutureProviders', () {
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockGuestRepository();
      container = ProviderContainer(
        overrides: [guestRepositoryProvider.overrideWithValue(mockRepository)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('guestsProvider fetches all guests', () async {
      when(
        mockRepository.getGuests(ordering: '-created_at'),
      ).thenAnswer((_) async => testGuests);

      final guests = await container.read(guestsProvider.future);
      expect(guests.length, 3);
    });

    test('vipGuestsProvider fetches VIP guests', () async {
      when(
        mockRepository.getVipGuests(),
      ).thenAnswer((_) async => [testGuests[1]]);

      final guests = await container.read(vipGuestsProvider.future);
      expect(guests.length, 1);
      expect(guests.first.isVip, true);
    });

    test('returningGuestsProvider fetches returning guests', () async {
      when(
        mockRepository.getReturningGuests(),
      ).thenAnswer((_) async => [testGuests[0], testGuests[1]]);

      final guests = await container.read(returningGuestsProvider.future);
      expect(guests.length, 2);
    });

    test('recentGuestsProvider fetches recent guests', () async {
      when(
        mockRepository.getRecentGuests(limit: 10),
      ).thenAnswer((_) async => testGuests);

      final guests = await container.read(recentGuestsProvider.future);
      expect(guests.length, 3);
    });

    test('guestByIdProvider fetches single guest', () async {
      when(
        mockRepository.getGuest(1),
      ).thenAnswer((_) async => testGuests.first);

      final guest = await container.read(guestByIdProvider(1).future);
      expect(guest.id, 1);
      expect(guest.fullName, 'Nguyen Van A');
    });

    test('guestSearchProvider searches guests', () async {
      final params = GuestSearchParams(query: 'Nguyen');

      when(
        mockRepository.searchGuests(query: 'Nguyen', searchBy: 'all'),
      ).thenAnswer((_) async => [testGuests[0]]);

      final guests = await container.read(guestSearchProvider(params).future);
      expect(guests.length, 1);
    });

    test('guestsByNationalityProvider filters by nationality', () async {
      when(
        mockRepository.getGuestsByNationality('Vietnam'),
      ).thenAnswer((_) async => [testGuests[0], testGuests[2]]);

      final guests = await container.read(
        guestsByNationalityProvider('Vietnam').future,
      );
      expect(guests.length, 2);
    });
  });
}
