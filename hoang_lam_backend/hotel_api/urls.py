"""URL configuration for hotel_api."""

from django.urls import include, path

from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

# ViewSets will be added as they are implemented
router = DefaultRouter()
# router.register(r'rooms', RoomViewSet, basename='room')
# router.register(r'bookings', BookingViewSet, basename='booking')
# router.register(r'finance', FinancialEntryViewSet, basename='finance')

urlpatterns = [
    # JWT Authentication
    path("auth/token/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("auth/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    # API endpoints (to be implemented)
    path("", include(router.urls)),
]
