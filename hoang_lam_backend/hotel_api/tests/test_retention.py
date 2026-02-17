"""Tests for data retention policy."""

from datetime import date, timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from hotel_api.models import (
    Booking,
    DateRateOverride,
    DeviceToken,
    ExchangeRate,
    FinancialCategory,
    FinancialEntry,
    Guest,
    GuestMessage,
    HousekeepingTask,
    LostAndFound,
    MaintenanceRequest,
    MessageTemplate,
    NightAudit,
    Notification,
    Room,
    RoomInspection,
    RoomType,
    SensitiveDataAccessLog,
)
from hotel_api.retention import apply_retention_policy

User = get_user_model()


class RetentionTestBase(TestCase):
    """Base class with shared fixtures for retention tests."""

    def setUp(self):
        self.user = User.objects.create_user(username="testuser", password="testpass123")
        self.room_type = RoomType.objects.create(name="Standard", base_rate=500000)
        self.room = Room.objects.create(
            room_type=self.room_type, number="101", floor=1
        )
        self.guest = Guest.objects.create(
            full_name="Test Guest",
            phone="0900000001",
            nationality="Vietnam",
        )


class TestNotificationRetention(RetentionTestBase):
    """Tests for notification cleanup (90-day retention)."""

    def test_old_notifications_deleted(self):
        """Notifications older than 90 days are deleted."""
        old_notif = Notification.objects.create(
            recipient=self.user,
            title="Old notification",
            body="Old body",
        )
        Notification.objects.filter(pk=old_notif.pk).update(
            created_at=timezone.now() - timedelta(days=91)
        )

        results = apply_retention_policy()
        self.assertEqual(results["notification"], 1)
        self.assertFalse(Notification.objects.filter(pk=old_notif.pk).exists())

    def test_recent_notifications_kept(self):
        """Notifications within 90 days are preserved."""
        recent_notif = Notification.objects.create(
            recipient=self.user,
            title="Recent notification",
            body="Recent body",
        )
        Notification.objects.filter(pk=recent_notif.pk).update(
            created_at=timezone.now() - timedelta(days=89)
        )

        results = apply_retention_policy()
        self.assertEqual(results["notification"], 0)
        self.assertTrue(Notification.objects.filter(pk=recent_notif.pk).exists())


class TestDeviceTokenRetention(RetentionTestBase):
    """Tests for device token cleanup (30-day retention for inactive)."""

    def test_inactive_device_tokens_deleted(self):
        """Inactive device tokens older than 30 days are deleted."""
        token = DeviceToken.objects.create(
            user=self.user, token="old_token_123", is_active=False
        )
        DeviceToken.objects.filter(pk=token.pk).update(
            updated_at=timezone.now() - timedelta(days=31)
        )

        results = apply_retention_policy()
        self.assertEqual(results["device_token"], 1)
        self.assertFalse(DeviceToken.objects.filter(pk=token.pk).exists())

    def test_active_device_tokens_kept(self):
        """Active device tokens are preserved regardless of age."""
        token = DeviceToken.objects.create(
            user=self.user, token="active_token_123", is_active=True
        )
        DeviceToken.objects.filter(pk=token.pk).update(
            updated_at=timezone.now() - timedelta(days=60)
        )

        results = apply_retention_policy()
        self.assertEqual(results["device_token"], 0)
        self.assertTrue(DeviceToken.objects.filter(pk=token.pk).exists())


class TestHousekeepingRetention(RetentionTestBase):
    """Tests for housekeeping task cleanup (1-year retention)."""

    def test_completed_housekeeping_deleted(self):
        """Completed housekeeping tasks older than 1 year are deleted."""
        task = HousekeepingTask.objects.create(
            room=self.room,
            task_type=HousekeepingTask.TaskType.CHECKOUT_CLEAN,
            status=HousekeepingTask.Status.COMPLETED,
            scheduled_date=date.today() - timedelta(days=400),
            created_by=self.user,
        )
        HousekeepingTask.objects.filter(pk=task.pk).update(
            created_at=timezone.now() - timedelta(days=400)
        )

        results = apply_retention_policy()
        self.assertEqual(results["housekeeping_task"], 1)
        self.assertFalse(HousekeepingTask.objects.filter(pk=task.pk).exists())

    def test_pending_housekeeping_kept(self):
        """Pending housekeeping tasks are preserved regardless of age."""
        task = HousekeepingTask.objects.create(
            room=self.room,
            task_type=HousekeepingTask.TaskType.CHECKOUT_CLEAN,
            status=HousekeepingTask.Status.PENDING,
            scheduled_date=date.today() - timedelta(days=400),
            created_by=self.user,
        )
        HousekeepingTask.objects.filter(pk=task.pk).update(
            created_at=timezone.now() - timedelta(days=400)
        )

        results = apply_retention_policy()
        self.assertEqual(results["housekeeping_task"], 0)
        self.assertTrue(HousekeepingTask.objects.filter(pk=task.pk).exists())


class TestBookingRetention(RetentionTestBase):
    """Tests for booking cleanup (3-year retention)."""

    def _create_old_booking(self, status, days_ago):
        """Helper to create a booking with check_out_date in the past."""
        checkout = date.today() - timedelta(days=days_ago)
        checkin = checkout - timedelta(days=1)
        return Booking.objects.create(
            room=self.room,
            guest=self.guest,
            check_in_date=checkin,
            check_out_date=checkout,
            status=status,
            nightly_rate=500000,
            total_amount=500000,
        )

    def test_old_checked_out_bookings_deleted(self):
        """Checked-out bookings older than 3 years are deleted."""
        booking = self._create_old_booking(Booking.Status.CHECKED_OUT, 1100)

        results = apply_retention_policy()
        self.assertEqual(results["booking"], 1)
        self.assertFalse(Booking.objects.filter(pk=booking.pk).exists())

    def test_recent_checked_out_bookings_kept(self):
        """Checked-out bookings within 3 years are preserved."""
        booking = self._create_old_booking(Booking.Status.CHECKED_OUT, 1000)

        results = apply_retention_policy()
        self.assertEqual(results["booking"], 0)
        self.assertTrue(Booking.objects.filter(pk=booking.pk).exists())

    def test_active_bookings_kept(self):
        """Checked-in bookings are preserved regardless of age."""
        booking = self._create_old_booking(Booking.Status.CHECKED_IN, 1100)

        results = apply_retention_policy()
        self.assertEqual(results["booking"], 0)
        self.assertTrue(Booking.objects.filter(pk=booking.pk).exists())

    def test_booking_cascade_deletes_payments(self):
        """Deleting a booking cascades to its payments."""
        from hotel_api.models import Payment

        booking = self._create_old_booking(Booking.Status.CHECKED_OUT, 1100)
        payment = Payment.objects.create(
            booking=booking,
            amount=500000,
            payment_date=booking.check_out_date,
        )

        apply_retention_policy()
        self.assertFalse(Booking.objects.filter(pk=booking.pk).exists())
        self.assertFalse(Payment.objects.filter(pk=payment.pk).exists())


class TestNightAuditRetention(RetentionTestBase):
    """Tests for night audit cleanup (5-year retention)."""

    def test_old_closed_night_audits_deleted(self):
        """Closed night audits older than 5 years are deleted."""
        audit = NightAudit.objects.create(
            audit_date=date.today() - timedelta(days=1830),
            status=NightAudit.Status.CLOSED,
            performed_by=self.user,
        )

        results = apply_retention_policy()
        self.assertEqual(results["night_audit"], 1)
        self.assertFalse(NightAudit.objects.filter(pk=audit.pk).exists())

    def test_draft_night_audits_kept(self):
        """Draft night audits are preserved regardless of age."""
        audit = NightAudit.objects.create(
            audit_date=date.today() - timedelta(days=1830),
            status=NightAudit.Status.DRAFT,
            performed_by=self.user,
        )

        results = apply_retention_policy()
        self.assertEqual(results["night_audit"], 0)
        self.assertTrue(NightAudit.objects.filter(pk=audit.pk).exists())


class TestAuditLogRetention(RetentionTestBase):
    """Tests for sensitive data access log retention (7-year retention)."""

    def test_audit_logs_kept_7_years(self):
        """Audit logs within 7 years are preserved."""
        log = SensitiveDataAccessLog.objects.create(
            user=self.user,
            action="view_guest",
            resource_type="guest",
            resource_id=1,
            fields_accessed=["id_number"],
            ip_address="127.0.0.1",
        )
        SensitiveDataAccessLog.objects.filter(pk=log.pk).update(
            timestamp=timezone.now() - timedelta(days=2550)
        )

        results = apply_retention_policy()
        self.assertEqual(results["sensitive_data_access_log"], 0)
        self.assertTrue(SensitiveDataAccessLog.objects.filter(pk=log.pk).exists())

    def test_very_old_audit_logs_deleted(self):
        """Audit logs older than 7 years are deleted."""
        log = SensitiveDataAccessLog.objects.create(
            user=self.user,
            action="view_guest",
            resource_type="guest",
            resource_id=1,
            fields_accessed=["id_number"],
            ip_address="127.0.0.1",
        )
        SensitiveDataAccessLog.objects.filter(pk=log.pk).update(
            timestamp=timezone.now() - timedelta(days=2560)
        )

        results = apply_retention_policy()
        self.assertEqual(results["sensitive_data_access_log"], 1)
        self.assertFalse(SensitiveDataAccessLog.objects.filter(pk=log.pk).exists())


class TestRetentionPolicyOptions(RetentionTestBase):
    """Tests for dry run and model filter options."""

    def test_dry_run_no_deletions(self):
        """Dry run reports counts without deleting records."""
        old_notif = Notification.objects.create(
            recipient=self.user,
            title="Old notification",
            body="Old body",
        )
        Notification.objects.filter(pk=old_notif.pk).update(
            created_at=timezone.now() - timedelta(days=91)
        )

        results = apply_retention_policy(dry_run=True)
        self.assertEqual(results["notification"], 1)
        # Record should still exist
        self.assertTrue(Notification.objects.filter(pk=old_notif.pk).exists())

    def test_model_filter(self):
        """Model filter only processes the specified model."""
        old_notif = Notification.objects.create(
            recipient=self.user,
            title="Old notification",
            body="Old body",
        )
        Notification.objects.filter(pk=old_notif.pk).update(
            created_at=timezone.now() - timedelta(days=91)
        )

        # Filter to only process device_token — notification should remain
        results = apply_retention_policy(model_filter="device_token")
        self.assertNotIn("notification", results)
        self.assertTrue(Notification.objects.filter(pk=old_notif.pk).exists())

    def test_model_filter_processes_target(self):
        """Model filter processes the specified model correctly."""
        old_notif = Notification.objects.create(
            recipient=self.user,
            title="Old notification",
            body="Old body",
        )
        Notification.objects.filter(pk=old_notif.pk).update(
            created_at=timezone.now() - timedelta(days=91)
        )

        results = apply_retention_policy(model_filter="notification")
        self.assertEqual(results["notification"], 1)
        self.assertFalse(Notification.objects.filter(pk=old_notif.pk).exists())


class TestLostAndFoundRetention(RetentionTestBase):
    """Tests for lost and found cleanup (2-year retention, disposed only)."""

    def test_disposed_items_deleted(self):
        """Disposed lost & found items older than 2 years are deleted."""
        item = LostAndFound.objects.create(
            item_name="Old Phone",
            status=LostAndFound.Status.DISPOSED,
            found_date=date.today() - timedelta(days=800),
            found_by=self.user,
        )
        LostAndFound.objects.filter(pk=item.pk).update(
            created_at=timezone.now() - timedelta(days=800)
        )

        results = apply_retention_policy()
        self.assertEqual(results["lost_and_found"], 1)
        self.assertFalse(LostAndFound.objects.filter(pk=item.pk).exists())

    def test_stored_items_kept(self):
        """Non-disposed lost & found items are preserved."""
        item = LostAndFound.objects.create(
            item_name="Stored Wallet",
            status=LostAndFound.Status.STORED,
            found_date=date.today() - timedelta(days=800),
            found_by=self.user,
        )
        LostAndFound.objects.filter(pk=item.pk).update(
            created_at=timezone.now() - timedelta(days=800)
        )

        results = apply_retention_policy()
        self.assertEqual(results["lost_and_found"], 0)
        self.assertTrue(LostAndFound.objects.filter(pk=item.pk).exists())
