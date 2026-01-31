"""
Tests for Night Audit endpoints.
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
    FinancialCategory,
    FinancialEntry,
    Guest,
    HotelUser,
    NightAudit,
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
def rooms(room_type):
    """Create test rooms."""
    rooms_list = []
    for i in range(1, 8):  # 7 rooms like the hotel
        room = Room.objects.create(
            number=f"10{i}",
            name=f"Phòng 10{i}",
            room_type=room_type,
            floor=1,
            status=Room.Status.AVAILABLE,
        )
        rooms_list.append(room)
    return rooms_list


@pytest.fixture
def guest(db):
    """Create a guest."""
    return Guest.objects.create(
        full_name="Nguyễn Văn Test",
        phone="+84901234567",
        id_type=Guest.IDType.CCCD,
        id_number="012345678901",
        nationality="Việt Nam",
    )


@pytest.fixture
def income_category(db):
    """Create an income category."""
    return FinancialCategory.objects.create(
        name="Tiền phòng",
        name_en="Room Revenue",
        category_type=FinancialCategory.CategoryType.INCOME,
        icon="hotel",
        color="#4CAF50",
        is_default=True,
    )


@pytest.fixture
def expense_category(db):
    """Create an expense category."""
    return FinancialCategory.objects.create(
        name="Tiền điện",
        name_en="Electricity",
        category_type=FinancialCategory.CategoryType.EXPENSE,
        icon="bolt",
        color="#F44336",
        is_default=True,
    )


@pytest.fixture
def booking_with_checkin(rooms, guest, room_type):
    """Create a booking with check-in today."""
    room = rooms[0]
    room.status = Room.Status.OCCUPIED
    room.save()

    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        status=Booking.Status.CHECKED_IN,
        actual_check_in=timezone.now(),
        nightly_rate=room_type.base_rate,
        total_amount=Decimal("1000000"),
        deposit_amount=Decimal("500000"),
        payment_method=Booking.PaymentMethod.CASH,
    )


@pytest.fixture
def booking_checkout_today(rooms, guest, room_type):
    """Create a booking with check-out today."""
    room = rooms[1]
    room.status = Room.Status.CLEANING
    room.save()

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
        deposit_amount=Decimal("800000"),
        payment_method=Booking.PaymentMethod.BANK_TRANSFER,
    )


# ==================== Night Audit List Tests ====================


@pytest.mark.django_db
class TestNightAuditList:
    """Tests for GET /api/v1/night-audits/"""

    def test_list_audits_requires_auth(self, api_client):
        """Listing audits requires authentication."""
        response = api_client.get("/api/v1/night-audits/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_audits_success(self, api_client, manager_user):
        """Manager can list audits."""
        api_client.force_authenticate(user=manager_user)

        # Create some audits
        NightAudit.objects.create(audit_date=date.today())
        NightAudit.objects.create(audit_date=date.today() - timedelta(days=1))

        response = api_client.get("/api/v1/night-audits/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 2

    def test_list_audits_filter_by_status(self, api_client, manager_user):
        """Can filter audits by status."""
        api_client.force_authenticate(user=manager_user)

        NightAudit.objects.create(audit_date=date.today(), status=NightAudit.Status.DRAFT)
        NightAudit.objects.create(
            audit_date=date.today() - timedelta(days=1), status=NightAudit.Status.CLOSED
        )

        response = api_client.get("/api/v1/night-audits/?status=draft")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 1
        assert response.data["results"][0]["status"] == "draft"

    def test_list_audits_filter_by_date_range(self, api_client, manager_user):
        """Can filter audits by date range."""
        api_client.force_authenticate(user=manager_user)

        NightAudit.objects.create(audit_date=date.today())
        NightAudit.objects.create(audit_date=date.today() - timedelta(days=5))
        NightAudit.objects.create(audit_date=date.today() - timedelta(days=10))

        date_from = (date.today() - timedelta(days=6)).isoformat()
        response = api_client.get(f"/api/v1/night-audits/?date_from={date_from}")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 2


# ==================== Night Audit Create Tests ====================


@pytest.mark.django_db
class TestNightAuditCreate:
    """Tests for POST /api/v1/night-audits/"""

    def test_create_audit_requires_auth(self, api_client):
        """Creating audit requires authentication."""
        response = api_client.post("/api/v1/night-audits/", {"audit_date": str(date.today())})
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_create_audit_success(self, api_client, manager_user, rooms):
        """Manager can create an audit for a date."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.post(
            "/api/v1/night-audits/",
            {"audit_date": str(date.today()), "notes": "Test audit"},
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["audit_date"] == str(date.today())
        assert response.data["status"] == "draft"
        assert response.data["notes"] == "Test audit"
        assert response.data["total_rooms"] == 7  # Based on rooms fixture

    def test_create_audit_duplicate_date_fails(self, api_client, manager_user, rooms):
        """Cannot create duplicate audit for same date."""
        api_client.force_authenticate(user=manager_user)

        # Create first audit
        NightAudit.objects.create(audit_date=date.today())

        response = api_client.post("/api/v1/night-audits/", {"audit_date": str(date.today())})

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Đã tồn tại" in response.data["detail"]


