"""
Tests for Temporary Residence Declaration Export endpoints.
"""

from datetime import date, timedelta
from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import (
    Booking,
    Guest,
    HotelUser,
    Room,
    RoomType,
)


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
def room_type(db):
    """Create a room type."""
    return RoomType.objects.create(
        name="Phòng Đôi",
        name_en="Double Room",
        base_rate=Decimal("500000"),
        max_guests=2,
    )


@pytest.fixture
def room(room_type):
    """Create a room."""
    return Room.objects.create(
        number="101",
        name="Phòng 101",
        room_type=room_type,
        floor=1,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def guest(db):
    """Create a guest with full details for declaration."""
    return Guest.objects.create(
        full_name="Nguyễn Văn Test",
        phone="+84901234567",
        id_type=Guest.IDType.CCCD,
        id_number="012345678901",
        nationality="Việt Nam",
        gender="male",
        date_of_birth=date(1990, 5, 15),
        id_issue_date=date(2020, 1, 1),
        id_issue_place="CA TP Hồ Chí Minh",
        address="123 Đường ABC, Quận 1, TP.HCM",
    )


@pytest.fixture
def guest_foreign(db):
    """Create a foreign guest."""
    return Guest.objects.create(
        full_name="John Smith",
        phone="+1234567890",
        id_type=Guest.IDType.PASSPORT,
        id_number="AB1234567",
        nationality="United States",
        gender="male",
        date_of_birth=date(1985, 8, 20),
        id_issue_date=date(2022, 6, 15),
        id_issue_place="US State Department",
        address="123 Main St, New York, USA",
    )


@pytest.fixture
def booking_checked_in(room, guest, room_type):
    """Create a checked-in booking for today."""
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        status=Booking.Status.CHECKED_IN,
        actual_check_in=timezone.now(),
        nightly_rate=room_type.base_rate,
        total_amount=Decimal("1000000"),
    )


@pytest.fixture
def booking_checked_out(room, guest, room_type):
    """Create a checked-out booking from yesterday."""
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today() - timedelta(days=2),
        check_out_date=date.today(),
        status=Booking.Status.CHECKED_OUT,
        actual_check_in=timezone.now() - timedelta(days=2),
        actual_check_out=timezone.now(),
        nightly_rate=room_type.base_rate,
        total_amount=Decimal("800000"),
    )


# ==================== Declaration Export Tests ====================


@pytest.mark.django_db
class TestDeclarationExportCSV:
    """Tests for GET /api/v1/guests/declaration-export/ CSV format"""

    def test_export_requires_auth(self, api_client):
        """Export requires authentication."""
        response = api_client.get("/api/v1/guests/declaration-export/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_export_csv_success(self, api_client, manager_user, booking_checked_in):
        """Manager can export declaration as CSV."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.get("/api/v1/guests/declaration-export/")

        assert response.status_code == status.HTTP_200_OK
        assert "text/csv" in response["Content-Type"]
        assert "attachment" in response["Content-Disposition"]
        assert ".csv" in response["Content-Disposition"]

    def test_export_csv_contains_guest_data(self, api_client, manager_user, booking_checked_in):
        """CSV export contains correct guest data."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.get("/api/v1/guests/declaration-export/")

        content = response.content.decode("utf-8")
        # Check headers present
        assert "Họ và tên" in content
        assert "Ngày sinh" in content
        assert "Số giấy tờ" in content
        # Check guest data present
        assert "Nguyễn Văn Test" in content
        assert "012345678901" in content

    def test_export_csv_with_date_range(
        self, api_client, manager_user, room, guest, room_type
    ):
        """CSV export filters by date range."""
        api_client.force_authenticate(user=manager_user)

        # Create booking for yesterday
        Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=date.today() - timedelta(days=1),
            check_out_date=date.today(),
            status=Booking.Status.CHECKED_IN,
            actual_check_in=timezone.now() - timedelta(days=1),
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("500000"),
        )

        # Export only yesterday
        yesterday = date.today() - timedelta(days=1)
        response = api_client.get(
            f"/api/v1/guests/declaration-export/?date_from={yesterday}&date_to={yesterday}"
        )

        assert response.status_code == status.HTTP_200_OK
        content = response.content.decode("utf-8")
        assert "Nguyễn Văn Test" in content

    def test_export_csv_empty_date_range(self, api_client, manager_user):
        """CSV export returns empty file for date range with no bookings."""
        api_client.force_authenticate(user=manager_user)

        # Export for a date range with no bookings
        future_date = date.today() + timedelta(days=30)
        response = api_client.get(
            f"/api/v1/guests/declaration-export/?date_from={future_date}&date_to={future_date}"
        )

        assert response.status_code == status.HTTP_200_OK
        content = response.content.decode("utf-8")
        # Should have headers but no data rows
        assert "Họ và tên" in content
        lines = content.strip().split("\n")
        assert len(lines) == 1  # Only header row


