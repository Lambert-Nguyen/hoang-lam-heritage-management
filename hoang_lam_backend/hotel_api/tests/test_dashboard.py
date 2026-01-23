"""
Tests for Dashboard endpoint.
"""

from datetime import date, timedelta
from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import Booking, Guest, HotelUser, Room, RoomType


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
def staff_user(create_user):
    """Create staff user."""
    return create_user("staff", "staff")


@pytest.fixture
def room_type(db):
    """Create a room type."""
    return RoomType.objects.create(
        name="Phòng Đôi",
        name_en="Double Room",
        base_rate=Decimal("500000"),
        max_guests=2,
    )


@pytest.fixture
def rooms(room_type):
    """Create test rooms with various statuses."""
    rooms = []
    rooms.append(
        Room.objects.create(
            number="101",
            name="Phòng 101",
            room_type=room_type,
            floor=1,
            status=Room.Status.AVAILABLE,
        )
    )
    rooms.append(
        Room.objects.create(
            number="102",
            name="Phòng 102",
            room_type=room_type,
            floor=1,
            status=Room.Status.OCCUPIED,
        )
    )
    rooms.append(
        Room.objects.create(
            number="103",
            name="Phòng 103",
            room_type=room_type,
            floor=1,
            status=Room.Status.CLEANING,
        )
    )
    rooms.append(
        Room.objects.create(
            number="201",
            name="Phòng 201",
            room_type=room_type,
            floor=2,
            status=Room.Status.OCCUPIED,
        )
    )
    rooms.append(
        Room.objects.create(
            number="202",
            name="Phòng 202",
            room_type=room_type,
            floor=2,
            status=Room.Status.AVAILABLE,
        )
    )
    return rooms


@pytest.fixture
def guest(db):
    """Create a test guest."""
    return Guest.objects.create(
        full_name="Nguyễn Văn A",
        phone="0901234567",
        nationality="Vietnam",
    )


@pytest.fixture
def bookings(rooms, guest):
    """Create test bookings."""
    today = date.today()
    bookings = []

    # Booking checking in today (pending)
    bookings.append(
        Booking.objects.create(
            room=rooms[0],
            guest=guest,
            check_in_date=today,
            check_out_date=today + timedelta(days=2),
            status=Booking.Status.CONFIRMED,
            nightly_rate=Decimal("500000"),
            total_amount=Decimal("1000000"),
        )
    )

    # Booking checking out today (checked_in)
    bookings.append(
        Booking.objects.create(
            room=rooms[1],
            guest=guest,
            check_in_date=today - timedelta(days=2),
            check_out_date=today,
            status=Booking.Status.CHECKED_IN,
            nightly_rate=Decimal("500000"),
            total_amount=Decimal("1000000"),
        )
    )

    # Pending booking for future
    bookings.append(
        Booking.objects.create(
            room=rooms[4],
            guest=guest,
            check_in_date=today + timedelta(days=3),
            check_out_date=today + timedelta(days=5),
            status=Booking.Status.PENDING,
            nightly_rate=Decimal("500000"),
            total_amount=Decimal("1000000"),
        )
    )

    return bookings


@pytest.mark.django_db
class TestDashboardView:
    """Tests for Dashboard API endpoint."""

    def test_dashboard_unauthenticated(self, api_client):
        """Test dashboard requires authentication."""
        response = api_client.get("/api/v1/dashboard/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_dashboard_authenticated(self, api_client, staff_user, rooms, bookings):
        """Test dashboard returns correct data for authenticated staff."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/dashboard/")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        # Check room status summary
        assert "room_status" in data
        assert data["room_status"]["total"] == 5
        assert data["room_status"]["available"] == 2
        assert data["room_status"]["occupied"] == 2
        assert data["room_status"]["cleaning"] == 1
        assert data["room_status"]["maintenance"] == 0
        assert data["room_status"]["blocked"] == 0

        # Check today's stats
        assert "today" in data
        assert data["today"]["date"] == date.today().isoformat()
        assert data["today"]["check_ins"] == 1  # 1 confirmed arriving today
        assert data["today"]["check_outs"] == 1  # 1 checked_in leaving today
        assert data["today"]["pending_arrivals"] == 1
        assert data["today"]["pending_departures"] == 1

        # Check occupancy
        assert "occupancy" in data
        assert data["occupancy"]["occupied_rooms"] == 2
        assert data["occupancy"]["total_rooms"] == 5
        assert data["occupancy"]["rate"] == 40.0  # 2/5 = 40%

        # Check booking counts
        assert "bookings" in data
        assert data["bookings"]["pending"] == 1
        assert data["bookings"]["confirmed"] == 1
        assert data["bookings"]["checked_in"] == 1

    def test_dashboard_empty_hotel(self, api_client, staff_user, db):
        """Test dashboard with no rooms or bookings."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/dashboard/")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert data["room_status"]["total"] == 0
        assert data["occupancy"]["rate"] == 0
        assert data["today"]["check_ins"] == 0
        assert data["today"]["check_outs"] == 0

    def test_dashboard_only_rooms_no_bookings(self, api_client, staff_user, rooms):
        """Test dashboard with rooms but no bookings."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/dashboard/")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert data["room_status"]["total"] == 5
        assert data["today"]["check_ins"] == 0
        assert data["today"]["check_outs"] == 0
        assert data["bookings"]["pending"] == 0
        assert data["bookings"]["confirmed"] == 0
        assert data["bookings"]["checked_in"] == 0
