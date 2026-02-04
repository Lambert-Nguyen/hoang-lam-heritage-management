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
    GroupBookingViewSet,
    GuestViewSet,
    HousekeepingTaskViewSet,
    LoginView,
    LogoutView,
    LostAndFoundViewSet,
    MaintenanceRequestViewSet,
    MinibarItemViewSet,
    MinibarSaleViewSet,
    NightAuditViewSet,
    PasswordChangeView,
    PaymentViewSet,
    ReceiptViewSet,
    RoomTypeViewSet,
    RoomViewSet,
    UserProfileView,
    # Phase 4: Reports
    OccupancyReportView,
    RevenueReportView,
    KPIReportView,
    ExpenseReportView,
    ChannelPerformanceView,
    GuestDemographicsView,
    ComparativeReportView,
    ExportReportView,
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
router.register(r"housekeeping-tasks", HousekeepingTaskViewSet, basename="housekeepingtask")
router.register(r"maintenance-requests", MaintenanceRequestViewSet, basename="maintenancerequest")
router.register(r"minibar-items", MinibarItemViewSet, basename="minibaritem")
router.register(r"minibar-sales", MinibarSaleViewSet, basename="minibarsale")
# Phase 3: Lost & Found and Group Booking
router.register(r"lost-found", LostAndFoundViewSet, basename="lostandfound")
router.register(r"group-bookings", GroupBookingViewSet, basename="groupbooking")

urlpatterns = [
    # JWT Authentication
    path("auth/login/", LoginView.as_view(), name="login"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/logout/", LogoutView.as_view(), name="logout"),
    path("auth/me/", UserProfileView.as_view(), name="user_profile"),
    path("auth/password/change/", PasswordChangeView.as_view(), name="password_change"),
    # Dashboard
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
    # Reports (Phase 4)
    path("reports/occupancy/", OccupancyReportView.as_view(), name="report_occupancy"),
    path("reports/revenue/", RevenueReportView.as_view(), name="report_revenue"),
    path("reports/kpi/", KPIReportView.as_view(), name="report_kpi"),
    path("reports/expenses/", ExpenseReportView.as_view(), name="report_expenses"),
    path("reports/channels/", ChannelPerformanceView.as_view(), name="report_channels"),
    path("reports/demographics/", GuestDemographicsView.as_view(), name="report_demographics"),
    path("reports/comparative/", ComparativeReportView.as_view(), name="report_comparative"),
    path("reports/export/", ExportReportView.as_view(), name="report_export"),
    # API endpoints
    path("", include(router.urls)),
]
