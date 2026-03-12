"""
Role-based authorization integration tests.

Tests that each role (owner, manager, staff, housekeeping) gets correct
access/denial across critical API endpoints, enforcing the role-policy matrix.
"""

from django.contrib.auth.models import User
from django.urls import reverse

import pytest
from rest_framework import status
from rest_framework.test import APIClient

from hotel_api.models import HotelUser


# ── Fixtures ──────────────────────────────────────────────────────────


@pytest.fixture
def api_client():
    return APIClient()


def _make_user(db, username, role):
    user = User.objects.create_user(username=username, password="testpass123")
    HotelUser.objects.create(user=user, role=role, phone=f"+84900{username[-6:]}")
    return user


@pytest.fixture
def owner_user(db):
    return _make_user(db, "owner001", "owner")


@pytest.fixture
def manager_user(db):
    return _make_user(db, "manager01", "manager")


@pytest.fixture
def staff_user(db):
    return _make_user(db, "staff001", "staff")


@pytest.fixture
def housekeeping_user(db):
    return _make_user(db, "hkeep001", "housekeeping")


@pytest.fixture
def owner_client(api_client, owner_user):
    api_client.force_authenticate(user=owner_user)
    return api_client


@pytest.fixture
def manager_client(api_client, manager_user):
    api_client.force_authenticate(user=manager_user)
    return api_client


@pytest.fixture
def staff_client(api_client, staff_user):
    api_client.force_authenticate(user=staff_user)
    return api_client


@pytest.fixture
def housekeeping_client(api_client, housekeeping_user):
    api_client.force_authenticate(user=housekeeping_user)
    return api_client


# ── Report endpoint tests (owner/manager only) ───────────────────────


REPORT_URLS = [
    "report_occupancy",
    "report_revenue",
    "report_kpi",
    "report_expenses",
    "report_channels",
    "report_demographics",
    "report_comparative",
]

REPORT_PARAMS = {"start_date": "2026-01-01", "end_date": "2026-01-31"}


@pytest.mark.django_db
class TestReportAuthorization:
    """Reports should be accessible only to owner and manager."""

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_owner_can_access_reports(self, owner_client, url_name):
        url = reverse(url_name)
        response = owner_client.get(url, REPORT_PARAMS)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_manager_can_access_reports(self, manager_client, url_name):
        url = reverse(url_name)
        response = manager_client.get(url, REPORT_PARAMS)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_staff_denied_reports(self, staff_client, url_name):
        url = reverse(url_name)
        response = staff_client.get(url, REPORT_PARAMS)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_housekeeping_denied_reports(self, housekeeping_client, url_name):
        url = reverse(url_name)
        response = housekeeping_client.get(url, REPORT_PARAMS)
        assert response.status_code == status.HTTP_403_FORBIDDEN


# ── Export report tests (owner/manager only) ──────────────────────────


@pytest.mark.django_db
class TestExportReportAuthorization:
    """Export report should be accessible only to owner and manager."""

    EXPORT_PARAMS = {
        "report_type": "occupancy",
        "start_date": "2026-01-01",
        "end_date": "2026-01-31",
        "format": "csv",
    }

    def test_owner_can_export(self, owner_client):
        url = reverse("report_export")
        response = owner_client.get(url, self.EXPORT_PARAMS)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_manager_can_export(self, manager_client):
        url = reverse("report_export")
        response = manager_client.get(url, self.EXPORT_PARAMS)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_staff_denied_export(self, staff_client):
        url = reverse("report_export")
        response = staff_client.get(url, self.EXPORT_PARAMS)
        assert response.status_code in (
            status.HTTP_403_FORBIDDEN,
            status.HTTP_404_NOT_FOUND,
        )

    def test_housekeeping_denied_export(self, housekeeping_client):
        url = reverse("report_export")
        response = housekeeping_client.get(url, self.EXPORT_PARAMS)
        assert response.status_code in (
            status.HTTP_403_FORBIDDEN,
            status.HTTP_404_NOT_FOUND,
        )


