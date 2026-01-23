"""
Serializers for API endpoints.
"""

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import Booking, Guest, HotelUser, Room, RoomType


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
