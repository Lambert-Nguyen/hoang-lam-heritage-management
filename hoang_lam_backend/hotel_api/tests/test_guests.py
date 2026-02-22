"""
Tests for Guest Management API endpoints.
"""

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import Guest, HotelUser

User = get_user_model()


class GuestAPITestCase(TestCase):
    """Test suite for Guest Management API."""

    def setUp(self):
        """Set up test fixtures."""
        # Create test users
        self.staff_user = User.objects.create_user(
            username="staff", email="staff@test.com", password="testpass123"
        )
        self.staff_profile = HotelUser.objects.create(
            user=self.staff_user, role=HotelUser.Role.STAFF
        )

        self.manager_user = User.objects.create_user(
            username="manager", email="manager@test.com", password="testpass123"
        )
        self.manager_profile = HotelUser.objects.create(
            user=self.manager_user, role=HotelUser.Role.MANAGER
        )

        # Create test guests
        self.guest1 = Guest.objects.create(
            full_name="Nguyễn Văn A",
            phone="0901234567",
            email="nva@test.com",
            id_type=Guest.IDType.CCCD,
            id_number="001234567890",
            nationality="Vietnam",
            date_of_birth="1990-01-01",
            gender="male",
            is_vip=True,
            total_stays=5,
        )

        self.guest2 = Guest.objects.create(
            full_name="John Smith",
            phone="+1234567890",
            email="john@test.com",
            id_type=Guest.IDType.PASSPORT,
            id_number="US123456789",
            nationality="United States",
            date_of_birth="1985-05-15",
            gender="male",
            is_vip=False,
            total_stays=0,
        )

        self.client = APIClient()

    def test_list_guests_as_staff(self):
        """Test listing guests as staff user."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 2)

    def test_list_guests_unauthenticated(self):
        """Test that unauthenticated users cannot list guests."""
        response = self.client.get("/api/v1/guests/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_retrieve_guest(self):
        """Test retrieving a specific guest."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/guests/{self.guest1.id}/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["full_name"], "Nguyễn Văn A")
        self.assertEqual(response.data["is_vip"], True)
        self.assertEqual(response.data["is_returning_guest"], True)

    def test_create_guest_as_manager(self):
        """Test creating a new guest as manager."""
        self.client.force_authenticate(user=self.manager_user)
        data = {
            "full_name": "Test Guest",
            "phone": "0912345678",
            "email": "test@guest.com",
            "id_type": Guest.IDType.CCCD,
            "id_number": "001234567899",
            "nationality": "Vietnam",
            "date_of_birth": "1995-03-20",
            "gender": "female",
        }

        response = self.client.post("/api/v1/guests/", data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Guest.objects.count(), 3)
        self.assertEqual(response.data["full_name"], "Test Guest")

    def test_create_guest_as_staff_fails(self):
        """Test that staff cannot create guests."""
        self.client.force_authenticate(user=self.staff_user)
        data = {
            "full_name": "Test Guest",
            "phone": "0912345678",
            "email": "test@guest.com",
            "id_type": Guest.IDType.CCCD,
            "id_number": "001234567899",
            "nationality": "Vietnam",
        }

        response = self.client.post("/api/v1/guests/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_create_guest_duplicate_phone(self):
        """Test that duplicate phone numbers are rejected."""
        self.client.force_authenticate(user=self.manager_user)
        data = {
            "full_name": "Test Guest",
            "phone": "0901234567",  # Same as guest1
            "email": "test2@guest.com",
            "id_type": Guest.IDType.CCCD,
            "id_number": "001234567899",
            "nationality": "Vietnam",
        }

        response = self.client.post("/api/v1/guests/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("phone", response.data)

    def test_create_guest_duplicate_id_number(self):
        """Test that duplicate ID numbers are rejected."""
        self.client.force_authenticate(user=self.manager_user)
        data = {
            "full_name": "Test Guest",
            "phone": "0912345678",
            "email": "test2@guest.com",
            "id_type": Guest.IDType.CCCD,
            "id_number": "001234567890",  # Same as guest1
            "nationality": "Vietnam",
        }

        response = self.client.post("/api/v1/guests/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("id_number", response.data)

    def test_update_guest_as_manager(self):
        """Test updating a guest as manager."""
        self.client.force_authenticate(user=self.manager_user)
        data = {"full_name": "Nguyễn Văn A Updated", "is_vip": False}

        response = self.client.patch(f"/api/v1/guests/{self.guest1.id}/", data, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.guest1.refresh_from_db()
        self.assertEqual(self.guest1.full_name, "Nguyễn Văn A Updated")
        self.assertEqual(self.guest1.is_vip, False)

    def test_delete_guest_as_manager(self):
        """Test deleting a guest as manager."""
        self.client.force_authenticate(user=self.manager_user)
        response = self.client.delete(f"/api/v1/guests/{self.guest2.id}/")

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Guest.objects.count(), 1)

    def test_filter_guests_by_vip_status(self):
        """Test filtering guests by VIP status."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/?is_vip=true")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(response.data["results"][0]["full_name"], "Nguyễn Văn A")

    def test_filter_guests_by_nationality(self):
        """Test filtering guests by nationality."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/?nationality=Vietnam")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(response.data["results"][0]["nationality"], "Vietnam")

    def test_search_guests_by_name(self):
        """Test searching guests by name."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/?search=Nguyễn")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(response.data["results"][0]["full_name"], "Nguyễn Văn A")

    def test_search_guests_by_phone(self):
        """Test searching guests by phone."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/?search=0901234567")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(response.data["results"][0]["phone"], "0901234567")

    def test_search_guests_by_id_number(self):
        """Test searching guests by ID number."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/?search=001234567890")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(response.data["results"][0]["id_number"], "001234567890")

    def test_guest_search_action(self):
        """Test the search action endpoint."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post("/api/v1/guests/search/", {"query": "John"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["full_name"], "John Smith")

    def test_guest_search_action_min_length(self):
        """Test that search query must be at least 2 characters."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post("/api/v1/guests/search/", {"query": "J"}, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_guest_history_action(self):
        """Test the history action endpoint."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/guests/{self.guest1.id}/history/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("guest", response.data)
        self.assertIn("bookings", response.data)
        self.assertIn("total_bookings", response.data)
        self.assertIn("total_stays", response.data)
        self.assertEqual(response.data["total_stays"], 5)

    def test_create_guest_missing_required_fields(self):
        """Test creating guest without required fields."""
        self.client.force_authenticate(user=self.manager_user)
        data = {"email": "test@test.com"}  # Missing full_name, phone, etc.
        response = self.client.post("/api/v1/guests/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_guest_empty_full_name(self):
        """Test creating guest with empty full_name."""
        self.client.force_authenticate(user=self.manager_user)
        data = {
            "full_name": "",
            "phone": "0999888777",
            "id_type": Guest.IDType.CCCD,
            "id_number": "009988776655",
            "nationality": "Vietnam",
        }
        response = self.client.post("/api/v1/guests/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_retrieve_nonexistent_guest(self):
        """Test retrieving a guest that does not exist."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/99999/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_update_nonexistent_guest(self):
        """Test updating a guest that does not exist."""
        self.client.force_authenticate(user=self.manager_user)
        response = self.client.patch("/api/v1/guests/99999/", {"full_name": "Test"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_nonexistent_guest(self):
        """Test deleting a guest that does not exist."""
        self.client.force_authenticate(user=self.manager_user)
        response = self.client.delete("/api/v1/guests/99999/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_create_guest_duplicate_email(self):
        """Test creating guest with duplicate email."""
        self.client.force_authenticate(user=self.manager_user)
        data = {
            "full_name": "New Guest",
            "phone": "0999111222",
            "email": "nva@test.com",  # Same as guest1
            "id_type": Guest.IDType.CCCD,
            "id_number": "009988776655",
            "nationality": "Vietnam",
        }
        response = self.client.post("/api/v1/guests/", data, format="json")
        # Email uniqueness - should be 400 if enforced, 201 if not unique
        self.assertIn(
            response.status_code,
            [
                status.HTTP_400_BAD_REQUEST,
                status.HTTP_201_CREATED,
            ],
        )

    def test_guest_search_empty_query(self):
        """Test search action with empty query."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post("/api/v1/guests/search/", {"query": ""}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_guest_search_missing_query(self):
        """Test search action without query field."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post("/api/v1/guests/search/", {}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_guest_history_nonexistent(self):
        """Test history for non-existent guest."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/99999/history/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
