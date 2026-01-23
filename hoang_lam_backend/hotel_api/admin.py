"""Admin configuration for hotel_api models."""

from django.contrib import admin

from .models import (
    Booking,
    ExchangeRate,
    FinancialCategory,
    FinancialEntry,
    HotelUser,
    Housekeeping,
    MinibarItem,
    MinibarSale,
    Room,
    RoomType,
)


@admin.register(RoomType)
class RoomTypeAdmin(admin.ModelAdmin):
    list_display = ["name", "base_rate", "max_guests", "is_active"]
    list_filter = ["is_active"]
    search_fields = ["name", "name_en"]


@admin.register(Room)
class RoomAdmin(admin.ModelAdmin):
    list_display = ["number", "name", "room_type", "floor", "status", "is_active"]
    list_filter = ["status", "floor", "room_type", "is_active"]
    search_fields = ["number", "name"]


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = [
        "room",
        "get_guest_name",
        "check_in_date",
        "check_out_date",
        "status",
        "source",
        "total_amount",
        "is_paid",
    ]
    list_filter = ["status", "source", "is_paid", "check_in_date"]
    search_fields = ["guest__full_name", "guest__phone", "ota_reference"]
    date_hierarchy = "check_in_date"
    raw_id_fields = ["room", "guest", "created_by"]

    def get_guest_name(self, obj):
        """Display guest full name from Guest FK or deprecated field."""
        return obj.guest.full_name if obj.guest else obj.guest_name
    get_guest_name.short_description = "Guest"
    get_guest_name.admin_order_field = "guest__full_name"


@admin.register(FinancialCategory)
class FinancialCategoryAdmin(admin.ModelAdmin):
    list_display = ["name", "category_type", "icon", "is_default", "is_active"]
    list_filter = ["category_type", "is_active"]


@admin.register(FinancialEntry)
class FinancialEntryAdmin(admin.ModelAdmin):
    list_display = ["date", "entry_type", "category", "amount", "currency", "description"]
    list_filter = ["entry_type", "category", "date", "payment_method"]
    search_fields = ["description", "receipt_number"]
    date_hierarchy = "date"
    raw_id_fields = ["booking", "created_by"]


@admin.register(HotelUser)
class HotelUserAdmin(admin.ModelAdmin):
    list_display = ["user", "role", "phone", "is_active"]
    list_filter = ["role", "is_active"]
    search_fields = ["user__username", "user__first_name", "user__last_name", "phone"]


@admin.register(Housekeeping)
class HousekeepingAdmin(admin.ModelAdmin):
    list_display = ["room", "task_type", "status", "scheduled_date", "assigned_to"]
    list_filter = ["status", "task_type", "scheduled_date"]
    date_hierarchy = "scheduled_date"
    raw_id_fields = ["room", "booking", "assigned_to", "created_by"]


@admin.register(MinibarItem)
class MinibarItemAdmin(admin.ModelAdmin):
    list_display = ["name", "price", "cost", "category", "is_active"]
    list_filter = ["category", "is_active"]
    search_fields = ["name"]


@admin.register(MinibarSale)
class MinibarSaleAdmin(admin.ModelAdmin):
    list_display = ["booking", "item", "quantity", "total", "date", "is_charged"]
    list_filter = ["is_charged", "date"]
    date_hierarchy = "date"
    raw_id_fields = ["booking", "created_by"]


@admin.register(ExchangeRate)
class ExchangeRateAdmin(admin.ModelAdmin):
    list_display = ["from_currency", "to_currency", "rate", "date", "source"]
    list_filter = ["from_currency", "source"]
    date_hierarchy = "date"
