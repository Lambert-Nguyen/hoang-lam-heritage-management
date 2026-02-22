"""Tests for Phase 5.3: Guest Messaging System."""

from datetime import date, timedelta
from decimal import Decimal

from django.contrib.auth.models import User

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.messaging_service import (
    EmailService,
    GuestMessagingService,
    SMSService,
    ZaloService,
)
from hotel_api.models import (
    Booking,
    Guest,
    GuestMessage,
    HotelUser,
    MessageTemplate,
    Room,
    RoomType,
)

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
def room_type(db):
    return RoomType.objects.create(
        name="Phòng Đôi",
        name_en="Double Room",
        base_rate=Decimal("500000"),
        max_guests=2,
    )


@pytest.fixture
def room(db, room_type):
    return Room.objects.create(
        number="101",
        name="Phòng 101",
        room_type=room_type,
        floor=1,
        status=Room.Status.AVAILABLE,
    )


@pytest.fixture
def guest(db):
    return Guest.objects.create(
        full_name="Nguyễn Văn A",
        phone="0901234567",
        email="nguyen.a@example.com",
        id_type=Guest.IDType.CCCD,
        id_number="001234567890",
    )


@pytest.fixture
def booking(db, room, guest, owner_user):
    return Booking.objects.create(
        room=room,
        guest=guest,
        check_in_date=date.today(),
        check_out_date=date.today() + timedelta(days=2),
        status=Booking.Status.CONFIRMED,
        source=Booking.Source.WALK_IN,
        nightly_rate=Decimal("500000"),
        total_amount=Decimal("1000000"),
        created_by=owner_user,
    )


@pytest.fixture
def sms_template(db):
    return MessageTemplate.objects.create(
        name="Test SMS Confirmation",
        template_type=MessageTemplate.TemplateType.BOOKING_CONFIRMATION,
        channel=MessageTemplate.Channel.SMS,
        subject="Xác nhận đặt phòng",
        body="Chào {guest_name}, phòng {room_number} từ {check_in_date} đến {check_out_date}.",
    )


@pytest.fixture
def email_template(db):
    return MessageTemplate.objects.create(
        name="Test Email Confirmation",
        template_type=MessageTemplate.TemplateType.BOOKING_CONFIRMATION,
        channel=MessageTemplate.Channel.EMAIL,
        subject="Xác nhận #{room_number} - {hotel_name}",
        body="Kính chào {guest_name},\n\nPhòng: {room_number}\nNgày: {check_in_date} → {check_out_date}\nTổng: {total_amount}",
    )


@pytest.fixture
def pre_arrival_template(db):
    return MessageTemplate.objects.create(
        name="Test Pre-Arrival",
        template_type=MessageTemplate.TemplateType.PRE_ARRIVAL,
        channel=MessageTemplate.Channel.SMS,
        subject="Chào mừng - {hotel_name}",
        body="Chào {guest_name}, WiFi: {wifi_password}",
    )


@pytest.fixture
def authenticated_client(api_client, owner_user):
    api_client.force_authenticate(user=owner_user)
    return api_client


# ===== Model Tests =====


class TestMessageTemplateModel:
    def test_create_template(self, sms_template):
        assert sms_template.pk is not None
        assert sms_template.name == "Test SMS Confirmation"
        assert sms_template.template_type == MessageTemplate.TemplateType.BOOKING_CONFIRMATION
        assert sms_template.channel == MessageTemplate.Channel.SMS
        assert sms_template.is_active is True

    def test_template_str(self, sms_template):
        assert "Test SMS Confirmation" in str(sms_template)

    def test_template_render(self, sms_template):
        context = {
            "guest_name": "Nguyễn Văn A",
            "room_number": "101",
            "check_in_date": "01/01/2026",
            "check_out_date": "03/01/2026",
        }
        subject, body = sms_template.render(context)
        assert subject == "Xác nhận đặt phòng"
        assert "Nguyễn Văn A" in body
        assert "101" in body
        assert "01/01/2026" in body

    def test_template_render_with_missing_vars(self, sms_template):
        context = {"guest_name": "Test"}
        subject, body = sms_template.render(context)
        assert "Test" in body
        # Missing vars remain as placeholders
        assert "{room_number}" in body

    def test_available_variables(self):
        assert "guest_name" in MessageTemplate.AVAILABLE_VARIABLES
        assert "room_number" in MessageTemplate.AVAILABLE_VARIABLES
        assert "hotel_name" in MessageTemplate.AVAILABLE_VARIABLES
        assert "wifi_password" in MessageTemplate.AVAILABLE_VARIABLES


