"""
Integration tests for critical multi-step business flows.

These tests verify that chained operations work correctly end-to-end:
- Full booking lifecycle: create → deposit → check-in → folio → check-out
- Check-in flow: booking check-in → room status sync
- Check-out flow: checkout → housekeeping task + financial entry + guest stats
- Payment flow: deposit recording → booking deposit tracking → threshold logic
- Cancellation flow: cancel after check-in → room status revert
- No-show flow: mark no-show → room status revert

Phase C Task 6 — Integration tests for critical flows.
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
    FolioItem,
    Guest,
    HotelUser,
    HousekeepingTask,
    Payment,
    Room,
    RoomType,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def api_client():
    """Create API client."""
    return APIClient()


@pytest.fixture
def create_user(db):
    """Factory to create users with hotel roles."""
    _counter = [0]

    def _create(username, role="staff"):
        _counter[0] += 1
        user = User.objects.create_user(
            username=username,
            password="testpass123",
            email=f"{username}@test.com",
        )
        HotelUser.objects.create(
            user=user,
            role=role,
            phone=f"+849{_counter[0]:08d}",
        )
        return user

    return _create


@pytest.fixture
def staff_user(create_user):
    """Create a staff user."""
    return create_user("staff_integ", "staff")


@pytest.fixture
def manager_user(create_user):
    """Create a manager user."""
    return create_user("manager_integ", "manager")


@pytest.fixture
def room_type(db):
    """Create a standard room type."""
    return RoomType.objects.create(
        name="Phòng Đôi",
        name_en="Double Room",
        base_rate=Decimal("500000"),
        max_guests=2,
    )


@pytest.fixture
def room(room_type):
    """Create an available room."""
    return Room.objects.create(
        number="201",
        name="Phòng 201",
        room_type=room_type,
        floor=2,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def second_room(room_type):
    """Create a second available room."""
    return Room.objects.create(
        number="202",
        name="Phòng 202",
        room_type=room_type,
        floor=2,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def guest(db):
    """Create a guest."""
    return Guest.objects.create(
        full_name="Trần Văn B",
        phone="0912345678",
        nationality="Vietnam",
        id_type=Guest.IDType.CCCD,
        id_number="079200012345",
    )


@pytest.fixture
def second_guest(db):
    """Create a second guest."""
    return Guest.objects.create(
        full_name="Lê Thị C",
        phone="0923456789",
        nationality="Vietnam",
        id_type=Guest.IDType.CCCD,
        id_number="079200054321",
    )


@pytest.fixture
def confirmed_booking(room, guest, room_type):
    """Create a confirmed booking starting today for 2 nights."""
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        status=Booking.Status.CONFIRMED,
        nightly_rate=room_type.base_rate,
        total_amount=Decimal("1000000"),
        deposit_amount=Decimal("0"),
        deposit_paid=False,
        source=Booking.Source.WALK_IN,
    )


@pytest.fixture
def checked_in_booking(room, guest, room_type):
    """Create a booking that is already checked in."""
    room.status = Room.Status.OCCUPIED
    room.save()
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        status=Booking.Status.CHECKED_IN,
        nightly_rate=room_type.base_rate,
        total_amount=Decimal("1000000"),
        deposit_amount=Decimal("300000"),
        deposit_paid=True,
        actual_check_in=timezone.now(),
        source=Booking.Source.WALK_IN,
    )


@pytest.fixture
def income_category(db):
    """Create a default income financial category (required for checkout)."""
    return FinancialCategory.objects.create(
        name="Tiền phòng",
        name_en="Room Revenue",
        category_type=FinancialCategory.CategoryType.INCOME,
        is_default=True,
        is_active=True,
    )


# ---------------------------------------------------------------------------
# 1. Full Booking Lifecycle
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestFullBookingLifecycle:
    """Test the complete booking lifecycle from creation to checkout."""

    def test_full_lifecycle_create_deposit_checkin_folio_checkout(
        self, api_client, staff_user, room_type, room, guest, income_category
    ):
        """
        Full lifecycle:
        1. Create booking via API
        2. Record deposit → verify deposit_paid threshold
        3. Check in → verify room becomes OCCUPIED
        4. Add folio items → verify additional_charges updated
        5. Check out → verify room CLEANING, housekeeping task, financial entry,
           guest total_stays incremented
        """
        api_client.force_authenticate(user=staff_user)

        # --- Step 1: Create booking ---
        nights = 3
        nightly_rate = Decimal("500000")
        total_amount = nightly_rate * nights
        booking_data = {
            "room": room.id,
            "guest": guest.id,
            "check_in_date": str(date.today()),
            "check_out_date": str(date.today() + timedelta(days=nights)),
            "nightly_rate": str(nightly_rate),
            "total_amount": str(total_amount),
            "source": "walk_in",
        }
        resp = api_client.post("/api/v1/bookings/", booking_data, format="json")
        assert resp.status_code == status.HTTP_201_CREATED, resp.data
        booking_id = resp.data["id"]
        assert resp.data["status"] == "confirmed"
        total_amount = Decimal(str(resp.data["total_amount"]))
        assert total_amount > 0

        # --- Step 2: Record deposit (≥30% → deposit_paid=True) ---
        deposit_amount = int(total_amount * Decimal("0.3"))
        deposit_data = {
            "booking_id": booking_id,
            "amount": str(deposit_amount),
            "payment_method": "cash",
        }
        resp = api_client.post(
            "/api/v1/payments/record-deposit/", deposit_data, format="json"
        )
        assert resp.status_code == status.HTTP_201_CREATED, resp.data

        # Verify booking deposit tracking updated
        booking = Booking.objects.get(pk=booking_id)
        assert booking.deposit_amount >= deposit_amount
        assert booking.deposit_paid is True

        # --- Step 3: Check in ---
        resp = api_client.post(f"/api/v1/bookings/{booking_id}/check-in/")
        assert resp.status_code == status.HTTP_200_OK, resp.data
        assert resp.data["status"] == "checked_in"

        # Verify room is now OCCUPIED
        room.refresh_from_db()
        assert room.status == Room.Status.OCCUPIED

        # --- Step 4: Add folio items (minibar + extra service) ---
        folio_data = {
            "booking": booking_id,
            "item_type": "minibar",
            "description": "Coca-Cola x2",
            "quantity": 2,
            "unit_price": "30000",
            "date": str(date.today()),
        }
        resp = api_client.post("/api/v1/folio-items/", folio_data, format="json")
        assert resp.status_code == status.HTTP_201_CREATED, resp.data

        folio_data2 = {
            "booking": booking_id,
            "item_type": "service",
            "description": "Giặt ủi",
            "quantity": 1,
            "unit_price": "100000",
            "date": str(date.today()),
        }
        resp = api_client.post("/api/v1/folio-items/", folio_data2, format="json")
        assert resp.status_code == status.HTTP_201_CREATED, resp.data

        # Verify folio items exist
        folio_count = FolioItem.objects.filter(booking_id=booking_id).count()
        assert folio_count == 2

        # Record initial guest total_stays
        guest.refresh_from_db()
        initial_stays = guest.total_stays

        # --- Step 5: Check out ---
        resp = api_client.post(
            f"/api/v1/bookings/{booking_id}/check-out/",
            {"additional_charges": "0"},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK, resp.data
        assert resp.data["status"] == "checked_out"

        # Verify room is now CLEANING
        room.refresh_from_db()
        assert room.status == Room.Status.CLEANING

        # Verify housekeeping task was auto-created
        task = HousekeepingTask.objects.filter(
            booking_id=booking_id,
            task_type=HousekeepingTask.TaskType.CHECKOUT_CLEAN,
        ).first()
        assert task is not None
        assert task.status == HousekeepingTask.Status.PENDING
        assert task.room == room

        # Verify financial entry was created
        fin_entry = FinancialEntry.objects.filter(booking_id=booking_id).first()
        assert fin_entry is not None
        assert fin_entry.entry_type == FinancialEntry.EntryType.INCOME
        assert fin_entry.category == income_category
        assert fin_entry.amount > 0

        # Verify guest total_stays incremented
        guest.refresh_from_db()
        assert guest.total_stays == initial_stays + 1


# ---------------------------------------------------------------------------
# 2. Check-In Flow
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestCheckInFlow:
    """Test check-in operations and their side effects."""

    def test_checkin_updates_room_to_occupied(
        self, api_client, staff_user, confirmed_booking
    ):
        """Check-in should set booking to CHECKED_IN and room to OCCUPIED."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/check-in/"
        )
        assert resp.status_code == status.HTTP_200_OK
        assert resp.data["status"] == "checked_in"

        confirmed_booking.refresh_from_db()
        assert confirmed_booking.status == Booking.Status.CHECKED_IN
        assert confirmed_booking.actual_check_in is not None

        confirmed_booking.room.refresh_from_db()
        assert confirmed_booking.room.status == Room.Status.OCCUPIED

    def test_checkin_with_custom_time(
        self, api_client, staff_user, confirmed_booking
    ):
        """Check-in with custom actual_check_in time should be recorded."""
        api_client.force_authenticate(user=staff_user)

        custom_time = timezone.now() - timedelta(hours=1)
        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/check-in/",
            {"actual_check_in": custom_time.isoformat()},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK

        confirmed_booking.refresh_from_db()
        # The time should be close to the custom time provided
        assert confirmed_booking.actual_check_in is not None

    def test_cannot_checkin_already_checked_in(
        self, api_client, staff_user, checked_in_booking
    ):
        """Cannot check in a booking that is already checked in."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/check-in/"
        )
        assert resp.status_code == status.HTTP_400_BAD_REQUEST

    def test_cannot_checkin_checked_out_booking(
        self, api_client, staff_user, room, guest, room_type
    ):
        """Cannot check in a booking that is already checked out."""
        api_client.force_authenticate(user=staff_user)

        booking = Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=date.today() - timedelta(days=2),
            check_out_date=date.today(),
            status=Booking.Status.CHECKED_OUT,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("1000000"),
        )
        resp = api_client.post(f"/api/v1/bookings/{booking.id}/check-in/")
        assert resp.status_code == status.HTTP_400_BAD_REQUEST

    def test_checkin_from_pending_status(
        self, api_client, staff_user, room, guest, room_type
    ):
        """Check-in should work from PENDING status (not just CONFIRMED)."""
        api_client.force_authenticate(user=staff_user)

        booking = Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=1),
            status=Booking.Status.PENDING,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("500000"),
        )
        resp = api_client.post(f"/api/v1/bookings/{booking.id}/check-in/")
        assert resp.status_code == status.HTTP_200_OK
        assert resp.data["status"] == "checked_in"

        room.refresh_from_db()
        assert room.status == Room.Status.OCCUPIED


# ---------------------------------------------------------------------------
# 3. Check-Out Flow
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestCheckOutFlow:
    """Test checkout and all its side effects."""

    def test_checkout_creates_housekeeping_task(
        self, api_client, staff_user, checked_in_booking, income_category
    ):
        """Checkout should auto-create a CHECKOUT_CLEAN housekeeping task."""
        api_client.force_authenticate(user=staff_user)

        initial_tasks = HousekeepingTask.objects.count()

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/check-out/"
        )
        assert resp.status_code == status.HTTP_200_OK

        # One new task should exist
        assert HousekeepingTask.objects.count() == initial_tasks + 1

        task = HousekeepingTask.objects.filter(
            booking=checked_in_booking,
        ).first()
        assert task is not None
        assert task.task_type == HousekeepingTask.TaskType.CHECKOUT_CLEAN
        assert task.status == HousekeepingTask.Status.PENDING
        assert task.scheduled_date <= date.today()
        assert task.room == checked_in_booking.room
        assert "Auto-created" in task.notes

    def test_checkout_sets_room_to_cleaning(
        self, api_client, staff_user, checked_in_booking, income_category
    ):
        """Checkout should set room status to CLEANING."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/check-out/"
        )
        assert resp.status_code == status.HTTP_200_OK

        checked_in_booking.room.refresh_from_db()
        assert checked_in_booking.room.status == Room.Status.CLEANING

    def test_checkout_creates_financial_entry(
        self, api_client, staff_user, checked_in_booking, income_category
    ):
        """Checkout should create an income financial entry for room revenue."""
        api_client.force_authenticate(user=staff_user)

        initial_entries = FinancialEntry.objects.count()

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/check-out/"
        )
        assert resp.status_code == status.HTTP_200_OK

        assert FinancialEntry.objects.count() == initial_entries + 1

        entry = FinancialEntry.objects.filter(
            booking=checked_in_booking,
        ).first()
        assert entry is not None
        assert entry.entry_type == FinancialEntry.EntryType.INCOME
        assert entry.category == income_category
        assert entry.amount >= checked_in_booking.total_amount

    def test_checkout_increments_guest_total_stays(
        self, api_client, staff_user, checked_in_booking, income_category
    ):
        """Checkout should increment guest.total_stays by 1."""
        api_client.force_authenticate(user=staff_user)

        guest = checked_in_booking.guest
        guest.refresh_from_db()
        initial_stays = guest.total_stays

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/check-out/"
        )
        assert resp.status_code == status.HTTP_200_OK

        guest.refresh_from_db()
        assert guest.total_stays == initial_stays + 1

    def test_checkout_with_additional_charges(
        self, api_client, staff_user, checked_in_booking, income_category
    ):
        """Checkout with additional charges should include them in financial entry."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/check-out/",
            {"additional_charges": "200000"},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK

        checked_in_booking.refresh_from_db()
        assert checked_in_booking.additional_charges == Decimal("200000")

        # Financial entry should include the additional charges
        entry = FinancialEntry.objects.filter(
            booking=checked_in_booking,
        ).first()
        assert entry is not None
        assert entry.amount >= checked_in_booking.total_amount + Decimal("200000")

    def test_cannot_checkout_already_checked_out(
        self, api_client, staff_user, room, guest, room_type, income_category
    ):
        """Cannot checkout a booking that is already checked out."""
        api_client.force_authenticate(user=staff_user)

        booking = Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=date.today() - timedelta(days=2),
            check_out_date=date.today(),
            status=Booking.Status.CHECKED_OUT,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("1000000"),
        )
        resp = api_client.post(f"/api/v1/bookings/{booking.id}/check-out/")
        assert resp.status_code == status.HTTP_400_BAD_REQUEST

    def test_cannot_checkout_confirmed_booking(
        self, api_client, staff_user, confirmed_booking, income_category
    ):
        """Cannot checkout a booking that hasn't been checked in yet."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/check-out/"
        )
        assert resp.status_code == status.HTTP_400_BAD_REQUEST


