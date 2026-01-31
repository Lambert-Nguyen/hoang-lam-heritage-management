"""URL configuration for hotel_api."""

from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    BookingViewSet,
    DashboardView,
    ExchangeRateViewSet,
    FinancialCategoryViewSet,
    FinancialEntryViewSet,
    FolioItemViewSet,
    GuestViewSet,
    LoginView,
    LogoutView,
    NightAuditViewSet,
    PasswordChangeView,
    PaymentViewSet,
    ReceiptViewSet,
    RoomTypeViewSet,
    RoomViewSet,
    UserProfileView,
)

# Register ViewSets
router = DefaultRouter()
router.register(r"room-types", RoomTypeViewSet, basename="roomtype")
router.register(r"rooms", RoomViewSet, basename="room")
router.register(r"guests", GuestViewSet, basename="guest")
router.register(r"bookings", BookingViewSet, basename="booking")
router.register(r"finance/categories", FinancialCategoryViewSet, basename="financialcategory")
router.register(r"finance/entries", FinancialEntryViewSet, basename="financialentry")
router.register(r"night-audits", NightAuditViewSet, basename="nightaudit")
router.register(r"payments", PaymentViewSet, basename="payment")
router.register(r"folio-items", FolioItemViewSet, basename="folioitem")
router.register(r"exchange-rates", ExchangeRateViewSet, basename="exchangerate")
router.register(r"receipts", ReceiptViewSet, basename="receipt")

urlpatterns = [
    # JWT Authentication
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/me/", UserProfileView.as_view(), name="user_profile"),
    path("auth/password/change/", PasswordChangeView.as_view(), name="password_change"),
    # Dashboard
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
    # API endpoints
    path("", include(router.urls)),
]
