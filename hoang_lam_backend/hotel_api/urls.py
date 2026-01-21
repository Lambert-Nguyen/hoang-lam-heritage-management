"""URL configuration for hotel_api."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import LoginView, LogoutView, PasswordChangeView, UserProfileView

# ViewSets will be added as they are implemented
router = DefaultRouter()
# router.register(r'rooms', RoomViewSet, basename='room')
# router.register(r'bookings', BookingViewSet, basename='booking')
# router.register(r'finance', FinancialEntryViewSet, basename='finance')

urlpatterns = [
    # JWT Authentication
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/me/", UserProfileView.as_view(), name="user_profile"),
    path("auth/password/change/", PasswordChangeView.as_view(), name="password_change"),
    # API endpoints (to be implemented)
    path("", include(router.urls)),
]
