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

from .models import Booking, Guest, Room, RoomType
from .permissions import IsManager, IsStaff
from .serializers import (
    BookingListSerializer,
    BookingSerializer,
    BookingStatusUpdateSerializer,
    CheckInSerializer,
    CheckOutSerializer,
    GuestListSerializer,
    GuestSearchSerializer,
    GuestSerializer,
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


# ==================== Guest Management Views ====================


@extend_schema_view(
    list=extend_schema(
        summary="List guests",
        description="Get list of all guests with filtering options.",
        parameters=[
            OpenApiParameter(
                name="is_vip",
                type=bool,
                description="Filter by VIP status",
                required=False,
            ),
            OpenApiParameter(
                name="nationality",
                type=str,
                description="Filter by nationality",
                required=False,
            ),
            OpenApiParameter(
                name="search",
                type=str,
                description="Search by name, phone, or ID number",
                required=False,
            ),
        ],
        responses={200: GuestListSerializer(many=True)},
        tags=["Guest Management"],
    ),
    retrieve=extend_schema(
        summary="Get guest details",
        description="Get detailed information about a specific guest.",
        responses={200: GuestSerializer},
        tags=["Guest Management"],
    ),
    create=extend_schema(
        summary="Create new guest",
        description="Create a new guest record.",
        request=GuestSerializer,
        responses={201: GuestSerializer},
        tags=["Guest Management"],
    ),
    update=extend_schema(
        summary="Update guest",
        description="Update a guest's information.",
        request=GuestSerializer,
        responses={200: GuestSerializer},
        tags=["Guest Management"],
    ),
    partial_update=extend_schema(
        summary="Partial update guest",
        description="Partially update a guest's information.",
        request=GuestSerializer,
        responses={200: GuestSerializer},
        tags=["Guest Management"],
    ),
    destroy=extend_schema(
        summary="Delete guest",
        description="Delete a guest record. This is a soft delete that deactivates the guest.",
        responses={204: OpenApiResponse(description="Guest deleted successfully")},
        tags=["Guest Management"],
    ),
)
class GuestViewSet(viewsets.ModelViewSet):
    """ViewSet for managing guests."""

    permission_classes = [IsAuthenticated, IsStaff]
    serializer_class = GuestSerializer
    filterset_fields = ["is_vip", "nationality"]
    search_fields = ["full_name", "phone", "id_number"]
    ordering_fields = ["created_at", "full_name", "total_stays"]
    ordering = ["-created_at"]

    def get_queryset(self):
        """Get queryset with optional filtering."""
        queryset = Guest.objects.all()

        # Filter by VIP status
        is_vip = self.request.query_params.get("is_vip")
        if is_vip is not None:
            queryset = queryset.filter(is_vip=is_vip.lower() == "true")

        # Filter by nationality
        nationality = self.request.query_params.get("nationality")
        if nationality:
            queryset = queryset.filter(nationality=nationality)

        # Search by name, phone, or ID number
        search = self.request.query_params.get("search")
        if search:
            queryset = queryset.filter(
                Q(full_name__icontains=search)
                | Q(phone__icontains=search)
                | Q(id_number__icontains=search)
            )

        return queryset.order_by(*self.ordering)

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "list":
            return GuestListSerializer
        elif self.action == "search":
            return GuestSearchSerializer
        return GuestSerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsManager()]
        return [IsAuthenticated(), IsStaff()]

    @extend_schema(
        summary="Search guests",
        description="Search for guests by name, phone, or ID number.",
        request=GuestSearchSerializer,
        responses={200: GuestListSerializer(many=True)},
        tags=["Guest Management"],
    )
    @action(detail=False, methods=["post"], url_path="search")
    def search(self, request):
        """Search for guests."""
        serializer = GuestSearchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        query = serializer.validated_data["query"]
        guests = Guest.objects.filter(
            Q(full_name__icontains=query) | Q(phone__icontains=query) | Q(id_number__icontains=query)
        )

        return Response(
            GuestListSerializer(guests, many=True).data,
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Get guest booking history",
        description="Get all bookings for a specific guest.",
        responses={
            200: OpenApiResponse(
                description="Guest booking history",
                response={
                    "type": "object",
                    "properties": {
                        "guest": {"$ref": "#/components/schemas/Guest"},
                        "bookings": {"type": "array", "items": {"$ref": "#/components/schemas/BookingList"}},
                        "total_bookings": {"type": "integer"},
                        "total_stays": {"type": "integer"},
                    },
                },
            )
        },
        tags=["Guest Management"],
    )
    @action(detail=True, methods=["get"], url_path="history")
    def history(self, request, pk=None):
        """Get booking history for a guest."""
        guest = self.get_object()
        bookings = Booking.objects.filter(guest=guest).select_related("room", "room__room_type").order_by(
            "-check_in_date"
        )

        return Response(
            {
                "guest": GuestSerializer(guest).data,
                "bookings": BookingListSerializer(bookings, many=True).data,
                "total_bookings": bookings.count(),
                "total_stays": guest.total_stays,
            },
            status=status.HTTP_200_OK,
        )