# ── Minibar endpoint tests (staff and above) ─────────────────────────


@pytest.mark.django_db
class TestMinibarAuthorization:
    """Minibar items/sales should be accessible to staff, manager, and owner only."""

    def test_owner_can_list_minibar_items(self, owner_client):
        url = reverse("minibaritem-list")
        response = owner_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_manager_can_list_minibar_items(self, manager_client):
        url = reverse("minibaritem-list")
        response = manager_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_staff_can_list_minibar_items(self, staff_client):
        url = reverse("minibaritem-list")
        response = staff_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_housekeeping_denied_minibar_items(self, housekeeping_client):
        url = reverse("minibaritem-list")
        response = housekeeping_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_housekeeping_denied_minibar_sales(self, housekeeping_client):
        url = reverse("minibarsale-list")
        response = housekeeping_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN


# ── Staff list endpoint tests (staff and above) ──────────────────────


@pytest.mark.django_db
class TestStaffListAuthorization:
    """Staff list should be accessible to staff, manager, and owner only."""

    def test_owner_can_list_staff(self, owner_client):
        url = reverse("staff_list")
        response = owner_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_manager_can_list_staff(self, manager_client):
        url = reverse("staff_list")
        response = manager_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_staff_can_list_staff(self, staff_client):
        url = reverse("staff_list")
        response = staff_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_housekeeping_denied_staff_list(self, housekeeping_client):
        url = reverse("staff_list")
        response = housekeeping_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN


# ── Finance endpoint tests (staff reads, manager writes) ─────────────


@pytest.mark.django_db
class TestFinanceAuthorization:
    """
    Finance categories/entries:
    - Read: staff and above (IsStaff base)
    - Write: manager and above (get_permissions override)
    """

    def test_owner_can_list_finance_categories(self, owner_client):
        url = reverse("financialcategory-list")
        response = owner_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_manager_can_list_finance_categories(self, manager_client):
        url = reverse("financialcategory-list")
        response = manager_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_staff_can_list_finance_categories(self, staff_client):
        url = reverse("financialcategory-list")
        response = staff_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_housekeeping_denied_finance_categories(self, housekeeping_client):
        url = reverse("financialcategory-list")
        response = housekeeping_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_owner_can_list_finance_entries(self, owner_client):
        url = reverse("financialentry-list")
        response = owner_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_housekeeping_denied_finance_entries(self, housekeeping_client):
        url = reverse("financialentry-list")
        response = housekeeping_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_staff_denied_create_finance_category(self, staff_client):
        url = reverse("financialcategory-list")
        response = staff_client.post(url, {"name": "Test", "type": "income"})
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_manager_can_create_finance_category(self, manager_client):
        url = reverse("financialcategory-list")
        response = manager_client.post(
            url, {"name": "Test Category", "type": "income"}, format="json"
        )
        # Should not be 403 (may be 400 if missing required fields, but not forbidden)
        assert response.status_code != status.HTTP_403_FORBIDDEN


# ── Lost & Found endpoint tests (staff and above) ────────────────────


@pytest.mark.django_db
class TestLostFoundAuthorization:
    """Lost & Found should be accessible to staff, manager, and owner only."""

    def test_owner_can_list_lost_found(self, owner_client):
        url = reverse("lostandfound-list")
        response = owner_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_staff_can_list_lost_found(self, staff_client):
        url = reverse("lostandfound-list")
        response = staff_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_housekeeping_denied_lost_found(self, housekeeping_client):
        url = reverse("lostandfound-list")
        response = housekeeping_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN


# ── Housekeeping endpoint tests (all roles can access) ────────────────