class TestGuestMessageModel:
    def test_create_message(self, db, guest, owner_user):
        message = GuestMessage.objects.create(
            guest=guest,
            channel=MessageTemplate.Channel.SMS,
            subject="Test",
            body="Test message",
            sent_by=owner_user,
        )
        assert message.pk is not None
        assert message.status == GuestMessage.Status.DRAFT
        assert message.guest == guest

    def test_message_str(self, db, guest, owner_user):
        message = GuestMessage.objects.create(
            guest=guest,
            channel=MessageTemplate.Channel.SMS,
            subject="Test Subject",
            body="Test body",
            sent_by=owner_user,
        )
        assert "Nguyễn Văn A" in str(message)
        assert "Test Subject" in str(message)


# ===== Service Tests =====


class TestSMSService:
    def test_send_disabled(self, settings):
        settings.SMS_ENABLED = False
        result = SMSService.send("0901234567", "Test message")
        assert result["success"] is True
        assert "mock-sms" in result["message_id"]

    def test_send_empty_phone(self):
        result = SMSService.send("", "Test message")
        assert result["success"] is False


class TestEmailService:
    def test_send_disabled(self, settings):
        settings.EMAIL_ENABLED = False
        result = EmailService.send("test@example.com", "Subject", "Body")
        assert result["success"] is True
        assert "mock-email" in result["message_id"]

    def test_send_empty_email(self):
        result = EmailService.send("", "Subject", "Body")
        assert result["success"] is False


class TestZaloService:
    def test_send_disabled(self, settings):
        settings.ZALO_ENABLED = False
        result = ZaloService.send("0901234567", "Test message")
        assert result["success"] is True
        assert "mock-zalo" in result["message_id"]

    def test_send_empty_phone(self):
        result = ZaloService.send("", "Test message")
        assert result["success"] is False


class TestGuestMessagingService:
    def test_get_recipient_sms(self, guest):
        address = GuestMessagingService.get_recipient_address(guest, "sms")
        assert address == "0901234567"

    def test_get_recipient_email(self, guest):
        address = GuestMessagingService.get_recipient_address(guest, "email")
        assert address == "nguyen.a@example.com"

    def test_get_recipient_zalo(self, guest):
        address = GuestMessagingService.get_recipient_address(guest, "zalo")
        assert address == "0901234567"

    def test_render_template_with_booking(self, sms_template, guest, booking):
        subject, body = GuestMessagingService.render_template(sms_template, guest, booking)
        assert "Nguyễn Văn A" in body
        assert "101" in body

    def test_render_template_without_booking(self, sms_template, guest):
        subject, body = GuestMessagingService.render_template(sms_template, guest, None)
        assert "Nguyễn Văn A" in body

    def test_send_message_sms(self, db, guest, owner_user, settings):
        settings.SMS_ENABLED = False
        message = GuestMessage.objects.create(
            guest=guest,
            channel="sms",
            subject="Test",
            body="Test message",
            sent_by=owner_user,
        )
        result = GuestMessagingService.send_message(message)
        assert result is True
        message.refresh_from_db()
        assert message.status == "sent"
        assert message.recipient_address == "0901234567"

    def test_send_message_email(self, db, guest, owner_user, settings):
        settings.EMAIL_ENABLED = False
        message = GuestMessage.objects.create(
            guest=guest,
            channel="email",
            subject="Test Subject",
            body="Test body",
            sent_by=owner_user,
        )
        result = GuestMessagingService.send_message(message)
        assert result is True
        message.refresh_from_db()
        assert message.status == "sent"
        assert message.recipient_address == "nguyen.a@example.com"

    def test_send_message_no_contact(self, db, owner_user):
        guest_no_email = Guest.objects.create(
            full_name="No Email",
            phone="0999999999",
            email="",
        )
        message = GuestMessage.objects.create(
            guest=guest_no_email,
            channel="email",
            subject="Test",
            body="Test",
            sent_by=owner_user,
        )
        result = GuestMessagingService.send_message(message)
        assert result is False
        message.refresh_from_db()
        assert message.status == "failed"