# ==================== Night Audit Detail Tests ====================


@pytest.mark.django_db
class TestNightAuditDetail:
    """Tests for GET /api/v1/night-audits/{id}/"""

    def test_get_audit_detail(self, api_client, manager_user):
        """Can get audit detail."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(
            audit_date=date.today(),
            total_rooms=7,
            rooms_occupied=3,
            rooms_available=4,
            total_income=Decimal("5000000"),
        )

        response = api_client.get(f"/api/v1/night-audits/{audit.id}/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["audit_date"] == str(date.today())
        assert response.data["total_rooms"] == 7
        assert response.data["rooms_occupied"] == 3


# ==================== Night Audit Update Tests ====================


@pytest.mark.django_db
class TestNightAuditUpdate:
    """Tests for PUT /api/v1/night-audits/{id}/"""

    def test_update_draft_audit(self, api_client, manager_user):
        """Can update a draft audit."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(
            audit_date=date.today(), status=NightAudit.Status.DRAFT, notes="Initial"
        )

        response = api_client.patch(f"/api/v1/night-audits/{audit.id}/", {"notes": "Updated notes"})

        assert response.status_code == status.HTTP_200_OK
        assert response.data["notes"] == "Updated notes"

    def test_cannot_update_closed_audit(self, api_client, manager_user):
        """Cannot update a closed audit."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(audit_date=date.today(), status=NightAudit.Status.CLOSED)

        response = api_client.patch(f"/api/v1/night-audits/{audit.id}/", {"notes": "Try update"})

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Không thể chỉnh sửa" in response.data["detail"]


# ==================== Night Audit Delete Tests ====================


@pytest.mark.django_db
class TestNightAuditDelete:
    """Tests for DELETE /api/v1/night-audits/{id}/"""

    def test_delete_draft_audit(self, api_client, manager_user):
        """Can delete a draft audit."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(audit_date=date.today(), status=NightAudit.Status.DRAFT)

        response = api_client.delete(f"/api/v1/night-audits/{audit.id}/")

        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not NightAudit.objects.filter(id=audit.id).exists()

    def test_cannot_delete_closed_audit(self, api_client, manager_user):
        """Cannot delete a closed audit."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(audit_date=date.today(), status=NightAudit.Status.CLOSED)

        response = api_client.delete(f"/api/v1/night-audits/{audit.id}/")

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Không thể xóa" in response.data["detail"]


# ==================== Night Audit Close Tests ====================


@pytest.mark.django_db
class TestNightAuditClose:
    """Tests for POST /api/v1/night-audits/{id}/close/"""

    def test_close_audit(self, api_client, manager_user):
        """Can close a draft audit."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(audit_date=date.today(), status=NightAudit.Status.DRAFT)

        response = api_client.post(f"/api/v1/night-audits/{audit.id}/close/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["status"] == "closed"

        # Verify in database
        audit.refresh_from_db()
        assert audit.status == NightAudit.Status.CLOSED
        assert audit.closed_by == manager_user
        assert audit.closed_at is not None

    def test_cannot_close_already_closed_audit(self, api_client, manager_user):
        """Cannot close an already closed audit."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(
            audit_date=date.today(),
            status=NightAudit.Status.CLOSED,
            closed_at=timezone.now(),
        )

        response = api_client.post(f"/api/v1/night-audits/{audit.id}/close/")

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "đã được đóng" in response.data["detail"]


# ==================== Night Audit Recalculate Tests ====================


@pytest.mark.django_db
class TestNightAuditRecalculate:
    """Tests for POST /api/v1/night-audits/{id}/recalculate/"""

    def test_recalculate_audit(self, api_client, manager_user, rooms, booking_with_checkin):
        """Can recalculate audit statistics."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(
            audit_date=date.today(),
            status=NightAudit.Status.DRAFT,
            rooms_occupied=0,  # Wrong value
        )

        response = api_client.post(f"/api/v1/night-audits/{audit.id}/recalculate/")

        assert response.status_code == status.HTTP_200_OK
        # After recalculation, should have correct room count
        assert response.data["rooms_occupied"] >= 1  # At least the occupied room

    def test_cannot_recalculate_closed_audit(self, api_client, manager_user):
        """Cannot recalculate a closed audit."""
        api_client.force_authenticate(user=manager_user)

        audit = NightAudit.objects.create(audit_date=date.today(), status=NightAudit.Status.CLOSED)

        response = api_client.post(f"/api/v1/night-audits/{audit.id}/recalculate/")

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Không thể tính lại" in response.data["detail"]