@pytest.mark.django_db
class TestHousekeepingAuthorization:
    """Housekeeping tasks should be accessible to all authenticated roles."""

    def test_housekeeping_denied_tasks(self, housekeeping_client):
        """Housekeeping role is denied direct API access; tasks are assigned via staff/manager."""
        url = reverse("housekeepingtask-list")
        response = housekeeping_client.get(url)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    def test_staff_can_list_tasks(self, staff_client):
        url = reverse("housekeepingtask-list")
        response = staff_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_owner_can_list_tasks(self, owner_client):
        url = reverse("housekeepingtask-list")
        response = owner_client.get(url)
        assert response.status_code != status.HTTP_403_FORBIDDEN


# ══════════════════════════════════════════════════════════════════════
# P2 Regression: Role × Endpoint matrix (drift-detection tests)
# ══════════════════════════════════════════════════════════════════════
#
# These parametrized tests assert the COMPLETE role-endpoint matrix from
# docs/ROLE_POLICY_MATRIX.md.  Any permission change that breaks these
# tests means the matrix document must be updated, too.

# ── Helper: list-endpoint URL names grouped by expected permission ────

# IsStaffOrManager: owner ✅  manager ✅  staff ✅  housekeeping ❌
STAFF_OR_MANAGER_LIST_ENDPOINTS = [
    "nightaudit-list",
    "payment-list",
    "folioitem-list",
    "housekeepingtask-list",
    "maintenancerequest-list",
    "minibaritem-list",
    "minibarsale-list",
    "lostandfound-list",
    "groupbooking-list",
    "inspectiontemplate-list",
    "roominspection-list",
    "rateplan-list",
    "daterateoverride-list",
]

# IsStaff (base): owner ✅  manager ✅  staff ✅  housekeeping ❌
STAFF_LIST_ENDPOINTS = [
    "roomtype-list",
    "room-list",
    "guest-list",
    "booking-list",
    "financialcategory-list",
    "financialentry-list",
]

# IsOwnerOrManager: owner ✅  manager ✅  staff ❌  housekeeping ❌
OWNER_OR_MANAGER_LIST_ENDPOINTS = [
    "auditlog-list",
]

# IsAuthenticated: owner ✅  manager ✅  staff ✅  housekeeping ✅
AUTHENTICATED_LIST_ENDPOINTS = [
    "notification-list",
    "messagetemplate-list",
    "guestmessage-list",
    "exchangerate-list",
]

# Named path endpoints (non-router)

# IsStaffOrManager
STAFF_OR_MANAGER_PATH_ENDPOINTS = [
    "staff_list",
]

# IsOwnerOrManager
OWNER_OR_MANAGER_PATH_ENDPOINTS = [
    "admin_reset_password",
]


