"""
Unit tests for Celery tasks (hotel_api/tasks.py).

Each task uses lazy imports, so mocking targets the source modules directly.
PushNotificationService.notify_staff is mocked to avoid real push calls.
"""

from datetime import date, timedelta
from decimal import Decimal
from unittest.mock import MagicMock, patch

from django.contrib.auth import get_user_model
from django.test import TestCase

from hotel_api.models import Booking, Guest, HotelUser, Room, RoomType

User = get_user_model()


class TaskTestBase(TestCase):
    """Shared fixtures for task tests that need real bookings."""

    def setUp(self):
        self.user = User.objects.create_user(username="task_user", password="pass123")
        HotelUser.objects.create(user=self.user, role=HotelUser.Role.STAFF)
        self.room_type = RoomType.objects.create(name="Standard", base_rate=Decimal("500000"))
        self.room = Room.objects.create(
            room_type=self.room_type, number="T01", floor=1, status=Room.Status.AVAILABLE
        )
        self.guest = Guest.objects.create(
            full_name="Task Guest",
            phone="0900000099",
            nationality="Vietnam",
        )

    def _make_booking(self, check_in, check_out, booking_status):
        return Booking.objects.create(
            room=self.room,
            guest=self.guest,
            check_in_date=check_in,
            check_out_date=check_out,
            nightly_rate=Decimal("500000"),
            total_amount=Decimal("500000") * (check_out - check_in).days,
            status=booking_status,
        )


# ─────────────────────────────────────────────
# send_checkin_reminders
# ─────────────────────────────────────────────


class TestSendCheckinReminders(TaskTestBase):
    """Tests for the send_checkin_reminders Celery task."""

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_no_pending_checkins_returns_early(self, mock_notify):
        """Returns 'No pending check-ins.' when nothing is due today."""
        from hotel_api.tasks import send_checkin_reminders

        result = send_checkin_reminders()

        self.assertEqual(result, "No pending check-ins.")
        mock_notify.assert_not_called()

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_sends_reminder_for_confirmed_checkin(self, mock_notify):
        """Sends one reminder for a CONFIRMED booking due today."""
        from hotel_api.tasks import send_checkin_reminders

        today = date.today()
        self._make_booking(today, today + timedelta(days=2), Booking.Status.CONFIRMED)

        result = send_checkin_reminders()

        self.assertEqual(result, "Sent 1 check-in reminder(s).")
        mock_notify.assert_called_once()

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_sends_reminder_for_pending_checkin(self, mock_notify):
        """Sends reminder for a PENDING booking due today."""
        from hotel_api.tasks import send_checkin_reminders

        today = date.today()
        self._make_booking(today, today + timedelta(days=1), Booking.Status.PENDING)

        result = send_checkin_reminders()

        self.assertEqual(result, "Sent 1 check-in reminder(s).")
        mock_notify.assert_called_once()

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_ignores_checked_out_bookings(self, mock_notify):
        """Does not send a reminder for CHECKED_OUT bookings on today's date."""
        from hotel_api.tasks import send_checkin_reminders

        today = date.today()
        self._make_booking(today, today + timedelta(days=1), Booking.Status.CHECKED_OUT)

        result = send_checkin_reminders()

        self.assertEqual(result, "No pending check-ins.")
        mock_notify.assert_not_called()

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_counts_multiple_checkins(self, mock_notify):
        """Returns correct count when multiple bookings are due today."""
        from hotel_api.tasks import send_checkin_reminders

        # Need a second room so there is no room conflict
        room2 = Room.objects.create(
            room_type=self.room_type, number="T02", floor=1, status=Room.Status.AVAILABLE
        )
        guest2 = Guest.objects.create(
            full_name="Second Guest", phone="0900000088", nationality="Vietnam"
        )
        today = date.today()
        self._make_booking(today, today + timedelta(days=2), Booking.Status.CONFIRMED)
        Booking.objects.create(
            room=room2,
            guest=guest2,
            check_in_date=today,
            check_out_date=today + timedelta(days=3),
            nightly_rate=Decimal("500000"),
            total_amount=Decimal("1500000"),
            status=Booking.Status.CONFIRMED,
        )

        result = send_checkin_reminders()

        self.assertEqual(result, "Sent 2 check-in reminder(s).")
        self.assertEqual(mock_notify.call_count, 2)


# ─────────────────────────────────────────────
# send_checkout_reminders
# ─────────────────────────────────────────────


