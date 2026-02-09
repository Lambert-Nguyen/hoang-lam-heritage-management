"""
Serializers for API endpoints.
"""

from decimal import Decimal

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.db import models
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import Booking, DateRateOverride, DeviceToken, FinancialCategory, FinancialEntry, Guest, GroupBooking, GuestMessage, HotelUser, HousekeepingTask, InspectionTemplate, LostAndFound, MaintenanceRequest, MessageTemplate, MinibarItem, MinibarSale, NightAudit, Notification, RatePlan, Room, RoomInspection, RoomType


class LoginSerializer(serializers.Serializer):
    """Login credentials serializer."""

    username = serializers.CharField(required=True)
    password = serializers.CharField(
        required=True, write_only=True, style={"input_type": "password"}
    )

    def validate(self, attrs):
        username = attrs.get("username")
        password = attrs.get("password")

        if username and password:
            user = authenticate(username=username, password=password)
            if not user:
                raise serializers.ValidationError(
                    "Tên đăng nhập hoặc mật khẩu không đúng.", code="authentication"
                )
            if not user.is_active:
                raise serializers.ValidationError(
                    "Tài khoản đã bị vô hiệu hóa.", code="authentication"
                )
        else:
            raise serializers.ValidationError(
                "Phải cung cấp cả tên đăng nhập và mật khẩu.", code="authentication"
            )

        attrs["user"] = user
        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    """User profile serializer with HotelUser details."""

    role = serializers.SerializerMethodField()
    role_display = serializers.SerializerMethodField()
    phone = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "role",
            "role_display",
            "phone",
        ]
        read_only_fields = ["id", "username"]

    def get_role(self, obj):
        """Get user role."""
        return obj.hotel_profile.role if hasattr(obj, "hotel_profile") else None

    def get_role_display(self, obj):
        """Get user role display name."""
        return obj.hotel_profile.get_role_display() if hasattr(obj, "hotel_profile") else None

    def get_phone(self, obj):
        """Get user phone number."""
        return obj.hotel_profile.phone if hasattr(obj, "hotel_profile") else None


class PasswordChangeSerializer(serializers.Serializer):
    """Password change serializer."""

    old_password = serializers.CharField(
        required=True, write_only=True, style={"input_type": "password"}
    )
    new_password = serializers.CharField(
        required=True, write_only=True, style={"input_type": "password"}
    )
    confirm_password = serializers.CharField(
        required=True, write_only=True, style={"input_type": "password"}
    )

    def validate_old_password(self, value):
        """Validate that old password is correct."""
        user = self.context["request"].user
        if not user.check_password(value):
            raise serializers.ValidationError("Mật khẩu cũ không đúng.")
        return value

    def validate(self, attrs):
        """Validate that new passwords match and meet requirements."""
        if attrs["new_password"] != attrs["confirm_password"]:
            raise serializers.ValidationError({"confirm_password": "Mật khẩu xác nhận không khớp."})

        # Validate new password using Django's password validators
        validate_password(attrs["new_password"], user=self.context["request"].user)

        return attrs

    def save(self):
        """Update the user's password."""
        user = self.context["request"].user
        user.set_password(self.validated_data["new_password"])
        user.save()
        return user


# ==================== Room Management Serializers ====================


