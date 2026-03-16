"""
Tests for extend_stay and swap_room booking actions.
"""

from datetime import date, timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase

from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import Booking, Guest, HotelUser, Room, RoomType

User = get_user_model()


class ExtendStayTestCase(TestCase):
    """Tests for the extend-stay booking action."""

    def setUp(self):
        self.client = APIClient()
        self.staff_user = User.objects.create_user(username="staff_ext", password="testpass123")
        HotelUser.objects.create(user=self.staff_user, role=HotelUser.Role.STAFF)

        self.room_type = RoomType.objects.create(name="Standard", base_rate=500000, max_guests=2)
        self.room = Room.objects.create(
            room_type=self.room_type,
            number="201",
            floor=2,
            status=Room.Status.OCCUPIED,
        )
        self.guest = Guest.objects.create(
            full_name="Trần Văn B",
            phone="0912345678",
            id_type=Guest.IDType.CCCD,
            id_number="001234567891",
            nationality="Vietnam",
        )

        today = date.today()
        self.booking = Booking.objects.create(
            guest=self.guest,
            room=self.room,
            check_in_date=today - timedelta(days=1),
            check_out_date=today + timedelta(days=2),
            nightly_rate=500000,
            total_amount=1500000,
            status=Booking.Status.CHECKED_IN,
        )
        self.client.force_authenticate(user=self.staff_user)

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_extend_stay_success(self, mock_notify):
        """Extending stay should update check_out_date and recalculate total."""
        new_date = self.booking.check_out_date + timedelta(days=3)
        url = f"/api/v1/bookings/{self.booking.pk}/extend-stay/"
        response = self.client.post(url, {"new_check_out_date": new_date.isoformat()})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.booking.refresh_from_db()
        self.assertEqual(self.booking.check_out_date, new_date)

        expected_nights = (new_date - self.booking.check_in_date).days
        expected_total = self.room_type.base_rate * expected_nights
        self.assertEqual(self.booking.total_amount, expected_total)
        self.assertIn("Gia hạn", self.booking.notes)

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_extend_stay_earlier_date_rejected(self, mock_notify):
        """Cannot extend to a date before the current checkout."""
        earlier = self.booking.check_out_date - timedelta(days=1)
        url = f"/api/v1/bookings/{self.booking.pk}/extend-stay/"
        response = self.client.post(url, {"new_check_out_date": earlier.isoformat()})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_extend_stay_not_checked_in(self, mock_notify):
        """Cannot extend a booking that is not checked in."""
        self.booking.status = Booking.Status.CONFIRMED
        self.booking.save()

        new_date = self.booking.check_out_date + timedelta(days=1)
        url = f"/api/v1/bookings/{self.booking.pk}/extend-stay/"
        response = self.client.post(url, {"new_check_out_date": new_date.isoformat()})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_extend_stay_overlap_rejected(self, mock_notify):
        """Cannot extend if another booking occupies the room in that period."""
        future_date = self.booking.check_out_date + timedelta(days=1)
        Booking.objects.create(
            guest=self.guest,
            room=self.room,
            check_in_date=future_date,
            check_out_date=future_date + timedelta(days=2),
            nightly_rate=500000,
            total_amount=1000000,
            status=Booking.Status.CONFIRMED,
        )

        url = f"/api/v1/bookings/{self.booking.pk}/extend-stay/"
        response = self.client.post(
            url, {"new_check_out_date": (future_date + timedelta(days=1)).isoformat()}
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class SwapRoomTestCase(TestCase):
    """Tests for the swap-room booking action."""

    def setUp(self):
        self.client = APIClient()
        self.staff_user = User.objects.create_user(username="staff_swap", password="testpass123")
        HotelUser.objects.create(user=self.staff_user, role=HotelUser.Role.STAFF)

        self.room_type = RoomType.objects.create(
            name="Standard Swap", base_rate=600000, max_guests=2
        )
        self.room_old = Room.objects.create(
            room_type=self.room_type,
            number="301",
            floor=3,
            status=Room.Status.OCCUPIED,
        )
        self.room_new = Room.objects.create(
            room_type=self.room_type,
            number="302",
            floor=3,
            status=Room.Status.AVAILABLE,
        )
        self.guest = Guest.objects.create(
            full_name="Lê Thị C",
            phone="0923456789",
            id_type=Guest.IDType.CCCD,
            id_number="001234567892",
            nationality="Vietnam",
        )

        today = date.today()
        self.booking = Booking.objects.create(
            guest=self.guest,
            room=self.room_old,
            check_in_date=today - timedelta(days=1),
            check_out_date=today + timedelta(days=2),
            nightly_rate=600000,
            total_amount=1800000,
            status=Booking.Status.CHECKED_IN,
        )
        self.client.force_authenticate(user=self.staff_user)

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_swap_room_success(self, mock_notify):
        """Swapping room should update booking, old room to CLEANING, new room to OCCUPIED."""
        url = f"/api/v1/bookings/{self.booking.pk}/swap-room/"
        response = self.client.post(
            url,
            {"new_room": self.room_new.pk, "reason": "Guest preferred higher floor"},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)

        self.booking.refresh_from_db()
        self.assertEqual(self.booking.room_id, self.room_new.pk)
        self.assertIn("Đổi phòng", self.booking.notes)

        self.room_old.refresh_from_db()
        self.assertEqual(self.room_old.status, Room.Status.CLEANING)

        self.room_new.refresh_from_db()
        self.assertEqual(self.room_new.status, Room.Status.OCCUPIED)

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_swap_same_room_rejected(self, mock_notify):
        """Cannot swap to the same room."""
        url = f"/api/v1/bookings/{self.booking.pk}/swap-room/"
        response = self.client.post(url, {"new_room": self.room_old.pk})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_swap_not_checked_in(self, mock_notify):
        """Cannot swap room for a booking that is not checked in."""
        self.booking.status = Booking.Status.CONFIRMED
        self.booking.save()

        url = f"/api/v1/bookings/{self.booking.pk}/swap-room/"
        response = self.client.post(url, {"new_room": self.room_new.pk})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_swap_unauthenticated(self):
        """Unauthenticated users cannot swap rooms."""
        self.client.force_authenticate(user=None)
        url = f"/api/v1/bookings/{self.booking.pk}/swap-room/"
        response = self.client.post(url, {"new_room": self.room_new.pk})

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
