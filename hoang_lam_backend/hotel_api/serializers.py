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

from .models import Booking, FinancialCategory, FinancialEntry, Guest, HotelUser, NightAudit, Room, RoomType


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
    notes = serializers.CharField(required=False, allow_blank=True)

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
    nights = serializers.ReadOnlyField()
    balance_due = serializers.ReadOnlyField()

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
            "nightly_rate",
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