class RoomTypeSerializer(serializers.ModelSerializer):
    """RoomType serializer with full details."""

    room_count = serializers.SerializerMethodField()
    available_room_count = serializers.SerializerMethodField()

    class Meta:
        model = RoomType
        fields = [
            "id",
            "name",
            "name_en",
            "base_rate",
            # Hourly booking fields
            "hourly_rate",
            "first_hour_rate",
            "allows_hourly",
            "min_hours",
            # Guest capacity
            "max_guests",
            "description",
            "amenities",
            "is_active",
            "room_count",
            "available_room_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_room_count(self, obj):
        """Get total number of rooms of this type."""
        return obj.rooms.filter(is_active=True).count()

    def get_available_room_count(self, obj):
        """Get number of available rooms of this type."""
        return obj.rooms.filter(is_active=True, status=Room.Status.AVAILABLE).count()

    def validate_base_rate(self, value):
        """Validate that base rate is positive."""
        if value <= 0:
            raise serializers.ValidationError("Giá phòng phải lớn hơn 0.")
        return value

    def validate_max_guests(self, value):
        """Validate that max guests is positive."""
        if value <= 0:
            raise serializers.ValidationError("Số khách tối đa phải lớn hơn 0.")
        return value


class RoomTypeListSerializer(serializers.ModelSerializer):
    """Simplified RoomType serializer for list views."""

    room_count = serializers.SerializerMethodField()
    available_room_count = serializers.SerializerMethodField()

    class Meta:
        model = RoomType
        fields = [
            "id",
            "name",
            "name_en",
            "base_rate",
            "hourly_rate",
            "allows_hourly",
            "max_guests",
            "is_active",
            "room_count",
            "available_room_count",
        ]

    def get_room_count(self, obj):
        return obj.rooms.filter(is_active=True).count()

    def get_available_room_count(self, obj):
        return obj.rooms.filter(is_active=True, status=Room.Status.AVAILABLE).count()


class RoomSerializer(serializers.ModelSerializer):
    """Room serializer with full details."""

    room_type_name = serializers.CharField(source="room_type.name", read_only=True)
    room_type_details = RoomTypeListSerializer(source="room_type", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = Room
        fields = [
            "id",
            "number",
            "name",
            "room_type",
            "room_type_name",
            "room_type_details",
            "floor",
            "status",
            "status_display",
            "amenities",
            "notes",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def validate_number(self, value):
        """Validate room number uniqueness."""
        instance = self.instance
        if Room.objects.filter(number=value).exclude(pk=instance.pk if instance else None).exists():
            raise serializers.ValidationError("Số phòng này đã tồn tại.")
        return value

    def validate_floor(self, value):
        """Validate floor number."""
        if value < 1:
            raise serializers.ValidationError("Số tầng phải lớn hơn 0.")
        return value


class RoomListSerializer(serializers.ModelSerializer):
    """Simplified Room serializer for list views."""

    room_type_name = serializers.CharField(source="room_type.name", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    base_rate = serializers.DecimalField(
        source="room_type.base_rate", max_digits=12, decimal_places=0, read_only=True
    )

    class Meta:
        model = Room
        fields = [
            "id",
            "number",
            "name",
            "room_type",
            "room_type_name",
            "floor",
            "status",
            "status_display",
            "base_rate",
            "is_active",
        ]


class RoomStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating room status."""

    status = serializers.ChoiceField(choices=Room.Status.choices, required=True)
    notes = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate_status(self, value):
        """Validate status transition."""
        room = self.context.get("room")
        if room and room.status == value:
            raise serializers.ValidationError("Phòng đã ở trạng thái này rồi.")
        return value


class RoomAvailabilitySerializer(serializers.Serializer):
    """Serializer for room availability check request."""

    check_in = serializers.DateField(required=True)
    check_out = serializers.DateField(required=True)
    room_type = serializers.PrimaryKeyRelatedField(
        queryset=RoomType.objects.filter(is_active=True), required=False, allow_null=True
    )

    def validate(self, attrs):
        """Validate date range."""
        if attrs["check_out"] <= attrs["check_in"]:
            raise serializers.ValidationError({"check_out": "Ngày trả phòng phải sau ngày nhận phòng."})
        return attrs


# ==================== Guest Management Serializers ====================


class GuestSerializer(serializers.ModelSerializer):
    """Guest serializer with full details."""

    is_returning_guest = serializers.ReadOnlyField()
    booking_count = serializers.SerializerMethodField()

    class Meta:
        model = Guest
        fields = [
            "id",
            "full_name",
            "phone",
            "email",
            "id_type",
            "id_number",
            "id_issue_date",
            "id_issue_place",
            "id_image",
            "nationality",
            "date_of_birth",
            "gender",
            "address",
            "city",
            "country",
            "is_vip",
            "total_stays",
            "preferences",
            "notes",
            "is_returning_guest",
            "booking_count",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "total_stays", "created_at", "updated_at"]

    @extend_schema_field(serializers.IntegerField)
    def get_booking_count(self, obj):
        """Get total number of bookings for this guest."""
        return obj.bookings.count()

    def validate_phone(self, value):
        """Validate phone number format and uniqueness, normalize input."""
        import re
        
        if not value:
            raise serializers.ValidationError("Phone number is required.")
        
        # Normalize: remove all non-digit characters
        cleaned = re.sub(r"\D", "", value)
        
        # Validate length (Vietnamese phone numbers: 10-11 digits)
        if len(cleaned) < 10 or len(cleaned) > 11:
            raise serializers.ValidationError("Phone number must be 10-11 digits.")
        
        # Check for uniqueness
        instance = self.instance
        if Guest.objects.filter(phone=cleaned).exclude(pk=instance.pk if instance else None).exists():
            raise serializers.ValidationError("This phone number already exists.")
        
        return cleaned

    def validate_id_number(self, value):
        """Validate ID number if provided."""
        if value:
            # Check if ID number already exists (for other guests)
            instance = self.instance
            if Guest.objects.filter(id_number=value).exclude(pk=instance.pk if instance else None).exists():
                raise serializers.ValidationError("This ID number already exists.")
        return value


class GuestListSerializer(serializers.ModelSerializer):
    """Simplified Guest serializer for list views."""

    is_returning_guest = serializers.ReadOnlyField()
    booking_count = serializers.IntegerField(read_only=True)  # From annotation

    class Meta:
        model = Guest
        fields = [
            "id",
            "full_name",
            "phone",
            "email",
            "nationality",
            "id_number",
            "is_vip",
            "total_stays",
            "is_returning_guest",
            "booking_count",
            "created_at",
        ]

    # Remove get_booking_count method as we use annotation


class GuestSearchSerializer(serializers.Serializer):
    """Serializer for guest search request."""

    query = serializers.CharField(required=True, min_length=2)
    search_by = serializers.ChoiceField(
        choices=["name", "phone", "id_number", "all"], default="all", required=False
    )

    def validate_query(self, value):
        """Validate search query."""
        if len(value.strip()) < 2:
            raise serializers.ValidationError("Từ khóa tìm kiếm phải có ít nhất 2 ký tự.")
        return value.strip()


# ==================== Booking Management Serializers ====================


class BookingSerializer(serializers.ModelSerializer):
    """Booking serializer with full details."""

    guest_details = GuestListSerializer(source="guest", read_only=True)
    room_number = serializers.CharField(source="room.number", read_only=True)
    room_type_name = serializers.CharField(source="room.room_type.name", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    source_display = serializers.CharField(source="get_source_display", read_only=True)
    booking_type_display = serializers.CharField(source="get_booking_type_display", read_only=True)
    nights = serializers.ReadOnlyField()
    balance_due = serializers.ReadOnlyField()
    is_hourly = serializers.ReadOnlyField()

    @extend_schema_field(serializers.IntegerField)
    def nights(self, obj):
        return obj.nights
    
    @extend_schema_field(serializers.DecimalField)
    def balance_due(self, obj):
        return obj.balance_due

    class Meta:
        model = Booking
        fields = [
            "id",
            "room",
            "room_number",
            "room_type_name",
            "check_in_date",
            "check_out_date",
            "actual_check_in",
            "actual_check_out",
            "guest",
            "guest_details",
            "guest_count",
            "status",
            "status_display",
            "source",
            "source_display",
            "ota_reference",
            # Booking type (hourly/overnight)
            "booking_type",
            "booking_type_display",
            "is_hourly",
            # Hourly booking fields
            "hours_booked",
            "hourly_rate",
            "expected_check_out_time",
            # Early/Late fees
            "early_check_in_fee",
            "late_check_out_fee",
            "early_check_in_hours",
            "late_check_out_hours",
            # Pricing
            "nightly_rate",
            "total_amount",
            "currency",
            "deposit_amount",
            "deposit_paid",
            "additional_charges",
            "payment_method",
            "is_paid",
            "notes",
            "special_requests",
            "nights",
            "balance_due",
            "created_by",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_by", "created_at", "updated_at"]

    def validate(self, attrs):
        """Validate booking data."""
        from datetime import date
        check_in = attrs.get("check_in_date")
        check_out = attrs.get("check_out_date")
        room = attrs.get("room")
        guest_count = attrs.get("guest_count", 1)
        deposit_amount = attrs.get("deposit_amount", 0)
        total_amount = attrs.get("total_amount")

        # Only validate dates if both are provided (not for partial updates)
        if check_in and check_out:
            # Validate check-out is after check-in
            if check_out <= check_in:
                raise serializers.ValidationError({"check_out_date": "Check-out date must be after check-in date."})
            
            # Validate check-in is not in the past (for new bookings only)
            if not self.instance and check_in < date.today():
                raise serializers.ValidationError({"check_in_date": "Check-in date cannot be in the past."})
        
        # Validate guest count does not exceed room capacity
        if room and guest_count:
            max_guests = room.room_type.max_guests
            if guest_count > max_guests:
                raise serializers.ValidationError(
                    {"guest_count": f"Guest count ({guest_count}) exceeds room capacity ({max_guests})."}
                )
        
        # Validate deposit does not exceed total amount
        if deposit_amount and total_amount and deposit_amount > total_amount:
            raise serializers.ValidationError(
                {"deposit_amount": "Deposit amount cannot exceed total amount."}
            )

        # Check for overlapping bookings with row-level locking to prevent race conditions
        if room and check_in and check_out:
            # Use select_for_update() within a transaction to lock the room
            overlapping = Booking.objects.select_for_update().filter(
                room=room,
                status__in=[Booking.Status.CONFIRMED, Booking.Status.CHECKED_IN],
            ).exclude(pk=self.instance.pk if self.instance else None)

            # Check if new booking overlaps with existing ones
            for booking in overlapping:
                if not (check_out <= booking.check_in_date or check_in >= booking.check_out_date):
                    raise serializers.ValidationError(
                        {
                            "room": f"Room is already booked from {booking.check_in_date} to {booking.check_out_date}."
                        }
                    )

        return attrs

    def create(self, validated_data):
        """Create booking with user tracking."""
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


class BookingListSerializer(serializers.ModelSerializer):
    """Simplified Booking serializer for list views."""

    guest_name = serializers.CharField(source="guest.full_name", read_only=True)
    guest_phone = serializers.CharField(source="guest.phone", read_only=True)
    room_number = serializers.CharField(source="room.number", read_only=True)
    room_type_name = serializers.CharField(source="room.room_type.name", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    booking_type_display = serializers.CharField(source="get_booking_type_display", read_only=True)
    nights = serializers.ReadOnlyField()

    class Meta:
        model = Booking
        fields = [
            "id",
            "room",
            "room_number",
            "room_type_name",
            "check_in_date",
            "check_out_date",
            "guest",
            "guest_name",
            "guest_phone",
            "guest_count",
            "status",
            "status_display",
            "source",
            "booking_type",
            "booking_type_display",
            "hours_booked",
            "nightly_rate",
            "hourly_rate",
            "total_amount",
            "is_paid",
            "nights",
            "created_at",
        ]


class BookingStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating booking status."""

    status = serializers.ChoiceField(choices=Booking.Status.choices, required=True)
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_status(self, value):
        """Validate status transition."""
        booking = self.context.get("booking")
        if booking and booking.status == value:
            raise serializers.ValidationError("Đặt phòng đã ở trạng thái này rồi.")
        return value

    def update(self, instance, validated_data):
        """Update booking status."""
        instance.status = validated_data.get("status", instance.status)
        if validated_data.get("notes"):
            instance.notes = validated_data["notes"]
        instance.save()
        return instance


class CheckInSerializer(serializers.Serializer):
    """Serializer for check-in action."""

    actual_check_in = serializers.DateTimeField(required=False)
    notes = serializers.CharField(required=False, allow_blank=True)


class CheckOutSerializer(serializers.Serializer):
    """Serializer for check-out action."""

    actual_check_out = serializers.DateTimeField(required=False)
    notes = serializers.CharField(required=False, allow_blank=True)
    additional_charges = serializers.DecimalField(
        max_digits=12, decimal_places=0, default=0, required=False
    )


class EarlyCheckInFeeSerializer(serializers.Serializer):
    """Serializer for recording early check-in fee."""

    hours = serializers.DecimalField(
        max_digits=4,
        decimal_places=1,
        help_text="Number of hours early (e.g. 2.0)",
    )
    fee = serializers.DecimalField(
        max_digits=12,
        decimal_places=0,
        help_text="Fee amount in VND",
    )
    notes = serializers.CharField(required=False, allow_blank=True)
    create_folio_item = serializers.BooleanField(
        default=True,
        help_text="Also create a FolioItem for tracking",
    )

    def validate_hours(self, value):
        if value <= 0:
            raise serializers.ValidationError("Số giờ phải lớn hơn 0.")
        if value > 24:
            raise serializers.ValidationError("Số giờ không được vượt quá 24.")
        return value

    def validate_fee(self, value):
        if value < 0:
            raise serializers.ValidationError("Phí không được âm.")
        return value


class LateCheckOutFeeSerializer(serializers.Serializer):
    """Serializer for recording late check-out fee."""

    hours = serializers.DecimalField(
        max_digits=4,
        decimal_places=1,
        help_text="Number of hours late (e.g. 3.0)",
    )
    fee = serializers.DecimalField(
        max_digits=12,
        decimal_places=0,
        help_text="Fee amount in VND",
    )
    notes = serializers.CharField(required=False, allow_blank=True)
    create_folio_item = serializers.BooleanField(
        default=True,
        help_text="Also create a FolioItem for tracking",
    )

    def validate_hours(self, value):
        if value <= 0:
            raise serializers.ValidationError("Số giờ phải lớn hơn 0.")
        if value > 24:
            raise serializers.ValidationError("Số giờ không được vượt quá 24.")
        return value

    def validate_fee(self, value):
        if value < 0:
            raise serializers.ValidationError("Phí không được âm.")
        return value


# ==================== Financial Serializers ====================


class FinancialCategorySerializer(serializers.ModelSerializer):
    """Serializer for FinancialCategory model."""

    entry_count = serializers.SerializerMethodField()

    class Meta:
        model = FinancialCategory
        fields = [
            "id",
            "name",
            "name_en",
            "category_type",
            "icon",
            "color",
            "is_default",
            "is_active",
            "sort_order",
            "entry_count",
        ]
        read_only_fields = ["id"]

    @extend_schema_field(int)
    def get_entry_count(self, obj):
        """Get number of entries in this category."""
        if hasattr(obj, "entry_count"):
            return obj.entry_count
        return obj.entries.count()


class FinancialCategoryListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing financial categories."""

    class Meta:
        model = FinancialCategory
        fields = ["id", "name", "name_en", "category_type", "icon", "color", "is_default"]


class FinancialEntrySerializer(serializers.ModelSerializer):
    """Serializer for FinancialEntry model."""

    category_details = FinancialCategoryListSerializer(source="category", read_only=True)
    booking_details = serializers.SerializerMethodField()
    amount_vnd = serializers.SerializerMethodField()

    class Meta:
        model = FinancialEntry
        fields = [
            "id",
            "entry_type",
            "category",
            "category_details",
            "amount",
            "currency",
            "exchange_rate",
            "amount_vnd",
            "date",
            "description",
            "booking",
            "booking_details",
            "payment_method",
            "receipt_number",
            "attachment",
            "created_by",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_by", "created_at", "updated_at"]

    @extend_schema_field(serializers.DictField)
    def get_booking_details(self, obj):
        """Get linked booking details if exists."""
        if obj.booking:
            return {
                "id": obj.booking.id,
                "room_number": obj.booking.room.number,
                "guest_name": obj.booking.guest.full_name,
                "check_in_date": obj.booking.check_in_date,
                "check_out_date": obj.booking.check_out_date,
            }
        return None

    @extend_schema_field(serializers.DecimalField(max_digits=15, decimal_places=0))
    def get_amount_vnd(self, obj):
        """Get amount converted to VND."""
        return obj.amount * obj.exchange_rate

    def validate(self, attrs):
        """Validate that category type matches entry type."""
        category = attrs.get("category")
        entry_type = attrs.get("entry_type")

        if category and entry_type:
            if category.category_type != entry_type:
                raise serializers.ValidationError(
                    {
                        "category": f"Danh mục {category.name} không phải loại {entry_type}. "
                        f"Vui lòng chọn danh mục {entry_type}."
                    }
                )

        return attrs


class FinancialEntryListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing financial entries."""

    category_name = serializers.CharField(source="category.name", read_only=True)
    category_icon = serializers.CharField(source="category.icon", read_only=True)
    category_color = serializers.CharField(source="category.color", read_only=True)
    room_number = serializers.CharField(source="booking.room.number", read_only=True, allow_null=True)

    class Meta:
        model = FinancialEntry
        fields = [
            "id",
            "entry_type",
            "category",
            "category_name",
            "category_icon",
            "category_color",
            "amount",
            "currency",
            "date",
            "description",
            "payment_method",
            "room_number",
            "created_at",
        ]


class FinancialSummarySerializer(serializers.Serializer):
    """Serializer for financial summary data."""

    period_start = serializers.DateField()
    period_end = serializers.DateField()
    total_income = serializers.DecimalField(max_digits=15, decimal_places=0)
    total_expense = serializers.DecimalField(max_digits=15, decimal_places=0)
    net_profit = serializers.DecimalField(max_digits=15, decimal_places=0)
    income_by_category = serializers.ListField(child=serializers.DictField())
    expense_by_category = serializers.ListField(child=serializers.DictField())


# Import NightAudit model for serializer
from .models import NightAudit


class NightAuditSerializer(serializers.ModelSerializer):
    """Full serializer for night audit."""

    performed_by_name = serializers.SerializerMethodField()
    closed_by_name = serializers.SerializerMethodField()
    status_display = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = NightAudit
        fields = [
            "id",
            "audit_date",
            "status",
            "status_display",
            # Room statistics
            "total_rooms",
            "rooms_occupied",
            "rooms_available",
            "rooms_cleaning",
            "rooms_maintenance",
            "occupancy_rate",
            # Booking statistics
            "check_ins_today",
            "check_outs_today",
            "no_shows",
            "cancellations",
            "new_bookings",
            # Financial summary
            "total_income",
            "room_revenue",
            "other_revenue",
            "total_expense",
            "net_revenue",
            # Payment breakdown
            "cash_collected",
            "bank_transfer_collected",
            "momo_collected",
            "other_payments",
            # Outstanding
            "pending_payments",
            "unpaid_bookings_count",
            # Notes
            "notes",
            # Audit info
            "performed_by",
            "performed_by_name",
            "performed_at",
            "closed_by",
            "closed_by_name",
            "closed_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "performed_by",
            "performed_by_name",
            "performed_at",
            "closed_by",
            "closed_by_name",
            "closed_at",
            "created_at",
            "updated_at",
        ]

    @extend_schema_field(serializers.CharField)
    def get_performed_by_name(self, obj):
        """Get name of user who performed the audit."""
        if obj.performed_by:
            return obj.performed_by.get_full_name() or obj.performed_by.username
        return None

    @extend_schema_field(serializers.CharField)
    def get_closed_by_name(self, obj):
        """Get name of user who closed the audit."""
        if obj.closed_by:
            return obj.closed_by.get_full_name() or obj.closed_by.username
        return None


class NightAuditListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing night audits."""

    status_display = serializers.CharField(source="get_status_display", read_only=True)
    performed_by_name = serializers.SerializerMethodField()

    class Meta:
        model = NightAudit
        fields = [
            "id",
            "audit_date",
            "status",
            "status_display",
            "total_rooms",
            "rooms_occupied",
            "occupancy_rate",
            "total_income",
            "total_expense",
            "net_revenue",
            "performed_by_name",
            "performed_at",
        ]

    @extend_schema_field(serializers.CharField)
    def get_performed_by_name(self, obj):
        """Get name of user who performed the audit."""
        if obj.performed_by:
            return obj.performed_by.get_full_name() or obj.performed_by.username
        return None


class NightAuditCreateSerializer(serializers.Serializer):
    """Serializer for creating/generating a night audit."""

    audit_date = serializers.DateField()
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_audit_date(self, value):
        """Validate that audit date is not in the future."""
        from datetime import date
        if value > date.today():
            raise serializers.ValidationError("Không thể tạo kiểm toán cho ngày trong tương lai.")
        return value


# ============================================================
# Payment Serializers (Phase 2.1.3)
# ============================================================

from .models import Payment, FolioItem, ExchangeRate


class PaymentSerializer(serializers.ModelSerializer):
    """Full serializer for Payment model."""

    payment_type_display = serializers.CharField(source="get_payment_type_display", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    payment_method_display = serializers.CharField(source="get_payment_method_display", read_only=True)
    created_by_name = serializers.SerializerMethodField()
    booking_room = serializers.SerializerMethodField()
    booking_guest = serializers.SerializerMethodField()

    class Meta:
        model = Payment
        fields = [
            "id",
            "booking",
            "booking_room",
            "booking_guest",
            "payment_type",
            "payment_type_display",
            "amount",
            "currency",
            "payment_method",
            "payment_method_display",
            "status",
            "status_display",
            "transaction_id",
            "reference_number",
            "receipt_number",
            "receipt_generated",
            "description",
            "notes",
            "payment_date",
            "created_by",
            "created_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "receipt_number",
            "created_by",
            "created_by_name",
            "created_at",
            "updated_at",
        ]

    @extend_schema_field(serializers.CharField)
    def get_created_by_name(self, obj):
        if obj.created_by:
            return obj.created_by.get_full_name() or obj.created_by.username
        return None

    @extend_schema_field(serializers.CharField)
    def get_booking_room(self, obj):
        if obj.booking:
            return obj.booking.room.number
        return None

    @extend_schema_field(serializers.CharField)
    def get_booking_guest(self, obj):
        if obj.booking:
            return obj.booking.guest.full_name
        return None


class PaymentListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing payments."""

    payment_type_display = serializers.CharField(source="get_payment_type_display", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    payment_method_display = serializers.CharField(source="get_payment_method_display", read_only=True)
    booking_room = serializers.SerializerMethodField()

    class Meta:
        model = Payment
        fields = [
            "id",
            "booking",
            "booking_room",
            "payment_type",
            "payment_type_display",
            "amount",
            "currency",
            "payment_method",
            "payment_method_display",
            "status",
            "status_display",
            "receipt_number",
            "payment_date",
        ]

    @extend_schema_field(serializers.CharField)
    def get_booking_room(self, obj):
        if obj.booking:
            return obj.booking.room.number
        return None


class PaymentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new payment."""

    class Meta:
        model = Payment
        fields = [
            "booking",
            "payment_type",
            "amount",
            "currency",
            "payment_method",
            "transaction_id",
            "reference_number",
            "description",
            "notes",
        ]

    def validate(self, attrs):
        booking = attrs.get("booking")
        payment_type = attrs.get("payment_type")
        amount = attrs.get("amount")

        # Validate deposit doesn't exceed total
        if booking and payment_type == Payment.PaymentType.DEPOSIT:
            existing_deposits = Payment.objects.filter(
                booking=booking,
                payment_type=Payment.PaymentType.DEPOSIT,
                status=Payment.Status.COMPLETED,
            ).aggregate(total=models.Sum("amount"))["total"] or 0
            if existing_deposits + amount > booking.total_amount:
                raise serializers.ValidationError(
                    {"amount": "Tổng tiền cọc không thể vượt quá tổng tiền đặt phòng."}
                )

        return attrs

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        payment = super().create(validated_data)

        # Update booking deposit status if deposit payment
        if payment.booking and payment.payment_type == Payment.PaymentType.DEPOSIT:
            booking = payment.booking
            total_deposits = Payment.objects.filter(
                booking=booking,
                payment_type=Payment.PaymentType.DEPOSIT,
                status=Payment.Status.COMPLETED,
            ).aggregate(total=models.Sum("amount"))["total"] or 0
            booking.deposit_amount = total_deposits
            booking.deposit_paid = total_deposits >= booking.total_amount * Decimal("0.3")  # 30% threshold
            booking.save(update_fields=["deposit_amount", "deposit_paid"])

        return payment


# ============================================================
# Folio Item Serializers (Phase 2.1.4)
# ============================================================


class FolioItemSerializer(serializers.ModelSerializer):
    """Full serializer for FolioItem model."""

    item_type_display = serializers.CharField(source="get_item_type_display", read_only=True)
    created_by_name = serializers.SerializerMethodField()
    booking_room = serializers.SerializerMethodField()

    class Meta:
        model = FolioItem
        fields = [
            "id",
            "booking",
            "booking_room",
            "item_type",
            "item_type_display",
            "description",
            "quantity",
            "unit_price",
            "total_price",
            "date",
            "minibar_sale",
            "is_paid",
            "is_voided",
            "void_reason",
            "created_by",
            "created_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "total_price",
            "created_by",
            "created_by_name",
            "created_at",
            "updated_at",
        ]

    @extend_schema_field(serializers.CharField)
    def get_created_by_name(self, obj):
        if obj.created_by:
            return obj.created_by.get_full_name() or obj.created_by.username
        return None

    @extend_schema_field(serializers.CharField)
    def get_booking_room(self, obj):
        return obj.booking.room.number


class FolioItemCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a new folio item."""

    class Meta:
        model = FolioItem
        fields = [
            "booking",
            "item_type",
            "description",
            "quantity",
            "unit_price",
            "date",
        ]

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


# ============================================================
# Exchange Rate Serializers (Phase 2.6)
# ============================================================


class ExchangeRateSerializer(serializers.ModelSerializer):
    """Full serializer for ExchangeRate model."""

    class Meta:
        model = ExchangeRate
        fields = [
            "id",
            "from_currency",
            "to_currency",
            "rate",
            "date",
            "source",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class ExchangeRateCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating exchange rate."""

    class Meta:
        model = ExchangeRate
        fields = ["from_currency", "to_currency", "rate", "date", "source"]

    def validate(self, attrs):
        from_currency = attrs.get("from_currency")
        to_currency = attrs.get("to_currency")
        date = attrs.get("date")

        # Check for duplicate
        if ExchangeRate.objects.filter(
            from_currency=from_currency,
            to_currency=to_currency,
            date=date,
        ).exists():
            raise serializers.ValidationError(
                "Tỷ giá cho cặp tiền tệ này vào ngày này đã tồn tại."
            )

        return attrs


class CurrencyConversionSerializer(serializers.Serializer):
    """Serializer for currency conversion request."""

    amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    from_currency = serializers.CharField(max_length=3)
    to_currency = serializers.CharField(max_length=3, default="VND")
    date = serializers.DateField(required=False)


# ============================================================
# Deposit Management Serializers (Phase 2.4)
# ============================================================


class DepositRecordSerializer(serializers.Serializer):
    """Serializer for recording a deposit payment."""

    booking_id = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=0)
    payment_method = serializers.ChoiceField(choices=Booking.PaymentMethod.choices)
    transaction_id = serializers.CharField(required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_booking_id(self, value):
        try:
            booking = Booking.objects.get(id=value)
        except Booking.DoesNotExist:
            raise serializers.ValidationError("Không tìm thấy đặt phòng.")

        if booking.status == Booking.Status.CANCELLED:
            raise serializers.ValidationError("Không thể nhận cọc cho đặt phòng đã hủy.")
        if booking.status == Booking.Status.CHECKED_OUT:
            raise serializers.ValidationError("Không thể nhận cọc cho đặt phòng đã trả phòng.")

        return value


class OutstandingDepositSerializer(serializers.ModelSerializer):
    """Serializer for bookings with outstanding deposits."""

    room_number = serializers.CharField(source="room.number", read_only=True)
    room_type = serializers.CharField(source="room.room_type.name", read_only=True)
    guest_name = serializers.CharField(source="guest.full_name", read_only=True)
    guest_phone = serializers.CharField(source="guest.phone", read_only=True)
    balance_due = serializers.DecimalField(max_digits=12, decimal_places=0, read_only=True)
    deposit_percentage = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            "id",
            "room_number",
            "room_type",
            "guest_name",
            "guest_phone",
            "check_in_date",
            "check_out_date",
            "total_amount",
            "deposit_amount",
            "deposit_paid",
            "balance_due",
            "deposit_percentage",
            "status",
        ]

    @extend_schema_field(serializers.DecimalField(max_digits=5, decimal_places=2))
    def get_deposit_percentage(self, obj):
        if obj.total_amount > 0:
            return round((obj.deposit_amount / obj.total_amount) * 100, 2)
        return 0


# ============================================================
# Receipt Generation Serializers (Phase 2.8)
# ============================================================


class ReceiptGenerateSerializer(serializers.Serializer):
    """Serializer for generating a receipt."""

    booking_id = serializers.IntegerField(required=False)
    payment_id = serializers.IntegerField(required=False)
    include_folio = serializers.BooleanField(default=True)
    language = serializers.ChoiceField(choices=[("vi", "Vietnamese"), ("en", "English")], default="vi")

    def validate(self, attrs):
        if not attrs.get("booking_id") and not attrs.get("payment_id"):
            raise serializers.ValidationError(
                "Phải cung cấp booking_id hoặc payment_id."
            )
        return attrs


class ReceiptDataSerializer(serializers.Serializer):
    """Serializer for receipt data output."""

    receipt_number = serializers.CharField()
    receipt_date = serializers.DateTimeField()
    hotel_name = serializers.CharField()
    hotel_address = serializers.CharField()
    hotel_phone = serializers.CharField()

    # Guest info
    guest_name = serializers.CharField()
    guest_phone = serializers.CharField()
    guest_id_number = serializers.CharField(allow_blank=True)

    # Booking info
    room_number = serializers.CharField()
    room_type = serializers.CharField()
    check_in_date = serializers.DateField()
    check_out_date = serializers.DateField()
    nights = serializers.IntegerField()

    # Financial
    room_total = serializers.DecimalField(max_digits=12, decimal_places=0)
    additional_charges = serializers.DecimalField(max_digits=12, decimal_places=0)
    total_amount = serializers.DecimalField(max_digits=12, decimal_places=0)
    deposit_paid = serializers.DecimalField(max_digits=12, decimal_places=0)
    balance_due = serializers.DecimalField(max_digits=12, decimal_places=0)

    # Folio items
    folio_items = serializers.ListField(child=serializers.DictField(), required=False)

    # Payment info
    payment_method = serializers.CharField()
    created_by = serializers.CharField()


# ============================================================
# Housekeeping Serializers (Phase 3.1)
# ============================================================


class HousekeepingTaskSerializer(serializers.ModelSerializer):
    """Full housekeeping task serializer."""

    room_number = serializers.CharField(source="room.number", read_only=True)
    assigned_to_name = serializers.CharField(source="assigned_to.get_full_name", read_only=True)
    created_by_name = serializers.CharField(source="created_by.get_full_name", read_only=True)
    task_type_display = serializers.CharField(source="get_task_type_display", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = HousekeepingTask
        fields = [
            "id",
            "room",
            "room_number",
            "task_type",
            "task_type_display",
            "status",
            "status_display",
            "scheduled_date",
            "completed_at",
            "assigned_to",
            "assigned_to_name",
            "notes",
            "booking",
            "created_by",
            "created_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]


class HousekeepingTaskCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating housekeeping tasks."""

    class Meta:
        model = HousekeepingTask
        fields = [
            "room",
            "task_type",
            "scheduled_date",
            "assigned_to",
            "notes",
            "booking",
        ]

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


class HousekeepingTaskUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating housekeeping tasks."""

    class Meta:
        model = HousekeepingTask
        fields = [
            "status",
            "assigned_to",
            "notes",
            "completed_at",
        ]


class HousekeepingTaskListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing housekeeping tasks."""

    room_number = serializers.CharField(source="room.number", read_only=True)
    assigned_to_name = serializers.CharField(source="assigned_to.get_full_name", read_only=True)
    task_type_display = serializers.CharField(source="get_task_type_display", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = HousekeepingTask
        fields = [
            "id",
            "room_number",
            "task_type",
            "task_type_display",
            "status",
            "status_display",
            "scheduled_date",
            "assigned_to_name",
        ]


# ============================================================
# Maintenance Request Serializers (Phase 3.1)
# ============================================================


class MaintenanceRequestSerializer(serializers.ModelSerializer):
    """Full maintenance request serializer."""

    room_number = serializers.CharField(source="room.number", read_only=True, allow_null=True)
    assigned_to_name = serializers.CharField(source="assigned_to.get_full_name", read_only=True, allow_null=True)
    reported_by_name = serializers.CharField(source="reported_by.get_full_name", read_only=True, allow_null=True)
    completed_by_name = serializers.CharField(source="completed_by.get_full_name", read_only=True, allow_null=True)
    priority_display = serializers.CharField(source="get_priority_display", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    category_display = serializers.CharField(source="get_category_display", read_only=True)

    class Meta:
        model = MaintenanceRequest
        fields = [
            "id",
            "room",
            "room_number",
            "location_description",
            "title",
            "description",
            "category",
            "category_display",
            "priority",
            "priority_display",
            "status",
            "status_display",
            "assigned_to",
            "assigned_to_name",
            "assigned_at",
            "estimated_cost",
            "actual_cost",
            "resolution_notes",
            "completed_at",
            "completed_by",
            "completed_by_name",
            "reported_by",
            "reported_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "reported_by", "assigned_at", "completed_at", "completed_by"]


class MaintenanceRequestCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating maintenance requests."""

    class Meta:
        model = MaintenanceRequest
        fields = [
            "room",
            "location_description",
            "title",
            "description",
            "category",
            "priority",
            "estimated_cost",
        ]

    def validate(self, attrs):
        # Require either room or location_description
        if not attrs.get("room") and not attrs.get("location_description"):
            raise serializers.ValidationError(
                "Vui lòng chọn phòng hoặc nhập vị trí cụ thể."
            )
        return attrs

    def create(self, validated_data):
        validated_data["reported_by"] = self.context["request"].user
        return super().create(validated_data)


class MaintenanceRequestUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating maintenance requests."""

    class Meta:
        model = MaintenanceRequest
        fields = [
            "status",
            "assigned_to",
            "priority",
            "estimated_cost",
            "actual_cost",
            "resolution_notes",
        ]


class MaintenanceRequestListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing maintenance requests."""

    room_number = serializers.CharField(source="room.number", read_only=True, allow_null=True)
    priority_display = serializers.CharField(source="get_priority_display", read_only=True)
    status_display = serializers.CharField(source="get_status_display", read_only=True)
    category_display = serializers.CharField(source="get_category_display", read_only=True)
    location = serializers.SerializerMethodField()

    class Meta:
        model = MaintenanceRequest
        fields = [
            "id",
            "title",
            "room_number",
            "location",
            "category",
            "category_display",
            "priority",
            "priority_display",
            "status",
            "status_display",
            "created_at",
        ]

    def get_location(self, obj):
        return obj.room.number if obj.room else obj.location_description


# ============================================================
# Minibar Serializers (Phase 3.4)
# ============================================================


class MinibarItemSerializer(serializers.ModelSerializer):
    """Full serializer for MinibarItem model."""

    class Meta:
        model = MinibarItem
        fields = [
            "id",
            "name",
            "price",
            "cost",
            "category",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class MinibarItemCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating minibar items."""

    class Meta:
        model = MinibarItem
        fields = ["name", "price", "cost", "category", "is_active"]

    def validate_name(self, value):
        if MinibarItem.objects.filter(name__iexact=value).exists():
            raise serializers.ValidationError("Sản phẩm minibar với tên này đã tồn tại.")
        return value

    def validate_price(self, value):
        if value < 0:
            raise serializers.ValidationError("Giá bán phải lớn hơn hoặc bằng 0.")
        return value

    def validate_cost(self, value):
        if value < 0:
            raise serializers.ValidationError("Giá vốn phải lớn hơn hoặc bằng 0.")
        return value


class MinibarItemUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating minibar items."""

    class Meta:
        model = MinibarItem
        fields = ["name", "price", "cost", "category", "is_active"]

    def validate_name(self, value):
        instance = self.instance
        if MinibarItem.objects.filter(name__iexact=value).exclude(pk=instance.pk).exists():
            raise serializers.ValidationError("Sản phẩm minibar với tên này đã tồn tại.")
        return value

    def validate_price(self, value):
        if value < 0:
            raise serializers.ValidationError("Giá bán phải lớn hơn hoặc bằng 0.")
        return value

    def validate_cost(self, value):
        if value < 0:
            raise serializers.ValidationError("Giá vốn phải lớn hơn hoặc bằng 0.")
        return value


class MinibarItemListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing minibar items."""

    class Meta:
        model = MinibarItem
        fields = ["id", "name", "price", "category", "is_active"]


class MinibarSaleSerializer(serializers.ModelSerializer):
    """Full serializer for MinibarSale model."""

    item_name = serializers.CharField(source="item.name", read_only=True)
    item_category = serializers.CharField(source="item.category", read_only=True)
    booking_guest_name = serializers.CharField(source="booking.guest_name", read_only=True)
    booking_room_number = serializers.CharField(source="booking.room.number", read_only=True)
    created_by_name = serializers.CharField(source="created_by.get_full_name", read_only=True)

    class Meta:
        model = MinibarSale
        fields = [
            "id",
            "booking",
            "booking_guest_name",
            "booking_room_number",
            "item",
            "item_name",
            "item_category",
            "quantity",
            "unit_price",
            "total",
            "date",
            "is_charged",
            "created_by",
            "created_by_name",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "unit_price",
            "total",
            "created_at",
        ]


class MinibarSaleCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating minibar sales."""

    class Meta:
        model = MinibarSale
        fields = ["booking", "item", "quantity", "date"]

    def validate_booking(self, value):
        if value.status not in ["confirmed", "checked_in"]:
            raise serializers.ValidationError(
                "Chỉ có thể thêm minibar cho đặt phòng đã xác nhận hoặc đã nhận phòng."
            )
        return value

    def validate_item(self, value):
        if not value.is_active:
            raise serializers.ValidationError("Sản phẩm này không còn hoạt động.")
        return value

    def validate_quantity(self, value):
        if value < 1:
            raise serializers.ValidationError("Số lượng phải lớn hơn 0.")
        return value

    def create(self, validated_data):
        item = validated_data["item"]
        quantity = validated_data["quantity"]
        validated_data["unit_price"] = item.price
        validated_data["total"] = item.price * quantity
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


class MinibarSaleUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating minibar sales."""

    class Meta:
        model = MinibarSale
        fields = ["quantity", "is_charged"]

    def validate_quantity(self, value):
        if value < 1:
            raise serializers.ValidationError("Số lượng phải lớn hơn 0.")
        return value

    def update(self, instance, validated_data):
        if "quantity" in validated_data and validated_data["quantity"] != instance.quantity:
            new_quantity = validated_data["quantity"]
            validated_data["total"] = instance.unit_price * new_quantity
        return super().update(instance, validated_data)


class MinibarSaleListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing minibar sales."""

    item_name = serializers.CharField(source="item.name", read_only=True)
    room_number = serializers.CharField(source="booking.room.number", read_only=True)

    class Meta:
        model = MinibarSale
        fields = [
            "id",
            "item_name",
            "room_number",
            "quantity",
            "total",
            "date",
            "is_charged",
        ]


class MinibarSaleBulkCreateSerializer(serializers.Serializer):
    """Serializer for bulk creating minibar sales."""

    booking = serializers.PrimaryKeyRelatedField(queryset=Booking.objects.all())
    items = serializers.ListField(
        child=serializers.DictField(child=serializers.IntegerField()),
        min_length=1,
    )
    date = serializers.DateField(required=False)

    def validate_booking(self, value):
        if value.status not in ["confirmed", "checked_in"]:
            raise serializers.ValidationError(
                "Chỉ có thể thêm minibar cho đặt phòng đã xác nhận hoặc đã nhận phòng."
            )
        return value

    def validate_items(self, value):
        for item_data in value:
            if "item_id" not in item_data or "quantity" not in item_data:
                raise serializers.ValidationError(
                    "Mỗi mục phải có item_id và quantity."
                )
            if item_data["quantity"] < 1:
                raise serializers.ValidationError("Số lượng phải lớn hơn 0.")
            try:
                item = MinibarItem.objects.get(pk=item_data["item_id"])
                if not item.is_active:
                    raise serializers.ValidationError(
                        f"Sản phẩm '{item.name}' không còn hoạt động."
                    )
            except MinibarItem.DoesNotExist:
                raise serializers.ValidationError(
                    f"Sản phẩm với ID {item_data['item_id']} không tồn tại."
                )
        return value

    def create(self, validated_data):
        from django.utils import timezone

        booking = validated_data["booking"]
        items_data = validated_data["items"]
        date = validated_data.get("date", timezone.now().date())
        user = self.context["request"].user

        sales = []
        for item_data in items_data:
            item = MinibarItem.objects.get(pk=item_data["item_id"])
            quantity = item_data["quantity"]
            sale = MinibarSale.objects.create(
                booking=booking,
                item=item,
                quantity=quantity,
                unit_price=item.price,
                total=item.price * quantity,
                date=date,
                created_by=user,
            )
            sales.append(sale)
        return sales


# ============================================================================
# PHASE 4: REPORT SERIALIZERS
# ============================================================================


class OccupancyReportSerializer(serializers.Serializer):
    """Occupancy report data serializer."""
    
    date = serializers.DateField()
    total_rooms = serializers.IntegerField()
    occupied_rooms = serializers.IntegerField()
    available_rooms = serializers.IntegerField()
    occupancy_rate = serializers.DecimalField(max_digits=5, decimal_places=2)
    revenue = serializers.DecimalField(max_digits=15, decimal_places=0)


class OccupancyReportRequestSerializer(serializers.Serializer):
    """Request parameters for occupancy report."""
    
    start_date = serializers.DateField(required=True)
    end_date = serializers.DateField(required=True)
    group_by = serializers.ChoiceField(
        choices=["day", "week", "month"],
        default="day",
        required=False,
    )
    room_type = serializers.IntegerField(required=False, allow_null=True)
    
    def validate(self, attrs):
        if attrs["start_date"] > attrs["end_date"]:
            raise serializers.ValidationError({
                "end_date": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        return attrs


class RevenueReportSerializer(serializers.Serializer):
    """Revenue report data serializer."""
    
    date = serializers.DateField(required=False)
    period = serializers.CharField(required=False)  # For week/month grouping
    room_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    additional_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    minibar_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    total_expenses = serializers.DecimalField(max_digits=15, decimal_places=0)
    net_profit = serializers.DecimalField(max_digits=15, decimal_places=0)
    profit_margin = serializers.DecimalField(max_digits=5, decimal_places=2)


class RevenueReportRequestSerializer(serializers.Serializer):
    """Request parameters for revenue report."""
    
    start_date = serializers.DateField(required=True)
    end_date = serializers.DateField(required=True)
    group_by = serializers.ChoiceField(
        choices=["day", "week", "month"],
        default="day",
        required=False,
    )
    category = serializers.IntegerField(required=False, allow_null=True)
    
    def validate(self, attrs):
        if attrs["start_date"] > attrs["end_date"]:
            raise serializers.ValidationError({
                "end_date": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        return attrs


class KPIReportSerializer(serializers.Serializer):
    """KPI metrics serializer (RevPAR, ADR, etc.)."""
    
    period_start = serializers.DateField()
    period_end = serializers.DateField()
    
    # Key metrics
    revpar = serializers.DecimalField(max_digits=15, decimal_places=0, help_text="Revenue Per Available Room")
    adr = serializers.DecimalField(max_digits=15, decimal_places=0, help_text="Average Daily Rate")
    occupancy_rate = serializers.DecimalField(max_digits=5, decimal_places=2, help_text="Occupancy percentage")
    
    # Totals
    total_room_nights_available = serializers.IntegerField()
    total_room_nights_sold = serializers.IntegerField()
    total_room_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    total_expenses = serializers.DecimalField(max_digits=15, decimal_places=0)
    net_profit = serializers.DecimalField(max_digits=15, decimal_places=0)
    
    # Comparisons (vs previous period)
    revpar_change = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    adr_change = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    occupancy_change = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    revenue_change = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)


class KPIReportRequestSerializer(serializers.Serializer):
    """Request parameters for KPI report."""
    
    start_date = serializers.DateField(required=True)
    end_date = serializers.DateField(required=True)
    compare_previous = serializers.BooleanField(default=True, required=False)
    
    def validate(self, attrs):
        if attrs["start_date"] > attrs["end_date"]:
            raise serializers.ValidationError({
                "end_date": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        return attrs


class ExpenseReportSerializer(serializers.Serializer):
    """Expense report by category."""
    
    category_id = serializers.IntegerField()
    category_name = serializers.CharField()
    category_icon = serializers.CharField()
    category_color = serializers.CharField()
    total_amount = serializers.DecimalField(max_digits=15, decimal_places=0)
    transaction_count = serializers.IntegerField()
    percentage = serializers.DecimalField(max_digits=5, decimal_places=2)


class ExpenseReportRequestSerializer(serializers.Serializer):
    """Request parameters for expense report."""
    
    start_date = serializers.DateField(required=True)
    end_date = serializers.DateField(required=True)
    
    def validate(self, attrs):
        if attrs["start_date"] > attrs["end_date"]:
            raise serializers.ValidationError({
                "end_date": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        return attrs


class ChannelPerformanceSerializer(serializers.Serializer):
    """Channel (booking source) performance data."""
    
    source = serializers.CharField()
    source_display = serializers.CharField()
    booking_count = serializers.IntegerField()
    total_nights = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    average_rate = serializers.DecimalField(max_digits=15, decimal_places=0)
    cancellation_count = serializers.IntegerField()
    cancellation_rate = serializers.DecimalField(max_digits=5, decimal_places=2)
    percentage_of_revenue = serializers.DecimalField(max_digits=5, decimal_places=2)


class ChannelPerformanceRequestSerializer(serializers.Serializer):
    """Request parameters for channel performance report."""
    
    start_date = serializers.DateField(required=True)
    end_date = serializers.DateField(required=True)
    
    def validate(self, attrs):
        if attrs["start_date"] > attrs["end_date"]:
            raise serializers.ValidationError({
                "end_date": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        return attrs


class GuestDemographicsSerializer(serializers.Serializer):
    """Guest demographics data."""
    
    nationality = serializers.CharField()
    guest_count = serializers.IntegerField()
    booking_count = serializers.IntegerField()
    total_nights = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=0)
    percentage = serializers.DecimalField(max_digits=5, decimal_places=2)
    average_stay = serializers.DecimalField(max_digits=5, decimal_places=2)


class GuestDemographicsRequestSerializer(serializers.Serializer):
    """Request parameters for guest demographics report."""
    
    start_date = serializers.DateField(required=True)
    end_date = serializers.DateField(required=True)
    group_by = serializers.ChoiceField(
        choices=["nationality", "source", "room_type"],
        default="nationality",
        required=False,
    )
    
    def validate(self, attrs):
        if attrs["start_date"] > attrs["end_date"]:
            raise serializers.ValidationError({
                "end_date": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        return attrs


class ComparativeReportSerializer(serializers.Serializer):
    """Comparative report (period over period)."""
    
    metric = serializers.CharField()
    current_period_value = serializers.DecimalField(max_digits=15, decimal_places=2)
    previous_period_value = serializers.DecimalField(max_digits=15, decimal_places=2, allow_null=True)
    change_amount = serializers.DecimalField(max_digits=15, decimal_places=2, allow_null=True)
    change_percentage = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)


class ComparativeReportRequestSerializer(serializers.Serializer):
    """Request parameters for comparative report."""
    
    current_start = serializers.DateField(required=True)
    current_end = serializers.DateField(required=True)
    previous_start = serializers.DateField(required=False, allow_null=True)
    previous_end = serializers.DateField(required=False, allow_null=True)
    comparison_type = serializers.ChoiceField(
        choices=["previous_period", "previous_year", "custom"],
        default="previous_period",
        required=False,
    )
    
    def validate(self, attrs):
        if attrs["current_start"] > attrs["current_end"]:
            raise serializers.ValidationError({
                "current_end": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        if attrs.get("comparison_type") == "custom":
            if not attrs.get("previous_start") or not attrs.get("previous_end"):
                raise serializers.ValidationError({
                    "previous_start": "Phải cung cấp khoảng thời gian trước khi so sánh custom."
                })
        return attrs


class ExportReportRequestSerializer(serializers.Serializer):
    """Request parameters for report export."""
    
    report_type = serializers.ChoiceField(
        choices=["occupancy", "revenue", "expenses", "kpi", "channels", "demographics"],
        required=True,
    )
    start_date = serializers.DateField(required=True)
    end_date = serializers.DateField(required=True)
    format = serializers.ChoiceField(
        choices=["xlsx", "csv"],
        default="xlsx",
        required=False,
    )
    
    def validate(self, attrs):
        if attrs["start_date"] > attrs["end_date"]:
            raise serializers.ValidationError({
                "end_date": "Ngày kết thúc phải sau ngày bắt đầu."
            })
        return attrs


# ============================================================
# Lost & Found Serializers (Phase 3)
# ============================================================


class LostAndFoundSerializer(serializers.ModelSerializer):
    """Full serializer for Lost & Found items."""

    status_display = serializers.CharField(source="get_status_display", read_only=True)
    category_display = serializers.CharField(source="get_category_display", read_only=True)
    room_number = serializers.SerializerMethodField()
    guest_name = serializers.SerializerMethodField()
    found_by_name = serializers.SerializerMethodField()
    claimed_by_staff_name = serializers.SerializerMethodField()

    class Meta:
        model = LostAndFound
        fields = [
            "id",
            "item_name",
            "description",
            "category",
            "category_display",
            "estimated_value",
            # Location
            "room",
            "room_number",
            "found_location",
            "storage_location",
            # Guest association
            "guest",
            "guest_name",
            "booking",
            # Status
            "status",
            "status_display",
            "found_date",
            "claimed_date",
            "disposed_date",
            # Staff
            "found_by",
            "found_by_name",
            "claimed_by_staff",
            "claimed_by_staff_name",
            # Contact
            "guest_contacted",
            "contact_notes",
            # Image
            "image",
            # Notes
            "notes",
            # Audit
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "claimed_date",
            "disposed_date",
            "claimed_by_staff",
            "created_at",
            "updated_at",
        ]

    @extend_schema_field(serializers.CharField)
    def get_room_number(self, obj):
        return obj.room.number if obj.room else None

    @extend_schema_field(serializers.CharField)
    def get_guest_name(self, obj):
        return obj.guest.full_name if obj.guest else None

    @extend_schema_field(serializers.CharField)
    def get_found_by_name(self, obj):
        if obj.found_by:
            return obj.found_by.get_full_name() or obj.found_by.username
        return None

    @extend_schema_field(serializers.CharField)
    def get_claimed_by_staff_name(self, obj):
        if obj.claimed_by_staff:
            return obj.claimed_by_staff.get_full_name() or obj.claimed_by_staff.username
        return None


class LostAndFoundListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing Lost & Found items."""

    status_display = serializers.CharField(source="get_status_display", read_only=True)
    category_display = serializers.CharField(source="get_category_display", read_only=True)
    room_number = serializers.SerializerMethodField()
    guest_name = serializers.SerializerMethodField()

    class Meta:
        model = LostAndFound
        fields = [
            "id",
            "item_name",
            "category",
            "category_display",
            "status",
            "status_display",
            "room",
            "room_number",
            "guest",
            "guest_name",
            "found_date",
            "estimated_value",
            "image",
        ]

    @extend_schema_field(serializers.CharField)
    def get_room_number(self, obj):
        return obj.room.number if obj.room else None

    @extend_schema_field(serializers.CharField)
    def get_guest_name(self, obj):
        return obj.guest.full_name if obj.guest else None


class LostAndFoundCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Lost & Found items."""

    class Meta:
        model = LostAndFound
        fields = [
            "item_name",
            "description",
            "category",
            "estimated_value",
            "room",
            "found_location",
            "storage_location",
            "guest",
            "booking",
            "found_date",
            "found_by",
            "guest_contacted",
            "contact_notes",
            "image",
            "notes",
        ]

    def create(self, validated_data):
        # Set initial status
        validated_data["status"] = LostAndFound.Status.FOUND
        return super().create(validated_data)


class LostAndFoundUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating Lost & Found items."""

    class Meta:
        model = LostAndFound
        fields = [
            "item_name",
            "description",
            "category",
            "estimated_value",
            "room",
            "found_location",
            "storage_location",
            "guest",
            "booking",
            "status",
            "guest_contacted",
            "contact_notes",
            "image",
            "notes",
        ]


class LostAndFoundClaimSerializer(serializers.Serializer):
    """Serializer for claiming a lost item."""

    notes = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        item = self.context.get("item")
        if item and item.status == LostAndFound.Status.CLAIMED:
            raise serializers.ValidationError("Vật phẩm này đã được trả cho khách.")
        if item and item.status in [LostAndFound.Status.DISPOSED, LostAndFound.Status.DONATED]:
            raise serializers.ValidationError("Vật phẩm này đã được xử lý.")
        return attrs


class LostAndFoundDisposeSerializer(serializers.Serializer):
    """Serializer for disposing a lost item."""

    method = serializers.ChoiceField(
        choices=["disposed", "donated"],
        default="disposed",
    )

    def validate(self, attrs):
        item = self.context.get("item")
        if item and item.status == LostAndFound.Status.CLAIMED:
            raise serializers.ValidationError("Không thể xử lý vật phẩm đã trả cho khách.")
        if item and item.status in [LostAndFound.Status.DISPOSED, LostAndFound.Status.DONATED]:
            raise serializers.ValidationError("Vật phẩm này đã được xử lý.")
        return attrs


# ============================================================
# Group Booking Serializers (Phase 3)
# ============================================================


class GroupBookingSerializer(serializers.ModelSerializer):
    """Full serializer for Group Booking."""

    status_display = serializers.CharField(source="get_status_display", read_only=True)
    source_display = serializers.CharField(source="get_source_display", read_only=True)
    created_by_name = serializers.SerializerMethodField()
    room_numbers = serializers.SerializerMethodField()
    nights = serializers.IntegerField(read_only=True)
    balance_due = serializers.DecimalField(max_digits=12, decimal_places=0, read_only=True)

    class Meta:
        model = GroupBooking
        fields = [
            "id",
            "name",
            "contact_name",
            "contact_phone",
            "contact_email",
            "company",
            # Dates
            "check_in_date",
            "check_out_date",
            "actual_check_in",
            "actual_check_out",
            "nights",
            # Room allocation
            "room_count",
            "guest_count",
            "rooms",
            "room_numbers",
            # Pricing
            "total_amount",
            "deposit_amount",
            "deposit_paid",
            "special_rate",
            "discount_percent",
            "currency",
            "balance_due",
            # Status
            "status",
            "status_display",
            "source",
            "source_display",
            # Notes
            "notes",
            "special_requests",
            # Audit
            "created_by",
            "created_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "actual_check_in",
            "actual_check_out",
            "created_by",
            "created_at",
            "updated_at",
        ]

    @extend_schema_field(serializers.CharField)
    def get_created_by_name(self, obj):
        if obj.created_by:
            return obj.created_by.get_full_name() or obj.created_by.username
        return None

    @extend_schema_field(serializers.ListField)
    def get_room_numbers(self, obj):
        return list(obj.rooms.values_list("number", flat=True))


class GroupBookingListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing Group Bookings."""

    status_display = serializers.CharField(source="get_status_display", read_only=True)
    nights = serializers.IntegerField(read_only=True)
    balance_due = serializers.DecimalField(max_digits=12, decimal_places=0, read_only=True)

    class Meta:
        model = GroupBooking
        fields = [
            "id",
            "name",
            "contact_name",
            "contact_phone",
            "company",
            "check_in_date",
            "check_out_date",
            "nights",
            "room_count",
            "guest_count",
            "total_amount",
            "deposit_paid",
            "balance_due",
            "status",
            "status_display",
        ]


class GroupBookingCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Group Bookings."""

    class Meta:
        model = GroupBooking
        fields = [
            "name",
            "contact_name",
            "contact_phone",
            "contact_email",
            "company",
            "check_in_date",
            "check_out_date",
            "room_count",
            "guest_count",
            "rooms",
            "total_amount",
            "deposit_amount",
            "deposit_paid",
            "special_rate",
            "discount_percent",
            "currency",
            "source",
            "notes",
            "special_requests",
        ]

    def validate(self, attrs):
        if attrs["check_in_date"] >= attrs["check_out_date"]:
            raise serializers.ValidationError({
                "check_out_date": "Ngày trả phòng phải sau ngày nhận phòng."
            })
        return attrs

    def create(self, validated_data):
        # Set created_by from request
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


class GroupBookingUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating Group Bookings."""

    class Meta:
        model = GroupBooking
        fields = [
            "name",
            "contact_name",
            "contact_phone",
            "contact_email",
            "company",
            "check_in_date",
            "check_out_date",
            "room_count",
            "guest_count",
            "rooms",
            "total_amount",
            "deposit_amount",
            "deposit_paid",
            "special_rate",
            "discount_percent",
            "status",
            "notes",
            "special_requests",
        ]

    def validate(self, attrs):
        check_in = attrs.get("check_in_date", self.instance.check_in_date)
        check_out = attrs.get("check_out_date", self.instance.check_out_date)
        if check_in >= check_out:
            raise serializers.ValidationError({
                "check_out_date": "Ngày trả phòng phải sau ngày nhận phòng."
            })
        return attrs


# ==============================================================================
# Room Inspection Serializers
# ==============================================================================


class InspectionTemplateSerializer(serializers.ModelSerializer):
    """Full serializer for Inspection Templates."""

    inspection_type_display = serializers.CharField(
        source="get_inspection_type_display", read_only=True
    )
    room_type_name = serializers.CharField(
        source="room_type.name", read_only=True, allow_null=True
    )
    item_count = serializers.SerializerMethodField()
    created_by_name = serializers.CharField(
        source="created_by.get_full_name", read_only=True, allow_null=True
    )

    class Meta:
        model = InspectionTemplate
        fields = [
            "id",
            "name",
            "inspection_type",
            "inspection_type_display",
            "room_type",
            "room_type_name",
            "is_default",
            "is_active",
            "items",
            "item_count",
            "created_by",
            "created_by_name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    @extend_schema_field(serializers.IntegerField())
    def get_item_count(self, obj):
        return len(obj.items) if obj.items else 0


class InspectionTemplateListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for template lists."""

    inspection_type_display = serializers.CharField(
        source="get_inspection_type_display", read_only=True
    )
    room_type_name = serializers.CharField(
        source="room_type.name", read_only=True, allow_null=True
    )
    item_count = serializers.SerializerMethodField()

    class Meta:
        model = InspectionTemplate
        fields = [
            "id",
            "name",
            "inspection_type",
            "inspection_type_display",
            "room_type",
            "room_type_name",
            "is_default",
            "is_active",
            "item_count",
        ]

    @extend_schema_field(serializers.IntegerField())
    def get_item_count(self, obj):
        return len(obj.items) if obj.items else 0


class InspectionTemplateCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Inspection Templates."""

    class Meta:
        model = InspectionTemplate
        fields = [
            "name",
            "inspection_type",
            "room_type",
            "is_default",
            "is_active",
            "items",
        ]

    def validate_items(self, value):
        """Validate checklist items format."""
        if not isinstance(value, list):
            raise serializers.ValidationError("Danh sách mục phải là một array.")

        for idx, item in enumerate(value):
            if not isinstance(item, dict):
                raise serializers.ValidationError(f"Mục {idx + 1} phải là một object.")
            if "item" not in item:
                raise serializers.ValidationError(f"Mục {idx + 1} phải có trường 'item'.")
            if "category" not in item:
                raise serializers.ValidationError(f"Mục {idx + 1} phải có trường 'category'.")

        return value

    def create(self, validated_data):
        validated_data["created_by"] = self.context["request"].user
        return super().create(validated_data)


class RoomInspectionSerializer(serializers.ModelSerializer):
    """Full serializer for Room Inspections."""

    room_number = serializers.CharField(source="room.number", read_only=True)
    room_type_name = serializers.CharField(
        source="room.room_type.name", read_only=True
    )
    inspection_type_display = serializers.CharField(
        source="get_inspection_type_display", read_only=True
    )
    status_display = serializers.CharField(
        source="get_status_display", read_only=True
    )
    inspector_name = serializers.CharField(
        source="inspector.get_full_name", read_only=True, allow_null=True
    )
    booking_info = serializers.SerializerMethodField()

    class Meta:
        model = RoomInspection
        fields = [
            "id",
            "room",
            "room_number",
            "room_type_name",
            "booking",
            "booking_info",
            "inspection_type",
            "inspection_type_display",
            "scheduled_date",
            "completed_at",
            "inspector",
            "inspector_name",
            "status",
            "status_display",
            "checklist_items",
            "total_items",
            "passed_items",
            "score",
            "issues_found",
            "critical_issues",
            "images",
            "notes",
            "action_required",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "total_items",
            "passed_items",
            "score",
            "issues_found",
            "critical_issues",
            "created_at",
            "updated_at",
        ]

    @extend_schema_field(serializers.DictField())
    def get_booking_info(self, obj):
        if not obj.booking:
            return None
        return {
            "id": obj.booking.id,
            "guest_name": obj.booking.guest.full_name if obj.booking.guest else None,
            "check_in_date": obj.booking.check_in_date,
            "check_out_date": obj.booking.check_out_date,
        }


class RoomInspectionListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for inspection lists."""

    room_number = serializers.CharField(source="room.number", read_only=True)
    inspection_type_display = serializers.CharField(
        source="get_inspection_type_display", read_only=True
    )
    status_display = serializers.CharField(
        source="get_status_display", read_only=True
    )
    inspector_name = serializers.CharField(
        source="inspector.get_full_name", read_only=True, allow_null=True
    )

    class Meta:
        model = RoomInspection
        fields = [
            "id",
            "room",
            "room_number",
            "inspection_type",
            "inspection_type_display",
            "scheduled_date",
            "completed_at",
            "inspector_name",
            "status",
            "status_display",
            "score",
            "issues_found",
            "critical_issues",
        ]


class RoomInspectionCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating Room Inspections."""

    template_id = serializers.IntegerField(required=False, write_only=True)

    class Meta:
        model = RoomInspection
        fields = [
            "room",
            "booking",
            "inspection_type",
            "scheduled_date",
            "inspector",
            "checklist_items",
            "notes",
            "template_id",
        ]

    def create(self, validated_data):
        template_id = validated_data.pop("template_id", None)

        # If template provided, copy checklist items from template
        if template_id:
            try:
                template = InspectionTemplate.objects.get(id=template_id, is_active=True)
                # Convert template items to inspection checklist format
                validated_data["checklist_items"] = [
                    {
                        "category": item.get("category", ""),
                        "item": item.get("item", ""),
                        "critical": item.get("critical", False),
                        "passed": None,  # Not yet inspected
                        "notes": "",
                    }
                    for item in template.items
                ]
            except InspectionTemplate.DoesNotExist:
                pass

        return super().create(validated_data)


class RoomInspectionUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating Room Inspections."""

    class Meta:
        model = RoomInspection
        fields = [
            "scheduled_date",
            "inspector",
            "status",
            "checklist_items",
            "images",
            "notes",
            "action_required",
        ]


class RoomInspectionCompleteSerializer(serializers.Serializer):
    """Serializer for completing a room inspection."""

    checklist_items = serializers.ListField(
        child=serializers.DictField(),
        required=True,
    )
    images = serializers.ListField(
        child=serializers.URLField(),
        required=False,
        default=list,
    )
    notes = serializers.CharField(required=False, allow_blank=True, default="")
    action_required = serializers.CharField(required=False, allow_blank=True, default="")

    def validate_checklist_items(self, value):
        """Validate that all items have been inspected."""
        for idx, item in enumerate(value):
            if item.get("passed") is None:
                raise serializers.ValidationError(
                    f"Mục '{item.get('item', idx + 1)}' chưa được kiểm tra."
                )
        return value


class RoomInspectionStatisticsSerializer(serializers.Serializer):
    """Serializer for inspection statistics."""

    total_inspections = serializers.IntegerField()
    completed_inspections = serializers.IntegerField()
    pending_inspections = serializers.IntegerField()
    requires_action = serializers.IntegerField()
    average_score = serializers.DecimalField(max_digits=5, decimal_places=2)
    total_issues = serializers.IntegerField()
    critical_issues = serializers.IntegerField()
    inspections_by_type = serializers.DictField()
    inspections_by_room = serializers.ListField()


# ============================================================
# RatePlan Serializers
# ============================================================


class RatePlanSerializer(serializers.ModelSerializer):
    """Full serializer for RatePlan with all details."""

    room_type_name = serializers.CharField(source="room_type.name", read_only=True)
    cancellation_policy_display = serializers.CharField(
        source="get_cancellation_policy_display", read_only=True
    )

    class Meta:
        model = RatePlan
        fields = [
            "id",
            "name",
            "name_en",
            "room_type",
            "room_type_name",
            "base_rate",
            "is_active",
            "min_stay",
            "max_stay",
            "advance_booking_days",
            "cancellation_policy",
            "cancellation_policy_display",
            "valid_from",
            "valid_to",
            "blackout_dates",
            "channels",
            "description",
            "includes_breakfast",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class RatePlanListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for RatePlan listings."""

    room_type_name = serializers.CharField(source="room_type.name", read_only=True)

    class Meta:
        model = RatePlan
        fields = [
            "id",
            "name",
            "room_type",
            "room_type_name",
            "base_rate",
            "is_active",
            "min_stay",
            "valid_from",
            "valid_to",
            "includes_breakfast",
        ]


class RatePlanCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating RatePlan."""

    class Meta:
        model = RatePlan
        fields = [
            "name",
            "name_en",
            "room_type",
            "base_rate",
            "is_active",
            "min_stay",
            "max_stay",
            "advance_booking_days",
            "cancellation_policy",
            "valid_from",
            "valid_to",
            "blackout_dates",
            "channels",
            "description",
            "includes_breakfast",
        ]

    def validate(self, attrs):
        """Validate date range."""
        valid_from = attrs.get("valid_from")
        valid_to = attrs.get("valid_to")
        if valid_from and valid_to and valid_from > valid_to:
            raise serializers.ValidationError(
                {"valid_to": "Ngày kết thúc phải sau ngày bắt đầu."}
            )
        return attrs


class RatePlanUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating RatePlan."""

    class Meta:
        model = RatePlan
        fields = [
            "name",
            "name_en",
            "base_rate",
            "is_active",
            "min_stay",
            "max_stay",
            "advance_booking_days",
            "cancellation_policy",
            "valid_from",
            "valid_to",
            "blackout_dates",
            "channels",
            "description",
            "includes_breakfast",
        ]

    def validate(self, attrs):
        """Validate date range."""
        valid_from = attrs.get("valid_from", self.instance.valid_from if self.instance else None)
        valid_to = attrs.get("valid_to", self.instance.valid_to if self.instance else None)
        if valid_from and valid_to and valid_from > valid_to:
            raise serializers.ValidationError(
                {"valid_to": "Ngày kết thúc phải sau ngày bắt đầu."}
            )
        return attrs


# ============================================================
# DateRateOverride Serializers
# ============================================================


class DateRateOverrideSerializer(serializers.ModelSerializer):
    """Full serializer for DateRateOverride with all details."""

    room_type_name = serializers.CharField(source="room_type.name", read_only=True)

    class Meta:
        model = DateRateOverride
        fields = [
            "id",
            "room_type",
            "room_type_name",
            "date",
            "rate",
            "reason",
            "closed_to_arrival",
            "closed_to_departure",
            "min_stay",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class DateRateOverrideListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for DateRateOverride listings."""

    room_type_name = serializers.CharField(source="room_type.name", read_only=True)

    class Meta:
        model = DateRateOverride
        fields = [
            "id",
            "room_type",
            "room_type_name",
            "date",
            "rate",
            "reason",
            "closed_to_arrival",
            "closed_to_departure",
        ]


class DateRateOverrideCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating DateRateOverride."""

    class Meta:
        model = DateRateOverride
        fields = [
            "room_type",
            "date",
            "rate",
            "reason",
            "closed_to_arrival",
            "closed_to_departure",
            "min_stay",
        ]


class DateRateOverrideUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating DateRateOverride."""

    class Meta:
        model = DateRateOverride
        fields = [
            "rate",
            "reason",
            "closed_to_arrival",
            "closed_to_departure",
            "min_stay",
        ]


class DateRateOverrideBulkCreateSerializer(serializers.Serializer):
    """Serializer for bulk creating DateRateOverride for a date range."""

    room_type = serializers.PrimaryKeyRelatedField(queryset=RoomType.objects.all())
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    rate = serializers.DecimalField(max_digits=12, decimal_places=0)
    reason = serializers.CharField(max_length=100, required=False, allow_blank=True, default="")
    closed_to_arrival = serializers.BooleanField(required=False, default=False)
    closed_to_departure = serializers.BooleanField(required=False, default=False)
    min_stay = serializers.IntegerField(required=False, min_value=1, allow_null=True, default=None)

    def validate(self, attrs):
        """Validate date range."""
        start_date = attrs.get("start_date")
        end_date = attrs.get("end_date")
        if start_date > end_date:
            raise serializers.ValidationError(
                {"end_date": "Ngày kết thúc phải sau ngày bắt đầu."}
            )
        return attrs


# ===== Phase 5: Notification Serializers =====


class NotificationSerializer(serializers.ModelSerializer):
    """Full notification serializer."""

    notification_type_display = serializers.CharField(
        source="get_notification_type_display", read_only=True
    )

    class Meta:
        model = Notification
        fields = [
            "id",
            "notification_type",
            "notification_type_display",
            "title",
            "body",
            "data",
            "booking",
            "is_read",
            "read_at",
            "is_sent",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "notification_type",
            "title",
            "body",
            "data",
            "booking",
            "is_sent",
            "created_at",
        ]


class NotificationListSerializer(serializers.ModelSerializer):
    """Lightweight notification serializer for listing."""

    notification_type_display = serializers.CharField(
        source="get_notification_type_display", read_only=True
    )

    class Meta:
        model = Notification
        fields = [
            "id",
            "notification_type",
            "notification_type_display",
            "title",
            "body",
            "is_read",
            "created_at",
        ]


class DeviceTokenSerializer(serializers.ModelSerializer):
    """Serializer for device token registration."""

    class Meta:
        model = DeviceToken
        fields = ["id", "token", "platform", "device_name"]
        read_only_fields = ["id"]

    def create(self, validated_data):
        user = self.context["request"].user
        token = validated_data["token"]

        # Upsert: reassign token if it exists for another user
        device, created = DeviceToken.objects.update_or_create(
            token=token,
            defaults={
                "user": user,
                "platform": validated_data.get("platform", DeviceToken.Platform.ANDROID),
                "device_name": validated_data.get("device_name", ""),
                "is_active": True,
            },
        )
        return device


class NotificationPreferencesSerializer(serializers.Serializer):
    """Serializer for notification preferences."""

    receive_notifications = serializers.BooleanField()


# ===== Phase 5.3: Guest Messaging Serializers =====


class MessageTemplateSerializer(serializers.ModelSerializer):
    """Full message template serializer."""

    template_type_display = serializers.CharField(
        source="get_template_type_display", read_only=True
    )
    channel_display = serializers.CharField(
        source="get_channel_display", read_only=True
    )
    available_variables = serializers.SerializerMethodField()

    class Meta:
        model = MessageTemplate
        fields = [
            "id",
            "name",
            "template_type",
            "template_type_display",
            "subject",
            "body",
            "channel",
            "channel_display",
            "is_active",
            "available_variables",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_available_variables(self, obj):
        return MessageTemplate.AVAILABLE_VARIABLES


class MessageTemplateListSerializer(serializers.ModelSerializer):
    """Lightweight message template serializer for listing."""

    template_type_display = serializers.CharField(
        source="get_template_type_display", read_only=True
    )
    channel_display = serializers.CharField(
        source="get_channel_display", read_only=True
    )

    class Meta:
        model = MessageTemplate
        fields = [
            "id",
            "name",
            "template_type",
            "template_type_display",
            "channel",
            "channel_display",
            "is_active",
        ]


class GuestMessageSerializer(serializers.ModelSerializer):
    """Full guest message serializer."""

    guest_name = serializers.CharField(source="guest.full_name", read_only=True)
    booking_display = serializers.SerializerMethodField()
    template_name = serializers.CharField(
        source="template.name", read_only=True, default=None
    )
    channel_display = serializers.CharField(
        source="get_channel_display", read_only=True
    )
    status_display = serializers.CharField(
        source="get_status_display", read_only=True
    )
    sent_by_name = serializers.CharField(
        source="sent_by.get_full_name", read_only=True, default=None
    )

    class Meta:
        model = GuestMessage
        fields = [
            "id",
            "guest",
            "guest_name",
            "booking",
            "booking_display",
            "template",
            "template_name",
            "channel",
            "channel_display",
            "subject",
            "body",
            "recipient_address",
            "status",
            "status_display",
            "sent_at",
            "send_error",
            "sent_by",
            "sent_by_name",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "status",
            "sent_at",
            "send_error",
            "sent_by",
            "recipient_address",
            "created_at",
        ]

    def get_booking_display(self, obj):
        if obj.booking:
            return f"#{obj.booking.id} - {obj.booking.room.number if obj.booking.room else 'N/A'}"
        return None


class GuestMessageListSerializer(serializers.ModelSerializer):
    """Lightweight guest message serializer for listing."""

    guest_name = serializers.CharField(source="guest.full_name", read_only=True)
    channel_display = serializers.CharField(
        source="get_channel_display", read_only=True
    )
    status_display = serializers.CharField(
        source="get_status_display", read_only=True
    )

    class Meta:
        model = GuestMessage
        fields = [
            "id",
            "guest",
            "guest_name",
            "booking",
            "channel",
            "channel_display",
            "subject",
            "status",
            "status_display",
            "sent_at",
            "created_at",
        ]


class SendMessageSerializer(serializers.Serializer):
    """Serializer for sending a guest message."""

    guest = serializers.IntegerField()
    booking = serializers.IntegerField(required=False, allow_null=True)
    template = serializers.IntegerField(required=False, allow_null=True)
    channel = serializers.ChoiceField(choices=MessageTemplate.Channel.choices)
    subject = serializers.CharField(max_length=200)
    body = serializers.CharField()


class PreviewMessageSerializer(serializers.Serializer):
    """Serializer for previewing a rendered message template."""

    template = serializers.IntegerField()
    guest = serializers.IntegerField()
    booking = serializers.IntegerField(required=False, allow_null=True)


