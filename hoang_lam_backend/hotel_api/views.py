"""
Views for API endpoints.
"""

from django.contrib.auth import get_user_model
from django.db.models import Q
from drf_spectacular.utils import OpenApiParameter, OpenApiResponse, extend_schema, extend_schema_view
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Room, RoomType
from .permissions import IsManager, IsStaff
from .serializers import (
    LoginSerializer,
    PasswordChangeSerializer,
    RoomAvailabilitySerializer,
    RoomListSerializer,
    RoomSerializer,
    RoomStatusUpdateSerializer,
    RoomTypeListSerializer,
    RoomTypeSerializer,
    UserProfileSerializer,
)

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


# ==================== Room Management Views ====================


@extend_schema_view(
    list=extend_schema(
        summary="List room types",
        description="Get list of all room types with room counts.",
        parameters=[
            OpenApiParameter(
                name="is_active",
                type=bool,
                description="Filter by active status",
                required=False,
            ),
        ],
        responses={200: RoomTypeListSerializer(many=True)},
        tags=["Room Management"],
    ),
    retrieve=extend_schema(
        summary="Get room type details",
        description="Get detailed information about a specific room type.",
        responses={200: RoomTypeSerializer},
        tags=["Room Management"],
    ),
    create=extend_schema(
        summary="Create room type",
        description="Create a new room type. Requires manager role.",
        request=RoomTypeSerializer,
        responses={201: RoomTypeSerializer},
        tags=["Room Management"],
    ),
    update=extend_schema(
        summary="Update room type",
        description="Update room type details. Requires manager role.",
        request=RoomTypeSerializer,
        responses={200: RoomTypeSerializer},
        tags=["Room Management"],
    ),
    partial_update=extend_schema(
        summary="Partially update room type",
        description="Partially update room type details. Requires manager role.",
        request=RoomTypeSerializer,
        responses={200: RoomTypeSerializer},
        tags=["Room Management"],
    ),
    destroy=extend_schema(
        summary="Delete room type",
        description="Delete a room type. Requires manager role. Cannot delete if rooms exist.",
        responses={204: None, 400: OpenApiResponse(description="Cannot delete - rooms exist")},
        tags=["Room Management"],
    ),
)
class RoomTypeViewSet(viewsets.ModelViewSet):
    """ViewSet for RoomType CRUD operations."""

    queryset = RoomType.objects.all()
    permission_classes = [IsAuthenticated, IsStaff]

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "list":
            return RoomTypeListSerializer
        return RoomTypeSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsManager()]
        return [IsAuthenticated(), IsStaff()]

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = super().get_queryset()

        # Filter by active status
        is_active = self.request.query_params.get("is_active")
        if is_active is not None:
            is_active_bool = is_active.lower() in ["true", "1", "yes"]
            queryset = queryset.filter(is_active=is_active_bool)

        return queryset.prefetch_related("rooms")

    def destroy(self, request, *args, **kwargs):
        """Delete room type, but prevent if rooms exist."""
        instance = self.get_object()

        # Check if any rooms exist for this type
        if instance.rooms.exists():
            return Response(
                {"detail": "Không thể xóa loại phòng đã có phòng. Hãy xóa hoặc chuyển phòng trước."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return super().destroy(request, *args, **kwargs)


@extend_schema_view(
    list=extend_schema(
        summary="List rooms",
        description="Get list of all rooms with filtering options.",
        parameters=[
            OpenApiParameter(name="status", type=str, description="Filter by status", required=False),
            OpenApiParameter(
                name="room_type", type=int, description="Filter by room type ID", required=False
            ),
            OpenApiParameter(name="floor", type=int, description="Filter by floor", required=False),
            OpenApiParameter(name="is_active", type=bool, description="Filter by active status", required=False),
            OpenApiParameter(name="search", type=str, description="Search by room number or name", required=False),
        ],
        responses={200: RoomListSerializer(many=True)},
        tags=["Room Management"],
    ),
    retrieve=extend_schema(
        summary="Get room details",
        description="Get detailed information about a specific room.",
        responses={200: RoomSerializer},
        tags=["Room Management"],
    ),
    create=extend_schema(
        summary="Create room",
        description="Create a new room. Requires manager role.",
        request=RoomSerializer,
        responses={201: RoomSerializer},
        tags=["Room Management"],
    ),
    update=extend_schema(
        summary="Update room",
        description="Update room details. Requires manager role.",
        request=RoomSerializer,
        responses={200: RoomSerializer},
        tags=["Room Management"],
    ),
    partial_update=extend_schema(
        summary="Partially update room",
        description="Partially update room details. Requires manager role.",
        request=RoomSerializer,
        responses={200: RoomSerializer},
        tags=["Room Management"],
    ),
    destroy=extend_schema(
        summary="Delete room",
        description="Delete a room. Requires manager role.",
        responses={204: None},
        tags=["Room Management"],
    ),
)
class RoomViewSet(viewsets.ModelViewSet):
    """ViewSet for Room CRUD operations."""

    queryset = Room.objects.all()
    permission_classes = [IsAuthenticated, IsStaff]

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "list":
            return RoomListSerializer
        elif self.action == "update_status":
            return RoomStatusUpdateSerializer
        return RoomSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsManager()]
        return [IsAuthenticated(), IsStaff()]

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = super().get_queryset().select_related("room_type")

        # Filter by status
        status_param = self.request.query_params.get("status")
        if status_param:
            queryset = queryset.filter(status=status_param)

        # Filter by room type
        room_type_param = self.request.query_params.get("room_type")
        if room_type_param:
            queryset = queryset.filter(room_type_id=room_type_param)

        # Filter by floor
        floor_param = self.request.query_params.get("floor")
        if floor_param:
            queryset = queryset.filter(floor=floor_param)

        # Filter by active status
        is_active = self.request.query_params.get("is_active")
        if is_active is not None:
            is_active_bool = is_active.lower() in ["true", "1", "yes"]
            queryset = queryset.filter(is_active=is_active_bool)

        # Search by room number or name
        search_param = self.request.query_params.get("search")
        if search_param:
            queryset = queryset.filter(Q(number__icontains=search_param) | Q(name__icontains=search_param))

        return queryset

    @extend_schema(
        summary="Update room status",
        description="Update the status of a room (e.g., available, occupied, cleaning).",
        request=RoomStatusUpdateSerializer,
        responses={
            200: RoomSerializer,
            400: OpenApiResponse(description="Invalid status transition"),
        },
        tags=["Room Management"],
    )
    @action(detail=True, methods=["post"], url_path="update-status")
    def update_status(self, request, pk=None):
        """Update room status."""
        room = self.get_object()
        serializer = RoomStatusUpdateSerializer(data=request.data, context={"room": room})
        serializer.is_valid(raise_exception=True)

        # Update room status
        room.status = serializer.validated_data["status"]
        if "notes" in serializer.validated_data:
            room.notes = serializer.validated_data["notes"]
        room.save()

        # Return updated room
        return Response(RoomSerializer(room).data, status=status.HTTP_200_OK)

    @extend_schema(
        summary="Check room availability",
        description="Check which rooms are available for a given date range.",
        request=RoomAvailabilitySerializer,
        responses={
            200: OpenApiResponse(
                description="Available rooms",
                response={
                    "type": "object",
                    "properties": {
                        "available_rooms": {"type": "array", "items": {"$ref": "#/components/schemas/RoomList"}},
                        "total_available": {"type": "integer", "description": "Total number of available rooms"},
                        "check_in": {"type": "string", "format": "date"},
                        "check_out": {"type": "string", "format": "date"},
                        "room_type": {"type": "integer", "nullable": True},
                    },
                },
            )
        },
        tags=["Room Management"],
    )
    @action(detail=False, methods=["post"], url_path="check-availability")
    def check_availability(self, request):
        """Check room availability for date range."""
        serializer = RoomAvailabilitySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        check_in = serializer.validated_data["check_in"]
        check_out = serializer.validated_data["check_out"]
        room_type = serializer.validated_data.get("room_type")

        # For now, return all available rooms (no booking overlap check yet)
        # Will be enhanced when Booking model endpoints are implemented
        available_rooms = Room.objects.filter(
            is_active=True,
            status=Room.Status.AVAILABLE,
        ).select_related("room_type")

        if room_type:
            available_rooms = available_rooms.filter(room_type=room_type)

        return Response(
            {
                "available_rooms": RoomListSerializer(available_rooms, many=True).data,
                "total_available": available_rooms.count(),
                "check_in": check_in,
                "check_out": check_out,
                "room_type": room_type.id if room_type else None,
            },
            status=status.HTTP_200_OK,
        )