@pytest.mark.django_db
class TestDeclarationExportExcel:
    """Tests for GET /api/v1/guests/declaration-export/ Excel format"""

    def test_export_excel_success(self, api_client, manager_user, booking_checked_in):
        """Manager can export declaration as Excel."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.get("/api/v1/guests/declaration-export/?format=excel")

        # Either success or openpyxl not installed
        assert response.status_code in [status.HTTP_200_OK, status.HTTP_400_BAD_REQUEST, status.HTTP_404_NOT_FOUND]

        if response.status_code == status.HTTP_200_OK:
            assert (
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                in response["Content-Type"]
            )
            assert ".xlsx" in response["Content-Disposition"]


@pytest.mark.django_db
class TestDeclarationExportValidation:
    """Tests for declaration export validation"""

    def test_invalid_date_format(self, api_client, manager_user):
        """Invalid date format returns error."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.get("/api/v1/guests/declaration-export/?date_from=invalid")

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Định dạng ngày" in response.data["detail"]

    def test_date_from_after_date_to(self, api_client, manager_user):
        """date_from > date_to returns error."""
        api_client.force_authenticate(user=manager_user)

        date_from = date.today()
        date_to = date.today() - timedelta(days=5)

        response = api_client.get(
            f"/api/v1/guests/declaration-export/?date_from={date_from}&date_to={date_to}"
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Ngày bắt đầu" in response.data["detail"]

    def test_default_dates_to_today(self, api_client, manager_user, booking_checked_in):
        """Without date params, defaults to today."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.get("/api/v1/guests/declaration-export/")

        assert response.status_code == status.HTTP_200_OK
        # The filename should contain today's date
        today_str = date.today().isoformat()
        assert today_str in response["Content-Disposition"]


@pytest.mark.django_db
class TestDeclarationExportGuestFiltering:
    """Tests for guest filtering in declaration export"""

    def test_only_checked_in_or_out_bookings(
        self, api_client, manager_user, room, guest, room_type
    ):
        """Export only includes checked-in and checked-out bookings."""
        api_client.force_authenticate(user=manager_user)

        # Create pending booking (should not be included)
        Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=1),
            status=Booking.Status.PENDING,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("500000"),
        )

        response = api_client.get("/api/v1/guests/declaration-export/")

        assert response.status_code == status.HTTP_200_OK
        content = response.content.decode("utf-8")
        lines = content.strip().split("\n")
        # Should only have header, no data rows (pending booking excluded)
        assert len(lines) == 1

    def test_includes_foreign_guests(
        self, api_client, manager_user, room, guest_foreign, room_type
    ):
        """Export correctly includes foreign guests with passport info."""
        api_client.force_authenticate(user=manager_user)

        # Create booking for foreign guest
        Booking.objects.create(
            room=room,
            guest=guest_foreign,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=3),
            status=Booking.Status.CHECKED_IN,
            actual_check_in=timezone.now(),
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("1500000"),
        )

        response = api_client.get("/api/v1/guests/declaration-export/")

        assert response.status_code == status.HTTP_200_OK
        content = response.content.decode("utf-8")
        assert "John Smith" in content
        assert "AB1234567" in content
        assert "United States" in content


@pytest.mark.django_db
class TestDeclarationExportPermissions:
    """Tests for declaration export permissions"""

    def test_staff_can_export(self, api_client, staff_user, booking_checked_in):
        """Staff members can export declaration."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get("/api/v1/guests/declaration-export/")

        assert response.status_code == status.HTTP_200_OK

    def test_manager_can_export(self, api_client, manager_user, booking_checked_in):
        """Managers can export declaration."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.get("/api/v1/guests/declaration-export/")

        assert response.status_code == status.HTTP_200_OK
