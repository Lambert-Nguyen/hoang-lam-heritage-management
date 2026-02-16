"""
Tests for authentication endpoints.
"""

from datetime import timedelta

import pytest
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken, RefreshToken

from hotel_api.models import HotelUser

User = get_user_model()


@pytest.fixture
def api_client():
    """Create API client."""
    return APIClient()


@pytest.fixture
def create_user(db):
    """Factory for creating users with HotelUser profile."""

    def _create_user(username="testuser", password="testpass123", role="staff", **kwargs):
        user = User.objects.create_user(
            username=username, password=password, email=f"{username}@test.com", **kwargs
        )
        HotelUser.objects.create(user=user, role=role, phone="0123456789")
        return user

    return _create_user


@pytest.fixture
def owner_user(create_user):
    """Create owner user."""
    return create_user(username="owner", role="owner")


@pytest.fixture
def manager_user(create_user):
    """Create manager user."""
    return create_user(username="manager", role="manager")


@pytest.fixture
def staff_user(create_user):
    """Create staff user."""
    return create_user(username="staff", role="staff")


@pytest.fixture
def housekeeping_user(create_user):
    """Create housekeeping user."""
    return create_user(username="housekeeping", role="housekeeping")


@pytest.fixture
def authenticated_client(api_client, staff_user):
    """Return authenticated API client."""
    refresh = RefreshToken.for_user(staff_user)
    api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
    return api_client


