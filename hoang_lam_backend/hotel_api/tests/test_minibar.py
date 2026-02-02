"""Tests for minibar endpoints."""

from datetime import date, timedelta
from decimal import Decimal

import pytest
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import Booking, Guest, HotelUser, MinibarItem, MinibarSale, Room, RoomType


@pytest.fixture
def api_client():
    """Create API client."""
    return APIClient()


@pytest.fixture
def create_user(db):
    """Factory to create users with roles."""

    def _create_user(username, role="staff"):
        user = User.objects.create_user(username=username, password="testpass123")
        HotelUser.objects.create(
            user=user, role=role, phone=f"+84{username[-9:]}"
        )
        return user

    return _create_user


@pytest.fixture
def manager_user(create_user):
    """Create manager user."""
    return create_user("manager001", "manager")


@pytest.fixture
def staff_user(create_user):
    """Create staff user."""
    return create_user("staff001", "staff")


@pytest.fixture
def room_type(db):
    """Create room type."""
    return RoomType.objects.create(
        name="Standard",
        name_en="Standard Room",
        base_rate=Decimal("300000"),
        max_guests=2,
        description="Standard room",
    )


@pytest.fixture
def room(db, room_type):
    """Create a room."""
    return Room.objects.create(
        number="101",
        name="Phòng 101",
        room_type=room_type,
        floor=1,
        status=Room.Status.OCCUPIED,
    )


@pytest.fixture
def guest(db):
    """Create a guest."""
    return Guest.objects.create(
        full_name="Nguyen Van A",
        id_type="cccd",
        id_number="123456789012",
        phone="+84987654321",
    )


@pytest.fixture
def booking(db, room, guest, manager_user):
    """Create a booking."""
    from datetime import date, timedelta
    today = date.today()
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=today,
        check_out_date=today + timedelta(days=2),
        status=Booking.Status.CHECKED_IN,
        nightly_rate=Decimal("300000"),
        total_amount=Decimal("600000"),
        created_by=manager_user,
    )


@pytest.fixture
def minibar_item(db):
    """Create a minibar item."""
    return MinibarItem.objects.create(
        name="Coca Cola",
        price=Decimal("25000"),
        cost=Decimal("15000"),
        category="Beverages",
        is_active=True,
    )


@pytest.fixture
def minibar_item2(db):
    """Create another minibar item."""
    return MinibarItem.objects.create(
        name="Snickers Bar",
        price=Decimal("30000"),
        cost=Decimal("18000"),
        category="Snacks",
        is_active=True,
    )


@pytest.fixture
def inactive_item(db):
    """Create an inactive minibar item."""
    return MinibarItem.objects.create(
        name="Old Product",
        price=Decimal("20000"),
        cost=Decimal("10000"),
        category="Other",
        is_active=False,
    )


@pytest.fixture
def minibar_sale(db, booking, minibar_item, staff_user):
    """Create a minibar sale."""
    return MinibarSale.objects.create(
        booking=booking,
        item=minibar_item,
        quantity=2,
        unit_price=minibar_item.price,
        total=minibar_item.price * 2,
        date=date.today(),
        created_by=staff_user,
    )


# ============================================================
# MinibarItem Tests
# ============================================================