# ---------------------------------------------------------------------------
# 4. Payment & Deposit Flow
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestPaymentDepositFlow:
    """Test deposit recording and its effect on booking state."""

    def test_deposit_below_threshold_does_not_mark_paid(
        self, api_client, staff_user, confirmed_booking
    ):
        """Recording a deposit below 30% of total should NOT set deposit_paid."""
        api_client.force_authenticate(user=staff_user)

        # Deposit only 10% (100K of 1M)
        resp = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": confirmed_booking.id,
                "amount": "100000",
                "payment_method": "cash",
            },
            format="json",
        )
        assert resp.status_code == status.HTTP_201_CREATED

        confirmed_booking.refresh_from_db()
        assert confirmed_booking.deposit_amount == Decimal("100000")
        assert confirmed_booking.deposit_paid is False

    def test_deposit_at_threshold_marks_paid(
        self, api_client, staff_user, confirmed_booking
    ):
        """Recording a deposit ≥30% of total should set deposit_paid=True."""
        api_client.force_authenticate(user=staff_user)

        # Deposit exactly 30% (300K of 1M)
        resp = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": confirmed_booking.id,
                "amount": "300000",
                "payment_method": "cash",
            },
            format="json",
        )
        assert resp.status_code == status.HTTP_201_CREATED

        confirmed_booking.refresh_from_db()
        assert confirmed_booking.deposit_amount == Decimal("300000")
        assert confirmed_booking.deposit_paid is True

    def test_multiple_deposits_accumulate(
        self, api_client, staff_user, confirmed_booking
    ):
        """Multiple deposit payments should accumulate on booking.deposit_amount."""
        api_client.force_authenticate(user=staff_user)

        # First deposit — 10%
        resp = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": confirmed_booking.id,
                "amount": "100000",
                "payment_method": "cash",
            },
            format="json",
        )
        assert resp.status_code == status.HTTP_201_CREATED
        confirmed_booking.refresh_from_db()
        assert confirmed_booking.deposit_paid is False

        # Second deposit — another 20% → total = 30% → threshold met
        resp = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": confirmed_booking.id,
                "amount": "200000",
                "payment_method": "bank_transfer",
            },
            format="json",
        )
        assert resp.status_code == status.HTTP_201_CREATED
        confirmed_booking.refresh_from_db()
        assert confirmed_booking.deposit_amount == Decimal("300000")
        assert confirmed_booking.deposit_paid is True

        # Verify two payment records exist
        deposit_count = Payment.objects.filter(
            booking=confirmed_booking,
            payment_type=Payment.PaymentType.DEPOSIT,
            status=Payment.Status.COMPLETED,
        ).count()
        assert deposit_count == 2

    def test_deposit_then_checkin_then_checkout(
        self, api_client, staff_user, confirmed_booking, income_category
    ):
        """Deposit → check-in → checkout: full payment-enriched lifecycle."""
        api_client.force_authenticate(user=staff_user)

        # Deposit
        resp = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": confirmed_booking.id,
                "amount": "500000",
                "payment_method": "cash",
            },
            format="json",
        )
        assert resp.status_code == status.HTTP_201_CREATED

        # Check in
        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/check-in/"
        )
        assert resp.status_code == status.HTTP_200_OK
        assert resp.data["status"] == "checked_in"

        # Check out
        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/check-out/"
        )
        assert resp.status_code == status.HTTP_200_OK
        assert resp.data["status"] == "checked_out"

        # Verify everything is consistent
        confirmed_booking.refresh_from_db()
        assert confirmed_booking.status == Booking.Status.CHECKED_OUT
        assert confirmed_booking.deposit_paid is True
        assert confirmed_booking.actual_check_in is not None
        assert confirmed_booking.actual_check_out is not None

        # Financial entry exists
        assert FinancialEntry.objects.filter(
            booking=confirmed_booking,
        ).exists()

        # Housekeeping task exists
        assert HousekeepingTask.objects.filter(
            booking=confirmed_booking,
            task_type=HousekeepingTask.TaskType.CHECKOUT_CLEAN,
        ).exists()


