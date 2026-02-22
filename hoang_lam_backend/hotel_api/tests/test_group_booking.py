"""
Tests for Group Booking feature.

Tests cover:
- GroupBooking model CRUD
- Status transitions (confirm, check-in, check-out, cancel)
- Room assignment
- API endpoints
- Balance and nights calculations
"""

import pytest
from datetime import date, timedelta
from decimal import Decimal

from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status

from hotel_api.models import GroupBooking, HotelUser, Room, RoomType


# ===== Fixtures =====


@pytest.fixture
def owner_user(db):
    user = User.objects.create_user(
        username="gbowner",
        password="testpass123",
        first_name="Group",
        last_name="Owner",
    )
    HotelUser.objects.create(user=user, role=HotelUser.Role.OWNER)
    return user


@pytest.fixture
def room_type(db):
    return RoomType.objects.create(
        name="Group Room Type",
        base_rate=Decimal("400000"),
        max_guests=2,
        description="Group test room",
    )


@pytest.fixture
def rooms(db, room_type):
    return [Room.objects.create(number=f"G-{i}", floor=1, room_type=room_type) for i in range(1, 4)]


@pytest.fixture
def group_booking(db, owner_user):
    return GroupBooking.objects.create(
        name="Tour ABC",
        contact_name="Trần Văn B",
        contact_phone="0922222222",
        contact_email="tour@abc.com",
        company="ABC Travel",
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=3),
        room_count=3,
        guest_count=6,
        total_amount=Decimal("3600000"),
        deposit_amount=Decimal("1000000"),
        special_rate=Decimal("400000"),
        status=GroupBooking.Status.TENTATIVE,
        created_by=owner_user,
    )


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def authenticated_client(api_client, owner_user):
    api_client.force_authenticate(user=owner_user)
    return api_client


# ===== Model Tests =====


@pytest.mark.django_db
class TestGroupBookingModel:
    def test_create_group_booking(self, group_booking):
        assert group_booking.pk is not None
        assert group_booking.name == "Tour ABC"
        assert group_booking.status == GroupBooking.Status.TENTATIVE

    def test_str(self, group_booking):
        assert "Tour ABC" in str(group_booking)
        assert "3 phòng" in str(group_booking)

    def test_nights_property(self, group_booking):
        assert group_booking.nights == 3

    def test_balance_due_property(self, group_booking):
        # total=3600000, deposit=1000000
        assert group_booking.balance_due == Decimal("2600000")

    def test_room_assignment(self, group_booking, rooms):
        group_booking.rooms.set(rooms)
        assert group_booking.rooms.count() == 3

    def test_default_status_tentative(self, db, owner_user):
        gb = GroupBooking.objects.create(
            name="Test Default",
            contact_name="Test",
            contact_phone="0900000000",
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=1),
            room_count=1,
            guest_count=1,
            total_amount=Decimal("400000"),
            created_by=owner_user,
        )
        assert gb.status == GroupBooking.Status.TENTATIVE


# ===== API Tests - CRUD =====


