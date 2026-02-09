"""
Tests for Early Check-in / Late Check-out Fees feature.

Tests cover:
- API endpoints for recording early/late fees
- Fee validation (hours, amounts)
- FolioItem creation for fee tracking
- Balance calculation with fees included
- Status restrictions
"""

import pytest
from datetime import date, timedelta
from decimal import Decimal

from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status

from hotel_api.models import Booking, FolioItem, Guest, HotelUser, Room, RoomType


# ===== Fixtures =====


@pytest.fixture
def owner_user(db):
    user = User.objects.create_user(
        username="feeowner",
        password="testpass123",
        first_name="Fee",
        last_name="Owner",
    )
    HotelUser.objects.create(user=user, role=HotelUser.Role.OWNER)
    return user


@pytest.fixture
def room_type(db):
    return RoomType.objects.create(
        name="Fee Test Room",
        base_rate=Decimal("500000"),
        max_guests=2,
        description="Test room",
    )


@pytest.fixture
def room(db, room_type):
    return Room.objects.create(
        number="FEE-101",
        floor=1,
        room_type=room_type,
        status=Room.Status.OCCUPIED,
    )


@pytest.fixture
def guest(db):
    return Guest.objects.create(
        full_name="Nguyễn Fee Tester",
        phone="0911111111",
        email="fee@test.com",
    )


@pytest.fixture
def checked_in_booking(db, room, guest, owner_user):
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        status=Booking.Status.CHECKED_IN,
        source=Booking.Source.WALK_IN,
        nightly_rate=Decimal("500000"),
        total_amount=Decimal("1000000"),
        deposit_amount=Decimal("500000"),
        created_by=owner_user,
    )


@pytest.fixture
def confirmed_booking(db, guest, owner_user, room_type):
    room2 = Room.objects.create(
        number="FEE-102",
        floor=1,
        room_type=room_type,
        status=Room.Status.AVAILABLE,
    )
    return Booking.objects.create(
        room=room2,
        guest=guest,
        check_in_date=date.today() + timedelta(days=1),
        check_out_date=date.today() + timedelta(days=3),
        status=Booking.Status.CONFIRMED,
        source=Booking.Source.WALK_IN,
        nightly_rate=Decimal("500000"),
        total_amount=Decimal("1000000"),
        created_by=owner_user,
    )