@pytest.mark.django_db
class TestRoleEndpointMatrixRegression:
    """
    Regression suite: asserts the full role × endpoint matrix.
    If a permission class changes, these tests will catch the drift.
    """

    # ── IsStaffOrManager list endpoints ──────────────────────────────

    @pytest.mark.parametrize("url_name", STAFF_OR_MANAGER_LIST_ENDPOINTS)
    def test_owner_allowed_stafformanager_endpoint(self, owner_client, url_name):
        response = owner_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", STAFF_OR_MANAGER_LIST_ENDPOINTS)
    def test_manager_allowed_stafformanager_endpoint(self, manager_client, url_name):
        response = manager_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", STAFF_OR_MANAGER_LIST_ENDPOINTS)
    def test_staff_allowed_stafformanager_endpoint(self, staff_client, url_name):
        response = staff_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", STAFF_OR_MANAGER_LIST_ENDPOINTS)
    def test_housekeeping_denied_stafformanager_endpoint(
        self, housekeeping_client, url_name
    ):
        response = housekeeping_client.get(reverse(url_name))
        assert response.status_code == status.HTTP_403_FORBIDDEN

    # ── IsStaff list endpoints ───────────────────────────────────────

    @pytest.mark.parametrize("url_name", STAFF_LIST_ENDPOINTS)
    def test_owner_allowed_staff_endpoint(self, owner_client, url_name):
        response = owner_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", STAFF_LIST_ENDPOINTS)
    def test_manager_allowed_staff_endpoint(self, manager_client, url_name):
        response = manager_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", STAFF_LIST_ENDPOINTS)
    def test_staff_allowed_staff_endpoint(self, staff_client, url_name):
        response = staff_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", STAFF_LIST_ENDPOINTS)
    def test_housekeeping_denied_staff_endpoint(self, housekeeping_client, url_name):
        response = housekeeping_client.get(reverse(url_name))
        assert response.status_code == status.HTTP_403_FORBIDDEN

    # ── IsOwnerOrManager list endpoints ──────────────────────────────

    @pytest.mark.parametrize("url_name", OWNER_OR_MANAGER_LIST_ENDPOINTS)
    def test_owner_allowed_ownerormanager_endpoint(self, owner_client, url_name):
        response = owner_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", OWNER_OR_MANAGER_LIST_ENDPOINTS)
    def test_manager_allowed_ownerormanager_endpoint(self, manager_client, url_name):
        response = manager_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", OWNER_OR_MANAGER_LIST_ENDPOINTS)
    def test_staff_denied_ownerormanager_endpoint(self, staff_client, url_name):
        response = staff_client.get(reverse(url_name))
        assert response.status_code == status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", OWNER_OR_MANAGER_LIST_ENDPOINTS)
    def test_housekeeping_denied_ownerormanager_endpoint(
        self, housekeeping_client, url_name
    ):
        response = housekeeping_client.get(reverse(url_name))
        assert response.status_code == status.HTTP_403_FORBIDDEN

    # ── IsAuthenticated list endpoints ───────────────────────────────

    @pytest.mark.parametrize("url_name", AUTHENTICATED_LIST_ENDPOINTS)
    def test_owner_allowed_authenticated_endpoint(self, owner_client, url_name):
        response = owner_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", AUTHENTICATED_LIST_ENDPOINTS)
    def test_housekeeping_allowed_authenticated_endpoint(
        self, housekeeping_client, url_name
    ):
        response = housekeeping_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    # ── Named path endpoints ─────────────────────────────────────────

    @pytest.mark.parametrize("url_name", STAFF_OR_MANAGER_PATH_ENDPOINTS)
    def test_staff_allowed_stafformanager_path(self, staff_client, url_name):
        response = staff_client.get(reverse(url_name))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", STAFF_OR_MANAGER_PATH_ENDPOINTS)
    def test_housekeeping_denied_stafformanager_path(
        self, housekeeping_client, url_name
    ):
        response = housekeeping_client.get(reverse(url_name))
        assert response.status_code == status.HTTP_403_FORBIDDEN

    # ── Reports (IsOwnerOrManager) ───────────────────────────────────

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_owner_allowed_report(self, owner_client, url_name):
        response = owner_client.get(reverse(url_name), REPORT_PARAMS)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_manager_allowed_report(self, manager_client, url_name):
        response = manager_client.get(reverse(url_name), REPORT_PARAMS)
        assert response.status_code != status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_staff_denied_report(self, staff_client, url_name):
        response = staff_client.get(reverse(url_name), REPORT_PARAMS)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    @pytest.mark.parametrize("url_name", REPORT_URLS)
    def test_housekeeping_denied_report(self, housekeeping_client, url_name):
        response = housekeeping_client.get(reverse(url_name), REPORT_PARAMS)
        assert response.status_code == status.HTTP_403_FORBIDDEN

    # ── Dashboard (IsStaff base) ─────────────────────────────────────

    def test_owner_allowed_dashboard(self, owner_client):
        response = owner_client.get(reverse("dashboard"))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_staff_allowed_dashboard(self, staff_client):
        response = staff_client.get(reverse("dashboard"))
        assert response.status_code != status.HTTP_403_FORBIDDEN

    def test_housekeeping_denied_dashboard(self, housekeeping_client):
        response = housekeeping_client.get(reverse("dashboard"))
        assert response.status_code == status.HTTP_403_FORBIDDEN
