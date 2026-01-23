"""
Tests for Financial Management endpoints.
"""

from datetime import date, timedelta
from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import (
    Booking,
    FinancialCategory,
    FinancialEntry,
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
    )


@pytest.fixture
def booking(room, guest):
    """Create a booking."""
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        status=Booking.Status.CHECKED_IN,
        nightly_rate=Decimal("500000"),
        total_amount=Decimal("1000000"),
    )


@pytest.fixture
def financial_entries(income_category, expense_category, staff_user, booking):
    """Create test financial entries."""
    today = date.today()
    entries = []

    # Income entry today
    entries.append(
        FinancialEntry.objects.create(
            entry_type=FinancialEntry.EntryType.INCOME,
            category=income_category,
            amount=Decimal("500000"),
            date=today,
            description="Tiền phòng 101",
            booking=booking,
            payment_method=Booking.PaymentMethod.CASH,
            created_by=staff_user,
        )
    )

    # Expense entry today
    entries.append(
        FinancialEntry.objects.create(
            entry_type=FinancialEntry.EntryType.EXPENSE,
            category=expense_category,
            amount=Decimal("100000"),
            date=today,
            description="Tiền điện tháng 1",
            payment_method=Booking.PaymentMethod.BANK_TRANSFER,
            created_by=staff_user,
        )
    )

    # Income entry yesterday
    entries.append(
        FinancialEntry.objects.create(
            entry_type=FinancialEntry.EntryType.INCOME,
            category=income_category,
            amount=Decimal("600000"),
            date=today - timedelta(days=1),
            description="Tiền phòng 102",
            payment_method=Booking.PaymentMethod.CASH,
            created_by=staff_user,
        )
    )

    return entries


@pytest.mark.django_db
class TestFinancialCategoryViewSet:
    """Tests for FinancialCategory API endpoints."""

    def test_list_categories_unauthenticated(self, api_client):
        """Test listing categories requires authentication."""
        response = api_client.get("/api/v1/finance/categories/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_categories_as_staff(self, api_client, staff_user, income_category, expense_category):
        """Test staff can list categories."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/finance/categories/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()["results"]) == 2

    def test_filter_categories_by_type(self, api_client, staff_user, income_category, expense_category):
        """Test filtering categories by type."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/finance/categories/?category_type=income")

        assert response.status_code == status.HTTP_200_OK
        results = response.json()["results"]
        assert len(results) == 1
        assert results[0]["category_type"] == "income"

    def test_create_category_as_staff_fails(self, api_client, staff_user):
        """Test staff cannot create categories."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/finance/categories/",
            {
                "name": "Minibar",
                "name_en": "Minibar",
                "category_type": "income",
            },
        )

        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_create_category_as_manager(self, api_client, manager_user):
        """Test manager can create categories."""
        api_client.force_authenticate(user=manager_user)
        response = api_client.post(
            "/api/v1/finance/categories/",
            {
                "name": "Minibar",
                "name_en": "Minibar",
                "category_type": "income",
                "icon": "local_bar",
                "color": "#FF9800",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["name"] == "Minibar"

    def test_retrieve_category(self, api_client, staff_user, income_category):
        """Test retrieving a single category."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get(f"/api/v1/finance/categories/{income_category.id}/")

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["name"] == "Tiền phòng"