# ===== API Tests =====


@pytest.mark.django_db
class TestMessageTemplateAPI:
    def test_list_templates(self, authenticated_client, sms_template, email_template):
        response = authenticated_client.get("/api/v1/message-templates/")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        # Handle paginated or non-paginated response
        results = data.get("results", data) if isinstance(data, dict) else data
        assert len(results) >= 2

    def test_create_template(self, authenticated_client):
        response = authenticated_client.post(
            "/api/v1/message-templates/",
            {
                "name": "New Template",
                "template_type": "custom",
                "channel": "sms",
                "subject": "Test",
                "body": "Hello {guest_name}",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["name"] == "New Template"

    def test_retrieve_template(self, authenticated_client, sms_template):
        response = authenticated_client.get(f"/api/v1/message-templates/{sms_template.pk}/")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["name"] == sms_template.name
        assert "available_variables" in data

    def test_update_template(self, authenticated_client, sms_template):
        response = authenticated_client.patch(
            f"/api/v1/message-templates/{sms_template.pk}/",
            {"name": "Updated Name"},
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.json()["name"] == "Updated Name"

    def test_delete_template(self, authenticated_client, sms_template):
        response = authenticated_client.delete(f"/api/v1/message-templates/{sms_template.pk}/")
        assert response.status_code == status.HTTP_204_NO_CONTENT
        assert not MessageTemplate.objects.filter(pk=sms_template.pk).exists()

    def test_filter_by_type(self, authenticated_client, sms_template, pre_arrival_template):
        response = authenticated_client.get(
            "/api/v1/message-templates/?template_type=booking_confirmation"
        )
        assert response.status_code == status.HTTP_200_OK
        results = response.json().get("results", response.json())
        if isinstance(results, dict):
            results = results.get("results", [results])
        for t in results:
            assert t["template_type"] == "booking_confirmation"

    def test_filter_by_channel(self, authenticated_client, sms_template, email_template):
        response = authenticated_client.get("/api/v1/message-templates/?channel=email")
        assert response.status_code == status.HTTP_200_OK

    def test_preview_template(self, authenticated_client, sms_template, guest, booking):
        response = authenticated_client.post(
            "/api/v1/message-templates/preview/",
            {
                "template": sms_template.pk,
                "guest": guest.pk,
                "booking": booking.pk,
            },
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "Nguyễn Văn A" in data["body"]
        assert "101" in data["body"]
        assert data["channel"] == "sms"
        assert data["recipient_address"] == "0901234567"

    def test_preview_template_without_booking(self, authenticated_client, sms_template, guest):
        response = authenticated_client.post(
            "/api/v1/message-templates/preview/",
            {
                "template": sms_template.pk,
                "guest": guest.pk,
            },
            format="json",
        )
        assert response.status_code == status.HTTP_200_OK

    def test_preview_template_not_found(self, authenticated_client, guest):
        response = authenticated_client.post(
            "/api/v1/message-templates/preview/",
            {"template": 99999, "guest": guest.pk},
            format="json",
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.django_db
class TestGuestMessageAPI:
    def test_list_messages(self, authenticated_client, guest, owner_user):
        GuestMessage.objects.create(
            guest=guest,
            channel="sms",
            subject="Test",
            body="Test body",
            sent_by=owner_user,
        )
        response = authenticated_client.get("/api/v1/guest-messages/")
        assert response.status_code == status.HTTP_200_OK

    def test_send_message(self, authenticated_client, guest, settings):
        settings.SMS_ENABLED = False
        response = authenticated_client.post(
            "/api/v1/guest-messages/send/",
            {
                "guest": guest.pk,
                "channel": "sms",
                "subject": "Test",
                "body": "Hello there!",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["status"] == "sent"
        assert data["guest_name"] == "Nguyễn Văn A"
        assert data["recipient_address"] == "0901234567"

    def test_send_message_with_booking(self, authenticated_client, guest, booking, settings):
        settings.SMS_ENABLED = False
        response = authenticated_client.post(
            "/api/v1/guest-messages/send/",
            {
                "guest": guest.pk,
                "booking": booking.pk,
                "channel": "sms",
                "subject": "Booking Update",
                "body": "Your booking is confirmed",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["booking"] == booking.pk

    def test_send_message_with_template(self, authenticated_client, guest, sms_template, settings):
        settings.SMS_ENABLED = False
        response = authenticated_client.post(
            "/api/v1/guest-messages/send/",
            {
                "guest": guest.pk,
                "template": sms_template.pk,
                "channel": "sms",
                "subject": "From template",
                "body": "Hello Nguyễn Văn A",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["template"] == sms_template.pk

    def test_send_email_message(self, authenticated_client, guest, settings):
        settings.EMAIL_ENABLED = False
        response = authenticated_client.post(
            "/api/v1/guest-messages/send/",
            {
                "guest": guest.pk,
                "channel": "email",
                "subject": "Email Test",
                "body": "Email body",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_201_CREATED
        assert response.json()["status"] == "sent"

    def test_send_message_guest_not_found(self, authenticated_client):
        response = authenticated_client.post(
            "/api/v1/guest-messages/send/",
            {
                "guest": 99999,
                "channel": "sms",
                "subject": "Test",
                "body": "Test",
            },
            format="json",
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_filter_messages_by_guest(self, authenticated_client, guest, owner_user):
        GuestMessage.objects.create(
            guest=guest,
            channel="sms",
            subject="Test",
            body="Test",
            sent_by=owner_user,
        )
        response = authenticated_client.get(f"/api/v1/guest-messages/?guest={guest.pk}")
        assert response.status_code == status.HTTP_200_OK

    def test_filter_messages_by_status(self, authenticated_client, guest, owner_user):
        GuestMessage.objects.create(
            guest=guest,
            channel="sms",
            subject="Test",
            body="Test",
            status=GuestMessage.Status.SENT,
            sent_by=owner_user,
        )
        response = authenticated_client.get("/api/v1/guest-messages/?status=sent")
        assert response.status_code == status.HTTP_200_OK

    def test_resend_failed_message(self, authenticated_client, guest, owner_user, settings):
        settings.SMS_ENABLED = False
        message = GuestMessage.objects.create(
            guest=guest,
            channel="sms",
            subject="Failed message",
            body="Test",
            status=GuestMessage.Status.FAILED,
            recipient_address="0901234567",
            sent_by=owner_user,
        )
        response = authenticated_client.post(f"/api/v1/guest-messages/{message.pk}/resend/")
        assert response.status_code == status.HTTP_200_OK
        assert response.json()["status"] == "sent"

    def test_resend_non_failed_message(self, authenticated_client, guest, owner_user):
        message = GuestMessage.objects.create(
            guest=guest,
            channel="sms",
            subject="Sent message",
            body="Test",
            status=GuestMessage.Status.SENT,
            sent_by=owner_user,
        )
        response = authenticated_client.post(f"/api/v1/guest-messages/{message.pk}/resend/")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_unauthenticated_access(self, api_client):
        response = api_client.get("/api/v1/guest-messages/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

        response = api_client.get("/api/v1/message-templates/")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
