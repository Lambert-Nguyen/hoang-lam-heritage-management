"""
Tests for Room Management endpoints.
"""

import pytest
from decimal import Decimal
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status

from hotel_api.models import Room, RoomType, HotelUser


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
def owner_user(create_user):
    """Create owner user."""
    return create_user("owner", "owner")


@pytest.fixture
def manager_user(create_user):
    """Create manager user."""
    return create_user("manager", "manager")


@pytest.fixture
def staff_user(create_user):
    """Create staff user."""
    return create_user("staff", "staff")


@pytest.fixture
def authenticated_client(api_client, staff_user):
    """Create authenticated API client."""
    api_client.force_authenticate(user=staff_user)
    return api_client


@pytest.fixture
def manager_client(api_client, manager_user):
    """Create authenticated manager API client."""
    api_client.force_authenticate(user=manager_user)
    return api_client


@pytest.fixture
def room_type_single(db):
    """Create single room type."""
    return RoomType.objects.create(
        name="Phòng Đơn",
        name_en="Single Room",
        base_rate=Decimal("300000"),
        max_guests=1,
        description="Single room",
        amenities=["WiFi", "AC"],
    )


@pytest.fixture
def room_type_double(db):
    """Create double room type."""
    return RoomType.objects.create(
        name="Phòng Đôi",
        name_en="Double Room",
        base_rate=Decimal("400000"),
        max_guests=2,
        description="Double room",
        amenities=["WiFi", "AC", "TV"],
    )