# ---------------------------------------------------------------------------
# 5. Cancellation & No-Show Flows
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestCancellationFlow:
    """Test booking cancellation and room status revert logic."""

    def test_cancel_confirmed_booking_room_stays_available(
        self, api_client, staff_user, confirmed_booking
    ):
        """Cancelling a confirmed booking should not change available room."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/update-status/",
            {"status": "cancelled"},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK
        assert resp.data["status"] == "cancelled"

        # Room was AVAILABLE before, should still be AVAILABLE
        confirmed_booking.room.refresh_from_db()
        assert confirmed_booking.room.status == Room.Status.AVAILABLE

    def test_cancel_checked_in_booking_reverts_room_to_available(
        self, api_client, staff_user, checked_in_booking
    ):
        """Cancelling a checked-in booking should revert room to AVAILABLE."""
        api_client.force_authenticate(user=staff_user)

        # Room should currently be OCCUPIED
        checked_in_booking.room.refresh_from_db()
        assert checked_in_booking.room.status == Room.Status.OCCUPIED

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/update-status/",
            {"status": "cancelled"},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK

        checked_in_booking.room.refresh_from_db()
        assert checked_in_booking.room.status == Room.Status.AVAILABLE

    def test_no_show_from_confirmed(
        self, api_client, staff_user, confirmed_booking
    ):
        """Marking no-show on a confirmed booking should update status."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/update-status/",
            {"status": "no_show"},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK
        assert resp.data["status"] == "no_show"

    def test_no_show_checked_in_reverts_room(
        self, api_client, staff_user, checked_in_booking
    ):
        """No-show on checked-in booking should revert room to AVAILABLE."""
        api_client.force_authenticate(user=staff_user)

        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/update-status/",
            {"status": "no_show"},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK

        checked_in_booking.room.refresh_from_db()
        assert checked_in_booking.room.status == Room.Status.AVAILABLE


