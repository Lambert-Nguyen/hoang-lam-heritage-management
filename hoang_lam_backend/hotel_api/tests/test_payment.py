"""Tests for Payment, FolioItem, and ExchangeRate API endpoints."""

from datetime import date, timedelta
from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import (
    Booking,
    ExchangeRate,
    FolioItem,
    Guest,
    HotelUser,
    Payment,
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
    return create_user("manager123", "manager")


@pytest.fixture
def staff_user(create_user):
    """Create staff user."""
    return create_user("staff1234", "staff")


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
    """Create a guest."""
    return Guest.objects.create(
        full_name="Nguyễn Văn A",
        phone="0901234567",
        nationality="Vietnam",
        id_number="123456789012",
    )


@pytest.fixture
def booking(room, guest, room_type):
    """Create a booking."""
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
    )


@pytest.fixture
def payment(booking, staff_user):
    """Create a payment."""
    return Payment.objects.create(
        booking=booking,
        payment_type=Payment.PaymentType.DEPOSIT,
        amount=Decimal("300000"),
        payment_method=Booking.PaymentMethod.CASH,
        status=Payment.Status.COMPLETED,
        created_by=staff_user,
    )


@pytest.fixture
def folio_item(booking, staff_user):
    """Create a folio item."""
    return FolioItem.objects.create(
        booking=booking,
        item_type=FolioItem.ItemType.MINIBAR,
        description="Nước ngọt",
        quantity=2,
        unit_price=Decimal("30000"),
        date=date.today(),
        created_by=staff_user,
    )


@pytest.fixture
def exchange_rate(db):
    """Create an exchange rate."""
    return ExchangeRate.objects.create(
        from_currency="USD",
        to_currency="VND",
        rate=Decimal("24500.00"),
        date=date.today(),
        source="manual",
    )


# ============================================================
# Payment ViewSet Tests
# ============================================================