@pytest.mark.django_db
class TestLoginView:
    """Tests for login endpoint."""

    def test_login_success(self, api_client, staff_user):
        """Test successful login."""
        url = reverse("login")
        data = {"username": "staff", "password": "testpass123"}

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data
        assert "refresh" in response.data
        assert "user" in response.data
        assert response.data["user"]["username"] == "staff"
        assert response.data["user"]["role"] == "staff"

    def test_login_invalid_credentials(self, api_client, staff_user):
        """Test login with invalid credentials."""
        url = reverse("login")
        data = {"username": "staff", "password": "wrongpassword"}

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_missing_fields(self, api_client):
        """Test login with missing fields."""
        url = reverse("login")
        data = {"username": "staff"}  # Missing password

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_inactive_user(self, api_client, staff_user):
        """Test login with inactive user."""
        staff_user.is_active = False
        staff_user.save()

        url = reverse("login")
        data = {"username": "staff", "password": "testpass123"}

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestTokenRefreshView:
    """Tests for token refresh endpoint."""

    def test_refresh_token_success(self, api_client, staff_user):
        """Test successful token refresh."""
        refresh = RefreshToken.for_user(staff_user)

        url = reverse("token_refresh")
        data = {"refresh": str(refresh)}

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data

    def test_refresh_token_invalid(self, api_client):
        """Test token refresh with invalid token."""
        url = reverse("token_refresh")
        data = {"refresh": "invalid-token"}

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestLogoutView:
    """Tests for logout endpoint."""

    def test_logout_success(self, authenticated_client, staff_user):
        """Test successful logout."""
        refresh = RefreshToken.for_user(staff_user)

        url = reverse("logout")
        data = {"refresh": str(refresh)}

        response = authenticated_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_200_OK
        assert "detail" in response.data

    def test_logout_missing_token(self, authenticated_client):
        """Test logout without refresh token."""
        url = reverse("logout")
        data = {}

        response = authenticated_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_logout_unauthenticated(self, api_client, staff_user):
        """Test logout without authentication."""
        refresh = RefreshToken.for_user(staff_user)

        url = reverse("logout")
        data = {"refresh": str(refresh)}

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestUserProfileView:
    """Tests for user profile endpoint."""

    def test_get_profile_success(self, authenticated_client, staff_user):
        """Test getting user profile."""
        url = reverse("user_profile")

        response = authenticated_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["username"] == "staff"
        assert response.data["role"] == "staff"
        assert "role_display" in response.data

    def test_get_profile_unauthenticated(self, api_client):
        """Test getting profile without authentication."""
        url = reverse("user_profile")

        response = api_client.get(url)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestPasswordChangeView:
    """Tests for password change endpoint."""

    def test_password_change_success(self, authenticated_client, staff_user):
        """Test successful password change."""
        url = reverse("password_change")
        data = {
            "old_password": "testpass123",
            "new_password": "newpass123!@#",
            "confirm_password": "newpass123!@#",
        }

        response = authenticated_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_200_OK

        # Verify new password works
        staff_user.refresh_from_db()
        assert staff_user.check_password("newpass123!@#")

    def test_password_change_wrong_old_password(self, authenticated_client):
        """Test password change with wrong old password."""
        url = reverse("password_change")
        data = {
            "old_password": "wrongpassword",
            "new_password": "newpass123!@#",
            "confirm_password": "newpass123!@#",
        }

        response = authenticated_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_password_change_mismatch(self, authenticated_client):
        """Test password change with mismatched new passwords."""
        url = reverse("password_change")
        data = {
            "old_password": "testpass123",
            "new_password": "newpass123!@#",
            "confirm_password": "different123!@#",
        }

        response = authenticated_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_password_change_weak_password(self, authenticated_client):
        """Test password change with weak password."""
        url = reverse("password_change")
        data = {"old_password": "testpass123", "new_password": "123", "confirm_password": "123"}

        response = authenticated_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_password_change_unauthenticated(self, api_client):
        """Test password change without authentication."""
        url = reverse("password_change")
        data = {
            "old_password": "testpass123",
            "new_password": "newpass123!@#",
            "confirm_password": "newpass123!@#",
        }

        response = api_client.post(url, data, format="json")

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestPermissions:
    """Tests for role-based permissions."""

    def test_owner_has_all_permissions(self, api_client, owner_user):
        """Test that owner has access to all endpoints."""
        refresh = RefreshToken.for_user(owner_user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        url = reverse("user_profile")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["role"] == "owner"

    def test_manager_role_display(self, api_client, manager_user):
        """Test manager role is correctly displayed."""
        refresh = RefreshToken.for_user(manager_user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        url = reverse("user_profile")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["role"] == "manager"
        assert "Quản lý" in response.data["role_display"]

    def test_housekeeping_role_display(self, api_client, housekeeping_user):
        """Test housekeeping role is correctly displayed."""
        refresh = RefreshToken.for_user(housekeeping_user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")

        url = reverse("user_profile")
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.data["role"] == "housekeeping"
        assert "Buồng phòng" in response.data["role_display"]


@pytest.mark.django_db
class TestLoginErrorCases:
    """Error case tests for login endpoint."""

    def test_login_empty_body(self, api_client):
        """Test login with empty request body."""
        url = reverse("login")
        response = api_client.post(url, {}, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_nonexistent_user(self, api_client):
        """Test login with a user that does not exist."""
        url = reverse("login")
        data = {"username": "nonexistent", "password": "somepass123"}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_missing_username(self, api_client):
        """Test login with missing username field."""
        url = reverse("login")
        data = {"password": "testpass123"}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_empty_password(self, api_client, staff_user):
        """Test login with empty password string."""
        url = reverse("login")
        data = {"username": "staff", "password": ""}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.django_db
class TestTokenRefreshErrorCases:
    """Error case tests for token refresh."""

    def test_refresh_with_empty_body(self, api_client):
        """Test token refresh with empty body."""
        url = reverse("token_refresh")
        response = api_client.post(url, {}, format="json")
        assert response.status_code in [
            status.HTTP_400_BAD_REQUEST,
            status.HTTP_401_UNAUTHORIZED,
        ]

    def test_refresh_with_expired_blacklisted_token(self, api_client, staff_user):
        """Test refresh with a blacklisted token."""
        refresh = RefreshToken.for_user(staff_user)
        refresh.blacklist()
        url = reverse("token_refresh")
        data = {"refresh": str(refresh)}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestPasswordChangeErrorCases:
    """Error case tests for password change."""

    def test_password_change_missing_all_fields(self, authenticated_client):
        """Test password change with empty body."""
        url = reverse("password_change")
        response = authenticated_client.post(url, {}, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_password_change_missing_confirm(self, authenticated_client):
        """Test password change without confirm_password."""
        url = reverse("password_change")
        data = {
            "old_password": "testpass123",
            "new_password": "newpass123!@#",
        }
        response = authenticated_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_password_change_same_as_old(self, authenticated_client):
        """Test password change with new password same as old."""
        url = reverse("password_change")
        data = {
            "old_password": "testpass123",
            "new_password": "testpass123",
            "confirm_password": "testpass123",
        }
        response = authenticated_client.post(url, data, format="json")
        # Should either succeed or reject (depends on implementation)
        # At minimum it should not crash
        assert response.status_code in [
            status.HTTP_200_OK,
            status.HTTP_400_BAD_REQUEST,
        ]


@pytest.mark.django_db
class TestLogoutErrorCases:
    """Error case tests for logout."""

    def test_logout_with_invalid_token(self, authenticated_client):
        """Test logout with invalid refresh token."""
        url = reverse("logout")
        data = {"refresh": "invalid-token-string"}
        response = authenticated_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_logout_with_already_blacklisted_token(self, authenticated_client, staff_user):
        """Test logout with already blacklisted token."""
        refresh = RefreshToken.for_user(staff_user)
        refresh.blacklist()
        url = reverse("logout")
        data = {"refresh": str(refresh)}
        response = authenticated_client.post(url, data, format="json")
        # Should handle gracefully - either 200 or 400
        assert response.status_code in [
            status.HTTP_200_OK,
            status.HTTP_400_BAD_REQUEST,
        ]


@pytest.mark.django_db
class TestLoginEdgeCases:
    """Edge case tests for login endpoint."""

    def test_login_sql_injection_username(self, api_client):
        """Test login with SQL injection characters in username."""
        url = reverse("login")
        data = {"username": "' OR 1=1 --", "password": "testpass123"}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_extremely_long_password(self, api_client, staff_user):
        """Test login with an extremely long password string."""
        url = reverse("login")
        data = {"username": "staff", "password": "x" * 10000}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_with_null_values(self, api_client):
        """Test login with null username and password."""
        url = reverse("login")
        data = {"username": None, "password": None}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_login_with_extra_fields_ignored(self, api_client, staff_user):
        """Test that extra fields in login request are ignored."""
        url = reverse("login")
        data = {
            "username": "staff",
            "password": "testpass123",
            "extra_field": "should be ignored",
            "admin": True,
        }
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_200_OK
        assert "access" in response.data


@pytest.mark.django_db
class TestTokenEdgeCases:
    """Edge case tests for token operations."""

    def test_refresh_with_access_token(self, api_client, staff_user):
        """Test using an access token as a refresh token."""
        access = AccessToken.for_user(staff_user)
        url = reverse("token_refresh")
        data = {"refresh": str(access)}
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_refresh_missing_refresh_key(self, api_client):
        """Test token refresh with wrong field name."""
        url = reverse("token_refresh")
        data = {"token": "some-token-value"}
        response = api_client.post(url, data, format="json")
        assert response.status_code in [
            status.HTTP_400_BAD_REQUEST,
            status.HTTP_401_UNAUTHORIZED,
        ]

    def test_expired_token_returns_401(self, api_client, staff_user):
        """Test that an expired access token returns 401."""
        access = AccessToken.for_user(staff_user)
        # Set token to expire immediately
        access.set_exp(lifetime=-timedelta(seconds=1))
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {str(access)}")
        url = reverse("user_profile")
        response = api_client.get(url)
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.django_db
class TestPasswordChangeEdgeCases:
    """Edge case tests for password change."""

    def test_password_change_common_password(self, authenticated_client):
        """Test password change with a commonly used password."""
        url = reverse("password_change")
        data = {
            "old_password": "testpass123",
            "new_password": "password123",
            "confirm_password": "password123",
        }
        response = authenticated_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_password_change_too_similar_to_username(self, api_client, create_user):
        """Test password change with password too similar to username."""
        user = create_user(username="johndoe", password="oldpass!@#456")
        refresh = RefreshToken.for_user(user)
        api_client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        url = reverse("password_change")
        data = {
            "old_password": "oldpass!@#456",
            "new_password": "johndoe1",
            "confirm_password": "johndoe1",
        }
        response = api_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_password_change_numeric_only(self, authenticated_client):
        """Test password change with numeric-only password."""
        url = reverse("password_change")
        data = {
            "old_password": "testpass123",
            "new_password": "12345678",
            "confirm_password": "12345678",
        }
        response = authenticated_client.post(url, data, format="json")
        assert response.status_code == status.HTTP_400_BAD_REQUEST
