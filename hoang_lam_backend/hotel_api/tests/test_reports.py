"""
Tests for Phase 4: Reports & Analytics endpoints.
"""

from datetime import date, timedelta
from decimal import Decimal

from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import (
    Booking,
    FinancialCategory,
    FinancialEntry,
    Guest,
    MinibarItem,
    MinibarSale,
    Room,
    RoomType,
)


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def user(db):
    return User.objects.create_user(
        username="testuser", password="testpass123", email="test@example.com"
    )


@pytest.fixture
def authenticated_client(api_client, user):
    api_client.force_authenticate(user=user)
    return api_client


@pytest.fixture
def room_type(db):
    return RoomType.objects.create(
        name="Phòng Đôi",
        name_en="Double Room",
        base_rate=500000,
        max_guests=2,
    )


@pytest.fixture
def rooms(db, room_type):
    rooms = []
    for i in range(1, 8):  # 7 rooms
        rooms.append(
            Room.objects.create(
                number=f"10{i}",
                room_type=room_type,
                floor=1,
                status="available",
            )
        )
    return rooms


@pytest.fixture
def guests(db):
    guests = []
    nationalities = ["Vietnam", "USA", "Japan", "Korea", "France"]
    for i, nat in enumerate(nationalities):
        guests.append(
            Guest.objects.create(
                full_name=f"Guest {i+1}",
                phone=f"090000000{i}",
                nationality=nat,
            )
        )
    return guests


@pytest.fixture
def bookings(db, rooms, guests, user):
    today = timezone.now().date()
    bookings = []
    sources = ["walk_in", "booking_com", "agoda", "phone", "walk_in"]

    for i, (room, guest, source) in enumerate(zip(rooms[:5], guests, sources)):
        check_in = today - timedelta(days=5 - i)
        check_out = check_in + timedelta(days=2)
        booking = Booking.objects.create(
            room=room,
            guest=guest,
            check_in_date=check_in,
            check_out_date=check_out,
            status="checked_out" if check_out <= today else "checked_in",
            source=source,
            nightly_rate=500000,
            total_amount=1000000,
            created_by=user,
        )
        bookings.append(booking)
    return bookings


@pytest.fixture
def income_category(db):
    return FinancialCategory.objects.create(
        name="Tiền phòng",
        name_en="Room Revenue",
        category_type="income",
        icon="hotel",
    )


@pytest.fixture
def expense_categories(db):
    categories = []
    expense_types = [
        ("Tiền điện", "Electricity", "bolt", "#FFC107"),
        ("Tiền nước", "Water", "water_drop", "#2196F3"),
        ("Vật tư", "Supplies", "inventory", "#4CAF50"),
    ]
    for name, name_en, icon, color in expense_types:
        categories.append(
            FinancialCategory.objects.create(
                name=name,
                name_en=name_en,
                category_type="expense",
                icon=icon,
                color=color,
            )
        )
    return categories


@pytest.fixture
def financial_entries(db, income_category, expense_categories, bookings, user):
    today = timezone.now().date()
    entries = []

    # Income entries linked to bookings
    for booking in bookings[:3]:
        entries.append(
            FinancialEntry.objects.create(
                entry_type="income",
                category=income_category,
                amount=1000000,
                date=booking.check_out_date,
                description=f"Room payment - {booking.room.number}",
                booking=booking,
                created_by=user,
            )
        )

    # Expense entries
    for i, cat in enumerate(expense_categories):
        entries.append(
            FinancialEntry.objects.create(
                entry_type="expense",
                category=cat,
                amount=(i + 1) * 100000,  # 100k, 200k, 300k
                date=today - timedelta(days=i),
                description=f"Payment for {cat.name}",
                created_by=user,
            )
        )

    return entries


@pytest.fixture
def minibar_items(db):
    items = []
    for i, name in enumerate(["Coca Cola", "Snickers", "Water"]):
        items.append(
            MinibarItem.objects.create(
                name=name,
                price=(i + 1) * 20000,
                cost=(i + 1) * 10000,
                category="beverage" if i != 1 else "snack",
            )
        )
    return items


@pytest.fixture
def minibar_sales(db, minibar_items, bookings, user):
    today = timezone.now().date()
    sales = []
    for booking in bookings[:2]:
        for item in minibar_items[:2]:
            sales.append(
                MinibarSale.objects.create(
                    booking=booking,
                    item=item,
                    quantity=2,
                    unit_price=item.price,
                    total=item.price * 2,
                    date=today - timedelta(days=1),
                    created_by=user,
                )
            )
    return sales


# ============================================================================
# OCCUPANCY REPORT TESTS
# ============================================================================


