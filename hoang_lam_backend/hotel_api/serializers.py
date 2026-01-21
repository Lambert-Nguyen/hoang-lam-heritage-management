"""
Serializers for authentication endpoints.
"""

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import HotelUser


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