class TestSendCheckoutReminders(TaskTestBase):
    """Tests for the send_checkout_reminders Celery task."""

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_no_pending_checkouts_returns_early(self, mock_notify):
        """Returns 'No pending check-outs.' when nothing is due today."""
        from hotel_api.tasks import send_checkout_reminders

        result = send_checkout_reminders()

        self.assertEqual(result, "No pending check-outs.")
        mock_notify.assert_not_called()

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_sends_reminder_for_checked_in_checkout(self, mock_notify):
        """Sends one reminder for a CHECKED_IN booking due out today."""
        from hotel_api.tasks import send_checkout_reminders

        today = date.today()
        self._make_booking(today - timedelta(days=2), today, Booking.Status.CHECKED_IN)

        result = send_checkout_reminders()

        self.assertEqual(result, "Sent 1 check-out reminder(s).")
        mock_notify.assert_called_once()

    @patch("hotel_api.services.PushNotificationService.notify_staff")
    def test_ignores_confirmed_booking_on_checkout_date(self, mock_notify):
        """CONFIRMED bookings (not CHECKED_IN) are not sent checkout reminders."""
        from hotel_api.tasks import send_checkout_reminders

        today = date.today()
        self._make_booking(today - timedelta(days=1), today, Booking.Status.CONFIRMED)

        result = send_checkout_reminders()

        self.assertEqual(result, "No pending check-outs.")
        mock_notify.assert_not_called()


# ─────────────────────────────────────────────
# cleanup_expired_tokens
# ─────────────────────────────────────────────


class TestCleanupExpiredTokens(TestCase):
    """Tests for the cleanup_expired_tokens Celery task."""

    def test_returns_zero_when_no_expired_tokens(self):
        """Reports 0 cleanups when the token table has no expired rows."""
        from hotel_api.tasks import cleanup_expired_tokens

        with patch(
            "rest_framework_simplejwt.token_blacklist.models.OutstandingToken"
        ) as mock_token_cls:
            mock_qs = MagicMock()
            mock_qs.count.return_value = 0
            mock_token_cls.objects.filter.return_value = mock_qs

            result = cleanup_expired_tokens()

        self.assertEqual(result, "Cleaned up 0 expired token(s).")
        mock_qs.delete.assert_not_called()

    def test_deletes_expired_tokens_and_returns_count(self):
        """Deletes expired tokens and returns the correct count string."""
        from hotel_api.tasks import cleanup_expired_tokens

        with patch(
            "rest_framework_simplejwt.token_blacklist.models.OutstandingToken"
        ) as mock_token_cls:
            mock_qs = MagicMock()
            mock_qs.count.return_value = 7
            mock_token_cls.objects.filter.return_value = mock_qs

            result = cleanup_expired_tokens()

        self.assertEqual(result, "Cleaned up 7 expired token(s).")
        mock_qs.delete.assert_called_once()

    def test_filters_by_expiry_time(self):
        """Queries are filtered on expires_at__lt=now."""
        from hotel_api.tasks import cleanup_expired_tokens

        with patch(
            "rest_framework_simplejwt.token_blacklist.models.OutstandingToken"
        ) as mock_token_cls:
            mock_qs = MagicMock()
            mock_qs.count.return_value = 0
            mock_token_cls.objects.filter.return_value = mock_qs

            cleanup_expired_tokens()

        call_kwargs = mock_token_cls.objects.filter.call_args
        self.assertIn("expires_at__lt", call_kwargs.kwargs)


# ─────────────────────────────────────────────
# apply_data_retention_policy
# ─────────────────────────────────────────────


class TestApplyDataRetentionPolicy(TestCase):
    """Tests for the apply_data_retention_policy Celery task."""

    @patch("hotel_api.retention.apply_retention_policy")
    def test_calls_retention_with_dry_run_false(self, mock_apply):
        """Task always runs retention with dry_run=False."""
        from hotel_api.tasks import apply_data_retention_policy

        mock_apply.return_value = {}

        apply_data_retention_policy()

        mock_apply.assert_called_once_with(dry_run=False)

    @patch("hotel_api.retention.apply_retention_policy")
    def test_returns_summary_string(self, mock_apply):
        """Return value summarises total records deleted."""
        from hotel_api.tasks import apply_data_retention_policy

        mock_apply.return_value = {"notification": 5, "booking": 2}

        result = apply_data_retention_policy()

        self.assertIn("Deleted 7 record(s)", result)

    @patch("hotel_api.retention.apply_retention_policy")
    def test_returns_zero_when_nothing_deleted(self, mock_apply):
        """Returns zero total when retention policy deletes nothing."""
        from hotel_api.tasks import apply_data_retention_policy

        mock_apply.return_value = {"notification": 0, "booking": 0}

        result = apply_data_retention_policy()

        self.assertIn("Deleted 0 record(s)", result)
