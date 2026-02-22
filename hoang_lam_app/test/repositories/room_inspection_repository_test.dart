import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoang_lam_app/models/room_inspection.dart';
import 'package:hoang_lam_app/repositories/room_inspection_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:hoang_lam_app/core/network/api_client.dart';
import 'package:hoang_lam_app/core/config/app_constants.dart';

@GenerateMocks([ApiClient])
import 'room_inspection_repository_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;
  late RoomInspectionRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = RoomInspectionRepository(apiClient: mockApiClient);
  });

  group('RoomInspectionRepository', () {
    group('getInspections', () {
      test('returns list of inspections', () async {
        final mockResponse = [
          {
            'id': 1,
            'room': 101,
            'room_number': '101',
            'inspection_type': 'checkout',
            'scheduled_date': '2024-01-15',
            'status': 'pending',
            'checklist_items': [],
            'images': [],
            'notes': '',
            'action_required': '',
          },
        ];

        when(
          mockApiClient.get<dynamic>(
            AppConstants.roomInspectionsEndpoint,
            queryParameters: anyNamed('queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.getInspections();

        expect(result, isA<List<RoomInspection>>());
        expect(result.length, 1);
        expect(result.first.id, 1);
        expect(result.first.roomNumber, '101');
      });

      test('returns empty list when no inspections', () async {
        when(
          mockApiClient.get<dynamic>(
            AppConstants.roomInspectionsEndpoint,
            queryParameters: anyNamed('queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: [],
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.getInspections();

        expect(result, isEmpty);
      });
    });

    group('getInspection', () {
      test('returns single inspection', () async {
        final mockResponse = {
          'id': 1,
          'room': 101,
          'room_number': '101',
          'inspection_type': 'checkout',
          'scheduled_date': '2024-01-15',
          'status': 'pending',
          'checklist_items': [],
          'images': [],
          'notes': '',
          'action_required': '',
        };

        when(
          mockApiClient.get<Map<String, dynamic>>(
            '${AppConstants.roomInspectionsEndpoint}1/',
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.getInspection(1);

        expect(result, isA<RoomInspection>());
        expect(result.id, 1);
      });
    });

    group('createInspection', () {
      test('creates and returns new inspection', () async {
        final createData = RoomInspectionCreate(
          room: 101,
          inspectionType: InspectionType.checkout,
          scheduledDate: '2024-01-15',
        );

        final mockResponse = {
          'id': 1,
          'room': 101,
          'room_number': '101',
          'inspection_type': 'checkout',
          'scheduled_date': '2024-01-15',
          'status': 'pending',
          'checklist_items': [],
          'images': [],
          'notes': '',
          'action_required': '',
        };

        when(
          mockApiClient.post<Map<String, dynamic>>(
            AppConstants.roomInspectionsEndpoint,
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 201,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.createInspection(createData);

        expect(result, isA<RoomInspection>());
        expect(result.id, 1);
        expect(result.room, 101);
      });
    });

    group('startInspection', () {
      test('starts inspection and returns updated inspection', () async {
        final mockResponse = {
          'id': 1,
          'room': 101,
          'room_number': '101',
          'inspection_type': 'checkout',
          'scheduled_date': '2024-01-15',
          'status': 'in_progress',
          'checklist_items': [],
          'images': [],
          'notes': '',
          'action_required': '',
        };

        when(
          mockApiClient.post<Map<String, dynamic>>(
            '${AppConstants.roomInspectionsEndpoint}1/start/',
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.startInspection(1);

        expect(result.status, InspectionStatus.inProgress);
      });
    });

    group('completeInspection', () {
      test('completes inspection and returns updated inspection', () async {
        final completeData = CompleteInspection(
          checklistItems: [
            ChecklistItem(category: 'bedroom', item: 'Bed', passed: true),
          ],
        );

        final mockResponse = {
          'id': 1,
          'room': 101,
          'room_number': '101',
          'inspection_type': 'checkout',
          'scheduled_date': '2024-01-15',
          'status': 'completed',
          'checklist_items': [
            {
              'category': 'bedroom',
              'item': 'Bed',
              'critical': false,
              'passed': true,
              'notes': '',
            },
          ],
          'images': [],
          'notes': '',
          'action_required': '',
          'score': 100.0,
        };

        when(
          mockApiClient.post<Map<String, dynamic>>(
            '${AppConstants.roomInspectionsEndpoint}1/complete/',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.completeInspection(1, completeData);

        expect(result.status, InspectionStatus.completed);
        expect(result.score, 100.0);
      });
    });

    group('getStatistics', () {
      test('returns inspection statistics', () async {
        final mockResponse = {
          'total_inspections': 100,
          'completed_inspections': 80,
          'pending_inspections': 15,
          'requires_action': 5,
          'average_score': 92.5,
          'total_issues': 20,
          'critical_issues': 3,
          'inspections_by_type': {'checkout': 50},
          'inspections_by_room': [],
        };

        when(
          mockApiClient.get<Map<String, dynamic>>(
            '${AppConstants.roomInspectionsEndpoint}statistics/',
            queryParameters: anyNamed('queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.getStatistics();

        expect(result, isA<InspectionStatistics>());
        expect(result.totalInspections, 100);
        expect(result.averageScore, 92.5);
      });
    });

    group('getTemplates', () {
      test('returns list of templates', () async {
        final mockResponse = [
          {
            'id': 1,
            'name': 'Standard Checkout',
            'inspection_type': 'checkout',
            'is_default': true,
            'is_active': true,
            'items': [],
          },
        ];

        when(
          mockApiClient.get<dynamic>(
            AppConstants.inspectionTemplatesEndpoint,
            queryParameters: anyNamed('queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.getTemplates();

        expect(result, isA<List<InspectionTemplate>>());
        expect(result.length, 1);
        expect(result.first.name, 'Standard Checkout');
      });
    });

    group('createTemplate', () {
      test('creates and returns new template', () async {
        final createData = InspectionTemplateCreate(
          name: 'New Template',
          inspectionType: InspectionType.routine,
          items: [TemplateItem(category: 'general', item: 'Check door')],
        );

        final mockResponse = {
          'id': 1,
          'name': 'New Template',
          'inspection_type': 'routine',
          'is_default': false,
          'is_active': true,
          'items': [
            {'category': 'general', 'item': 'Check door', 'critical': false},
          ],
          'item_count': 1,
        };

        when(
          mockApiClient.post<Map<String, dynamic>>(
            AppConstants.inspectionTemplatesEndpoint,
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 201,
            requestOptions: RequestOptions(),
          ),
        );

        final result = await repository.createTemplate(createData);

        expect(result, isA<InspectionTemplate>());
        expect(result.name, 'New Template');
        expect(result.items.length, 1);
      });
    });
  });
}