@pytest.mark.django_db
class TestMinibarItemList:
    """Tests for listing minibar items."""

    def test_list_items_authenticated(self, api_client, staff_user, minibar_item, minibar_item2):
        """Authenticated user can list minibar items."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/minibar-items/")

        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert len(results) >= 2

    def test_list_items_unauthenticated(self, api_client, minibar_item):
        """Unauthenticated users cannot list items."""
        response = api_client.get("/api/v1/minibar-items/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_filter_by_active_status(self, api_client, staff_user, minibar_item, inactive_item):
        """Can filter items by active status."""
        api_client.force_authenticate(user=staff_user)

        # Active items only
        response = api_client.get("/api/v1/minibar-items/?is_active=true")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert all(item["is_active"] for item in results)

        # Inactive items only
        response = api_client.get("/api/v1/minibar-items/?is_active=false")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert all(not item["is_active"] for item in results)

    def test_filter_by_category(self, api_client, staff_user, minibar_item, minibar_item2):
        """Can filter items by category."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get("/api/v1/minibar-items/?category=Beverages")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert all(item["category"] == "Beverages" for item in results)

    def test_search_by_name(self, api_client, staff_user, minibar_item, minibar_item2):
        """Can search items by name."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get("/api/v1/minibar-items/?search=Coca")
        assert response.status_code == status.HTTP_200_OK
        results = response.data.get("results", response.data)
        assert len(results) >= 1
        assert any("Coca" in item["name"] for item in results)


@pytest.mark.django_db
class TestMinibarItemCreate:
    """Tests for creating minibar items."""

    def test_create_item_success(self, api_client, staff_user):
        """Staff can create minibar items."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "name": "Pepsi",
            "price": 25000,
            "cost": 15000,
            "category": "Beverages",
            "is_active": True,
        }
        response = api_client.post("/api/v1/minibar-items/", data)

        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["name"] == "Pepsi"
        assert response.data["price"] == "25000"

    def test_create_duplicate_name_fails(self, api_client, staff_user, minibar_item):
        """Cannot create item with duplicate name."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "name": "Coca Cola",  # Already exists
            "price": 30000,
            "cost": 20000,
            "category": "Beverages",
        }
        response = api_client.post("/api/v1/minibar-items/", data)

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "name" in response.data

    def test_create_negative_price_fails(self, api_client, staff_user):
        """Cannot create item with negative price."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "name": "Invalid Item",
            "price": -1000,
            "cost": 500,
            "category": "Other",
        }
        response = api_client.post("/api/v1/minibar-items/", data)

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "price" in response.data


