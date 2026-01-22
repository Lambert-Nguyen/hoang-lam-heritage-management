"""URL configuration for hotel_api."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    LoginView,
    LogoutView,
    PasswordChangeView,
    RoomTypeViewSet,
    RoomViewSet,
    UserProfileView,
)

# Register ViewSets
router = DefaultRouter()
router.register(r"room-types", RoomTypeViewSet, basename="roomtype")
router.register(r"rooms", RoomViewSet, basename="room")
# To be added:
# router.register(r'bookings', BookingViewSet, basename='booking')
# router.register(r'finance', FinancialEntryViewSet, basename='finance')

urlpatterns = [
    # JWT Authentication
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/me/", UserProfileView.as_view(), name="user_profile"),
    path("auth/password/change/", PasswordChangeView.as_view(), name="password_change"),
    # API endpoints
    path("", include(router.urls)),
]