@pytest.mark.django_db
class TestPaymentViewSet:
    """Tests for Payment API endpoints."""

    def test_list_payments_unauthenticated(self, api_client):
        """Test listing payments requires authentication."""
        response = api_client.get("/api/v1/payments/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_payments_as_staff(self, api_client, staff_user, payment):
        """Test staff can list payments."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/payments/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()["results"]) == 1

    def test_create_payment(self, api_client, staff_user, booking):
        """Test creating a payment."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/payments/",
            {
                "booking": booking.id,
                "payment_type": "deposit",
                "amount": "500000",
                "payment_method": "cash",
                "description": "Đặt cọc phòng",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["amount"] == "500000"
        assert response.json()["payment_type"] == "deposit"

    def test_filter_payments_by_booking(self, api_client, staff_user, payment, booking):
        """Test filtering payments by booking."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/payments/?booking={booking.id}")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()["results"]) == 1

    def test_filter_payments_by_type(self, api_client, staff_user, payment):
        """Test filtering payments by type."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/payments/?payment_type=deposit")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()["results"]) == 1

    def test_record_deposit(self, api_client, staff_user, booking):
        """Test recording a deposit payment."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": booking.id,
                "amount": "300000",
                "payment_method": "cash",
                "notes": "Đặt cọc 30%",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["payment_type"] == "deposit"
        assert response.json()["amount"] == "300000"

        # Check booking deposit updated
        booking.refresh_from_db()
        assert booking.deposit_amount == Decimal("300000")
        assert booking.deposit_paid is True  # 30% threshold met

    def test_record_deposit_for_cancelled_booking(self, api_client, staff_user, booking):
        """Test cannot record deposit for cancelled booking."""
        booking.status = Booking.Status.CANCELLED
        booking.save()

        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/payments/record-deposit/",
            {
                "booking_id": booking.id,
                "amount": "300000",
                "payment_method": "cash",
            },
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_booking_deposits(self, api_client, staff_user, payment, booking):
        """Test getting deposits for a booking."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/payments/booking/{booking.id}/deposits/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()) == 1

    def test_outstanding_deposits(self, api_client, staff_user, booking):
        """Test getting outstanding deposits report."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/payments/outstanding-deposits/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()) == 1
        assert response.json()[0]["id"] == booking.id


# ============================================================
# FolioItem ViewSet Tests
# ============================================================


@pytest.mark.django_db
class TestFolioItemViewSet:
    """Tests for FolioItem API endpoints."""

    def test_list_folio_items_unauthenticated(self, api_client):
        """Test listing folio items requires authentication."""
        response = api_client.get("/api/v1/folio-items/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_folio_items_as_staff(self, api_client, staff_user, folio_item):
        """Test staff can list folio items."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/folio-items/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()["results"]) == 1

    def test_create_folio_item(self, api_client, staff_user, booking):
        """Test creating a folio item."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/folio-items/",
            {
                "booking": booking.id,
                "item_type": "minibar",
                "description": "Coca cola",
                "quantity": 2,
                "unit_price": "25000",
                "date": date.today().isoformat(),
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["total_price"] == "50000"

    def test_void_folio_item(self, api_client, staff_user, folio_item):
        """Test voiding a folio item."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            f"/api/v1/folio-items/{folio_item.id}/void/",
            {"reason": "Khách trả lại"},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["is_voided"] is True

    def test_void_paid_folio_item_fails(self, api_client, staff_user, folio_item):
        """Test cannot void a paid folio item."""
        folio_item.is_paid = True
        folio_item.save()

        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            f"/api/v1/folio-items/{folio_item.id}/void/",
            {"reason": "Test"},
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_booking_folio(self, api_client, staff_user, folio_item, booking):
        """Test getting all folio items for a booking."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/folio-items/booking/{booking.id}/")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert len(data["items"]) == 1
        assert data["summary"]["total"] == 60000  # 2 x 30000


# ============================================================
# ExchangeRate ViewSet Tests
# ============================================================


@pytest.mark.django_db
class TestExchangeRateViewSet:
    """Tests for ExchangeRate API endpoints."""

    def test_list_exchange_rates_unauthenticated(self, api_client):
        """Test listing exchange rates requires authentication."""
        response = api_client.get("/api/v1/exchange-rates/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_exchange_rates(self, api_client, staff_user, exchange_rate):
        """Test listing exchange rates."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/exchange-rates/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()["results"]) == 1

    def test_create_exchange_rate(self, api_client, staff_user):
        """Test creating an exchange rate."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/exchange-rates/",
            {
                "from_currency": "EUR",
                "to_currency": "VND",
                "rate": "27000.00",
                "date": date.today().isoformat(),
                "source": "manual",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["from_currency"] == "EUR"

    def test_create_duplicate_rate_fails(self, api_client, staff_user, exchange_rate):
        """Test creating duplicate exchange rate fails."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/exchange-rates/",
            {
                "from_currency": "USD",
                "to_currency": "VND",
                "rate": "25000.00",
                "date": date.today().isoformat(),
                "source": "manual",
            },
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_latest_rates(self, api_client, staff_user, exchange_rate):
        """Test getting latest exchange rates."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/exchange-rates/latest/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()) == 1
        assert response.json()[0]["from_currency"] == "USD"

    def test_convert_currency(self, api_client, staff_user, exchange_rate):
        """Test currency conversion."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/exchange-rates/convert/",
            {
                "amount": "100",
                "from_currency": "USD",
                "to_currency": "VND",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert float(data["original_amount"]) == 100.0
        assert float(data["converted_amount"]) == 2450000.00  # 100 * 24500

    def test_convert_same_currency(self, api_client, staff_user):
        """Test converting same currency returns same amount."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/exchange-rates/convert/",
            {
                "amount": "100000",
                "from_currency": "VND",
                "to_currency": "VND",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        assert float(response.json()["converted_amount"]) == 100000.0

    def test_convert_unknown_currency(self, api_client, staff_user):
        """Test converting unknown currency returns error."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/exchange-rates/convert/",
            {
                "amount": "100",
                "from_currency": "JPY",
                "to_currency": "VND",
            },
        )

        assert response.status_code == status.HTTP_404_NOT_FOUND


# ============================================================
# Receipt ViewSet Tests
# ============================================================


@pytest.mark.django_db
class TestReceiptViewSet:
    """Tests for Receipt API endpoints."""

    def test_generate_receipt_unauthenticated(self, api_client):
        """Test generating receipt requires authentication."""
        response = api_client.post("/api/v1/receipts/generate/", {"booking_id": 1})
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_generate_receipt_for_booking(self, api_client, staff_user, booking):
        """Test generating receipt for a booking."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/receipts/generate/",
            {"booking_id": booking.id, "include_folio": True},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["room_number"] == "101"
        assert data["guest_name"] == "Nguyễn Văn A"
        assert "receipt_number" in data

    def test_generate_receipt_missing_params(self, api_client, staff_user):
        """Test generating receipt without booking or payment fails."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post("/api/v1/receipts/generate/", {})

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_download_receipt_not_found(self, api_client, staff_user):
        """Test downloading receipt for non-existent booking."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/receipts/download/999/")

        assert response.status_code == status.HTTP_404_NOT_FOUND