@pytest.mark.django_db
class TestFinancialEntryViewSet:
    """Tests for FinancialEntry API endpoints."""

    def test_list_entries_unauthenticated(self, api_client):
        """Test listing entries requires authentication."""
        response = api_client.get("/api/v1/finance/entries/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_entries_as_staff(self, api_client, staff_user, financial_entries):
        """Test staff can list entries."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/finance/entries/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.json()["results"]) == 3

    def test_filter_entries_by_type(self, api_client, staff_user, financial_entries):
        """Test filtering entries by type."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/finance/entries/?entry_type=income")

        assert response.status_code == status.HTTP_200_OK
        results = response.json()["results"]
        assert len(results) == 2
        assert all(e["entry_type"] == "income" for e in results)

    def test_filter_entries_by_date(self, api_client, staff_user, financial_entries):
        """Test filtering entries by date range."""
        api_client.force_authenticate(user=staff_user)
        today = date.today()
        response = api_client.get(f"/api/v1/finance/entries/?date_from={today}&date_to={today}")

        assert response.status_code == status.HTTP_200_OK
        # Should only include entries from today (2 entries)
        assert len(response.json()["results"]) == 2

    def test_create_income_entry(self, api_client, staff_user, income_category):
        """Test creating an income entry."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/finance/entries/",
            {
                "entry_type": "income",
                "category": income_category.id,
                "amount": "800000",
                "date": date.today().isoformat(),
                "description": "Tiền phòng 201",
                "payment_method": "cash",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["amount"] == "800000"
        assert response.json()["created_by"] == staff_user.id

    def test_create_expense_entry(self, api_client, staff_user, expense_category):
        """Test creating an expense entry."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/finance/entries/",
            {
                "entry_type": "expense",
                "category": expense_category.id,
                "amount": "50000",
                "date": date.today().isoformat(),
                "description": "Vật tư vệ sinh",
                "payment_method": "cash",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["entry_type"] == "expense"

    def test_create_entry_mismatched_category(self, api_client, staff_user, expense_category):
        """Test creating entry with mismatched category type fails."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.post(
            "/api/v1/finance/entries/",
            {
                "entry_type": "income",  # Trying to use expense category for income
                "category": expense_category.id,
                "amount": "100000",
                "date": date.today().isoformat(),
                "description": "Test",
                "payment_method": "cash",
            },
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "category" in response.json()

    def test_daily_summary(self, api_client, staff_user, financial_entries):
        """Test daily summary endpoint."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/finance/entries/daily-summary/")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert data["date"] == date.today().isoformat()
        assert data["total_income"] == 500000  # Only today's income
        assert data["total_expense"] == 100000  # Only today's expense
        assert data["net_profit"] == 400000
        assert data["income_entries"] == 1
        assert data["expense_entries"] == 1

    def test_daily_summary_with_date(self, api_client, staff_user, financial_entries):
        """Test daily summary for specific date."""
        api_client.force_authenticate(user=staff_user)
        yesterday = date.today() - timedelta(days=1)
        response = api_client.get(f"/api/v1/finance/entries/daily-summary/?date={yesterday}")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert data["date"] == yesterday.isoformat()
        assert data["total_income"] == 600000  # Yesterday's income
        assert data["total_expense"] == 0  # No expense yesterday

    def test_monthly_summary(self, api_client, staff_user, financial_entries):
        """Test monthly summary endpoint."""
        api_client.force_authenticate(user=staff_user)
        today = date.today()
        response = api_client.get(
            f"/api/v1/finance/entries/monthly-summary/?year={today.year}&month={today.month}"
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert data["year"] == today.year
        assert data["month"] == today.month
        assert data["total_income"] == 1100000  # All income entries
        assert data["total_expense"] == 100000
        assert data["net_profit"] == 1000000
        assert len(data["income_by_category"]) == 1
        assert len(data["expense_by_category"]) == 1

    def test_monthly_summary_invalid_month(self, api_client, staff_user):
        """Test monthly summary with invalid month."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/finance/entries/monthly-summary/?month=13")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_update_entry_as_staff_fails(self, api_client, staff_user, financial_entries):
        """Test staff cannot update entries."""
        api_client.force_authenticate(user=staff_user)
        entry = financial_entries[0]
        response = api_client.patch(
            f"/api/v1/finance/entries/{entry.id}/",
            {"amount": "999999"},
        )

        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_update_entry_as_manager(self, api_client, manager_user, financial_entries, income_category):
        """Test manager can update entries."""
        api_client.force_authenticate(user=manager_user)
        entry = financial_entries[0]
        response = api_client.patch(
            f"/api/v1/finance/entries/{entry.id}/",
            {"amount": "999999"},
        )

        assert response.status_code == status.HTTP_200_OK
        assert response.json()["amount"] == "999999"

    def test_delete_entry_as_manager(self, api_client, manager_user, financial_entries):
        """Test manager can delete entries."""
        api_client.force_authenticate(user=manager_user)
        entry = financial_entries[0]
        response = api_client.delete(f"/api/v1/finance/entries/{entry.id}/")

        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not FinancialEntry.objects.filter(id=entry.id).exists()