@pytest.mark.django_db
class TestOccupancyReport:
    """Tests for occupancy report endpoint."""

    def test_occupancy_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_occupancy")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_occupancy_report_missing_dates(self, authenticated_client):
        """Test that missing date parameters return error."""
        url = reverse("report_occupancy")
        response = authenticated_client.get(url)
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_occupancy_report_invalid_dates(self, authenticated_client):
        """Test that end_date before start_date returns error."""
        url = reverse("report_occupancy")
        response = authenticated_client.get(
            url,
            {
                "start_date": "2024-01-10",
                "end_date": "2024-01-05",
            },
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_occupancy_report_daily(self, authenticated_client, rooms, bookings):
        """Test daily occupancy report."""
        today = timezone.now().date()
        url = reverse("report_occupancy")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=5)).isoformat(),
                "end_date": today.isoformat(),
                "group_by": "day",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "summary" in data
        assert "data" in data
        assert data["summary"]["total_rooms"] == 7
        assert len(data["data"]) == 6  # 6 days

    def test_occupancy_report_weekly(self, authenticated_client, rooms, bookings):
        """Test weekly grouped occupancy report."""
        today = timezone.now().date()
        url = reverse("report_occupancy")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=14)).isoformat(),
                "end_date": today.isoformat(),
                "group_by": "week",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "summary" in data
        assert "data" in data
        # Weekly grouping should have fewer entries
        assert len(data["data"]) <= 3

    def test_occupancy_report_monthly(self, authenticated_client, rooms, bookings):
        """Test monthly grouped occupancy report."""
        today = timezone.now().date()
        url = reverse("report_occupancy")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=60)).isoformat(),
                "end_date": today.isoformat(),
                "group_by": "month",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "summary" in data
        assert "data" in data
        assert len(data["data"]) <= 3  # Max 3 months

    def test_occupancy_report_no_rooms(self, authenticated_client):
        """Test occupancy report with no rooms."""
        today = timezone.now().date()
        url = reverse("report_occupancy")
        response = authenticated_client.get(
            url,
            {
                "start_date": today.isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["summary"]["total_rooms"] == 0


# ============================================================================
# REVENUE REPORT TESTS
# ============================================================================


@pytest.mark.django_db
class TestRevenueReport:
    """Tests for revenue report endpoint."""

    def test_revenue_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_revenue")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_revenue_report_daily(self, authenticated_client, financial_entries, minibar_sales):
        """Test daily revenue report."""
        today = timezone.now().date()
        url = reverse("report_revenue")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
                "group_by": "day",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "summary" in data
        assert "data" in data
        assert data["summary"]["total_revenue"] >= 0
        assert data["summary"]["total_expenses"] >= 0

    def test_revenue_report_includes_minibar(
        self, authenticated_client, financial_entries, minibar_sales
    ):
        """Test that revenue report includes minibar sales."""
        today = timezone.now().date()
        url = reverse("report_revenue")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        # Should have minibar revenue
        assert data["summary"]["minibar_revenue"] > 0

    def test_revenue_report_profit_margin(self, authenticated_client, financial_entries):
        """Test that profit margin is calculated correctly."""
        today = timezone.now().date()
        url = reverse("report_revenue")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        # Verify profit margin calculation
        total = data["summary"]["total_revenue"]
        net = data["summary"]["net_profit"]
        if total > 0:
            expected_margin = round((net / total) * 100, 2)
            assert data["summary"]["profit_margin"] == expected_margin


# ============================================================================
# KPI REPORT TESTS
# ============================================================================


@pytest.mark.django_db
class TestKPIReport:
    """Tests for KPI report endpoint."""

    def test_kpi_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_kpi")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_kpi_report_basic(self, authenticated_client, rooms, bookings, financial_entries):
        """Test basic KPI report."""
        today = timezone.now().date()
        url = reverse("report_kpi")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "current" in data
        current = data["current"]
        assert "revpar" in current
        assert "adr" in current
        assert "occupancy_rate" in current
        assert "total_room_nights_available" in current

    def test_kpi_report_with_comparison(
        self, authenticated_client, rooms, bookings, financial_entries
    ):
        """Test KPI report with previous period comparison."""
        today = timezone.now().date()
        url = reverse("report_kpi")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
                "compare_previous": "true",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "current" in data
        assert "previous" in data
        assert "changes" in data

    def test_kpi_revpar_calculation(self, authenticated_client, rooms, bookings, financial_entries):
        """Test RevPAR is calculated correctly."""
        today = timezone.now().date()
        url = reverse("report_kpi")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
                "compare_previous": "false",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        current = data["current"]
        # RevPAR = Room Revenue / Available Room Nights
        # Verify the calculation makes sense
        assert current["revpar"] >= 0
        assert current["total_room_nights_available"] > 0


# ============================================================================
# EXPENSE REPORT TESTS
# ============================================================================


@pytest.mark.django_db
class TestExpenseReport:
    """Tests for expense breakdown report endpoint."""

    def test_expense_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_expenses")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_expense_report_by_category(
        self, authenticated_client, financial_entries, expense_categories
    ):
        """Test expense breakdown by category."""
        today = timezone.now().date()
        url = reverse("report_expenses")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "summary" in data
        assert "data" in data
        assert data["summary"]["total_expenses"] == 600000  # 100k + 200k + 300k
        assert len(data["data"]) == 3  # 3 expense categories

    def test_expense_report_percentages(self, authenticated_client, financial_entries):
        """Test that category percentages sum to 100."""
        today = timezone.now().date()
        url = reverse("report_expenses")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=7)).isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        if data["data"]:
            total_percentage = sum(item["percentage"] for item in data["data"])
            assert abs(total_percentage - 100) < 0.1  # Allow for rounding


