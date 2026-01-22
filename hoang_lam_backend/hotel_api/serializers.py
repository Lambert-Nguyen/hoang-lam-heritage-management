"""
Serializers for API endpoints.
"""

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import HotelUser, Room, RoomType


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