# ==================== Night Audit Today Tests ====================


@pytest.mark.django_db
class TestNightAuditToday:
    """Tests for GET /api/v1/night-audits/today/"""

    def test_get_today_creates_if_not_exists(self, api_client, manager_user, rooms):
        """Getting today's audit creates one if not exists."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.get("/api/v1/night-audits/today/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["audit_date"] == str(date.today())
        assert response.data["status"] == "draft"
        assert NightAudit.objects.filter(audit_date=date.today()).exists()

    def test_get_today_returns_existing(self, api_client, manager_user):
        """Getting today's audit returns existing one."""
        api_client.force_authenticate(user=manager_user)

        # Create existing audit
        existing = NightAudit.objects.create(
            audit_date=date.today(),
            status=NightAudit.Status.DRAFT,
            notes="Existing audit",
        )

        response = api_client.get("/api/v1/night-audits/today/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["id"] == existing.id
        assert response.data["notes"] == "Existing audit"


# ==================== Night Audit Statistics Tests ====================


@pytest.mark.django_db
class TestNightAuditStatistics:
    """Tests for audit statistics calculation."""

    def test_audit_calculates_room_stats(
        self, api_client, manager_user, rooms, booking_with_checkin
    ):
        """Audit correctly calculates room statistics."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.post("/api/v1/night-audits/", {"audit_date": str(date.today())})

        assert response.status_code == status.HTTP_201_CREATED
        data = response.data
        assert data["total_rooms"] == 7
        assert data["rooms_occupied"] == 1  # One room with checked-in booking

    def test_audit_calculates_checkin_stats(
        self, api_client, manager_user, rooms, booking_with_checkin
    ):
        """Audit correctly counts check-ins today."""
        api_client.force_authenticate(user=manager_user)

        response = api_client.post("/api/v1/night-audits/", {"audit_date": str(date.today())})

        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["check_ins_today"] >= 1

    def test_audit_calculates_financial_stats(
        self, api_client, manager_user, rooms, income_category
    ):
        """Audit correctly calculates financial statistics."""
        api_client.force_authenticate(user=manager_user)

        # Create income entry
        FinancialEntry.objects.create(
            entry_type=FinancialEntry.EntryType.INCOME,
            category=income_category,
            amount=Decimal("1500000"),
            date=date.today(),
            description="Room payment",
            payment_method=Booking.PaymentMethod.CASH,
        )

        response = api_client.post("/api/v1/night-audits/", {"audit_date": str(date.today())})

        assert response.status_code == status.HTTP_201_CREATED
        # Financial stats should include the income entry
        assert Decimal(response.data["total_income"]) >= Decimal("1500000")