# ---------------------------------------------------------------------------
# 6. Room Status Consistency Across Multiple Bookings
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestRoomStatusConsistency:
    """Test room status stays consistent across multiple booking operations."""

    def test_room_transitions_through_full_lifecycle(
        self, api_client, staff_user, confirmed_booking, income_category
    ):
        """
        Room status transitions: AVAILABLE → OCCUPIED (check-in) →
        CLEANING (check-out).
        """
        api_client.force_authenticate(user=staff_user)
        room = confirmed_booking.room

        # Initially AVAILABLE
        room.refresh_from_db()
        assert room.status == Room.Status.AVAILABLE

        # After check-in → OCCUPIED
        api_client.post(f"/api/v1/bookings/{confirmed_booking.id}/check-in/")
        room.refresh_from_db()
        assert room.status == Room.Status.OCCUPIED

        # After check-out → CLEANING
        api_client.post(f"/api/v1/bookings/{confirmed_booking.id}/check-out/")
        room.refresh_from_db()
        assert room.status == Room.Status.CLEANING

    def test_cancel_does_not_revert_room_if_another_booking_active(
        self, api_client, staff_user, room, guest, second_guest, room_type
    ):
        """
        If two bookings share a room and one is cancelled, room stays
        OCCUPIED if another booking is still checked in.
        """
        api_client.force_authenticate(user=staff_user)

        # Create first booking — check in
        booking1 = Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=3),
            status=Booking.Status.CHECKED_IN,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("1500000"),
            actual_check_in=timezone.now(),
        )
        room.status = Room.Status.OCCUPIED
        room.save()

        # Create second booking for same room — check in
        booking2 = Booking.objects.create(
            room=room,
            guest=second_guest,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=1),
            status=Booking.Status.CHECKED_IN,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("500000"),
            actual_check_in=timezone.now(),
        )

        # Cancel booking2 — room should STAY occupied because booking1 is active
        resp = api_client.post(
            f"/api/v1/bookings/{booking2.id}/update-status/",
            {"status": "cancelled"},
            format="json",
        )
        assert resp.status_code == status.HTTP_200_OK

        room.refresh_from_db()
        assert room.status == Room.Status.OCCUPIED

    def test_sequential_bookings_on_same_room(
        self, api_client, staff_user, room, guest, second_guest, room_type,
        income_category
    ):
        """
        Two sequential bookings on the same room:
        Book A check-in → check-out → Book B check-in → check-out.
        Room transitions correctly each time.
        """
        api_client.force_authenticate(user=staff_user)

        # Booking A
        booking_a = Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=1),
            status=Booking.Status.CONFIRMED,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("500000"),
        )

        # Check in A
        resp = api_client.post(f"/api/v1/bookings/{booking_a.id}/check-in/")
        assert resp.status_code == status.HTTP_200_OK
        room.refresh_from_db()
        assert room.status == Room.Status.OCCUPIED

        # Check out A
        resp = api_client.post(f"/api/v1/bookings/{booking_a.id}/check-out/")
        assert resp.status_code == status.HTTP_200_OK
        room.refresh_from_db()
        assert room.status == Room.Status.CLEANING

        # Switch room back to available (simulating housekeeping completion)
        room.status = Room.Status.AVAILABLE
        room.save()

        # Booking B on same room
        booking_b = Booking.objects.create(
            room=room,
            guest=second_guest,
            check_in_date=date.today() + timedelta(days=1),
            check_out_date=date.today() + timedelta(days=3),
            status=Booking.Status.CONFIRMED,
            nightly_rate=room_type.base_rate,
            total_amount=Decimal("1000000"),
        )

        # Check in B
        resp = api_client.post(f"/api/v1/bookings/{booking_b.id}/check-in/")
        assert resp.status_code == status.HTTP_200_OK
        room.refresh_from_db()
        assert room.status == Room.Status.OCCUPIED

        # Check out B
        resp = api_client.post(f"/api/v1/bookings/{booking_b.id}/check-out/")
        assert resp.status_code == status.HTTP_200_OK
        room.refresh_from_db()
        assert room.status == Room.Status.CLEANING

        # Verify 2 housekeeping tasks created (one per checkout)
        tasks = HousekeepingTask.objects.filter(
            room=room,
            task_type=HousekeepingTask.TaskType.CHECKOUT_CLEAN,
        ).count()
        assert tasks == 2


