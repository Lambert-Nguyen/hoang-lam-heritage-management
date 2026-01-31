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

from .models import Booking, FinancialCategory, FinancialEntry, Guest, Room, RoomType
from .permissions import IsManager, IsStaff
from .serializers import (
    BookingListSerializer,
    BookingSerializer,
    BookingStatusUpdateSerializer,
    CheckInSerializer,
    CheckOutSerializer,
    FinancialCategoryListSerializer,
    FinancialCategorySerializer,
    FinancialEntryListSerializer,
    FinancialEntrySerializer,
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
        """Get queryset with optional filtering and optimized annotations."""
        from django.db.models import Count
        
        queryset = Guest.objects.annotate(booking_count=Count("bookings")).all()

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

    @extend_schema(
        summary="Export temporary residence declaration",
        description="Export guest data for temporary residence declaration to police. "
                    "Returns CSV or Excel file with guest information for a date range.",
        parameters=[
            OpenApiParameter(
                name="date_from",
                type=str,
                description="Start date for export (YYYY-MM-DD). Defaults to today.",
                required=False,
            ),
            OpenApiParameter(
                name="date_to",
                type=str,
                description="End date for export (YYYY-MM-DD). Defaults to today.",
                required=False,
            ),
            OpenApiParameter(
                name="format",
                type=str,
                description="Export format: 'csv' or 'excel'. Defaults to 'csv'.",
                required=False,
            ),
        ],
        responses={
            200: OpenApiResponse(
                description="File download (CSV or Excel)",
            )
        },
        tags=["Guest Management"],
    )
    @action(detail=False, methods=["get"], url_path="declaration-export")
    def declaration_export(self, request):
        """Export temporary residence declaration for police reporting."""
        import csv
        import io
        from datetime import date

        from django.http import HttpResponse

        # Get date range parameters
        date_from = request.query_params.get("date_from")
        date_to = request.query_params.get("date_to")
        export_format = request.query_params.get("format", "csv").lower()

        today = date.today()
        try:
            date_from = date.fromisoformat(date_from) if date_from else today
            date_to = date.fromisoformat(date_to) if date_to else today
        except ValueError:
            return Response(
                {"detail": "Định dạng ngày không hợp lệ. Sử dụng YYYY-MM-DD."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if date_from > date_to:
            return Response(
                {"detail": "Ngày bắt đầu không được lớn hơn ngày kết thúc."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get guests who checked in during the date range
        bookings = Booking.objects.filter(
            check_in_date__gte=date_from,
            check_in_date__lte=date_to,
            status__in=[Booking.Status.CHECKED_IN, Booking.Status.CHECKED_OUT],
        ).select_related("guest", "room")

        # Prepare data rows
        rows = []
        for booking in bookings:
            guest = booking.guest
            rows.append({
                "stt": len(rows) + 1,
                "ho_ten": guest.full_name,
                "ngay_sinh": guest.date_of_birth.strftime("%d/%m/%Y") if guest.date_of_birth else "",
                "gioi_tinh": "Nam" if guest.gender == "male" else "Nữ" if guest.gender == "female" else "",
                "quoc_tich": guest.nationality or "Việt Nam",
                "loai_giay_to": guest.get_id_type_display() if hasattr(guest, "get_id_type_display") else guest.id_type,
                "so_giay_to": guest.id_number or "",
                "ngay_cap": guest.id_issue_date.strftime("%d/%m/%Y") if guest.id_issue_date else "",
                "noi_cap": guest.id_issue_place or "",
                "dia_chi_thuong_tru": guest.address or "",
                "so_dien_thoai": guest.phone or "",
                "so_phong": booking.room.number,
                "ngay_den": booking.check_in_date.strftime("%d/%m/%Y"),
                "ngay_di": booking.check_out_date.strftime("%d/%m/%Y") if booking.actual_check_out else "",
            })

        if export_format == "excel":
            try:
                import openpyxl
                from openpyxl.utils import get_column_letter

                wb = openpyxl.Workbook()
                ws = wb.active
                ws.title = "Khai báo lưu trú"

                # Headers
                headers = [
                    "STT", "Họ và tên", "Ngày sinh", "Giới tính", "Quốc tịch",
                    "Loại giấy tờ", "Số giấy tờ", "Ngày cấp", "Nơi cấp",
                    "Địa chỉ thường trú", "Số điện thoại", "Số phòng",
                    "Ngày đến", "Ngày đi"
                ]
                for col, header in enumerate(headers, 1):
                    ws.cell(row=1, column=col, value=header)

                # Data rows
                for row_idx, row_data in enumerate(rows, 2):
                    ws.cell(row=row_idx, column=1, value=row_data["stt"])
                    ws.cell(row=row_idx, column=2, value=row_data["ho_ten"])
                    ws.cell(row=row_idx, column=3, value=row_data["ngay_sinh"])
                    ws.cell(row=row_idx, column=4, value=row_data["gioi_tinh"])
                    ws.cell(row=row_idx, column=5, value=row_data["quoc_tich"])
                    ws.cell(row=row_idx, column=6, value=row_data["loai_giay_to"])
                    ws.cell(row=row_idx, column=7, value=row_data["so_giay_to"])
                    ws.cell(row=row_idx, column=8, value=row_data["ngay_cap"])
                    ws.cell(row=row_idx, column=9, value=row_data["noi_cap"])
                    ws.cell(row=row_idx, column=10, value=row_data["dia_chi_thuong_tru"])
                    ws.cell(row=row_idx, column=11, value=row_data["so_dien_thoai"])
                    ws.cell(row=row_idx, column=12, value=row_data["so_phong"])
                    ws.cell(row=row_idx, column=13, value=row_data["ngay_den"])
                    ws.cell(row=row_idx, column=14, value=row_data["ngay_di"])

                # Save to buffer
                buffer = io.BytesIO()
                wb.save(buffer)
                buffer.seek(0)

                response = HttpResponse(
                    buffer.getvalue(),
                    content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                )
                filename = f"khai_bao_luu_tru_{date_from}_{date_to}.xlsx"
                response["Content-Disposition"] = f'attachment; filename="{filename}"'
                return response

            except ImportError:
                return Response(
                    {"detail": "Thư viện openpyxl chưa được cài đặt. Vui lòng sử dụng format=csv."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            # CSV export
            buffer = io.StringIO()
            writer = csv.writer(buffer)

            # Headers
            writer.writerow([
                "STT", "Họ và tên", "Ngày sinh", "Giới tính", "Quốc tịch",
                "Loại giấy tờ", "Số giấy tờ", "Ngày cấp", "Nơi cấp",
                "Địa chỉ thường trú", "Số điện thoại", "Số phòng",
                "Ngày đến", "Ngày đi"
            ])

            # Data rows
            for row_data in rows:
                writer.writerow([
                    row_data["stt"],
                    row_data["ho_ten"],
                    row_data["ngay_sinh"],
                    row_data["gioi_tinh"],
                    row_data["quoc_tich"],
                    row_data["loai_giay_to"],
                    row_data["so_giay_to"],
                    row_data["ngay_cap"],
                    row_data["noi_cap"],
                    row_data["dia_chi_thuong_tru"],
                    row_data["so_dien_thoai"],
                    row_data["so_phong"],
                    row_data["ngay_den"],
                    row_data["ngay_di"],
                ])

            response = HttpResponse(
                buffer.getvalue(),
                content_type="text/csv; charset=utf-8-sig",  # utf-8-sig for Excel compatibility
            )
            filename = f"khai_bao_luu_tru_{date_from}_{date_to}.csv"
            response["Content-Disposition"] = f'attachment; filename="{filename}"'
            return response


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
        from django.db import transaction
        from django.utils import timezone

        booking = self.get_object()

        if booking.status == Booking.Status.CHECKED_IN:
            return Response(
                {"detail": "Guest is already checked in."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if booking.status not in [Booking.Status.PENDING, Booking.Status.CONFIRMED]:
            return Response(
                {"detail": f"Cannot check in booking with status {booking.get_status_display()}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = CheckInSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Use atomic transaction to ensure consistency
        with transaction.atomic():
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
        from django.db import transaction
        from django.utils import timezone

        booking = self.get_object()

        if booking.status == Booking.Status.CHECKED_OUT:
            return Response(
                {"detail": "Guest is already checked out."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if booking.status != Booking.Status.CHECKED_IN:
            return Response(
                {"detail": f"Cannot check out booking with status {booking.get_status_display()}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = CheckOutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Use atomic transaction to ensure consistency
        with transaction.atomic():
            booking.status = Booking.Status.CHECKED_OUT
            booking.actual_check_out = serializer.validated_data.get("actual_check_out", timezone.now())
            # Append to existing notes if provided
            additional_notes = serializer.validated_data.get("notes", "")
            if additional_notes:
                booking.notes = f"{booking.notes}\n{additional_notes}" if booking.notes else additional_notes
            # Store additional charges
            booking.additional_charges = serializer.validated_data.get("additional_charges", 0)
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


# ==================== Dashboard Views ====================


@extend_schema_view(
    get=extend_schema(
        summary="Get dashboard summary",
        description="Get aggregated dashboard metrics including room status, today's stats, and revenue summary.",
        responses={
            200: OpenApiResponse(
                description="Dashboard summary",
                response={
                    "type": "object",
                    "properties": {
                        "room_status": {
                            "type": "object",
                            "properties": {
                                "total": {"type": "integer"},
                                "available": {"type": "integer"},
                                "occupied": {"type": "integer"},
                                "cleaning": {"type": "integer"},
                                "maintenance": {"type": "integer"},
                                "blocked": {"type": "integer"},
                            },
                        },
                        "today": {
                            "type": "object",
                            "properties": {
                                "date": {"type": "string", "format": "date"},
                                "check_ins": {"type": "integer"},
                                "check_outs": {"type": "integer"},
                                "pending_arrivals": {"type": "integer"},
                                "pending_departures": {"type": "integer"},
                            },
                        },
                        "occupancy": {
                            "type": "object",
                            "properties": {
                                "rate": {"type": "number", "format": "float"},
                                "occupied_rooms": {"type": "integer"},
                                "total_rooms": {"type": "integer"},
                            },
                        },
                        "bookings": {
                            "type": "object",
                            "properties": {
                                "pending": {"type": "integer"},
                                "confirmed": {"type": "integer"},
                                "checked_in": {"type": "integer"},
                            },
                        },
                    },
                },
            )
        },
        tags=["Dashboard"],
    )
)
class DashboardView(APIView):
    """Dashboard summary endpoint for hotel overview."""

    permission_classes = [IsAuthenticated, IsStaff]

    def get(self, request):
        """Get dashboard summary metrics."""
        from datetime import date

        from django.db.models import Count

        today = date.today()

        # Room status summary
        room_status = (
            Room.objects.filter(is_active=True)
            .values("status")
            .annotate(count=Count("id"))
        )
        room_status_dict = {item["status"]: item["count"] for item in room_status}
        total_rooms = Room.objects.filter(is_active=True).count()

        # Today's check-ins and check-outs
        today_check_ins = Booking.objects.filter(
            check_in_date=today,
            status__in=[Booking.Status.PENDING, Booking.Status.CONFIRMED],
        ).count()
        today_check_outs = Booking.objects.filter(
            check_out_date=today,
            status=Booking.Status.CHECKED_IN,
        ).count()

        # Already checked in/out today
        completed_check_ins = Booking.objects.filter(
            check_in_date=today,
            status=Booking.Status.CHECKED_IN,
        ).count()
        completed_check_outs = Booking.objects.filter(
            check_out_date=today,
            status=Booking.Status.CHECKED_OUT,
        ).count()

        # Booking status counts
        pending_bookings = Booking.objects.filter(status=Booking.Status.PENDING).count()
        confirmed_bookings = Booking.objects.filter(status=Booking.Status.CONFIRMED).count()
        checked_in_bookings = Booking.objects.filter(status=Booking.Status.CHECKED_IN).count()

        # Calculate occupancy
        occupied_rooms = room_status_dict.get(Room.Status.OCCUPIED, 0)
        occupancy_rate = (occupied_rooms / total_rooms * 100) if total_rooms > 0 else 0

        return Response(
            {
                "room_status": {
                    "total": total_rooms,
                    "available": room_status_dict.get(Room.Status.AVAILABLE, 0),
                    "occupied": occupied_rooms,
                    "cleaning": room_status_dict.get(Room.Status.CLEANING, 0),
                    "maintenance": room_status_dict.get(Room.Status.MAINTENANCE, 0),
                    "blocked": room_status_dict.get(Room.Status.BLOCKED, 0),
                },
                "today": {
                    "date": today.isoformat(),
                    "check_ins": today_check_ins + completed_check_ins,
                    "check_outs": today_check_outs + completed_check_outs,
                    "pending_arrivals": today_check_ins,
                    "pending_departures": today_check_outs,
                },
                "occupancy": {
                    "rate": round(occupancy_rate, 1),
                    "occupied_rooms": occupied_rooms,
                    "total_rooms": total_rooms,
                },
                "bookings": {
                    "pending": pending_bookings,
                    "confirmed": confirmed_bookings,
                    "checked_in": checked_in_bookings,
                },
            },
            status=status.HTTP_200_OK,
        )


# ==================== Financial Management Views ====================


@extend_schema_view(
    list=extend_schema(
        summary="List financial categories",
        description="Get list of all financial categories.",
        parameters=[
            OpenApiParameter(
                name="category_type",
                type=str,
                description="Filter by category type (income/expense)",
                required=False,
            ),
            OpenApiParameter(
                name="is_active",
                type=bool,
                description="Filter by active status",
                required=False,
            ),
        ],
        responses={200: FinancialCategoryListSerializer(many=True)},
        tags=["Financial Management"],
    ),
    retrieve=extend_schema(
        summary="Get financial category details",
        description="Get detailed information about a specific financial category.",
        responses={200: FinancialCategorySerializer},
        tags=["Financial Management"],
    ),
    create=extend_schema(
        summary="Create financial category",
        description="Create a new financial category. Requires manager role.",
        request=FinancialCategorySerializer,
        responses={201: FinancialCategorySerializer},
        tags=["Financial Management"],
    ),
    update=extend_schema(
        summary="Update financial category",
        description="Update a financial category. Requires manager role.",
        request=FinancialCategorySerializer,
        responses={200: FinancialCategorySerializer},
        tags=["Financial Management"],
    ),
    partial_update=extend_schema(
        summary="Partially update financial category",
        description="Partially update a financial category. Requires manager role.",
        request=FinancialCategorySerializer,
        responses={200: FinancialCategorySerializer},
        tags=["Financial Management"],
    ),
    destroy=extend_schema(
        summary="Delete financial category",
        description="Delete a financial category. Requires manager role.",
        responses={204: None},
        tags=["Financial Management"],
    ),
)
class FinancialCategoryViewSet(viewsets.ModelViewSet):
    """ViewSet for FinancialCategory CRUD operations."""

    queryset = FinancialCategory.objects.all()
    permission_classes = [IsAuthenticated, IsStaff]

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "list":
            return FinancialCategoryListSerializer
        return FinancialCategorySerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ["create", "update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsManager()]
        return [IsAuthenticated(), IsStaff()]

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        from django.db.models import Count

        queryset = super().get_queryset().annotate(entry_count=Count("entries"))

        # Filter by category type
        category_type = self.request.query_params.get("category_type")
        if category_type:
            queryset = queryset.filter(category_type=category_type)

        # Filter by active status
        is_active = self.request.query_params.get("is_active")
        if is_active is not None:
            is_active_bool = is_active.lower() in ["true", "1", "yes"]
            queryset = queryset.filter(is_active=is_active_bool)

        return queryset


@extend_schema_view(
    list=extend_schema(
        summary="List financial entries",
        description="Get list of financial entries with filtering options.",
        parameters=[
            OpenApiParameter(
                name="entry_type",
                type=str,
                description="Filter by entry type (income/expense)",
                required=False,
            ),
            OpenApiParameter(
                name="category",
                type=int,
                description="Filter by category ID",
                required=False,
            ),
            OpenApiParameter(
                name="date_from",
                type=str,
                description="Filter entries from this date (YYYY-MM-DD)",
                required=False,
            ),
            OpenApiParameter(
                name="date_to",
                type=str,
                description="Filter entries until this date (YYYY-MM-DD)",
                required=False,
            ),
            OpenApiParameter(
                name="payment_method",
                type=str,
                description="Filter by payment method",
                required=False,
            ),
        ],
        responses={200: FinancialEntryListSerializer(many=True)},
        tags=["Financial Management"],
    ),
    retrieve=extend_schema(
        summary="Get financial entry details",
        description="Get detailed information about a specific financial entry.",
        responses={200: FinancialEntrySerializer},
        tags=["Financial Management"],
    ),
    create=extend_schema(
        summary="Create financial entry",
        description="Create a new financial entry (income or expense).",
        request=FinancialEntrySerializer,
        responses={201: FinancialEntrySerializer},
        tags=["Financial Management"],
    ),
    update=extend_schema(
        summary="Update financial entry",
        description="Update a financial entry. Requires manager role.",
        request=FinancialEntrySerializer,
        responses={200: FinancialEntrySerializer},
        tags=["Financial Management"],
    ),
    partial_update=extend_schema(
        summary="Partially update financial entry",
        description="Partially update a financial entry. Requires manager role.",
        request=FinancialEntrySerializer,
        responses={200: FinancialEntrySerializer},
        tags=["Financial Management"],
    ),
    destroy=extend_schema(
        summary="Delete financial entry",
        description="Delete a financial entry. Requires manager role.",
        responses={204: None},
        tags=["Financial Management"],
    ),
)
class FinancialEntryViewSet(viewsets.ModelViewSet):
    """ViewSet for FinancialEntry CRUD operations."""

    queryset = FinancialEntry.objects.all()
    permission_classes = [IsAuthenticated, IsStaff]

    def get_serializer_class(self):
        """Return appropriate serializer class."""
        if self.action == "list":
            return FinancialEntryListSerializer
        return FinancialEntrySerializer

    def get_permissions(self):
        """Set permissions based on action."""
        if self.action in ["update", "partial_update", "destroy"]:
            return [IsAuthenticated(), IsManager()]
        return [IsAuthenticated(), IsStaff()]

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = super().get_queryset().select_related(
            "category", "booking", "booking__room", "booking__guest", "created_by"
        )

        # Filter by entry type
        entry_type = self.request.query_params.get("entry_type")
        if entry_type:
            queryset = queryset.filter(entry_type=entry_type)

        # Filter by category
        category = self.request.query_params.get("category")
        if category:
            queryset = queryset.filter(category_id=category)

        # Filter by date range
        date_from = self.request.query_params.get("date_from")
        if date_from:
            queryset = queryset.filter(date__gte=date_from)

        date_to = self.request.query_params.get("date_to")
        if date_to:
            queryset = queryset.filter(date__lte=date_to)

        # Filter by payment method
        payment_method = self.request.query_params.get("payment_method")
        if payment_method:
            queryset = queryset.filter(payment_method=payment_method)

        return queryset.order_by("-date", "-created_at")

    def perform_create(self, serializer):
        """Set created_by to current user."""
        serializer.save(created_by=self.request.user)

    @extend_schema(
        summary="Get daily financial summary",
        description="Get financial summary for a specific day.",
        parameters=[
            OpenApiParameter(
                name="date",
                type=str,
                description="Date for summary (YYYY-MM-DD). Defaults to today.",
                required=False,
            ),
        ],
        responses={
            200: OpenApiResponse(
                description="Daily financial summary",
                response={
                    "type": "object",
                    "properties": {
                        "date": {"type": "string", "format": "date"},
                        "total_income": {"type": "number"},
                        "total_expense": {"type": "number"},
                        "net_profit": {"type": "number"},
                        "income_entries": {"type": "integer"},
                        "expense_entries": {"type": "integer"},
                        "income_by_category": {"type": "array"},
                        "expense_by_category": {"type": "array"},
                    },
                },
            )
        },
        tags=["Financial Management"],
    )
    @action(detail=False, methods=["get"], url_path="daily-summary")
    def daily_summary(self, request):
        """Get financial summary for a day."""
        from datetime import date, datetime

        from django.db.models import Sum

        date_param = request.query_params.get("date")
        if date_param:
            try:
                summary_date = datetime.strptime(date_param, "%Y-%m-%d").date()
            except ValueError:
                return Response(
                    {"detail": "Định dạng ngày không hợp lệ. Sử dụng YYYY-MM-DD."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
        else:
            summary_date = date.today()

        # Get totals
        entries = FinancialEntry.objects.filter(date=summary_date)

        total_income = (
            entries.filter(entry_type=FinancialEntry.EntryType.INCOME).aggregate(total=Sum("amount"))[
                "total"
            ]
            or 0
        )

        total_expense = (
            entries.filter(entry_type=FinancialEntry.EntryType.EXPENSE).aggregate(total=Sum("amount"))[
                "total"
            ]
            or 0
        )

        # Get breakdown by category
        income_by_category = list(
            entries.filter(entry_type=FinancialEntry.EntryType.INCOME)
            .values("category__name", "category__icon", "category__color")
            .annotate(total=Sum("amount"))
            .order_by("-total")
        )

        expense_by_category = list(
            entries.filter(entry_type=FinancialEntry.EntryType.EXPENSE)
            .values("category__name", "category__icon", "category__color")
            .annotate(total=Sum("amount"))
            .order_by("-total")
        )

        return Response(
            {
                "date": summary_date.isoformat(),
                "total_income": total_income,
                "total_expense": total_expense,
                "net_profit": total_income - total_expense,
                "income_entries": entries.filter(entry_type=FinancialEntry.EntryType.INCOME).count(),
                "expense_entries": entries.filter(entry_type=FinancialEntry.EntryType.EXPENSE).count(),
                "income_by_category": income_by_category,
                "expense_by_category": expense_by_category,
            },
            status=status.HTTP_200_OK,
        )

    @extend_schema(
        summary="Get monthly financial summary",
        description="Get financial summary for a specific month.",
        parameters=[
            OpenApiParameter(
                name="year",
                type=int,
                description="Year for summary. Defaults to current year.",
                required=False,
            ),
            OpenApiParameter(
                name="month",
                type=int,
                description="Month for summary (1-12). Defaults to current month.",
                required=False,
            ),
        ],
        responses={
            200: OpenApiResponse(
                description="Monthly financial summary",
                response={
                    "type": "object",
                    "properties": {
                        "year": {"type": "integer"},
                        "month": {"type": "integer"},
                        "total_income": {"type": "number"},
                        "total_expense": {"type": "number"},
                        "net_profit": {"type": "number"},
                        "profit_margin": {"type": "number"},
                        "income_by_category": {"type": "array"},
                        "expense_by_category": {"type": "array"},
                        "daily_totals": {"type": "array"},
                    },
                },
            )
        },
        tags=["Financial Management"],
    )
    @action(detail=False, methods=["get"], url_path="monthly-summary")
    def monthly_summary(self, request):
        """Get financial summary for a month."""
        from datetime import date

        from django.db.models import Sum
        from django.db.models.functions import TruncDate

        # Get year and month parameters
        year = request.query_params.get("year")
        month = request.query_params.get("month")

        today = date.today()
        year = int(year) if year else today.year
        month = int(month) if month else today.month

        if not (1 <= month <= 12):
            return Response(
                {"detail": "Tháng phải từ 1 đến 12."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Get entries for the month
        entries = FinancialEntry.objects.filter(date__year=year, date__month=month)

        total_income = (
            entries.filter(entry_type=FinancialEntry.EntryType.INCOME).aggregate(total=Sum("amount"))[
                "total"
            ]
            or 0
        )

        total_expense = (
            entries.filter(entry_type=FinancialEntry.EntryType.EXPENSE).aggregate(total=Sum("amount"))[
                "total"
            ]
            or 0
        )

        net_profit = total_income - total_expense
        profit_margin = (net_profit / total_income * 100) if total_income > 0 else 0

        # Get breakdown by category
        income_by_category = list(
            entries.filter(entry_type=FinancialEntry.EntryType.INCOME)
            .values("category__name", "category__icon", "category__color")
            .annotate(total=Sum("amount"))
            .order_by("-total")
        )

        expense_by_category = list(
            entries.filter(entry_type=FinancialEntry.EntryType.EXPENSE)
            .values("category__name", "category__icon", "category__color")
            .annotate(total=Sum("amount"))
            .order_by("-total")
        )

        # Get daily totals for chart - manual grouping for SQLite compatibility
        from collections import defaultdict

        daily_data = defaultdict(lambda: {"income": 0, "expense": 0})
        for entry in entries:
            day_str = entry.date.isoformat()
            if entry.entry_type == FinancialEntry.EntryType.INCOME:
                daily_data[day_str]["income"] += entry.amount
            else:
                daily_data[day_str]["expense"] += entry.amount

        daily_totals = [
            {"day": day, "income": data["income"], "expense": data["expense"]}
            for day, data in sorted(daily_data.items())
        ]

        return Response(
            {
                "year": year,
                "month": month,
                "total_income": total_income,
                "total_expense": total_expense,
                "net_profit": net_profit,
                "profit_margin": round(profit_margin, 1),
                "income_by_category": income_by_category,
                "expense_by_category": expense_by_category,
                "daily_totals": daily_totals,
            },
            status=status.HTTP_200_OK,
        )


# Import NightAudit model and serializers
from .models import NightAudit
from .serializers import (
    NightAuditCreateSerializer,
    NightAuditListSerializer,
    NightAuditSerializer,
)


@extend_schema_view(
    list=extend_schema(
        summary="List night audits",
        description="Get a paginated list of night audits with optional filtering.",
        parameters=[
            OpenApiParameter(
                name="status",
                type=str,
                description="Filter by status (draft, completed, closed)",
            ),
            OpenApiParameter(
                name="date_from",
                type=str,
                description="Filter from date (YYYY-MM-DD)",
            ),
            OpenApiParameter(
                name="date_to",
                type=str,
                description="Filter to date (YYYY-MM-DD)",
            ),
        ],
        tags=["Night Audit"],
    ),
    retrieve=extend_schema(
        summary="Get night audit details",
        description="Get detailed information about a specific night audit.",
        tags=["Night Audit"],
    ),
    create=extend_schema(
        summary="Create/generate night audit",
        description="Create a new night audit for a specific date. Statistics are calculated automatically.",
        tags=["Night Audit"],
    ),
    update=extend_schema(
        summary="Update night audit",
        description="Update night audit details (only for draft audits).",
        tags=["Night Audit"],
    ),
    partial_update=extend_schema(
        summary="Partially update night audit",
        description="Partially update night audit details (only for draft audits).",
        tags=["Night Audit"],
    ),
    destroy=extend_schema(
        summary="Delete night audit",
        description="Delete a night audit (only for draft audits).",
        tags=["Night Audit"],
    ),
)
class NightAuditViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing night audits.

    Endpoints:
    - GET /night-audits/ - List all night audits
    - POST /night-audits/ - Generate night audit for a date
    - GET /night-audits/{id}/ - Get audit details
    - PUT /night-audits/{id}/ - Update audit (draft only)
    - DELETE /night-audits/{id}/ - Delete audit (draft only)
    - POST /night-audits/{id}/close/ - Close the audit
    - POST /night-audits/{id}/recalculate/ - Recalculate statistics
    - GET /night-audits/today/ - Get or create today's audit
    - GET /night-audits/latest/ - Get the most recent audit
    """

    queryset = NightAudit.objects.all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == "list":
            return NightAuditListSerializer
        if self.action == "create":
            return NightAuditCreateSerializer
        return NightAuditSerializer

    def get_queryset(self):
        """Filter queryset based on query parameters."""
        queryset = NightAudit.objects.all()

        # Filter by status
        status_filter = self.request.query_params.get("status")
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by date range
        date_from = self.request.query_params.get("date_from")
        date_to = self.request.query_params.get("date_to")
        if date_from:
            queryset = queryset.filter(audit_date__gte=date_from)
        if date_to:
            queryset = queryset.filter(audit_date__lte=date_to)

        return queryset.order_by("-audit_date")

    def create(self, request, *args, **kwargs):
        """Create or generate a night audit for a specific date."""
        from django.utils import timezone

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        audit_date = serializer.validated_data["audit_date"]
        notes = serializer.validated_data.get("notes", "")

        # Check if audit already exists for this date
        existing = NightAudit.objects.filter(audit_date=audit_date).first()
        if existing:
            return Response(
                {
                    "detail": f"Đã tồn tại kiểm toán cho ngày {audit_date}.",
                    "existing_id": existing.id,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Create new audit
        audit = NightAudit.objects.create(
            audit_date=audit_date,
            notes=notes,
            performed_by=request.user,
            performed_at=timezone.now(),
            status=NightAudit.Status.DRAFT,
        )

        # Calculate statistics
        audit.calculate_statistics()
        audit.save()

        return Response(
            NightAuditSerializer(audit).data,
            status=status.HTTP_201_CREATED,
        )

    def update(self, request, *args, **kwargs):
        """Update night audit (only draft audits)."""
        instance = self.get_object()

        if instance.status == NightAudit.Status.CLOSED:
            return Response(
                {"detail": "Không thể chỉnh sửa kiểm toán đã đóng."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        """Delete night audit (only draft audits)."""
        instance = self.get_object()

        if instance.status == NightAudit.Status.CLOSED:
            return Response(
                {"detail": "Không thể xóa kiểm toán đã đóng."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return super().destroy(request, *args, **kwargs)

    @extend_schema(
        summary="Close night audit",
        description="Close the audit - no more changes allowed after closing.",
        request=None,
        responses={200: NightAuditSerializer},
        tags=["Night Audit"],
    )
    @action(detail=True, methods=["post"], url_path="close")
    def close(self, request, pk=None):
        """Close the night audit."""
        audit = self.get_object()

        if audit.status == NightAudit.Status.CLOSED:
            return Response(
                {"detail": "Kiểm toán đã được đóng."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        audit.close_audit(request.user)
        return Response(NightAuditSerializer(audit).data)

    @extend_schema(
        summary="Recalculate statistics",
        description="Recalculate all statistics for the audit (only for non-closed audits).",
        request=None,
        responses={200: NightAuditSerializer},
        tags=["Night Audit"],
    )
    @action(detail=True, methods=["post"], url_path="recalculate")
    def recalculate(self, request, pk=None):
        """Recalculate audit statistics."""
        audit = self.get_object()

        if audit.status == NightAudit.Status.CLOSED:
            return Response(
                {"detail": "Không thể tính lại kiểm toán đã đóng."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        audit.calculate_statistics()
        audit.save()

        return Response(NightAuditSerializer(audit).data)

    @extend_schema(
        summary="Get today's audit",
        description="Get today's night audit. Creates a draft if not exists.",
        responses={200: NightAuditSerializer},
        tags=["Night Audit"],
    )
    @action(detail=False, methods=["get"], url_path="today")
    def today(self, request):
        """Get or create today's night audit."""
        from datetime import date

        from django.utils import timezone

        today = date.today()
        audit = NightAudit.objects.filter(audit_date=today).first()

        if not audit:
            # Create draft audit for today
            audit = NightAudit.objects.create(
                audit_date=today,
                performed_by=request.user,
                performed_at=timezone.now(),
                status=NightAudit.Status.DRAFT,
            )
            audit.calculate_statistics()
            audit.save()

        return Response(NightAuditSerializer(audit).data)

    @extend_schema(
        summary="Get latest audit",
        description="Get the most recent night audit.",
        responses={
            200: NightAuditSerializer,
            404: OpenApiResponse(description="No audits found"),
        },
        tags=["Night Audit"],
    )
    @action(detail=False, methods=["get"], url_path="latest")
    def latest(self, request):
        """Get the most recent night audit."""
        audit = NightAudit.objects.order_by("-audit_date").first()

        if not audit:
            return Response(
                {"detail": "Chưa có kiểm toán nào."},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(NightAuditSerializer(audit).data)