# ============================================================================
# CHANNEL PERFORMANCE TESTS
# ============================================================================


@pytest.mark.django_db
class TestChannelPerformance:
    """Tests for channel performance report endpoint."""

    def test_channel_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_channels")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_channel_performance_report(self, authenticated_client, bookings):
        """Test channel performance report."""
        today = timezone.now().date()
        url = reverse("report_channels")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=10)).isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "summary" in data
        assert "data" in data
        assert data["summary"]["total_bookings"] > 0

    def test_channel_performance_by_source(self, authenticated_client, bookings):
        """Test channel data is grouped by source."""
        today = timezone.now().date()
        url = reverse("report_channels")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=10)).isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        # Should have multiple sources
        sources = [item["source"] for item in data["data"]]
        assert "walk_in" in sources or "booking_com" in sources


# ============================================================================
# GUEST DEMOGRAPHICS TESTS
# ============================================================================


@pytest.mark.django_db
class TestGuestDemographics:
    """Tests for guest demographics report endpoint."""

    def test_demographics_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_demographics")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_demographics_by_nationality(self, authenticated_client, bookings, guests):
        """Test demographics grouped by nationality."""
        today = timezone.now().date()
        url = reverse("report_demographics")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=10)).isoformat(),
                "end_date": today.isoformat(),
                "group_by": "nationality",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "summary" in data
        assert "data" in data
        assert data["summary"]["total_guests"] > 0

    def test_demographics_nationalities(self, authenticated_client, bookings, guests):
        """Test that nationalities are properly grouped."""
        today = timezone.now().date()
        url = reverse("report_demographics")
        response = authenticated_client.get(
            url,
            {
                "start_date": (today - timedelta(days=10)).isoformat(),
                "end_date": today.isoformat(),
                "group_by": "nationality",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        nationalities = [item["nationality"] for item in data["data"]]
        # Should have multiple nationalities from our test data
        assert len(nationalities) > 1


# ============================================================================
# COMPARATIVE REPORT TESTS
# ============================================================================


@pytest.mark.django_db
class TestComparativeReport:
    """Tests for comparative report endpoint."""

    def test_comparative_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_comparative")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_comparative_previous_period(self, authenticated_client, bookings, financial_entries):
        """Test comparative report with previous period."""
        today = timezone.now().date()
        url = reverse("report_comparative")
        response = authenticated_client.get(
            url,
            {
                "current_start": (today - timedelta(days=7)).isoformat(),
                "current_end": today.isoformat(),
                "comparison_type": "previous_period",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert "current_period" in data
        assert "previous_period" in data
        assert "comparisons" in data

    def test_comparative_metrics(self, authenticated_client, bookings, financial_entries):
        """Test that all metrics are included in comparison."""
        today = timezone.now().date()
        url = reverse("report_comparative")
        response = authenticated_client.get(
            url,
            {
                "current_start": (today - timedelta(days=7)).isoformat(),
                "current_end": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        metric_keys = [item["metric_key"] for item in data["comparisons"]]
        assert "revenue" in metric_keys
        assert "expenses" in metric_keys
        assert "occupancy_rate" in metric_keys
        assert "revpar" in metric_keys


# ============================================================================
# EXPORT REPORT TESTS
# ============================================================================


@pytest.mark.django_db
class TestExportReport:
    """Tests for export report endpoint."""

    def test_export_report_unauthenticated(self, api_client):
        """Test that unauthenticated requests are rejected."""
        url = reverse("report_export")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_export_invalid_report_type(self, authenticated_client):
        """Test that invalid report type returns error."""
        today = timezone.now().date()
        url = reverse("report_export")
        response = authenticated_client.get(
            url,
            {
                "report_type": "invalid",
                "start_date": today.isoformat(),
                "end_date": today.isoformat(),
            },
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST
