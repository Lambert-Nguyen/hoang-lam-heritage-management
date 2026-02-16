"""Tests for sensitive data access audit logging."""

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import Guest, HotelUser, SensitiveDataAccessLog

User = get_user_model()


class TestAuditLogging(TestCase):
    """Tests for audit logging on guest data access."""

    def setUp(self):
        self.staff_user = User.objects.create_user(username="staff", password="testpass123")
        HotelUser.objects.create(user=self.staff_user, role=HotelUser.Role.STAFF)

        self.manager_user = User.objects.create_user(username="manager", password="testpass123")
        HotelUser.objects.create(user=self.manager_user, role=HotelUser.Role.MANAGER)

        self.guest = Guest.objects.create(
            full_name="Test Guest",
            phone="0900000001",
            id_number="001234567890",
            nationality="Vietnam",
        )
        self.client = APIClient()

    def test_guest_retrieve_creates_audit_log(self):
        """Viewing a single guest creates an audit log entry."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/guests/{self.guest.id}/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        log = SensitiveDataAccessLog.objects.filter(action="view_guest").first()
        self.assertIsNotNone(log)
        self.assertEqual(log.user, self.staff_user)
        self.assertEqual(log.resource_id, self.guest.id)

    def test_guest_list_creates_audit_log(self):
        """Listing guests creates an audit log entry."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get("/api/v1/guests/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        log = SensitiveDataAccessLog.objects.filter(action="list_guests").first()
        self.assertIsNotNone(log)
        self.assertEqual(log.user, self.staff_user)

    def test_guest_search_creates_audit_log(self):
        """Searching for guests creates an audit log entry."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.post(
            "/api/v1/guests/search/",
            {"query": "Test Guest"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        log = SensitiveDataAccessLog.objects.filter(action="search_guest").first()
        self.assertIsNotNone(log)
        self.assertEqual(log.details["query"], "Test Guest")

    def test_guest_history_creates_audit_log(self):
        """Viewing guest history creates an audit log entry."""
        self.client.force_authenticate(user=self.staff_user)
        response = self.client.get(f"/api/v1/guests/{self.guest.id}/history/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        log = SensitiveDataAccessLog.objects.filter(action="view_guest_history").first()
        self.assertIsNotNone(log)

    def test_guest_create_creates_audit_log(self):
        """Creating a guest creates an audit log entry."""
        self.client.force_authenticate(user=self.manager_user)
        response = self.client.post(
            "/api/v1/guests/",
            {"full_name": "New Guest", "phone": "0900000099"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        log = SensitiveDataAccessLog.objects.filter(action="create_guest").first()
        self.assertIsNotNone(log)
        self.assertEqual(log.resource_id, response.data["id"])

    def test_guest_update_creates_audit_log(self):
        """Updating a guest creates an audit log entry."""
        self.client.force_authenticate(user=self.manager_user)
        response = self.client.patch(
            f"/api/v1/guests/{self.guest.id}/",
            {"full_name": "Updated Name"},
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        log = SensitiveDataAccessLog.objects.filter(action="update_guest").first()
        self.assertIsNotNone(log)
        self.assertEqual(log.resource_id, self.guest.id)

    def test_audit_log_captures_ip_address(self):
        """Audit log captures client IP address."""
        self.client.force_authenticate(user=self.staff_user)
        self.client.get(f"/api/v1/guests/{self.guest.id}/")

        log = SensitiveDataAccessLog.objects.filter(action="view_guest").first()
        self.assertIsNotNone(log.ip_address)

    def test_audit_log_captures_fields(self):
        """Audit log records which sensitive fields were accessed."""
        self.client.force_authenticate(user=self.staff_user)
        self.client.get(f"/api/v1/guests/{self.guest.id}/")

        log = SensitiveDataAccessLog.objects.filter(action="view_guest").first()
        self.assertIn("id_number", log.fields_accessed)

    def test_audit_log_admin_readonly(self):
        """SensitiveDataAccessLog admin is read-only."""
        from hotel_api.admin import SensitiveDataAccessLogAdmin

        admin_instance = SensitiveDataAccessLogAdmin(SensitiveDataAccessLog, None)
        self.assertFalse(admin_instance.has_add_permission(None))
        self.assertFalse(admin_instance.has_change_permission(None))
        self.assertFalse(admin_instance.has_delete_permission(None))
