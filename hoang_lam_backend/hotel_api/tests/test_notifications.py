"""Tests for Phase 5.1: Notification System."""

from datetime import date, timedelta
from decimal import Decimal
from io import StringIO

import pytest
from django.contrib.auth.models import User
from django.core.management import call_command
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import (
    Booking,
    DeviceToken,
    Guest,
    HotelUser,
    Notification,
    Room,
    RoomType,
)
from hotel_api.services import PushNotificationService


# ===== Fixtures =====


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def owner_user(db):
    user = User.objects.create_user(username="owner", password="testpass123")
    HotelUser.objects.create(user=user, role=HotelUser.Role.OWNER, receive_notifications=True)
    return user


@pytest.fixture
def manager_user(db):
    user = User.objects.create_user(username="manager", password="testpass123")
    HotelUser.objects.create(user=user, role=HotelUser.Role.MANAGER, receive_notifications=True)
    return user


@pytest.fixture
def staff_user(db):
    user = User.objects.create_user(username="staff", password="testpass123")
    HotelUser.objects.create(user=user, role=HotelUser.Role.STAFF, receive_notifications=True)
    return user


@pytest.fixture
def room_type(db):
    return RoomType.objects.create(
        name="Phòng Đôi",
        name_en="Double Room",
        base_rate=Decimal("500000"),
        max_guests=2,
    )