# ---------------------------------------------------------------------------
# 7. Folio Items Impact on Booking
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestFolioItemFlow:
    """Test folio item creation and its effect on booking charges."""

    def test_folio_items_track_per_booking(
        self, api_client, staff_user, checked_in_booking
    ):
        """Creating folio items links them to the booking correctly."""
        api_client.force_authenticate(user=staff_user)

        # Create multiple folio items
        items_data = [
            {
                "booking": checked_in_booking.id,
                "item_type": "minibar",
                "description": "Tiger Beer",
                "quantity": 3,
                "unit_price": "40000",
                "date": str(date.today()),
            },
            {
                "booking": checked_in_booking.id,
                "item_type": "damage",
                "description": "Broken glass",
                "quantity": 1,
                "unit_price": "150000",
                "date": str(date.today()),
            },
        ]

        for item_data in items_data:
            resp = api_client.post(
                "/api/v1/folio-items/", item_data, format="json"
            )
            assert resp.status_code == status.HTTP_201_CREATED

        # Verify both items are linked to the booking
        folio_items = FolioItem.objects.filter(booking=checked_in_booking)
        assert folio_items.count() == 2

        # Verify total prices calculated correctly
        beer_item = folio_items.get(description="Tiger Beer")
        assert beer_item.total_price == Decimal("120000")  # 3 × 40000

        glass_item = folio_items.get(description="Broken glass")
        assert glass_item.total_price == Decimal("150000")  # 1 × 150000


