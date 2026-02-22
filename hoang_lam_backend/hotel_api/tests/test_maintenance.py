"""Tests for maintenance request endpoints."""

from decimal import Decimal

from django.contrib.auth.models import User

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import HotelUser, MaintenanceRequest, Room, RoomType


@pytest.fixture
def api_client():
    """Create API client."""
    return APIClient()


@pytest.fixture
def create_user(db):
    """Factory to create users with roles."""

    def _create_user(username, role="staff"):
        user = User.objects.create_user(username=username, password="testpass123")
        HotelUser.objects.create(user=user, role=role, phone=f"+84{username[-6:]}")
        return user

    return _create_user


@pytest.fixture
def manager_user(create_user):
    """Create manager user."""
    return create_user("manager", "manager")


@pytest.fixture
def staff_user(create_user):
    """Create staff user."""
    return create_user("staff", "staff")


@pytest.fixture
def maintenance_staff(create_user):
    """Create maintenance staff user."""
    return create_user("maintenance", "staff")


@pytest.fixture
def room_type(db):
    """Create room type."""
    return RoomType.objects.create(
        name="Standard",
        name_en="Standard Room",
        base_rate=Decimal("300000"),
        max_guests=2,
        description="Standard room",
    )


@pytest.fixture
def room(db, room_type):
    """Create a room."""
    return Room.objects.create(
        number="201",
        name="Phòng 201",
        room_type=room_type,
        floor=2,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def room2(db, room_type):
    """Create another room."""
    return Room.objects.create(
        number="202",
        name="Phòng 202",
        room_type=room_type,
        floor=2,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def maintenance_request(db, room, staff_user):
    """Create a maintenance request."""
    return MaintenanceRequest.objects.create(
        room=room,
        title="Broken AC",
        description="Air conditioner not cooling",
        category="ac_heating",
        priority="high",
        reported_by=staff_user,
    )


@pytest.fixture
def assigned_request(db, room, staff_user, maintenance_staff):
    """Create an assigned maintenance request."""
    return MaintenanceRequest.objects.create(
        room=room,
        title="Leaking faucet",
        description="Bathroom faucet is dripping",
        category="plumbing",
        priority="medium",
        status="assigned",
        reported_by=staff_user,
        assigned_to=maintenance_staff,
        estimated_cost=Decimal("50.00"),
    )


@pytest.fixture
def urgent_request(db, staff_user):
    """Create an urgent maintenance request without room."""
    return MaintenanceRequest.objects.create(
        title="Power outage",
        description="No electricity in hallway",
        location_description="Second floor hallway",
        category="electrical",
        priority="urgent",
        reported_by=staff_user,
    )


@pytest.mark.django_db
class TestMaintenanceRequestViewSet:
    """Tests for MaintenanceRequestViewSet."""

    def test_list_requests_as_staff(self, api_client, staff_user, maintenance_request):
        """Staff can list maintenance requests."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/maintenance-requests/")
        assert response.status_code == status.HTTP_200_OK
        assert "results" in response.data
        assert len(response.data["results"]) == 1

    def test_list_requests_unauthenticated(self, api_client, maintenance_request):
        """Unauthenticated users cannot list requests."""
        response = api_client.get("/api/v1/maintenance-requests/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_filter_requests_by_room(self, api_client, staff_user, maintenance_request, room):
        """Can filter requests by room."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/maintenance-requests/?room={room.id}")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

    def test_filter_requests_by_status(
        self, api_client, staff_user, maintenance_request, assigned_request
    ):
        """Can filter requests by status."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/maintenance-requests/?status=pending")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["status"] == "pending"

    def test_filter_requests_by_priority(
        self, api_client, staff_user, maintenance_request, urgent_request
    ):
        """Can filter requests by priority."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/maintenance-requests/?priority=urgent")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["priority"] == "urgent"

    def test_filter_requests_by_category(self, api_client, staff_user, maintenance_request):
        """Can filter requests by category."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/maintenance-requests/?category=ac_heating")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

    def test_filter_requests_by_assigned_to(
        self, api_client, staff_user, assigned_request, maintenance_staff
    ):
        """Can filter requests by assigned user."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(
            f"/api/v1/maintenance-requests/?assigned_to={maintenance_staff.id}"
        )
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1

    def test_retrieve_request(self, api_client, staff_user, maintenance_request):
        """Can retrieve a specific request."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/maintenance-requests/{maintenance_request.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == maintenance_request.id
        assert response.data["title"] == "Broken AC"

    def test_create_request_with_room(self, api_client, staff_user, room):
        """Can create request with room."""
        api_client.force_authenticate(user=staff_user)
        initial_count = MaintenanceRequest.objects.count()
        data = {
            "room": room.id,
            "title": "Broken window",
            "description": "Window latch is broken",
            "category": "structural",
            "priority": "medium",
        }
        response = api_client.post("/api/v1/maintenance-requests/", data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["title"] == "Broken window"
        # Verify the request was created
        assert MaintenanceRequest.objects.count() == initial_count + 1
        # Verify reported_by was set correctly
        req = MaintenanceRequest.objects.latest("id")
        assert req.reported_by == staff_user

    def test_create_request_with_location(self, api_client, staff_user):
        """Can create request with location description instead of room."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "title": "Broken light",
            "description": "Light not working",
            "location_description": "Lobby entrance",
            "category": "electrical",
            "priority": "low",
        }
        response = api_client.post("/api/v1/maintenance-requests/", data)
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["location_description"] == "Lobby entrance"

    def test_create_request_requires_location(self, api_client, staff_user):
        """Create request fails without room or location."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "title": "Something broken",
            "description": "Unknown location",
            "category": "other",
            "priority": "low",
        }
        response = api_client.post("/api/v1/maintenance-requests/", data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_update_request(self, api_client, manager_user, maintenance_request):
        """Can update a request."""
        api_client.force_authenticate(user=manager_user)
        data = {
            "priority": "urgent",
            "notes": "Guest complaint",
        }
        response = api_client.patch(f"/api/v1/maintenance-requests/{maintenance_request.id}/", data)
        assert response.status_code == status.HTTP_200_OK
        assert response.data["priority"] == "urgent"

    def test_delete_request(self, api_client, manager_user, maintenance_request):
        """Can delete a request."""
        api_client.force_authenticate(user=manager_user)
        response = api_client.delete(f"/api/v1/maintenance-requests/{maintenance_request.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not MaintenanceRequest.objects.filter(id=maintenance_request.id).exists()

    def test_assign_request(self, api_client, manager_user, maintenance_request, maintenance_staff):
        """Can assign a request to staff."""
        api_client.force_authenticate(user=manager_user)
        data = {
            "assigned_to": maintenance_staff.id,
            "estimated_cost": 100.00,
        }
        response = api_client.post(
            f"/api/v1/maintenance-requests/{maintenance_request.id}/assign/", data
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["assigned_to"] == maintenance_staff.id
        assert response.data["status"] == "assigned"
        assert Decimal(response.data["estimated_cost"]) == Decimal("100.00")

    def test_assign_request_without_user_id(self, api_client, manager_user, maintenance_request):
        """Assign without user ID returns error."""
        api_client.force_authenticate(user=manager_user)
        response = api_client.post(
            f"/api/v1/maintenance-requests/{maintenance_request.id}/assign/", {}
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_assign_request_user_not_found(self, api_client, manager_user, maintenance_request):
        """Assign to non-existent user returns error."""
        api_client.force_authenticate(user=manager_user)
        data = {"assigned_to": 99999}
        response = api_client.post(
            f"/api/v1/maintenance-requests/{maintenance_request.id}/assign/", data
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_complete_request(self, api_client, maintenance_staff, assigned_request):
        """Can complete a request."""
        api_client.force_authenticate(user=maintenance_staff)
        data = {
            "actual_cost": 45.00,
            "resolution_notes": "Replaced washer",
        }
        response = api_client.post(
            f"/api/v1/maintenance-requests/{assigned_request.id}/complete/", data
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "completed"
        assert response.data["completed_by"] == maintenance_staff.id
        assert Decimal(response.data["actual_cost"]) == Decimal("45.00")

    def test_complete_pending_request_fails(self, api_client, staff_user, maintenance_request):
        """Cannot complete a pending request."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            f"/api/v1/maintenance-requests/{maintenance_request.id}/complete/", {}
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_hold_request(self, api_client, manager_user, assigned_request):
        """Can put a request on hold."""
        api_client.force_authenticate(user=manager_user)
        data = {"reason": "Waiting for parts"}
        response = api_client.post(
            f"/api/v1/maintenance-requests/{assigned_request.id}/hold/", data
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "on_hold"

    def test_hold_completed_request_fails(self, api_client, manager_user, assigned_request):
        """Cannot hold a completed request."""
        api_client.force_authenticate(user=manager_user)
        assigned_request.status = "completed"
        assigned_request.save()
        response = api_client.post(f"/api/v1/maintenance-requests/{assigned_request.id}/hold/", {})
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_resume_request(self, api_client, manager_user, assigned_request):
        """Can resume a request from hold."""
        api_client.force_authenticate(user=manager_user)
        assigned_request.status = "on_hold"
        assigned_request.save()
        response = api_client.post(
            f"/api/v1/maintenance-requests/{assigned_request.id}/resume/", {}
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] in ["assigned", "in_progress"]

    def test_resume_non_held_request_fails(self, api_client, manager_user, maintenance_request):
        """Cannot resume a request that is not on hold."""
        api_client.force_authenticate(user=manager_user)
        response = api_client.post(
            f"/api/v1/maintenance-requests/{maintenance_request.id}/resume/", {}
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_cancel_request(self, api_client, manager_user, maintenance_request):
        """Can cancel a request."""
        api_client.force_authenticate(user=manager_user)
        data = {"reason": "No longer needed"}
        response = api_client.post(
            f"/api/v1/maintenance-requests/{maintenance_request.id}/cancel/", data
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "cancelled"

    def test_cancel_completed_request_fails(self, api_client, manager_user, assigned_request):
        """Cannot cancel a completed request."""
        api_client.force_authenticate(user=manager_user)
        assigned_request.status = "completed"
        assigned_request.save()
        response = api_client.post(
            f"/api/v1/maintenance-requests/{assigned_request.id}/cancel/", {}
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_urgent_requests(self, api_client, staff_user, maintenance_request, urgent_request):
        """Can get urgent and high priority requests."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/maintenance-requests/urgent/")
        assert response.status_code == status.HTTP_200_OK
        # Should include high and urgent priority requests
        assert len(response.data) == 2

    def test_my_requests(self, api_client, maintenance_staff, assigned_request):
        """Can get requests assigned to current user."""
        api_client.force_authenticate(user=maintenance_staff)
        response = api_client.get("/api/v1/maintenance-requests/my_requests/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) == 1
        # Verify it's the correct request
        assert response.data[0]["title"] == assigned_request.title


@pytest.mark.django_db
class TestMaintenanceRequestModel:
    """Tests for MaintenanceRequest model."""

    def test_create_request_with_room(self, room, staff_user):
        """Can create a maintenance request with room."""
        request = MaintenanceRequest.objects.create(
            room=room,
            title="Test issue",
            description="Test description",
            category="other",
            priority="low",
            reported_by=staff_user,
        )
        assert request.status == "pending"
        assert request.room == room

    def test_create_request_with_location(self, staff_user):
        """Can create a maintenance request with location."""
        request = MaintenanceRequest.objects.create(
            title="Test issue",
            description="Test description",
            location_description="Test location",
            category="other",
            priority="low",
            reported_by=staff_user,
        )
        assert request.room is None
        assert request.location_description == "Test location"

    def test_request_string_representation(self, maintenance_request):
        """Request has proper string representation."""
        expected = f"{maintenance_request.room.number} - Broken AC"
        assert str(maintenance_request) == expected

    def test_request_without_room_string(self, urgent_request):
        """Request without room shows location in string."""
        assert "Power outage" in str(urgent_request)

    def test_assign_method(self, maintenance_request, maintenance_staff):
        """Assign method updates fields correctly."""
        maintenance_request.assign(maintenance_staff)
        assert maintenance_request.assigned_to == maintenance_staff
        assert maintenance_request.status == "assigned"
        assert maintenance_request.assigned_at is not None

    def test_complete_method(self, assigned_request, maintenance_staff):
        """Complete method updates fields correctly."""
        assigned_request.complete(maintenance_staff, "Fixed the leak")
        assert assigned_request.status == "completed"
        assert assigned_request.completed_by == maintenance_staff
        assert assigned_request.completed_at is not None
        assert assigned_request.resolution_notes == "Fixed the leak"

    def test_priority_choices(self, room, staff_user):
        """All priority choices are valid."""
        for priority in ["low", "medium", "high", "urgent"]:
            request = MaintenanceRequest.objects.create(
                room=room,
                title=f"{priority} priority test",
                description="Test",
                category="other",
                priority=priority,
                reported_by=staff_user,
            )
            assert request.priority == priority

    def test_category_choices(self, room, staff_user):
        """All category choices are valid."""
        categories = [
            "electrical",
            "plumbing",
            "ac_heating",
            "furniture",
            "appliance",
            "structural",
            "safety",
            "other",
        ]
        for category in categories:
            request = MaintenanceRequest.objects.create(
                room=room,
                title=f"{category} test",
                description="Test",
                category=category,
                priority="low",
                reported_by=staff_user,
            )
            assert request.category == category