@pytest.fixture
def checked_out_booking(db, guest, owner_user, room_type):
    room3 = Room.objects.create(
        number="FEE-103",
        floor=1,
        room_type=room_type,
        status=Room.Status.CLEANING,
    )
    return Booking.objects.create(
        room=room3,
        guest=guest,
        check_in_date=date.today() - timedelta(days=2),
        check_out_date=date.today(),
        status=Booking.Status.CHECKED_OUT,
        source=Booking.Source.WALK_IN,
        nightly_rate=Decimal("500000"),
        total_amount=Decimal("1000000"),
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
class TestBookingFeeFields:
    def test_default_fee_values(self, checked_in_booking):
        """Fee fields should default to 0."""
        assert checked_in_booking.early_check_in_fee == 0
        assert checked_in_booking.late_check_out_fee == 0
        assert checked_in_booking.early_check_in_hours == 0
        assert checked_in_booking.late_check_out_hours == 0

    def test_balance_due_without_fees(self, checked_in_booking):
        """Balance due without fees = total + additional - deposit."""
        # total=1000000, deposit=500000, fees=0
        assert checked_in_booking.balance_due == Decimal("500000")

    def test_balance_due_with_early_fee(self, checked_in_booking):
        """Balance due should include early check-in fee."""
        checked_in_booking.early_check_in_fee = Decimal("100000")
        checked_in_booking.save()
        checked_in_booking.refresh_from_db()
        # 1000000 + 0 + 100000 + 0 - 500000 = 600000
        assert checked_in_booking.balance_due == Decimal("600000")

    def test_balance_due_with_late_fee(self, checked_in_booking):
        """Balance due should include late check-out fee."""
        checked_in_booking.late_check_out_fee = Decimal("150000")
        checked_in_booking.save()
        checked_in_booking.refresh_from_db()
        # 1000000 + 0 + 0 + 150000 - 500000 = 650000
        assert checked_in_booking.balance_due == Decimal("650000")

    def test_balance_due_with_both_fees(self, checked_in_booking):
        """Balance due should include both fees."""
        checked_in_booking.early_check_in_fee = Decimal("100000")
        checked_in_booking.late_check_out_fee = Decimal("150000")
        checked_in_booking.save()
        checked_in_booking.refresh_from_db()
        # 1000000 + 0 + 100000 + 150000 - 500000 = 750000
        assert checked_in_booking.balance_due == Decimal("750000")


# ===== API Tests - Early Check-in =====


@pytest.mark.django_db
class TestRecordEarlyCheckIn:
    def test_record_early_checkin_checked_in(self, authenticated_client, checked_in_booking):
        """Should record early check-in fee for checked-in booking."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert int(data["early_check_in_fee"]) == 100000
        assert float(data["early_check_in_hours"]) == 2.0

        # Verify DB
        checked_in_booking.refresh_from_db()
        assert checked_in_booking.early_check_in_fee == Decimal("100000")
        assert checked_in_booking.early_check_in_hours == Decimal("2.0")

    def test_record_early_checkin_confirmed(self, authenticated_client, confirmed_booking):
        """Should record early check-in fee for confirmed booking."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/record-early-checkin/",
            {"hours": 1.5, "fee": 75000},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert int(data["early_check_in_fee"]) == 75000

    def test_record_early_checkin_creates_folio_item(self, authenticated_client, checked_in_booking):
        """Should create a FolioItem when create_folio_item=True."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000, "create_folio_item": True},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK

        folio = FolioItem.objects.filter(
            booking=checked_in_booking,
            item_type="early_checkin",
        ).first()
        assert folio is not None
        assert folio.total_price == Decimal("100000")
        assert "2.0h" in folio.description

    def test_record_early_checkin_no_folio_item(self, authenticated_client, checked_in_booking):
        """Should NOT create a FolioItem when create_folio_item=False."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000, "create_folio_item": False},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        assert not FolioItem.objects.filter(
            booking=checked_in_booking,
            item_type="early_checkin",
        ).exists()

    def test_record_early_checkin_zero_fee_no_folio(self, authenticated_client, checked_in_booking):
        """Should NOT create a FolioItem when fee is 0."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 1.0, "fee": 0},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        assert not FolioItem.objects.filter(
            booking=checked_in_booking,
            item_type="early_checkin",
        ).exists()

    def test_record_early_checkin_with_notes(self, authenticated_client, checked_in_booking):
        """Should append notes to booking."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000, "notes": "Khách đến lúc 10h sáng"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        checked_in_booking.refresh_from_db()
        assert "Khách đến lúc 10h sáng" in checked_in_booking.notes

    def test_reject_checked_out_booking(self, authenticated_client, checked_out_booking):
        """Should reject early check-in fee for checked-out booking."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_out_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_reject_negative_hours(self, authenticated_client, checked_in_booking):
        """Should reject negative hours."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": -1, "fee": 100000},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_reject_excessive_hours(self, authenticated_client, checked_in_booking):
        """Should reject hours > 24."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 25, "fee": 100000},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_reject_negative_fee(self, authenticated_client, checked_in_booking):
        """Should reject negative fee."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": -50000},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_unauthenticated_access(self, api_client, checked_in_booking):
        """Should reject unauthenticated access."""
        response = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000},
            format="json",
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ===== API Tests - Late Check-out =====