# ==================== Booking Management Views ====================


@extend_schema_view(
    list=extend_schema(
        summary="List bookings",
        description="Get list of all bookings with filtering options.",
        parameters=[
            OpenApiParameter(
                name="status",
                type=str,
                description="Filter by booking status",
                required=False,
            ),
            OpenApiParameter(
                name="source",
                type=str,
                description="Filter by booking source",
                required=False,
            ),
            OpenApiParameter(
                name="room",
                type=int,
                description="Filter by room ID",
                required=False,
            ),
            OpenApiParameter(
                name="guest",
                type=int,
                description="Filter by guest ID",
                required=False,
            ),
            OpenApiParameter(
                name="check_in_from",
                type=str,
                description="Filter bookings with check-in date from this date (YYYY-MM-DD)",
                required=False,
            ),
            OpenApiParameter(
                name="check_in_to",
                type=str,
                description="Filter bookings with check-in date until this date (YYYY-MM-DD)",
                required=False,
            ),
        ],
        responses={200: BookingListSerializer(many=True)},
        tags=["Booking Management"],
    ),
    retrieve=extend_schema(
        summary="Get booking details",
        description="Get detailed information about a specific booking.",
        responses={200: BookingSerializer},
        tags=["Booking Management"],
    ),
    create=extend_schema(
        summary="Create new booking",
        description="Create a new booking. Automatically checks for room availability and overlaps.",
        request=BookingSerializer,
        responses={201: BookingSerializer},
        tags=["Booking Management"],
    ),
    update=extend_schema(
        summary="Update booking",
        description="Update a booking's information. Checks for room availability if dates or room changed.",
        request=BookingSerializer,
        responses={200: BookingSerializer},
        tags=["Booking Management"],
    ),
    partial_update=extend_schema(
        summary="Partial update booking",
        description="Partially update a booking's information.",
        request=BookingSerializer,
        responses={200: BookingSerializer},
        tags=["Booking Management"],
    ),
    destroy=extend_schema(
        summary="Delete booking",
        description="Delete a booking record. This is a hard delete.",
        responses={204: OpenApiResponse(description="Booking deleted successfully")},
        tags=["Booking Management"],
    ),
)
class BookingViewSet(viewsets.ModelViewSet):
    """ViewSet for managing bookings."""

    permission_classes = [IsAuthenticated, IsStaff]
    serializer_class = BookingSerializer
    filterset_fields = ["status", "source", "room", "guest"]
    ordering_fields = ["created_at", "check_in_date", "check_out_date"]
    ordering = ["-created_at"]

    def get_queryset(self):
        """Get queryset with optional filtering."""
        queryset = Booking.objects.select_related("guest", "room", "room__room_type").all()

        # Filter by date range
        check_in_from = self.request.query_params.get("check_in_from")
        if check_in_from:
            queryset = queryset.filter(check_in_date__gte=check_in_from)

        check_in_to = self.request.query_params.get("check_in_to")
        if check_in_to:
            queryset = queryset.filter(check_in_date__lte=check_in_to)

        return queryset.order_by(*self.ordering)

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "list":
            return BookingListSerializer
        elif self.action == "update_status":
            return BookingStatusUpdateSerializer
        elif self.action == "check_in":
            return CheckInSerializer
        elif self.action == "check_out":
            return CheckOutSerializer
        return BookingSerializer

    @extend_schema(
        summary="Update booking status",
        description="Update the status of a booking (e.g., confirm, cancel, no-show).",
        request=BookingStatusUpdateSerializer,
        responses={200: BookingSerializer},
        tags=["Booking Management"],
    )
    @action(detail=True, methods=["post"], url_path="update-status")
    def update_status(self, request, pk=None):
        """Update booking status."""
        booking = self.get_object()
        serializer = BookingStatusUpdateSerializer(booking, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(
            BookingSerializer(booking).data,
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Check in guest",
        description="Check in a guest for their booking. Updates status to CHECKED_IN.",
        request=CheckInSerializer,
        responses={200: BookingSerializer},
        tags=["Booking Management"],
    )
    @action(detail=True, methods=["post"], url_path="check-in")
    def check_in(self, request, pk=None):
        """Check in a guest."""
        from django.utils import timezone

        booking = self.get_object()

        if booking.status == Booking.Status.CHECKED_IN:
            return Response(
                {"detail": "Khách đã check-in rồi."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if booking.status not in [Booking.Status.PENDING, Booking.Status.CONFIRMED]:
            return Response(
                {"detail": f"Không thể check-in booking với trạng thái {booking.get_status_display()}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = CheckInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        booking.status = Booking.Status.CHECKED_IN
        booking.actual_check_in = serializer.validated_data.get("actual_check_in", timezone.now())
        booking.notes = serializer.validated_data.get("notes", booking.notes or "")
        booking.save()

        # Update room status to OCCUPIED
        room = booking.room
        room.status = Room.Status.OCCUPIED
        room.save()

        return Response(
            BookingSerializer(booking).data,
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Check out guest",
        description="Check out a guest from their booking. Updates status to CHECKED_OUT.",
        request=CheckOutSerializer,
        responses={200: BookingSerializer},
        tags=["Booking Management"],
    )
    @action(detail=True, methods=["post"], url_path="check-out")
    def check_out(self, request, pk=None):
        """Check out a guest."""
        from django.utils import timezone

        booking = self.get_object()

        if booking.status == Booking.Status.CHECKED_OUT:
            return Response(
                {"detail": "Khách đã check-out rồi."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if booking.status != Booking.Status.CHECKED_IN:
            return Response(
                {"detail": f"Không thể check-out booking với trạng thái {booking.get_status_display()}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = CheckOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        booking.status = Booking.Status.CHECKED_OUT
        booking.actual_check_out = serializer.validated_data.get("actual_check_out", timezone.now())
        # Append to existing notes if provided
        additional_notes = serializer.validated_data.get("notes", "")
        if additional_notes:
            booking.notes = f"{booking.notes}\n{additional_notes}" if booking.notes else additional_notes
        # Additional charges field doesn't exist in model, skip it
        booking.save()

        # Update room status to CLEANING
        room = booking.room
        room.status = Room.Status.CLEANING
        room.save()

        # Increment guest's total stays
        guest = booking.guest
        guest.total_stays += 1
        guest.save()

        return Response(
            BookingSerializer(booking).data,
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Get today's bookings",
        description="Get all bookings for today (check-ins and check-outs).",
        responses={
            200: OpenApiResponse(
                description="Today's bookings",
                response={
                    "type": "object",
                    "properties": {
                        "check_ins": {"type": "array", "items": {"$ref": "#/components/schemas/BookingList"}},
                        "check_outs": {"type": "array", "items": {"$ref": "#/components/schemas/BookingList"}},
                        "total_check_ins": {"type": "integer"},
                        "total_check_outs": {"type": "integer"},
                    },
                },
            )
        },
        tags=["Booking Management"],
    )
    @action(detail=False, methods=["get"], url_path="today")
    def today(self, request):
        """Get today's bookings."""
        from datetime import date

        today = date.today()

        check_ins = (
            Booking.objects.filter(check_in_date=today)
            .select_related("guest", "room", "room__room_type")
            .order_by("check_in_date")
        )

        check_outs = (
            Booking.objects.filter(check_out_date=today)
            .select_related("guest", "room", "room__room_type")
            .order_by("check_out_date")
        )

        return Response(
            {
                "check_ins": BookingListSerializer(check_ins, many=True).data,
                "check_outs": BookingListSerializer(check_outs, many=True).data,
                "total_check_ins": check_ins.count(),
                "total_check_outs": check_outs.count(),
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Get calendar view",
        description="Get bookings for a date range, useful for calendar view.",
        parameters=[
            OpenApiParameter(
                name="start_date",
                type=str,
                description="Start date (YYYY-MM-DD)",
                required=True,
            ),
            OpenApiParameter(
                name="end_date",
                type=str,
                description="End date (YYYY-MM-DD)",
                required=True,
            ),
        ],
        responses={
            200: OpenApiResponse(
                description="Bookings in date range",
                response={
                    "type": "object",
                    "properties": {
                        "bookings": {"type": "array", "items": {"$ref": "#/components/schemas/BookingList"}},
                        "total": {"type": "integer"},
                        "start_date": {"type": "string", "format": "date"},
                        "end_date": {"type": "string", "format": "date"},
                    },
                },
            )
        },
        tags=["Booking Management"],
    )
    @action(detail=False, methods=["get"], url_path="calendar")
    def calendar(self, request):
        """Get bookings for calendar view."""
        from datetime import datetime

        start_date = request.query_params.get("start_date")
        end_date = request.query_params.get("end_date")

        if not start_date or not end_date:
            return Response(
                {"detail": "Cần cung cấp start_date và end_date."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            start_date = datetime.strptime(start_date, "%Y-%m-%d").date()
            end_date = datetime.strptime(end_date, "%Y-%m-%d").date()
        except ValueError:
            return Response(
                {"detail": "Định dạng ngày không hợp lệ. Sử dụng YYYY-MM-DD."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        bookings = (
            Booking.objects.filter(
                Q(check_in_date__range=[start_date, end_date]) | Q(check_out_date__range=[start_date, end_date])
            )
            .select_related("guest", "room", "room__room_type")
            .order_by("check_in_date")
        )

        return Response(
            {
                "bookings": BookingListSerializer(bookings, many=True).data,
                "total": bookings.count(),
                "start_date": start_date,
                "end_date": end_date,
            },
            status=status.HTTP_200_OK,
        )