@pytest.mark.django_db
class TestGroupBookingAPI:
    def test_list(self, authenticated_client, group_booking):
        response = authenticated_client.get("/api/v1/group-bookings/")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        results = data.get("results", data) if isinstance(data, dict) else data
        assert len(results) >= 1

    def test_create(self, authenticated_client):
        response = authenticated_client.post(
            "/api/v1/group-bookings/",
            {
                "name": "Wedding Party",
                "contact_name": "Lê Văn C",
                "contact_phone": "0933333333",
                "check_in_date": (date.today() + timedelta(days=7)).isoformat(),
                "check_out_date": (date.today() + timedelta(days=9)).isoformat(),
                "room_count": 5,
                "guest_count": 10,
                "total_amount": 5000000,
                "special_rate": 500000,
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["name"] == "Wedding Party"
        # Verify created in DB with tentative status
        gb = GroupBooking.objects.get(name="Wedding Party")
        assert gb.status == GroupBooking.Status.TENTATIVE

    def test_retrieve(self, authenticated_client, group_booking):
        response = authenticated_client.get(f"/api/v1/group-bookings/{group_booking.id}/")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["name"] == "Tour ABC"
        assert data["contact_name"] == "Trần Văn B"

    def test_update(self, authenticated_client, group_booking):
        response = authenticated_client.patch(
            f"/api/v1/group-bookings/{group_booking.id}/",
            {"name": "Tour XYZ Updated", "guest_count": 8},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["name"] == "Tour XYZ Updated"
        assert data["guest_count"] == 8

    def test_delete(self, authenticated_client, group_booking):
        response = authenticated_client.delete(f"/api/v1/group-bookings/{group_booking.id}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not GroupBooking.objects.filter(id=group_booking.id).exists()


# ===== API Tests - Status Transitions =====


@pytest.mark.django_db
class TestGroupBookingStatusTransitions:
    def test_confirm(self, authenticated_client, group_booking):
        response = authenticated_client.post(f"/api/v1/group-bookings/{group_booking.id}/confirm/")
        assert response.status_code == status.HTTP_200_OK
        group_booking.refresh_from_db()
        assert group_booking.status == GroupBooking.Status.CONFIRMED

    def test_check_in(self, authenticated_client, group_booking):
        # Must confirm first
        group_booking.status = GroupBooking.Status.CONFIRMED
        group_booking.save()

        response = authenticated_client.post(f"/api/v1/group-bookings/{group_booking.id}/check-in/")
        assert response.status_code == status.HTTP_200_OK
        group_booking.refresh_from_db()
        assert group_booking.status == GroupBooking.Status.CHECKED_IN
        assert group_booking.actual_check_in is not None

    def test_check_out(self, authenticated_client, group_booking):
        group_booking.status = GroupBooking.Status.CHECKED_IN
        group_booking.save()

        response = authenticated_client.post(
            f"/api/v1/group-bookings/{group_booking.id}/check-out/"
        )
        assert response.status_code == status.HTTP_200_OK
        group_booking.refresh_from_db()
        assert group_booking.status == GroupBooking.Status.CHECKED_OUT
        assert group_booking.actual_check_out is not None

    def test_cancel(self, authenticated_client, group_booking):
        response = authenticated_client.post(f"/api/v1/group-bookings/{group_booking.id}/cancel/")
        assert response.status_code == status.HTTP_200_OK
        group_booking.refresh_from_db()
        assert group_booking.status == GroupBooking.Status.CANCELLED

    def test_cannot_confirm_non_tentative(self, authenticated_client, group_booking):
        group_booking.status = GroupBooking.Status.CONFIRMED
        group_booking.save()

        response = authenticated_client.post(f"/api/v1/group-bookings/{group_booking.id}/confirm/")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_check_in_tentative_allowed(self, authenticated_client, group_booking):
        """Group bookings can check-in from tentative status."""
        response = authenticated_client.post(f"/api/v1/group-bookings/{group_booking.id}/check-in/")
        assert response.status_code == status.HTTP_200_OK
        group_booking.refresh_from_db()
        assert group_booking.status == GroupBooking.Status.CHECKED_IN

    def test_cannot_check_in_checked_out(self, authenticated_client, group_booking):
        """Cannot check-in a checked-out group booking."""
        group_booking.status = GroupBooking.Status.CHECKED_OUT
        group_booking.save()
        response = authenticated_client.post(f"/api/v1/group-bookings/{group_booking.id}/check-in/")
        assert response.status_code == status.HTTP_400_BAD_REQUEST


# ===== API Tests - Room Assignment =====


@pytest.mark.django_db
class TestGroupBookingRoomAssignment:
    def test_assign_rooms(self, authenticated_client, group_booking, rooms):
        room_ids = [r.id for r in rooms]
        response = authenticated_client.post(
            f"/api/v1/group-bookings/{group_booking.id}/assign-rooms/",
            {"room_ids": room_ids},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        group_booking.refresh_from_db()
        assert group_booking.rooms.count() == 3

    def test_assign_empty_rooms_rejected(self, authenticated_client, group_booking):
        """Empty room list is rejected."""
        response = authenticated_client.post(
            f"/api/v1/group-bookings/{group_booking.id}/assign-rooms/",
            {"room_ids": []},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_unauthenticated_access(self, api_client, group_booking):
        response = api_client.get("/api/v1/group-bookings/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ===== Filter Tests =====


@pytest.mark.django_db
class TestGroupBookingFiltering:
    def test_filter_by_status(self, authenticated_client, group_booking):
        response = authenticated_client.get("/api/v1/group-bookings/", {"status": "tentative"})
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        results = data.get("results", data) if isinstance(data, dict) else data
        assert all(r["status"] == "tentative" for r in results)

    def test_search_by_name(self, authenticated_client, group_booking):
        response = authenticated_client.get("/api/v1/group-bookings/", {"search": "Tour ABC"})
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        results = data.get("results", data) if isinstance(data, dict) else data
        assert len(results) >= 1