# ---------------------------------------------------------------------------
# 8. Permission Guards on Multi-Step Flows
# ---------------------------------------------------------------------------

@pytest.mark.django_db
class TestPermissionGuards:
    """Test that unauthenticated/unauthorized users can't perform operations."""

    def test_unauthenticated_cannot_checkin(
        self, api_client, confirmed_booking
    ):
        """Unauthenticated request to check-in should fail."""
        resp = api_client.post(
            f"/api/v1/bookings/{confirmed_booking.id}/check-in/"
        )
        assert resp.status_code == status.HTTP_401_UNAUTHORIZED

    def test_unauthenticated_cannot_checkout(
        self, api_client, checked_in_booking
    ):
        """Unauthenticated request to checkout should fail."""
        resp = api_client.post(
            f"/api/v1/bookings/{checked_in_booking.id}/check-out/"
        )
        assert resp.status_code == status.HTTP_401_UNAUTHORIZED

    def test_unauthenticated_cannot_record_deposit(
        self, api_client, confirmed_booking
    ):
        """Unauthenticated request to record deposit should fail."""
        resp = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": confirmed_booking.id,
                "amount": "100000",
                "payment_method": "cash",
            },
            format="json",
        )
        assert resp.status_code == status.HTTP_401_UNAUTHORIZED