@pytest.fixture
def room_101(db, room_type_single):
    """Create room 101."""
    return Room.objects.create(
        number="101",
        name="Phòng 101",
        room_type=room_type_single,
        floor=1,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def room_102(db, room_type_double):
    """Create room 102."""
    return Room.objects.create(
        number="102",
        name="Phòng 102",
        room_type=room_type_double,
        floor=1,
        status=Room.Status.OCCUPIED,
    )


# ==================== RoomType Tests ====================


@pytest.mark.django_db
class TestRoomTypeViewSet:
    """Test RoomType CRUD operations."""

    def test_list_room_types(self, authenticated_client, room_type_single, room_type_double):
        """Test listing room types."""
        response = authenticated_client.get("/api/v1/room-types/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 2
        assert len(response.data["results"]) == 2
        assert response.data["results"][0]["name"] in ["Phòng Đơn", "Phòng Đôi"]

    def test_list_room_types_filter_active(self, authenticated_client, room_type_single):
        """Test filtering room types by active status."""
        room_type_single.is_active = False
        room_type_single.save()

        response = authenticated_client.get("/api/v1/room-types/?is_active=true")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 0
        assert len(response.data["results"]) == 0

    def test_retrieve_room_type(self, authenticated_client, room_type_single):
        """Test retrieving a single room type."""
        response = authenticated_client.get(f"/api/v1/room-types/{room_type_single.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "Phòng Đơn"
        assert response.data["base_rate"] == "300000"
        assert "room_count" in response.data
        assert "available_room_count" in response.data

    def test_create_room_type_as_manager(self, manager_client):
        """Test creating room type as manager."""
        data = {
            "name": "Phòng VIP",
            "name_en": "VIP Room",
            "base_rate": "800000",
            "max_guests": 2,
            "description": "VIP room",
            "amenities": ["WiFi", "AC", "Minibar"],
        }
        response = manager_client.post("/api/v1/room-types/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["name"] == "Phòng VIP"
        assert RoomType.objects.filter(name="Phòng VIP").exists()

    def test_create_room_type_as_staff_forbidden(self, authenticated_client):
        """Test creating room type as staff (should be forbidden)."""
        data = {
            "name": "Phòng VIP",
            "base_rate": "800000",
            "max_guests": 2,
        }
        response = authenticated_client.post("/api/v1/room-types/", data, format="json")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_create_room_type_invalid_rate(self, manager_client):
        """Test creating room type with invalid rate."""
        data = {
            "name": "Test Room",
            "base_rate": "-100",
            "max_guests": 2,
        }
        response = manager_client.post("/api/v1/room-types/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_update_room_type_as_manager(self, manager_client, room_type_single):
        """Test updating room type as manager."""
        data = {"base_rate": "350000"}
        response = manager_client.patch(
            f"/api/v1/room-types/{room_type_single.id}/", data, format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["base_rate"] == "350000"
        room_type_single.refresh_from_db()
        assert room_type_single.base_rate == Decimal("350000")

    def test_delete_room_type_without_rooms(self, manager_client, room_type_single):
        """Test deleting room type without rooms."""
        response = manager_client.delete(f"/api/v1/room-types/{room_type_single.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not RoomType.objects.filter(id=room_type_single.id).exists()

    def test_delete_room_type_with_rooms(self, manager_client, room_type_single, room_101):
        """Test deleting room type with existing rooms (should fail)."""
        response = manager_client.delete(f"/api/v1/room-types/{room_type_single.id}/")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Không thể xóa" in response.data["detail"]
        assert RoomType.objects.filter(id=room_type_single.id).exists()


# ==================== Room Tests ====================


@pytest.mark.django_db
class TestRoomViewSet:
    """Test Room CRUD operations."""

    def test_list_rooms(self, authenticated_client, room_101, room_102):
        """Test listing rooms."""
        response = authenticated_client.get("/api/v1/rooms/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 2
        assert len(response.data["results"]) == 2

    def test_list_rooms_filter_by_status(self, authenticated_client, room_101, room_102):
        """Test filtering rooms by status."""
        response = authenticated_client.get("/api/v1/rooms/?status=available")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["number"] == "101"

    def test_list_rooms_filter_by_room_type(
        self, authenticated_client, room_101, room_102, room_type_single
    ):
        """Test filtering rooms by room type."""
        response = authenticated_client.get(f"/api/v1/rooms/?room_type={room_type_single.id}")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["room_type"] == room_type_single.id

    def test_list_rooms_filter_by_floor(self, authenticated_client, room_101, room_102):
        """Test filtering rooms by floor."""
        response = authenticated_client.get("/api/v1/rooms/?floor=1")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 2
        assert len(response.data["results"]) == 2

    def test_list_rooms_search(self, authenticated_client, room_101, room_102):
        """Test searching rooms by number/name."""
        response = authenticated_client.get("/api/v1/rooms/?search=101")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["count"] == 1
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["number"] == "101"

    def test_retrieve_room(self, authenticated_client, room_101):
        """Test retrieving a single room."""
        response = authenticated_client.get(f"/api/v1/rooms/{room_101.id}/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["number"] == "101"
        assert response.data["status"] == Room.Status.AVAILABLE
        assert "room_type_details" in response.data

    def test_create_room_as_manager(self, manager_client, room_type_single):
        """Test creating room as manager."""
        data = {
            "number": "201",
            "name": "Phòng 201",
            "room_type": room_type_single.id,
            "floor": 2,
            "status": "available",
        }
        response = manager_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["number"] == "201"
        assert Room.objects.filter(number="201").exists()

    def test_create_room_duplicate_number(self, manager_client, room_type_single, room_101):
        """Test creating room with duplicate number."""
        data = {
            "number": "101",
            "room_type": room_type_single.id,
            "floor": 1,
        }
        response = manager_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "đã tồn tại" in str(response.data)

    def test_create_room_as_staff_forbidden(self, authenticated_client, room_type_single):
        """Test creating room as staff (should be forbidden)."""
        data = {
            "number": "201",
            "room_type": room_type_single.id,
            "floor": 2,
        }
        response = authenticated_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_update_room_as_manager(self, manager_client, room_101):
        """Test updating room as manager."""
        data = {"name": "Phòng 101 - Updated"}
        response = manager_client.patch(f"/api/v1/rooms/{room_101.id}/", data, format="json")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "Phòng 101 - Updated"

    def test_delete_room_as_manager(self, manager_client, room_101):
        """Test deleting room as manager."""
        response = manager_client.delete(f"/api/v1/rooms/{room_101.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not Room.objects.filter(id=room_101.id).exists()

    def test_update_room_status(self, authenticated_client, room_101):
        """Test updating room status."""
        data = {"status": "cleaning", "notes": "Đang dọn phòng"}
        response = authenticated_client.post(
            f"/api/v1/rooms/{room_101.id}/update-status/", data, format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "cleaning"
        room_101.refresh_from_db()
        assert room_101.status == Room.Status.CLEANING
        assert room_101.notes == "Đang dọn phòng"

    def test_update_room_status_same_status(self, authenticated_client, room_101):
        """Test updating room to same status (should fail)."""
        data = {"status": "available"}
        response = authenticated_client.post(
            f"/api/v1/rooms/{room_101.id}/update-status/", data, format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "đã ở trạng thái này" in str(response.data)

    def test_check_availability(self, authenticated_client, room_101, room_102):
        """Test checking room availability."""
        data = {
            "check_in": "2026-02-01",
            "check_out": "2026-02-03",
        }
        response = authenticated_client.post(
            "/api/v1/rooms/check-availability/", data, format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert "available_rooms" in response.data
        assert len(response.data["available_rooms"]) >= 1  # At least room_101 is available

    def test_check_availability_with_room_type_filter(
        self, authenticated_client, room_101, room_102, room_type_single
    ):
        """Test checking availability with room type filter."""
        data = {
            "check_in": "2026-02-01",
            "check_out": "2026-02-03",
            "room_type": room_type_single.id,
        }
        response = authenticated_client.post(
            "/api/v1/rooms/check-availability/", data, format="json"
        )
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["available_rooms"]) >= 1
        assert response.data["room_type"] == room_type_single.id

    def test_check_availability_invalid_dates(self, authenticated_client):
        """Test checking availability with invalid date range."""
        data = {
            "check_in": "2026-02-03",
            "check_out": "2026-02-01",  # Before check_in
        }
        response = authenticated_client.post(
            "/api/v1/rooms/check-availability/", data, format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST


# ==================== Permission Tests ====================


@pytest.mark.django_db
class TestRoomPermissions:
    """Test room management permissions."""

    def test_unauthenticated_access(self, api_client):
        """Test that unauthenticated users cannot access rooms."""
        response = api_client.get("/api/v1/rooms/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_staff_can_read_rooms(self, authenticated_client, room_101):
        """Test that staff can read rooms."""
        response = authenticated_client.get(f"/api/v1/rooms/{room_101.id}/")
        assert response.status_code == status.HTTP_200_OK

    def test_staff_cannot_create_rooms(self, authenticated_client, room_type_single):
        """Test that staff cannot create rooms."""
        data = {"number": "201", "room_type": room_type_single.id, "floor": 2}
        response = authenticated_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_manager_can_create_rooms(self, manager_client, room_type_single):
        """Test that manager can create rooms."""
        data = {"number": "201", "room_type": room_type_single.id, "floor": 2}
        response = manager_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED

    def test_staff_can_update_status(self, authenticated_client, room_101):
        """Test that staff can update room status."""
        data = {"status": "cleaning"}
        response = authenticated_client.post(
            f"/api/v1/rooms/{room_101.id}/update-status/", data, format="json"
        )
        assert response.status_code == status.HTTP_200_OK


# ==================== Error Case Tests ====================


@pytest.mark.django_db
class TestRoomErrorCases:
    """Error case tests for room management."""

    def test_create_room_missing_room_type(self, manager_client):
        """Test creating room without room_type."""
        data = {"number": "301", "floor": 3}
        response = manager_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_room_nonexistent_room_type(self, manager_client):
        """Test creating room with non-existent room type ID."""
        data = {"number": "301", "room_type": 99999, "floor": 3}
        response = manager_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_room_missing_number(self, manager_client, room_type_single):
        """Test creating room without number."""
        data = {"room_type": room_type_single.id, "floor": 2}
        response = manager_client.post("/api/v1/rooms/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_retrieve_nonexistent_room(self, authenticated_client):
        """Test retrieving a room that does not exist."""
        response = authenticated_client.get("/api/v1/rooms/99999/")
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_nonexistent_room(self, manager_client):
        """Test updating a room that does not exist."""
        data = {"name": "Updated"}
        response = manager_client.patch("/api/v1/rooms/99999/", data, format="json")
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_nonexistent_room(self, manager_client):
        """Test deleting a room that does not exist."""
        response = manager_client.delete("/api/v1/rooms/99999/")
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_status_nonexistent_room(self, authenticated_client):
        """Test updating status of non-existent room."""
        data = {"status": "cleaning"}
        response = authenticated_client.post(
            "/api/v1/rooms/99999/update-status/", data, format="json"
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_update_status_invalid_value(self, authenticated_client, room_101):
        """Test updating room status with invalid status value."""
        data = {"status": "nonexistent_status"}
        response = authenticated_client.post(
            f"/api/v1/rooms/{room_101.id}/update-status/", data, format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_update_status_missing_status(self, authenticated_client, room_101):
        """Test updating room status without providing status field."""
        response = authenticated_client.post(
            f"/api/v1/rooms/{room_101.id}/update-status/", {}, format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_check_availability_missing_dates(self, authenticated_client):
        """Test checking availability without required dates."""
        response = authenticated_client.post("/api/v1/rooms/check-availability/", {}, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_check_availability_invalid_date_format(self, authenticated_client):
        """Test checking availability with invalid date format."""
        data = {"check_in": "not-a-date", "check_out": "also-not-a-date"}
        response = authenticated_client.post(
            "/api/v1/rooms/check-availability/", data, format="json"
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestRoomTypeErrorCases:
    """Error case tests for room type management."""

    def test_create_room_type_missing_name(self, manager_client):
        """Test creating room type without name."""
        data = {"base_rate": "500000", "max_guests": 2}
        response = manager_client.post("/api/v1/room-types/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_room_type_zero_rate(self, manager_client):
        """Test creating room type with zero base rate."""
        data = {"name": "Test", "base_rate": "0", "max_guests": 2}
        response = manager_client.post("/api/v1/room-types/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_room_type_zero_guests(self, manager_client):
        """Test creating room type with zero max guests."""
        data = {"name": "Test", "base_rate": "500000", "max_guests": 0}
        response = manager_client.post("/api/v1/room-types/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_room_type_negative_guests(self, manager_client):
        """Test creating room type with negative max guests."""
        data = {"name": "Test", "base_rate": "500000", "max_guests": -1}
        response = manager_client.post("/api/v1/room-types/", data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_retrieve_nonexistent_room_type(self, authenticated_client):
        """Test retrieving a room type that does not exist."""
        response = authenticated_client.get("/api/v1/room-types/99999/")
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_delete_nonexistent_room_type(self, manager_client):
        """Test deleting a room type that does not exist."""
        response = manager_client.delete("/api/v1/room-types/99999/")
        assert response.status_code == status.HTTP_404_NOT_FOUND