@pytest.mark.django_db
class TestRecordLateCheckOut:
    def test_record_late_checkout(self, authenticated_client, checked_in_booking):
        """Should record late check-out fee."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-late-checkout/",
            {"hours": 3.0, "fee": 150000},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert int(data["late_check_out_fee"]) == 150000
        assert float(data["late_check_out_hours"]) == 3.0

        checked_in_booking.refresh_from_db()
        assert checked_in_booking.late_check_out_fee == Decimal("150000")

    def test_record_late_checkout_creates_folio_item(self, authenticated_client, checked_in_booking):
        """Should create a FolioItem for late check-out."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-late-checkout/",
            {"hours": 3.0, "fee": 150000},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK

        folio = FolioItem.objects.filter(
            booking=checked_in_booking,
            item_type="late_checkout",
        ).first()
        assert folio is not None
        assert folio.total_price == Decimal("150000")

    def test_reject_confirmed_booking(self, authenticated_client, confirmed_booking):
        """Should reject late check-out for confirmed (not checked-in) booking."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/record-late-checkout/",
            {"hours": 3.0, "fee": 150000},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_reject_checked_out_booking(self, authenticated_client, checked_out_booking):
        """Should reject late check-out for already checked-out booking."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_out_booking.id}/record-late-checkout/",
            {"hours": 3.0, "fee": 150000},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_with_notes(self, authenticated_client, checked_in_booking):
        """Should append notes for late check-out."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-late-checkout/",
            {"hours": 2.0, "fee": 80000, "notes": "Khách yêu cầu trả muộn"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        checked_in_booking.refresh_from_db()
        assert "Khách yêu cầu trả muộn" in checked_in_booking.notes

    def test_reject_negative_hours(self, authenticated_client, checked_in_booking):
        """Should reject negative hours."""
        response = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-late-checkout/",
            {"hours": -1, "fee": 150000},
            format="json",
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST


# ===== Combined Fee Tests =====


@pytest.mark.django_db
class TestCombinedFees:
    def test_both_fees_on_same_booking(self, authenticated_client, checked_in_booking):
        """Should allow recording both early and late fees on the same booking."""
        # Record early check-in
        response1 = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000},
            format="json",
        )
        assert response1.status_code == status.HTTP_200_OK

        # Record late check-out
        response2 = authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-late-checkout/",
            {"hours": 3.0, "fee": 150000},
            format="json",
        )
        assert response2.status_code == status.HTTP_200_OK

        # Re-fetch from DB
        booking = Booking.objects.get(pk=checked_in_booking.pk)
        assert booking.early_check_in_fee == Decimal("100000")
        assert booking.late_check_out_fee == Decimal("150000")
        assert booking.deposit_amount == Decimal("500000")
        # Folio items are marked is_paid=True, so additional_charges stays 0
        assert booking.additional_charges == Decimal("0")
        # Balance = 1000000 + 0 + 100000 + 150000 - 500000 = 750000
        assert booking.balance_due == Decimal("750000")

    def test_fees_in_serializer_response(self, authenticated_client, checked_in_booking):
        """Booking detail should include fee fields."""
        checked_in_booking.early_check_in_fee = Decimal("100000")
        checked_in_booking.early_check_in_hours = Decimal("2.0")
        checked_in_booking.late_check_out_fee = Decimal("150000")
        checked_in_booking.late_check_out_hours = Decimal("3.0")
        checked_in_booking.save()

        response = authenticated_client.get(
            f"/api/v1/bookings/{checked_in_booking.id}/",
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        # DecimalField values may be serialized as strings or integers
        assert int(data["early_check_in_fee"]) == 100000
        assert int(data["late_check_out_fee"]) == 150000
        assert float(data["early_check_in_hours"]) == 2.0
        assert float(data["late_check_out_hours"]) == 3.0

    def test_folio_items_created_for_both(self, authenticated_client, checked_in_booking):
        """Should create separate FolioItems for early and late fees."""
        authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-early-checkin/",
            {"hours": 2.0, "fee": 100000},
            format="json",
        )
        authenticated_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/record-late-checkout/",
            {"hours": 3.0, "fee": 150000},
            format="json",
        )

        folios = FolioItem.objects.filter(booking=checked_in_booking)
        assert folios.count() == 2
        types = set(folios.values_list("item_type", flat=True))
        assert types == {"early_checkin", "late_checkout"}
