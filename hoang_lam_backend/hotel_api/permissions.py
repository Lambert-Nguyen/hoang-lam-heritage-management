"""
Custom permissions for role-based access control.
"""

from rest_framework import permissions


class IsOwner(permissions.BasePermission):
    """Allow access only to users with 'owner' role."""

    message = "Chỉ chủ khách sạn mới có quyền thực hiện thao tác này."

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and hasattr(request.user, "hotel_profile")
            and request.user.hotel_profile.role == "owner"
        )


class IsManager(permissions.BasePermission):
    """Allow access only to users with 'manager' role or higher."""

    message = "Chỉ quản lý trở lên mới có quyền thực hiện thao tác này."

    def has_permission(self, request, view):
        if not (
            request.user
            and request.user.is_authenticated
            and hasattr(request.user, "hotel_profile")
        ):
            return False
        return request.user.hotel_profile.role in ["owner", "manager"]


class IsStaff(permissions.BasePermission):
    """Allow access only to users with 'staff' role or higher."""

    message = "Chỉ nhân viên trở lên mới có quyền thực hiện thao tác này."

    def has_permission(self, request, view):
        if not (
            request.user
            and request.user.is_authenticated
            and hasattr(request.user, "hotel_profile")
        ):
            return False
        return request.user.hotel_profile.role in ["owner", "manager", "staff"]


class IsHousekeeping(permissions.BasePermission):
    """Allow access only to users with 'housekeeping' role or higher."""

    message = "Chỉ nhân viên buồng phòng trở lên mới có quyền thực hiện thao tác này."

    def has_permission(self, request, view):
        if not (
            request.user
            and request.user.is_authenticated
            and hasattr(request.user, "hotel_profile")
        ):
            return False
        return request.user.hotel_profile.role in ["owner", "manager", "staff", "housekeeping"]


class IsOwnerOrManager(permissions.BasePermission):
    """Allow access only to owner or manager."""

    message = "Chỉ chủ khách sạn hoặc quản lý mới có quyền thực hiện thao tác này."

    def has_permission(self, request, view):
        return IsManager().has_permission(request, view)


class IsReadOnly(permissions.BasePermission):
    """Allow read-only access for safe methods."""

    def has_permission(self, request, view):
        return request.method in permissions.SAFE_METHODS