@pytest.fixture
def room(room_type):
    return Room.objects.create(
        room_type=room_type,
        number="101",
        name="Phòng 101",
        floor=1,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def guest(db):
    return Guest.objects.create(
        full_name="Nguyễn Văn A",
        phone="0901234567",
    )


@pytest.fixture
def booking(guest, room, owner_user):
    return Booking.objects.create(
        guest=guest,
        room=room,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        nightly_rate=Decimal("500000"),
        total_amount=Decimal("1000000"),
        status=Booking.Status.CONFIRMED,
        created_by=owner_user,
    )


@pytest.fixture(autouse=True)
def reset_fcm_service():
    """Reset PushNotificationService state before each test."""
    PushNotificationService._reset()
    yield
    PushNotificationService._reset()


# ===== Notification Model Tests =====


@pytest.mark.django_db
class TestNotificationModel:
    def test_create_notification(self, owner_user):
        notification = Notification.objects.create(
            recipient=owner_user,
            notification_type=Notification.NotificationType.BOOKING_CREATED,
            title="Đặt phòng mới: 101",
            body="Nguyễn Văn A - Phòng 101",
            data={"booking_id": "1", "room_number": "101"},
        )
        assert not notification.is_read
        assert not notification.is_sent
        assert notification.created_at is not None
        assert str(notification) == "owner - Đặt phòng mới: 101"

    def test_mark_read(self, owner_user):
        notification = Notification.objects.create(
            recipient=owner_user,
            notification_type=Notification.NotificationType.GENERAL,
            title="Test",
            body="Test body",
        )
        notification.mark_read()
        notification.refresh_from_db()
        assert notification.is_read
        assert notification.read_at is not None


# ===== DeviceToken Model Tests =====


@pytest.mark.django_db
class TestDeviceTokenModel:
    def test_create_device_token(self, owner_user):
        token = DeviceToken.objects.create(
            user=owner_user,
            token="fcm_token_123",
            platform=DeviceToken.Platform.ANDROID,
            device_name="Samsung Galaxy S24",
        )
        assert token.is_active
        assert token.platform == "android"

    def test_unique_token(self, owner_user):
        DeviceToken.objects.create(
            user=owner_user,
            token="same_token",
            platform=DeviceToken.Platform.ANDROID,
        )
        with pytest.raises(Exception):
            DeviceToken.objects.create(
                user=owner_user,
                token="same_token",
                platform=DeviceToken.Platform.IOS,
            )


# ===== PushNotificationService Tests =====
# FCM_ENABLED=False in development settings, so push won't actually send


@pytest.mark.django_db
class TestPushNotificationService:
    def test_notify_staff_creates_records(self, owner_user, manager_user):
        notifications = PushNotificationService.notify_staff(
            notification_type=Notification.NotificationType.BOOKING_CREATED,
            title="Đặt phòng mới: 101",
            body="Khách Test - Phòng 101",
            data={"booking_id": "1"},
        )
        assert len(notifications) == 2
        assert Notification.objects.count() == 2

    def test_notify_staff_excludes_user(self, owner_user, manager_user):
        notifications = PushNotificationService.notify_staff(
            notification_type=Notification.NotificationType.BOOKING_CREATED,
            title="Test",
            body="Test",
            exclude_user=owner_user,
        )
        assert len(notifications) == 1
        assert notifications[0].recipient == manager_user

    def test_notify_staff_respects_preference(self, owner_user, manager_user):
        profile = manager_user.hotel_profile
        profile.receive_notifications = False
        profile.save()

        notifications = PushNotificationService.notify_staff(
            notification_type=Notification.NotificationType.GENERAL,
            title="Test",
            body="Test",
        )
        assert len(notifications) == 1
        assert notifications[0].recipient == owner_user

    def test_notify_staff_with_booking(self, owner_user, booking):
        notifications = PushNotificationService.notify_staff(
            notification_type=Notification.NotificationType.BOOKING_CREATED,
            title="Test",
            body="Test",
            booking=booking,
        )
        for n in notifications:
            assert n.booking == booking


# ===== Notification API Tests =====


@pytest.mark.django_db
class TestNotificationAPI:
    def setup_method(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="apiuser", password="testpass123")
        HotelUser.objects.create(user=self.user, role=HotelUser.Role.STAFF)
        self.notif1 = Notification.objects.create(
            recipient=self.user,
            notification_type=Notification.NotificationType.BOOKING_CREATED,
            title="Đặt phòng mới: 101",
            body="Test body 1",
        )
        self.notif2 = Notification.objects.create(
            recipient=self.user,
            notification_type=Notification.NotificationType.CHECKOUT_REMINDER,
            title="Nhắc trả phòng: 102",
            body="Test body 2",
        )

    def test_list_notifications(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get("/api/v1/notifications/")
        assert response.status_code == status.HTTP_200_OK
        assert len(response.data["results"]) == 2

    def test_list_unauthenticated(self):
        response = self.client.get("/api/v1/notifications/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_only_own_notifications(self):
        other_user = User.objects.create_user(username="other", password="testpass123")
        HotelUser.objects.create(user=other_user, role=HotelUser.Role.STAFF)
        Notification.objects.create(
            recipient=other_user,
            notification_type=Notification.NotificationType.GENERAL,
            title="Other user notification",
            body="Should not be visible",
        )

        self.client.force_authenticate(user=self.user)
        response = self.client.get("/api/v1/notifications/")
        assert len(response.data["results"]) == 2

    def test_mark_read(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.post(f"/api/v1/notifications/{self.notif1.id}/read/")
        assert response.status_code == status.HTTP_200_OK
        self.notif1.refresh_from_db()
        assert self.notif1.is_read

    def test_mark_all_read(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.post("/api/v1/notifications/read-all/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["marked_read"] == 2
        self.notif1.refresh_from_db()
        self.notif2.refresh_from_db()
        assert self.notif1.is_read
        assert self.notif2.is_read

    def test_unread_count(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get("/api/v1/notifications/unread-count/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["unread_count"] == 2

        self.notif1.mark_read()
        response = self.client.get("/api/v1/notifications/unread-count/")
        assert response.data["unread_count"] == 1


# ===== DeviceToken API Tests =====


@pytest.mark.django_db
class TestDeviceTokenAPI:
    def setup_method(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="tokenuser", password="testpass123")
        HotelUser.objects.create(user=self.user, role=HotelUser.Role.STAFF)

    def test_register_device_token(self):
        self.client.force_authenticate(user=self.user)
        data = {
            "token": "fcm_token_abc123",
            "platform": "android",
            "device_name": "Samsung Galaxy S24",
        }
        response = self.client.post("/api/v1/devices/token/", data, format="json")
        assert response.status_code == status.HTTP_201_CREATED
        assert DeviceToken.objects.count() == 1
        assert DeviceToken.objects.first().user == self.user

    def test_register_duplicate_updates(self):
        self.client.force_authenticate(user=self.user)
        data = {"token": "same_token", "platform": "android"}
        self.client.post("/api/v1/devices/token/", data, format="json")
        self.client.post("/api/v1/devices/token/", data, format="json")
        assert DeviceToken.objects.count() == 1

    def test_deactivate_device_token(self):
        self.client.force_authenticate(user=self.user)
        DeviceToken.objects.create(
            user=self.user,
            token="token_to_remove",
            platform=DeviceToken.Platform.ANDROID,
        )
        response = self.client.delete(
            "/api/v1/devices/token/",
            {"token": "token_to_remove"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        token = DeviceToken.objects.first()
        assert not token.is_active

    def test_register_unauthenticated(self):
        response = self.client.post(
            "/api/v1/devices/token/",
            {"token": "test", "platform": "android"},
            format="json",
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ===== Notification Preferences API Tests =====


@pytest.mark.django_db
class TestNotificationPreferencesAPI:
    def setup_method(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username="prefuser", password="testpass123")
        self.profile = HotelUser.objects.create(
            user=self.user,
            role=HotelUser.Role.STAFF,
            receive_notifications=True,
        )

    def test_get_preferences(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get("/api/v1/notifications/preferences/")
        assert response.status_code == status.HTTP_200_OK
        assert response.data["receive_notifications"] is True

    def test_update_preferences(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.put(
            "/api/v1/notifications/preferences/",
            {"receive_notifications": False},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.data["receive_notifications"] is False
        self.profile.refresh_from_db()
        assert not self.profile.receive_notifications

    def test_preferences_unauthenticated(self):
        response = self.client.get("/api/v1/notifications/preferences/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


# ===== Booking Notification Integration Tests =====


@pytest.mark.django_db
class TestBookingNotificationIntegration:
    def setup_method(self):
        self.client = APIClient()

        self.mom = User.objects.create_user(username="mom", password="testpass123")
        HotelUser.objects.create(
            user=self.mom,
            role=HotelUser.Role.OWNER,
            receive_notifications=True,
        )

        self.brother = User.objects.create_user(username="brother", password="testpass123")
        HotelUser.objects.create(
            user=self.brother,
            role=HotelUser.Role.MANAGER,
            receive_notifications=True,
        )

        self.room_type = RoomType.objects.create(
            name="Deluxe",
            base_rate=Decimal("500000"),
            max_guests=2,
        )
        self.room = Room.objects.create(
            room_type=self.room_type,
            number="101",
            floor=1,
            status=Room.Status.AVAILABLE,
        )
        self.guest = Guest.objects.create(
            full_name="Nguyễn Văn A",
            phone="0901234567",
        )

    def test_check_in_creates_notification(self):
        booking = Booking.objects.create(
            guest=self.guest,
            room=self.room,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=2),
            nightly_rate=Decimal("500000"),
            total_amount=Decimal("1000000"),
            status=Booking.Status.CONFIRMED,
            created_by=self.mom,
        )

        self.client.force_authenticate(user=self.mom)
        response = self.client.post(f"/api/v1/bookings/{booking.id}/check-in/")
        assert response.status_code == status.HTTP_200_OK

        # Mom performed the action, so only brother gets notification
        brother_notifs = Notification.objects.filter(recipient=self.brother)
        assert brother_notifs.exists()
        assert (
            brother_notifs.first().notification_type
            == Notification.NotificationType.CHECKIN_COMPLETED
        )

    def test_check_out_creates_notification(self):
        booking = Booking.objects.create(
            guest=self.guest,
            room=self.room,
            check_in_date=date.today() - timedelta(days=2),
            check_out_date=date.today(),
            nightly_rate=Decimal("500000"),
            total_amount=Decimal("1000000"),
            status=Booking.Status.CHECKED_IN,
            created_by=self.mom,
        )
        self.room.status = Room.Status.OCCUPIED
        self.room.save()

        self.client.force_authenticate(user=self.brother)
        response = self.client.post(f"/api/v1/bookings/{booking.id}/check-out/")
        assert response.status_code == status.HTTP_200_OK

        # Brother performed the action, so only mom gets notification
        mom_notifs = Notification.objects.filter(recipient=self.mom)
        assert mom_notifs.exists()
        assert (
            mom_notifs.first().notification_type == Notification.NotificationType.CHECKOUT_COMPLETED
        )


# ===== Management Command Tests =====


@pytest.mark.django_db
class TestReminderCommands:
    def setup_method(self):
        self.user = User.objects.create_user(username="staff", password="testpass123")
        HotelUser.objects.create(
            user=self.user,
            role=HotelUser.Role.STAFF,
            receive_notifications=True,
        )

        self.room_type = RoomType.objects.create(
            name="Standard",
            base_rate=Decimal("300000"),
            max_guests=2,
        )
        self.room = Room.objects.create(
            room_type=self.room_type,
            number="201",
            floor=2,
        )
        self.guest = Guest.objects.create(
            full_name="Trần Thị B",
            phone="0987654321",
        )

    def test_checkout_reminder_command(self):
        Booking.objects.create(
            guest=self.guest,
            room=self.room,
            check_in_date=date.today() - timedelta(days=2),
            check_out_date=date.today(),
            nightly_rate=Decimal("300000"),
            total_amount=Decimal("600000"),
            status=Booking.Status.CHECKED_IN,
            created_by=self.user,
        )

        out = StringIO()
        call_command("send_checkout_reminders", stdout=out)
        assert "1 check-out reminder" in out.getvalue()

        notifs = Notification.objects.filter(
            notification_type=Notification.NotificationType.CHECKOUT_REMINDER
        )
        assert notifs.count() == 1

    def test_checkin_reminder_command(self):
        Booking.objects.create(
            guest=self.guest,
            room=self.room,
            check_in_date=date.today(),
            check_out_date=date.today() + timedelta(days=2),
            nightly_rate=Decimal("300000"),
            total_amount=Decimal("600000"),
            status=Booking.Status.CONFIRMED,
            created_by=self.user,
        )

        out = StringIO()
        call_command("send_checkin_reminders", stdout=out)
        assert "1 check-in reminder" in out.getvalue()

        notifs = Notification.objects.filter(
            notification_type=Notification.NotificationType.CHECKIN_REMINDER
        )
        assert notifs.count() == 1

    def test_no_pending_checkouts(self):
        out = StringIO()
        call_command("send_checkout_reminders", stdout=out)
        assert "No pending check-outs" in out.getvalue()
