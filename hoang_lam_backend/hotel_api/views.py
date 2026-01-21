"""
Views for authentication endpoints.
"""

from django.contrib.auth import get_user_model
from drf_spectacular.utils import OpenApiResponse, extend_schema, extend_schema_view
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import LoginSerializer, PasswordChangeSerializer, UserProfileSerializer

User = get_user_model()


@extend_schema_view(
    post=extend_schema(
        summary="User login",
        description="Authenticate user and return JWT access and refresh tokens.",
        request=LoginSerializer,
        responses={
            200: OpenApiResponse(
                description="Login successful",
                response={
                    "type": "object",
                    "properties": {
                        "access": {"type": "string", "description": "JWT access token"},
                        "refresh": {"type": "string", "description": "JWT refresh token"},
                        "user": {"$ref": "#/components/schemas/UserProfile"},
                    },
                },
            ),
            400: OpenApiResponse(description="Invalid credentials"),
        },
        tags=["Authentication"],
    )
)
class LoginView(APIView):
    """User login endpoint."""

    permission_classes = []
    authentication_classes = []

    def post(self, request):
        """Login with username and password."""
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data["user"]

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)

        # Get user profile data with related HotelUser
        user_with_profile = User.objects.select_related("hotel_profile").get(pk=user.pk)
        user_serializer = UserProfileSerializer(user_with_profile)

        return Response(
            {
                "access": str(refresh.access_token),
                "refresh": str(refresh),
                "user": user_serializer.data,
            },
            status=status.HTTP_200_OK,
        )


@extend_schema_view(
    post=extend_schema(
        summary="Logout",
        description="Blacklist the refresh token to logout the user.",
        request={
            "type": "object",
            "properties": {"refresh": {"type": "string", "description": "JWT refresh token"}},
            "required": ["refresh"],
        },
        responses={
            200: OpenApiResponse(description="Logout successful"),
            400: OpenApiResponse(description="Invalid token"),
        },
        tags=["Authentication"],
    )
)
class LogoutView(APIView):
    """User logout endpoint."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Blacklist the refresh token."""
        try:
            refresh_token = request.data.get("refresh")
            if not refresh_token:
                return Response(
                    {"detail": "Refresh token is required."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            token = RefreshToken(refresh_token)
            token.blacklist()

            return Response({"detail": "Đăng xuất thành công."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)


@extend_schema_view(
    get=extend_schema(
        summary="Get user profile",
        description="Retrieve the authenticated user's profile information.",
        responses={
            200: UserProfileSerializer,
            401: OpenApiResponse(description="Unauthorized"),
        },
        tags=["Authentication"],
    )
)
class UserProfileView(APIView):
    """User profile endpoint."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Get authenticated user's profile."""
        # Use select_related to avoid N+1 queries
        user = User.objects.select_related("hotel_profile").get(pk=request.user.pk)
        serializer = UserProfileSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)


@extend_schema_view(
    post=extend_schema(
        summary="Change password",
        description="Change the authenticated user's password.",
        request=PasswordChangeSerializer,
        responses={
            200: OpenApiResponse(description="Password changed successfully"),
            400: OpenApiResponse(description="Validation error"),
            401: OpenApiResponse(description="Unauthorized"),
        },
        tags=["Authentication"],
    )
)
class PasswordChangeView(APIView):
    """Password change endpoint."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        """Change user's password."""
        serializer = PasswordChangeSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(
            {"detail": "Mật khẩu đã được thay đổi thành công."}, status=status.HTTP_200_OK
        )
