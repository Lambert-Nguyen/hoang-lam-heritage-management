"""
Tests for Booking Management API endpoints.
"""

from datetime import date, timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import Booking, Guest, HotelUser, Room, RoomType

User = get_user_model()


class BookingAPITestCase(TestCase):
    """Test suite for Booking Management API."""

    def setUp(self):
        """Set up test fixtures."""
        # Create test users
        self.staff_user = User.objects.create_user(
            username="staff", email="staff@test.com", password="testpass123"
        )
        self.staff_profile = HotelUser.objects.create(
            user=self.staff_user, role=HotelUser.Role.STAFF
        )

        # Create room type and rooms
        self.room_type = RoomType.objects.create(
            name="Deluxe", base_rate=1000000, max_guests=2
        )
        self.room1 = Room.objects.create(
            room_type=self.room_type, number="101", floor=1, status=Room.Status.AVAILABLE
        )
        self.room2 = Room.objects.create(
            room_type=self.room_type, number="102", floor=1, status=Room.Status.AVAILABLE
        )

        # Create test guests
        self.guest1 = Guest.objects.create(
            full_name="Nguyễn Văn A",
            phone="0901234567",
            email="nva@test.com",
            id_type=Guest.IDType.CCCD,
            id_number="001234567890",
            nationality="Vietnam",
        )

        self.guest2 = Guest.objects.create(
            full_name="John Smith",
            phone="+1234567890",
            email="john@test.com",
            id_type=Guest.IDType.PASSPORT,
            id_number="US123456789",
            nationality="United States",
        )

        # Create test bookings
        today = date.today()
        self.booking1 = Booking.objects.create(
            guest=self.guest1,
            room=self.room1,
            check_in_date=today + timedelta(days=7),
            check_out_date=today + timedelta(days=10),
            nightly_rate=1000000,
            total_amount=3000000,
            deposit_amount=1500000,
            status=Booking.Status.CONFIRMED,
            source=Booking.Source.WEBSITE,
        )

        self.booking2 = Booking.objects.create(
            guest=self.guest2,
            room=self.room2,
            check_in_date=today,
            check_out_date=today + timedelta(days=2),
            nightly_rate=1000000,
            total_amount=2000000,
            deposit_amount=1000000,
            status=Booking.Status.CONFIRMED,
            source=Booking.Source.PHONE,
        )

        self.client = APIClient()

    def test_list_bookings_as_staff(self):
        """Test listing bookings as staff user."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/bookings/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 2)

    def test_list_bookings_unauthenticated(self):
        """Test that unauthenticated users cannot list bookings."""
        response = self.client.get("/api/v1/bookings/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_retrieve_booking(self):
        """Test retrieving a specific booking."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/bookings/{self.booking1.id}/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["guest_details"]["full_name"], "Nguyễn Văn A")
        self.assertEqual(response.data["nights"], 3)

    def test_create_booking_success(self):
        """Test creating a new booking successfully."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        data = {
            "guest": self.guest1.id,
            "room": self.room2.id,
            "check_in_date": str(today + timedelta(days=14)),
            "check_out_date": str(today + timedelta(days=17)),
            "nightly_rate": 1000000,
            "total_amount": 3000000,
            "deposit_amount": 1500000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
            "payment_method": Booking.PaymentMethod.CASH,
        }

        response = self.client.post("/api/v1/bookings/", data, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Booking.objects.count(), 3)

    def test_create_booking_invalid_dates(self):
        """Test that check_out must be after check_in."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        data = {
            "guest": self.guest1.id,
            "room": self.room2.id,
            "check_in_date": str(today + timedelta(days=5)),
            "check_out_date": str(today + timedelta(days=3)),  # Before check_in
            "nightly_rate": 1000000,
            "total_amount": 2000000,
            "deposit_amount": 1000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }

        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_booking_overlap(self):
        """Test that overlapping bookings are rejected."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        # Try to book room1 which already has booking1
        data = {
            "guest": self.guest2.id,
            "room": self.room1.id,
            "check_in_date": str(today + timedelta(days=8)),  # Overlaps with booking1
            "check_out_date": str(today + timedelta(days=11)),
            "nightly_rate": 1000000,
            "total_amount": 3000000,
            "deposit_amount": 1500000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }

        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("room", response.data)

    def test_update_booking(self):
        """Test updating a booking."""
        self.client.force_authenticate(user=self.staff_user)
        data = {"deposit_amount": 2000000}

        response = self.client.patch(
            f"/api/v1/bookings/{self.booking1.id}/", data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.booking1.refresh_from_db()
        self.assertEqual(self.booking1.deposit_amount, 2000000)

    def test_delete_booking(self):
        """Test deleting a booking."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.delete(f"/api/v1/bookings/{self.booking1.id}/")

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(Booking.objects.count(), 1)

    def test_filter_bookings_by_status(self):
        """Test filtering bookings by status."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/bookings/?status={Booking.Status.CONFIRMED}")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 2)

    def test_filter_bookings_by_guest(self):
        """Test filtering bookings by guest."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/bookings/?guest={self.guest1.id}")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_filter_bookings_by_room(self):
        """Test filtering bookings by room."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/bookings/?room={self.room1.id}")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_filter_bookings_by_date_range(self):
        """Test filtering bookings by check-in date range."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        response = self.client.get(
            f"/api/v1/bookings/?check_in_from={today}&check_in_to={today + timedelta(days=1)}"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)

    def test_update_booking_status(self):
        """Test the update_status action."""
        self.client.force_authenticate(user=self.staff_user)
        data = {"status": Booking.Status.CANCELLED, "notes": "Cancelled by guest"}

        response = self.client.post(
            f"/api/v1/bookings/{self.booking1.id}/update-status/", data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.booking1.refresh_from_db()
        self.assertEqual(self.booking1.status, Booking.Status.CANCELLED)

    def test_check_in_booking(self):
        """Test the check-in action."""
        self.client.force_authenticate(user=self.staff_user)
        data = {"notes": "Checked in successfully"}

        response = self.client.post(
            f"/api/v1/bookings/{self.booking2.id}/check-in/", data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.booking2.refresh_from_db()
        self.assertEqual(self.booking2.status, Booking.Status.CHECKED_IN)
        self.assertIsNotNone(self.booking2.actual_check_in)

        # Verify room status updated
        self.room2.refresh_from_db()
        self.assertEqual(self.room2.status, Room.Status.OCCUPIED)

    def test_check_in_already_checked_in(self):
        """Test that checking in an already checked-in booking fails."""
        self.client.force_authenticate(user=self.staff_user)
        self.booking2.status = Booking.Status.CHECKED_IN
        self.booking2.save()

        response = self.client.post(f"/api/v1/bookings/{self.booking2.id}/check-in/")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_check_out_booking(self):
        """Test the check-out action."""
        self.client.force_authenticate(user=self.staff_user)

        # First check in
        self.booking2.status = Booking.Status.CHECKED_IN
        self.booking2.save()

        data = {"notes": "Checked out successfully"}

        response = self.client.post(
            f"/api/v1/bookings/{self.booking2.id}/check-out/", data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.booking2.refresh_from_db()
        self.assertEqual(self.booking2.status, Booking.Status.CHECKED_OUT)
        self.assertIsNotNone(self.booking2.actual_check_out)

        # Verify room status updated
        self.room2.refresh_from_db()
        self.assertEqual(self.room2.status, Room.Status.CLEANING)

        # Verify guest total_stays incremented
        self.guest2.refresh_from_db()
        self.assertEqual(self.guest2.total_stays, 1)

    def test_check_out_not_checked_in(self):
        """Test that checking out a booking that's not checked in fails."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post(f"/api/v1/bookings/{self.booking1.id}/check-out/")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_today_bookings_action(self):
        """Test the today bookings action."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/bookings/today/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("check_ins", response.data)
        self.assertIn("check_outs", response.data)
        self.assertIn("total_check_ins", response.data)
        self.assertIn("total_check_outs", response.data)
        self.assertEqual(response.data["total_check_ins"], 1)  # booking2

    def test_calendar_action(self):
        """Test the calendar view action."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        response = self.client.get(
            f"/api/v1/bookings/calendar/?start_date={today}&end_date={today + timedelta(days=5)}"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("bookings", response.data)
        self.assertIn("total", response.data)
        self.assertEqual(response.data["total"], 1)  # Only booking2 in this range

    def test_calendar_action_missing_dates(self):
        """Test that calendar action requires both start and end dates."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/bookings/calendar/")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_calendar_action_invalid_date_format(self):
        """Test that calendar action validates date format."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(
            "/api/v1/bookings/calendar/?start_date=invalid&end_date=2024-12-31"
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_booking_missing_required_fields(self):
        """Test creating booking without required fields."""
        self.client.force_authenticate(user=self.staff_user)
        data = {"source": Booking.Source.WALK_IN}
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_booking_nonexistent_guest(self):
        """Test creating booking with non-existent guest ID."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        data = {
            "guest": 99999,
            "room": self.room1.id,
            "check_in_date": str(today + timedelta(days=20)),
            "check_out_date": str(today + timedelta(days=22)),
            "nightly_rate": 1000000,
            "total_amount": 2000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_booking_nonexistent_room(self):
        """Test creating booking with non-existent room ID."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        data = {
            "guest": self.guest1.id,
            "room": 99999,
            "check_in_date": str(today + timedelta(days=20)),
            "check_out_date": str(today + timedelta(days=22)),
            "nightly_rate": 1000000,
            "total_amount": 2000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_booking_checkin_equals_checkout(self):
        """Test creating booking where check-in equals check-out date."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        same_date = today + timedelta(days=20)
        data = {
            "guest": self.guest1.id,
            "room": self.room2.id,
            "check_in_date": str(same_date),
            "check_out_date": str(same_date),
            "nightly_rate": 1000000,
            "total_amount": 1000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_retrieve_nonexistent_booking(self):
        """Test retrieving a booking that does not exist."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/bookings/99999/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_update_nonexistent_booking(self):
        """Test updating a booking that does not exist."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.patch(
            "/api/v1/bookings/99999/", {"notes": "test"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_delete_nonexistent_booking(self):
        """Test deleting a booking that does not exist."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.delete("/api/v1/bookings/99999/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_check_in_cancelled_booking(self):
        """Test checking in a cancelled booking."""
        self.client.force_authenticate(user=self.staff_user)
        self.booking1.status = Booking.Status.CANCELLED
        self.booking1.save()
        response = self.client.post(f"/api/v1/bookings/{self.booking1.id}/check-in/")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_check_out_cancelled_booking(self):
        """Test checking out a cancelled booking."""
        self.client.force_authenticate(user=self.staff_user)
        self.booking1.status = Booking.Status.CANCELLED
        self.booking1.save()
        response = self.client.post(f"/api/v1/bookings/{self.booking1.id}/check-out/")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_update_status_invalid_value(self):
        """Test updating booking status with an invalid status value."""
        self.client.force_authenticate(user=self.staff_user)
        data = {"status": "nonexistent_status"}
        response = self.client.post(
            f"/api/v1/bookings/{self.booking1.id}/update-status/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_booking_guest_count_exceeds_capacity(self):
        """Test that guest count exceeding room capacity is rejected."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        data = {
            "guest": self.guest1.id,
            "room": self.room2.id,
            "check_in_date": str(today + timedelta(days=20)),
            "check_out_date": str(today + timedelta(days=22)),
            "guest_count": 5,  # room max_guests=2
            "nightly_rate": 1000000,
            "total_amount": 2000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("guest_count", response.data)

    def test_create_booking_deposit_exceeds_total(self):
        """Test that deposit amount exceeding total is rejected."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        data = {
            "guest": self.guest1.id,
            "room": self.room2.id,
            "check_in_date": str(today + timedelta(days=20)),
            "check_out_date": str(today + timedelta(days=22)),
            "nightly_rate": 1000000,
            "total_amount": 2000000,
            "deposit_amount": 5000000,  # > total_amount
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("deposit_amount", response.data)

    def test_create_booking_checkin_too_far_in_past(self):
        """Test that check-in date more than 7 days in the past is rejected."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        data = {
            "guest": self.guest1.id,
            "room": self.room2.id,
            "check_in_date": str(today - timedelta(days=30)),
            "check_out_date": str(today - timedelta(days=28)),
            "nightly_rate": 1000000,
            "total_amount": 2000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("check_in_date", response.data)

    def test_create_booking_cancelled_overlap_allowed(self):
        """Test that cancelled bookings don't block new bookings for same dates."""
        self.client.force_authenticate(user=self.staff_user)
        # Cancel booking1 first
        self.booking1.status = Booking.Status.CANCELLED
        self.booking1.save()

        today = date.today()
        data = {
            "guest": self.guest2.id,
            "room": self.room1.id,
            "check_in_date": str(today + timedelta(days=7)),
            "check_out_date": str(today + timedelta(days=10)),
            "nightly_rate": 1000000,
            "total_amount": 3000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_update_booking_creates_overlap(self):
        """Test that updating dates to overlap another booking is rejected."""
        self.client.force_authenticate(user=self.staff_user)
        # Move booking2 to room1 dates (overlap with booking1)
        today = date.today()
        data = {
            "room": self.room1.id,
            "check_in_date": str(today + timedelta(days=8)),
            "check_out_date": str(today + timedelta(days=11)),
        }
        response = self.client.patch(
            f"/api/v1/bookings/{self.booking2.id}/", data, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_check_in_nonexistent_booking(self):
        """Test check-in on a non-existent booking ID."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post("/api/v1/bookings/99999/check-in/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_check_out_nonexistent_booking(self):
        """Test check-out on a non-existent booking ID."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post("/api/v1/bookings/99999/check-out/")
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_check_in_no_show_booking(self):
        """Test checking in a no-show booking."""
        self.client.force_authenticate(user=self.staff_user)
        self.booking1.status = Booking.Status.NO_SHOW
        self.booking1.save()
        response = self.client.post(f"/api/v1/bookings/{self.booking1.id}/check-in/")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_check_out_pending_booking(self):
        """Test checking out a pending booking (not checked in)."""
        self.client.force_authenticate(user=self.staff_user)
        self.booking1.status = Booking.Status.PENDING
        self.booking1.save()
        response = self.client.post(f"/api/v1/bookings/{self.booking1.id}/check-out/")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_check_out_already_checked_out(self):
        """Test checking out an already checked-out booking."""
        self.client.force_authenticate(user=self.staff_user)
        self.booking1.status = Booking.Status.CHECKED_OUT
        self.booking1.save()
        response = self.client.post(f"/api/v1/bookings/{self.booking1.id}/check-out/")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_booking_unauthenticated(self):
        """Test creating a booking without authentication."""
        today = date.today()
        data = {
            "guest": self.guest1.id,
            "room": self.room2.id,
            "check_in_date": str(today + timedelta(days=20)),
            "check_out_date": str(today + timedelta(days=22)),
            "nightly_rate": 1000000,
            "total_amount": 2000000,
            "status": Booking.Status.CONFIRMED,
            "source": Booking.Source.WALK_IN,
        }
        response = self.client.post("/api/v1/bookings/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_calendar_end_before_start(self):
        """Test calendar with end_date before start_date returns 200 with empty results."""
        self.client.force_authenticate(user=self.staff_user)
        today = date.today()
        response = self.client.get(
            f"/api/v1/bookings/calendar/?start_date={today + timedelta(days=10)}&end_date={today}"
        )
        # The view does not validate date order — an inverted range simply
        # matches no bookings and returns an empty list with HTTP 200.
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total"], 0)
        self.assertEqual(response.data["bookings"], [])