@pytest.mark.django_db
class TestMinibarItemUpdate:
    """Tests for updating minibar items."""

    def test_update_item_success(self, api_client, staff_user, minibar_item):
        """Staff can update minibar items."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "name": "Coca Cola Large",
            "price": 30000,
            "cost": 18000,
            "category": "Beverages",
            "is_active": True,
        }
        response = api_client.put(f"/api/v1/minibar-items/{minibar_item.id}/", data)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["name"] == "Coca Cola Large"
        assert response.data["price"] == "30000"

    def test_partial_update_item(self, api_client, staff_user, minibar_item):
        """Can partially update minibar items."""
        api_client.force_authenticate(user=staff_user)
        data = {"price": 28000}
        response = api_client.patch(f"/api/v1/minibar-items/{minibar_item.id}/", data)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["price"] == "28000"


@pytest.mark.django_db
class TestMinibarItemActions:
    """Tests for minibar item custom actions."""

    def test_toggle_active(self, api_client, staff_user, minibar_item):
        """Can toggle item active status."""
        api_client.force_authenticate(user=staff_user)
        original_status = minibar_item.is_active

        response = api_client.post(f"/api/v1/minibar-items/{minibar_item.id}/toggle_active/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["is_active"] != original_status

    def test_get_active_items(self, api_client, staff_user, minibar_item, inactive_item):
        """Can get only active items."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get("/api/v1/minibar-items/active/")

        assert response.status_code == status.HTTP_200_OK
        assert all(item["is_active"] for item in response.data)

    def test_get_categories(self, api_client, staff_user, minibar_item, minibar_item2):
        """Can get distinct categories."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get("/api/v1/minibar-items/categories/")

        assert response.status_code == status.HTTP_200_OK
        assert "Beverages" in response.data
        assert "Snacks" in response.data


# ============================================================
# MinibarSale Tests
# ============================================================


@pytest.mark.django_db
class TestMinibarSaleList:
    """Tests for listing minibar sales."""

    def test_list_sales_authenticated(self, api_client, staff_user, minibar_sale):
        """Authenticated user can list minibar sales."""
        api_client.force_authenticate(user=staff_user)
        response = api_client.get("/api/v1/minibar-sales/")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) >= 1

    def test_filter_by_booking(self, api_client, staff_user, minibar_sale, booking):
        """Can filter sales by booking."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get(f"/api/v1/minibar-sales/?booking={booking.id}")

        assert response.status_code == status.HTTP_200_OK
        assert len(response.data) >= 1

    def test_filter_by_charged_status(self, api_client, staff_user, minibar_sale):
        """Can filter sales by charged status."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get("/api/v1/minibar-sales/?is_charged=false")
        assert response.status_code == status.HTTP_200_OK

    def test_filter_by_date_range(self, api_client, staff_user, minibar_sale):
        """Can filter sales by date range."""
        api_client.force_authenticate(user=staff_user)
        today = date.today().isoformat()

        response = api_client.get(f"/api/v1/minibar-sales/?date_from={today}&date_to={today}")

        assert response.status_code == status.HTTP_200_OK


@pytest.mark.django_db
class TestMinibarSaleCreate:
    """Tests for creating minibar sales."""

    def test_create_sale_success(self, api_client, staff_user, booking, minibar_item):
        """Staff can create minibar sales."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "booking": booking.id,
            "item": minibar_item.id,
            "quantity": 2,
            "date": date.today().isoformat(),
        }
        response = api_client.post("/api/v1/minibar-sales/", data)

        assert response.status_code == status.HTTP_201_CREATED
        assert response.data["quantity"] == 2
        assert Decimal(response.data["total"]) == minibar_item.price * 2

    def test_create_sale_invalid_booking_status(self, api_client, staff_user, booking, minibar_item):
        """Cannot create sale for cancelled booking."""
        booking.status = "cancelled"
        booking.save()

        api_client.force_authenticate(user=staff_user)
        data = {
            "booking": booking.id,
            "item": minibar_item.id,
            "quantity": 1,
            "date": date.today().isoformat(),
        }
        response = api_client.post("/api/v1/minibar-sales/", data)

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_sale_inactive_item_fails(self, api_client, staff_user, booking, inactive_item):
        """Cannot create sale for inactive item."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "booking": booking.id,
            "item": inactive_item.id,
            "quantity": 1,
            "date": date.today().isoformat(),
        }
        response = api_client.post("/api/v1/minibar-sales/", data)

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_create_sale_zero_quantity_fails(self, api_client, staff_user, booking, minibar_item):
        """Cannot create sale with zero quantity."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "booking": booking.id,
            "item": minibar_item.id,
            "quantity": 0,
            "date": date.today().isoformat(),
        }
        response = api_client.post("/api/v1/minibar-sales/", data)

        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestMinibarSaleBulkCreate:
    """Tests for bulk creating minibar sales."""

    def test_bulk_create_success(self, api_client, staff_user, booking, minibar_item, minibar_item2):
        """Can bulk create multiple sales."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "booking": booking.id,
            "items": [
                {"item_id": minibar_item.id, "quantity": 2},
                {"item_id": minibar_item2.id, "quantity": 1},
            ],
            "date": date.today().isoformat(),
        }
        response = api_client.post("/api/v1/minibar-sales/bulk_create/", data, format="json")

        assert response.status_code == status.HTTP_201_CREATED
        assert len(response.data) == 2

    def test_bulk_create_empty_items_fails(self, api_client, staff_user, booking):
        """Cannot bulk create with empty items."""
        api_client.force_authenticate(user=staff_user)
        data = {
            "booking": booking.id,
            "items": [],
        }
        response = api_client.post("/api/v1/minibar-sales/bulk_create/", data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestMinibarSaleUpdate:
    """Tests for updating minibar sales."""

    def test_update_quantity(self, api_client, staff_user, minibar_sale):
        """Can update sale quantity."""
        api_client.force_authenticate(user=staff_user)
        original_unit_price = minibar_sale.unit_price

        data = {"quantity": 5}
        response = api_client.patch(f"/api/v1/minibar-sales/{minibar_sale.id}/", data)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["quantity"] == 5
        assert Decimal(response.data["total"]) == original_unit_price * 5

    def test_update_charged_status(self, api_client, staff_user, minibar_sale):
        """Can update charged status."""
        api_client.force_authenticate(user=staff_user)
        data = {"is_charged": True}

        response = api_client.patch(f"/api/v1/minibar-sales/{minibar_sale.id}/", data)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["is_charged"] is True


@pytest.mark.django_db
class TestMinibarSaleActions:
    """Tests for minibar sale custom actions."""

    def test_mark_charged(self, api_client, staff_user, minibar_sale):
        """Can mark sale as charged."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.post(f"/api/v1/minibar-sales/{minibar_sale.id}/mark_charged/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["is_charged"] is True

    def test_mark_charged_already_charged_fails(self, api_client, staff_user, minibar_sale):
        """Cannot mark already charged sale."""
        minibar_sale.is_charged = True
        minibar_sale.save()

        api_client.force_authenticate(user=staff_user)
        response = api_client.post(f"/api/v1/minibar-sales/{minibar_sale.id}/mark_charged/")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_unmark_charged(self, api_client, staff_user, minibar_sale):
        """Can unmark sale as charged."""
        minibar_sale.is_charged = True
        minibar_sale.save()

        api_client.force_authenticate(user=staff_user)
        response = api_client.post(f"/api/v1/minibar-sales/{minibar_sale.id}/unmark_charged/")

        assert response.status_code == status.HTTP_200_OK
        assert response.data["is_charged"] is False

    def test_get_uncharged(self, api_client, staff_user, minibar_sale, booking):
        """Can get uncharged sales for booking."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get(f"/api/v1/minibar-sales/uncharged/?booking={booking.id}")

        assert response.status_code == status.HTTP_200_OK
        assert all(not sale["is_charged"] for sale in response.data)

    def test_get_uncharged_missing_booking_fails(self, api_client, staff_user):
        """Uncharged endpoint requires booking parameter."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get("/api/v1/minibar-sales/uncharged/")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_charge_all(self, api_client, staff_user, minibar_sale, booking, minibar_item):
        """Can charge all uncharged sales."""
        # Create another uncharged sale
        MinibarSale.objects.create(
            booking=booking,
            item=minibar_item,
            quantity=1,
            unit_price=minibar_item.price,
            total=minibar_item.price,
            date=date.today(),
            created_by=staff_user,
        )

        api_client.force_authenticate(user=staff_user)
        response = api_client.post("/api/v1/minibar-sales/charge_all/", {"booking": booking.id})

        assert response.status_code == status.HTTP_200_OK
        assert response.data["charged_count"] == 2

    def test_get_summary(self, api_client, staff_user, minibar_sale, booking):
        """Can get sales summary for booking."""
        api_client.force_authenticate(user=staff_user)

        response = api_client.get(f"/api/v1/minibar-sales/summary/?booking={booking.id}")

        assert response.status_code == status.HTTP_200_OK
        assert "total_sales" in response.data
        assert "total_amount" in response.data
        assert "charged_amount" in response.data
        assert "uncharged_amount" in response.data
        assert "items" in response.data


@pytest.mark.django_db
class TestMinibarSaleDelete:
    """Tests for deleting minibar sales."""

    def test_delete_sale(self, api_client, staff_user, minibar_sale):
        """Staff can delete minibar sales."""
        api_client.force_authenticate(user=staff_user)
        sale_id = minibar_sale.id

        response = api_client.delete(f"/api/v1/minibar-sales/{sale_id}/")

        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not MinibarSale.objects.filter(id=sale_id).exists()
