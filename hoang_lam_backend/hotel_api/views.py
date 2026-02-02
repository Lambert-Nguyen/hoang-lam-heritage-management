"""
Views for API endpoints.
"""

from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import models
from django.db.models import Q
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import OpenApiParameter, OpenApiResponse, extend_schema, extend_schema_view
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Booking, FinancialCategory, FinancialEntry, Guest, HousekeepingTask, MaintenanceRequest, NightAudit, Room, RoomType
from .permissions import IsManager, IsStaff, IsStaffOrManager
from .serializers import (
    BookingListSerializer,
    BookingSerializer,
    BookingStatusUpdateSerializer,
    CheckInSerializer,
    CheckOutSerializer,
    CurrencyConversionSerializer,
    DepositRecordSerializer,
    ExchangeRateSerializer,
    FinancialCategoryListSerializer,
    FinancialCategorySerializer,
    FinancialEntryListSerializer,
    FinancialEntrySerializer,
    FolioItemSerializer,
    GuestListSerializer,
    GuestSearchSerializer,
    GuestSerializer,
    HousekeepingTaskCreateSerializer,
    HousekeepingTaskListSerializer,
    HousekeepingTaskSerializer,
    HousekeepingTaskUpdateSerializer,
    LoginSerializer,
    MaintenanceRequestCreateSerializer,
    MaintenanceRequestListSerializer,
    MaintenanceRequestSerializer,
    MaintenanceRequestUpdateSerializer,
    NightAuditListSerializer,
    NightAuditSerializer,
    OutstandingDepositSerializer,
    PasswordChangeSerializer,
    PaymentListSerializer,
    PaymentSerializer,
    ReceiptDataSerializer,
    ReceiptGenerateSerializer,
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


# ============================================================
# Payment ViewSet (Phase 2.1.3)
# ============================================================


class PaymentViewSet(viewsets.ModelViewSet):
    """
    API endpoints for Payment management.

    Provides:
    - List payments (with filtering by booking, type, status, date range)
    - Create payment
    - Retrieve payment details
    - Update payment
    - Delete payment (only pending payments)
    - Record deposit action
    - Get deposits for a booking
    - Get outstanding deposits report
    """

    permission_classes = [IsAuthenticated, IsStaffOrManager]

    def get_queryset(self):
        from .models import Payment

        queryset = Payment.objects.select_related(
            "booking__room",
            "booking__guest",
            "created_by",
        ).all()

        # Filter by booking
        booking_id = self.request.query_params.get("booking")
        if booking_id:
            queryset = queryset.filter(booking_id=booking_id)

        # Filter by payment type
        payment_type = self.request.query_params.get("payment_type")
        if payment_type:
            queryset = queryset.filter(payment_type=payment_type)

        # Filter by status
        payment_status = self.request.query_params.get("status")
        if payment_status:
            queryset = queryset.filter(status=payment_status)

        # Filter by date range
        date_from = self.request.query_params.get("date_from")
        date_to = self.request.query_params.get("date_to")
        if date_from:
            queryset = queryset.filter(payment_date__date__gte=date_from)
        if date_to:
            queryset = queryset.filter(payment_date__date__lte=date_to)

        return queryset

    def get_serializer_class(self):
        from .serializers import (
            PaymentCreateSerializer,
            PaymentListSerializer,
            PaymentSerializer,
        )

        if self.action == "list":
            return PaymentListSerializer
        elif self.action == "create":
            return PaymentCreateSerializer
        return PaymentSerializer

    @extend_schema(
        summary="List payments",
        description="Get a list of payments with optional filtering.",
        parameters=[
            OpenApiParameter("booking", OpenApiTypes.INT, description="Filter by booking ID"),
            OpenApiParameter("payment_type", OpenApiTypes.STR, description="Filter by type (deposit, room_charge, etc.)"),
            OpenApiParameter("status", OpenApiTypes.STR, description="Filter by status"),
            OpenApiParameter("date_from", OpenApiTypes.DATE, description="Filter by date from"),
            OpenApiParameter("date_to", OpenApiTypes.DATE, description="Filter by date to"),
        ],
        tags=["Payments"],
    )
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    @extend_schema(
        summary="Create payment",
        description="Create a new payment record.",
        tags=["Payments"],
    )
    def create(self, request, *args, **kwargs):
        return super().create(request, *args, **kwargs)

    @extend_schema(
        summary="Record deposit",
        description="Quick action to record a deposit payment for a booking.",
        request=DepositRecordSerializer,
        responses={201: PaymentSerializer},
        tags=["Payments"],
    )
    @action(detail=False, methods=["post"], url_path="record-deposit")
    def record_deposit(self, request):
        """Record a deposit payment for a booking."""
        from .models import Payment
        from .serializers import DepositRecordSerializer, PaymentSerializer

        serializer = DepositRecordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        booking = Booking.objects.get(id=serializer.validated_data["booking_id"])

        payment = Payment.objects.create(
            booking=booking,
            payment_type=Payment.PaymentType.DEPOSIT,
            amount=serializer.validated_data["amount"],
            payment_method=serializer.validated_data["payment_method"],
            transaction_id=serializer.validated_data.get("transaction_id", ""),
            notes=serializer.validated_data.get("notes", ""),
            status=Payment.Status.COMPLETED,
            created_by=request.user,
        )

        # Update booking deposit amount
        from django.db.models import Sum

        total_deposits = Payment.objects.filter(
            booking=booking,
            payment_type=Payment.PaymentType.DEPOSIT,
            status=Payment.Status.COMPLETED,
        ).aggregate(total=Sum("amount"))["total"] or 0

        booking.deposit_amount = total_deposits
        booking.deposit_paid = total_deposits >= booking.total_amount * Decimal("0.3")
        booking.save(update_fields=["deposit_amount", "deposit_paid"])

        return Response(PaymentSerializer(payment).data, status=status.HTTP_201_CREATED)

    @extend_schema(
        summary="Get booking deposits",
        description="Get all deposit payments for a specific booking.",
        parameters=[
            OpenApiParameter("booking_id", OpenApiTypes.INT, location=OpenApiParameter.PATH),
        ],
        responses={200: PaymentListSerializer(many=True)},
        tags=["Payments"],
    )
    @action(detail=False, methods=["get"], url_path="booking/(?P<booking_id>[^/.]+)/deposits")
    def booking_deposits(self, request, booking_id=None):
        """Get all deposits for a booking."""
        from .models import Payment
        from .serializers import PaymentListSerializer

        deposits = Payment.objects.filter(
            booking_id=booking_id,
            payment_type=Payment.PaymentType.DEPOSIT,
        ).order_by("-payment_date")

        serializer = PaymentListSerializer(deposits, many=True)
        return Response(serializer.data)

    @extend_schema(
        summary="Outstanding deposits report",
        description="Get list of bookings with outstanding/pending deposits.",
        responses={200: OutstandingDepositSerializer(many=True)},
        tags=["Payments"],
    )
    @action(detail=False, methods=["get"], url_path="outstanding-deposits")
    def outstanding_deposits(self, request):
        """Get bookings with outstanding deposits."""
        from .serializers import OutstandingDepositSerializer

        bookings = Booking.objects.filter(
            deposit_paid=False,
            status__in=[
                Booking.Status.CONFIRMED,
                Booking.Status.CHECKED_IN,
            ],
        ).select_related("room__room_type", "guest").order_by("check_in_date")

        serializer = OutstandingDepositSerializer(bookings, many=True)
        return Response(serializer.data)


# ============================================================
# Folio Item ViewSet (Phase 2.1.4)
# ============================================================


class FolioItemViewSet(viewsets.ModelViewSet):
    """
    API endpoints for Folio Item management (room charges).

    Provides:
    - List folio items
    - Create folio item
    - Update folio item
    - Void folio item
    - Get booking folio
    """

    permission_classes = [IsAuthenticated, IsStaffOrManager]

    def get_queryset(self):
        from .models import FolioItem

        queryset = FolioItem.objects.select_related(
            "booking__room",
            "booking__guest",
            "created_by",
        ).all()

        # Filter by booking
        booking_id = self.request.query_params.get("booking")
        if booking_id:
            queryset = queryset.filter(booking_id=booking_id)

        # Filter by type
        item_type = self.request.query_params.get("item_type")
        if item_type:
            queryset = queryset.filter(item_type=item_type)

        # Filter by status
        include_voided = self.request.query_params.get("include_voided", "false").lower() == "true"
        if not include_voided:
            queryset = queryset.filter(is_voided=False)

        return queryset

    def get_serializer_class(self):
        from .serializers import FolioItemCreateSerializer, FolioItemSerializer

        if self.action == "create":
            return FolioItemCreateSerializer
        return FolioItemSerializer

    def create(self, request, *args, **kwargs):
        """Create folio item and return full serialized response."""
        from .serializers import FolioItemCreateSerializer, FolioItemSerializer

        serializer = FolioItemCreateSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        instance = serializer.save()
        return Response(
            FolioItemSerializer(instance).data,
            status=status.HTTP_201_CREATED,
        )

    @extend_schema(
        summary="Void folio item",
        description="Void a folio item (soft delete with reason).",
        request={"type": "object", "properties": {"reason": {"type": "string"}}},
        tags=["Folio Items"],
    )
    @action(detail=True, methods=["post"], url_path="void")
    def void(self, request, pk=None):
        """Void a folio item."""
        from .serializers import FolioItemSerializer

        item = self.get_object()

        if item.is_voided:
            return Response(
                {"detail": "Chi phí này đã bị hủy."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if item.is_paid:
            return Response(
                {"detail": "Không thể hủy chi phí đã thanh toán."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        item.is_voided = True
        item.void_reason = request.data.get("reason", "")
        item.save()

        return Response(FolioItemSerializer(item).data)

    @extend_schema(
        summary="Get booking folio",
        description="Get all folio items for a specific booking.",
        parameters=[
            OpenApiParameter("booking_id", OpenApiTypes.INT, location=OpenApiParameter.PATH),
        ],
        responses={200: FolioItemSerializer(many=True)},
        tags=["Folio Items"],
    )
    @action(detail=False, methods=["get"], url_path="booking/(?P<booking_id>[^/.]+)")
    def booking_folio(self, request, booking_id=None):
        """Get all folio items for a booking."""
        from .models import FolioItem
        from .serializers import FolioItemSerializer

        items = FolioItem.objects.filter(
            booking_id=booking_id,
            is_voided=False,
        ).order_by("date", "created_at")

        serializer = FolioItemSerializer(items, many=True)

        # Calculate summary
        from django.db.models import Sum

        summary = items.aggregate(
            total=Sum("total_price"),
            paid=Sum("total_price", filter=models.Q(is_paid=True)),
            unpaid=Sum("total_price", filter=models.Q(is_paid=False)),
        )

        return Response({
            "items": serializer.data,
            "summary": {
                "total": summary["total"] or 0,
                "paid": summary["paid"] or 0,
                "unpaid": summary["unpaid"] or 0,
            },
        })


# ============================================================
# Exchange Rate ViewSet (Phase 2.6)
# ============================================================


class ExchangeRateViewSet(viewsets.ModelViewSet):
    """
    API endpoints for Exchange Rate management.

    Provides:
    - List exchange rates
    - Create exchange rate
    - Convert currency
    - Get latest rates
    """

    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        from .models import ExchangeRate

        queryset = ExchangeRate.objects.all()

        # Filter by currency pair
        from_currency = self.request.query_params.get("from_currency")
        to_currency = self.request.query_params.get("to_currency")
        if from_currency:
            queryset = queryset.filter(from_currency=from_currency.upper())
        if to_currency:
            queryset = queryset.filter(to_currency=to_currency.upper())

        # Filter by date
        date = self.request.query_params.get("date")
        if date:
            queryset = queryset.filter(date=date)

        return queryset

    def get_serializer_class(self):
        from .serializers import ExchangeRateCreateSerializer, ExchangeRateSerializer

        if self.action == "create":
            return ExchangeRateCreateSerializer
        return ExchangeRateSerializer

    @extend_schema(
        summary="Get latest rates",
        description="Get the latest exchange rates for all currency pairs.",
        responses={200: ExchangeRateSerializer(many=True)},
        tags=["Exchange Rates"],
    )
    @action(detail=False, methods=["get"], url_path="latest")
    def latest_rates(self, request):
        """Get latest exchange rates."""
        from .models import ExchangeRate
        from .serializers import ExchangeRateSerializer

        # Get latest rate for each currency pair
        from django.db.models import Max

        latest_dates = ExchangeRate.objects.values(
            "from_currency", "to_currency"
        ).annotate(latest_date=Max("date"))

        rates = []
        for item in latest_dates:
            rate = ExchangeRate.objects.filter(
                from_currency=item["from_currency"],
                to_currency=item["to_currency"],
                date=item["latest_date"],
            ).first()
            if rate:
                rates.append(rate)

        serializer = ExchangeRateSerializer(rates, many=True)
        return Response(serializer.data)

    @extend_schema(
        summary="Convert currency",
        description="Convert an amount from one currency to another.",
        request=CurrencyConversionSerializer,
        responses={
            200: {"type": "object", "properties": {
                "original_amount": {"type": "number"},
                "from_currency": {"type": "string"},
                "converted_amount": {"type": "number"},
                "to_currency": {"type": "string"},
                "rate": {"type": "number"},
                "date": {"type": "string", "format": "date"},
            }},
        },
        tags=["Exchange Rates"],
    )
    @action(detail=False, methods=["post"], url_path="convert")
    def convert(self, request):
        """Convert currency."""
        from .models import ExchangeRate
        from .serializers import CurrencyConversionSerializer

        serializer = CurrencyConversionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        amount = serializer.validated_data["amount"]
        from_currency = serializer.validated_data["from_currency"].upper()
        to_currency = serializer.validated_data["to_currency"].upper()
        date = serializer.validated_data.get("date")

        # If same currency, no conversion needed
        if from_currency == to_currency:
            return Response({
                "original_amount": amount,
                "from_currency": from_currency,
                "converted_amount": amount,
                "to_currency": to_currency,
                "rate": 1,
                "date": date or "N/A",
            })

        # Find exchange rate
        if date:
            rate = ExchangeRate.objects.filter(
                from_currency=from_currency,
                to_currency=to_currency,
                date=date,
            ).first()
        else:
            # Get latest rate
            rate = ExchangeRate.objects.filter(
                from_currency=from_currency,
                to_currency=to_currency,
            ).order_by("-date").first()

        if not rate:
            return Response(
                {"detail": f"Không tìm thấy tỷ giá cho {from_currency} sang {to_currency}."},
                status=status.HTTP_404_NOT_FOUND,
            )

        converted_amount = amount * rate.rate

        return Response({
            "original_amount": amount,
            "from_currency": from_currency,
            "converted_amount": converted_amount,
            "to_currency": to_currency,
            "rate": rate.rate,
            "date": rate.date,
        })


# ============================================================
# Receipt Generation ViewSet (Phase 2.8)
# ============================================================


class ReceiptViewSet(viewsets.ViewSet):
    """
    API endpoints for Receipt generation.

    Provides:
    - Generate receipt for booking
    - Generate receipt for payment
    - Get receipt data (JSON)
    - Download receipt (PDF)
    """

    permission_classes = [IsAuthenticated, IsStaffOrManager]

    def _get_receipt_data(self, booking, payment=None, include_folio=True):
        """Generate receipt data for a booking."""
        from django.utils import timezone
        from .models import FolioItem

        # Generate receipt number
        date_str = timezone.now().strftime("%Y%m%d")
        receipt_count = booking.payments.filter(
            receipt_generated=True,
        ).count() + 1
        receipt_number = f"INV-{booking.room.number}-{date_str}-{receipt_count:03d}"

        # Get folio items
        folio_items = []
        if include_folio:
            items = FolioItem.objects.filter(
                booking=booking,
                is_voided=False,
            ).order_by("date")
            folio_items = [
                {
                    "date": item.date.isoformat(),
                    "description": item.description,
                    "quantity": item.quantity,
                    "unit_price": float(item.unit_price),
                    "total": float(item.total_price),
                }
                for item in items
            ]

        return {
            "receipt_number": receipt_number,
            "receipt_date": timezone.now().isoformat(),
            "hotel_name": "Nhà Nghỉ Hoàng Lâm Heritage",
            "hotel_address": "123 Đường ABC, Phường XYZ, TP.HCM",
            "hotel_phone": "028 1234 5678",
            "guest_name": booking.guest.full_name,
            "guest_phone": booking.guest.phone,
            "guest_id_number": booking.guest.id_number or "",
            "room_number": booking.room.number,
            "room_type": booking.room.room_type.name,
            "check_in_date": booking.check_in_date.isoformat(),
            "check_out_date": booking.check_out_date.isoformat(),
            "nights": booking.nights,
            "room_total": float(booking.total_amount),
            "additional_charges": float(booking.additional_charges),
            "total_amount": float(booking.total_amount + booking.additional_charges),
            "deposit_paid": float(booking.deposit_amount),
            "balance_due": float(booking.balance_due),
            "folio_items": folio_items,
            "payment_method": booking.get_payment_method_display(),
            "created_by": self.request.user.get_full_name() or self.request.user.username,
        }

    @extend_schema(
        summary="Generate receipt data",
        description="Generate receipt data for a booking (JSON format).",
        request=ReceiptGenerateSerializer,
        responses={200: ReceiptDataSerializer},
        tags=["Receipts"],
    )
    @action(detail=False, methods=["post"], url_path="generate")
    def generate(self, request):
        """Generate receipt data."""
        from .serializers import ReceiptGenerateSerializer

        serializer = ReceiptGenerateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        booking_id = serializer.validated_data.get("booking_id")
        payment_id = serializer.validated_data.get("payment_id")
        include_folio = serializer.validated_data.get("include_folio", True)

        if payment_id:
            from .models import Payment

            payment = Payment.objects.select_related(
                "booking__room__room_type",
                "booking__guest",
            ).get(id=payment_id)
            booking = payment.booking
        else:
            booking = Booking.objects.select_related(
                "room__room_type",
                "guest",
            ).get(id=booking_id)
            payment = None

        receipt_data = self._get_receipt_data(booking, payment, include_folio)
        return Response(receipt_data)

    @extend_schema(
        summary="Download receipt PDF",
        description="Download receipt as PDF file.",
        parameters=[
            OpenApiParameter("booking_id", OpenApiTypes.INT, description="Booking ID"),
        ],
        tags=["Receipts"],
    )
    @action(detail=False, methods=["get"], url_path="download/(?P<booking_id>[^/.]+)")
    def download(self, request, booking_id=None):
        """Download receipt as PDF."""
        from django.http import HttpResponse

        try:
            booking = Booking.objects.select_related(
                "room__room_type",
                "guest",
            ).get(id=booking_id)
        except Booking.DoesNotExist:
            return Response(
                {"detail": "Không tìm thấy đặt phòng."},
                status=status.HTTP_404_NOT_FOUND,
            )

        receipt_data = self._get_receipt_data(booking)

        # Try to generate PDF
        try:
            from reportlab.lib.pagesizes import A4
            from reportlab.pdfgen import canvas
            from reportlab.lib.units import cm
            from io import BytesIO

            buffer = BytesIO()
            p = canvas.Canvas(buffer, pagesize=A4)
            width, height = A4

            # Header
            p.setFont("Helvetica-Bold", 16)
            p.drawString(2 * cm, height - 2 * cm, receipt_data["hotel_name"])

            p.setFont("Helvetica", 10)
            p.drawString(2 * cm, height - 2.6 * cm, receipt_data["hotel_address"])
            p.drawString(2 * cm, height - 3 * cm, f"Tel: {receipt_data['hotel_phone']}")

            # Receipt info
            p.setFont("Helvetica-Bold", 14)
            p.drawString(2 * cm, height - 4 * cm, f"HÓA ĐƠN #{receipt_data['receipt_number']}")

            p.setFont("Helvetica", 10)
            y = height - 5 * cm

            # Guest info
            p.drawString(2 * cm, y, f"Khách hàng: {receipt_data['guest_name']}")
            y -= 0.5 * cm
            p.drawString(2 * cm, y, f"SĐT: {receipt_data['guest_phone']}")
            y -= 0.5 * cm
            if receipt_data["guest_id_number"]:
                p.drawString(2 * cm, y, f"CCCD/Passport: {receipt_data['guest_id_number']}")
                y -= 0.5 * cm

            # Booking info
            y -= 0.5 * cm
            p.drawString(2 * cm, y, f"Phòng: {receipt_data['room_number']} - {receipt_data['room_type']}")
            y -= 0.5 * cm
            p.drawString(2 * cm, y, f"Ngày: {receipt_data['check_in_date']} - {receipt_data['check_out_date']} ({receipt_data['nights']} đêm)")
            y -= cm

            # Financial
            p.setFont("Helvetica-Bold", 10)
            p.drawString(2 * cm, y, "Chi tiết thanh toán:")
            y -= 0.5 * cm

            p.setFont("Helvetica", 10)
            p.drawString(2 * cm, y, f"Tiền phòng: {receipt_data['room_total']:,.0f} VND")
            y -= 0.5 * cm
            if receipt_data["additional_charges"] > 0:
                p.drawString(2 * cm, y, f"Chi phí phát sinh: {receipt_data['additional_charges']:,.0f} VND")
                y -= 0.5 * cm
            p.drawString(2 * cm, y, f"Tổng cộng: {receipt_data['total_amount']:,.0f} VND")
            y -= 0.5 * cm
            p.drawString(2 * cm, y, f"Đã đặt cọc: {receipt_data['deposit_paid']:,.0f} VND")
            y -= 0.5 * cm
            p.setFont("Helvetica-Bold", 10)
            p.drawString(2 * cm, y, f"Còn lại: {receipt_data['balance_due']:,.0f} VND")

            # Footer
            p.setFont("Helvetica", 8)
            p.drawString(2 * cm, 2 * cm, f"Người lập: {receipt_data['created_by']}")
            p.drawString(2 * cm, 1.5 * cm, f"Ngày: {receipt_data['receipt_date']}")

            p.showPage()
            p.save()

            buffer.seek(0)
            response = HttpResponse(buffer.getvalue(), content_type="application/pdf")
            response["Content-Disposition"] = f'attachment; filename="receipt_{booking_id}.pdf"'
            return response

        except ImportError:
            # reportlab not installed, return JSON data instead
            return Response({
                "detail": "PDF generation not available. Returning JSON data.",
                "data": receipt_data,
            })


@extend_schema_view(
    list=extend_schema(
        summary="List housekeeping tasks",
        description="List all housekeeping tasks with filtering options.",
        parameters=[
            OpenApiParameter(
                name="room",
                type=OpenApiTypes.INT,
                description="Filter by room ID",
            ),
            OpenApiParameter(
                name="status",
                type=OpenApiTypes.STR,
                description="Filter by status (pending, in_progress, completed, verified)",
            ),
            OpenApiParameter(
                name="task_type",
                type=OpenApiTypes.STR,
                description="Filter by task type (cleaning, turndown, inspection, deep_clean, laundry)",
            ),
            OpenApiParameter(
                name="assigned_to",
                type=OpenApiTypes.INT,
                description="Filter by assigned user ID",
            ),
            OpenApiParameter(
                name="scheduled_date",
                type=OpenApiTypes.DATE,
                description="Filter by scheduled date (YYYY-MM-DD)",
            ),
            OpenApiParameter(
                name="priority",
                type=OpenApiTypes.STR,
                description="Filter by priority (low, medium, high, urgent)",
            ),
        ],
        tags=["Housekeeping"],
    ),
    retrieve=extend_schema(
        summary="Get housekeeping task details",
        description="Get detailed information about a specific housekeeping task.",
        tags=["Housekeeping"],
    ),
    create=extend_schema(
        summary="Create housekeeping task",
        description="Create a new housekeeping task.",
        tags=["Housekeeping"],
    ),
    update=extend_schema(
        summary="Update housekeeping task",
        description="Update a housekeeping task.",
        tags=["Housekeeping"],
    ),
    partial_update=extend_schema(
        summary="Partial update housekeeping task",
        description="Partially update a housekeeping task.",
        tags=["Housekeeping"],
    ),
    destroy=extend_schema(
        summary="Delete housekeeping task",
        description="Delete a housekeeping task.",
        tags=["Housekeeping"],
    ),
)
class HousekeepingTaskViewSet(viewsets.ModelViewSet):
    """ViewSet for managing housekeeping tasks."""

    permission_classes = [IsAuthenticated, IsStaffOrManager]
    queryset = HousekeepingTask.objects.all()

    def get_serializer_class(self):
        if self.action == "list":
            return HousekeepingTaskListSerializer
        elif self.action == "create":
            return HousekeepingTaskCreateSerializer
        elif self.action in ["update", "partial_update"]:
            return HousekeepingTaskUpdateSerializer
        return HousekeepingTaskSerializer

    def get_queryset(self):
        queryset = HousekeepingTask.objects.select_related(
            "room", "assigned_to", "created_by"
        ).order_by("-created_at")

        # Filter by room
        room = self.request.query_params.get("room")
        if room:
            queryset = queryset.filter(room_id=room)

        # Filter by status
        status_filter = self.request.query_params.get("status")
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by task type
        task_type = self.request.query_params.get("task_type")
        if task_type:
            queryset = queryset.filter(task_type=task_type)

        # Filter by assigned user
        assigned_to = self.request.query_params.get("assigned_to")
        if assigned_to:
            queryset = queryset.filter(assigned_to_id=assigned_to)

        # Filter by scheduled date
        scheduled_date = self.request.query_params.get("scheduled_date")
        if scheduled_date:
            queryset = queryset.filter(scheduled_date=scheduled_date)

        # Filter by priority
        priority = self.request.query_params.get("priority")
        if priority:
            queryset = queryset.filter(priority=priority)

        return queryset

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @extend_schema(
        summary="Assign housekeeping task",
        description="Assign a housekeeping task to a staff member.",
        request={
            "type": "object",
            "properties": {
                "assigned_to": {
                    "type": "integer",
                    "description": "User ID of the staff member to assign",
                },
            },
            "required": ["assigned_to"],
        },
        responses={
            200: HousekeepingTaskSerializer,
            400: OpenApiResponse(description="Invalid request"),
            404: OpenApiResponse(description="Task or user not found"),
        },
        tags=["Housekeeping"],
    )
    @action(detail=True, methods=["post"])
    def assign(self, request, pk=None):
        """Assign the task to a staff member."""
        task = self.get_object()
        assigned_to_id = request.data.get("assigned_to")

        if not assigned_to_id:
            return Response(
                {"detail": "assigned_to is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(pk=assigned_to_id)
        except User.DoesNotExist:
            return Response(
                {"detail": "User not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        task.assigned_to = user
        if task.status == "pending":
            task.status = "in_progress"
        task.save()

        serializer = HousekeepingTaskSerializer(task)
        return Response(serializer.data)

    @extend_schema(
        summary="Complete housekeeping task",
        description="Mark a housekeeping task as completed.",
        request={
            "type": "object",
            "properties": {
                "notes": {
                    "type": "string",
                    "description": "Optional completion notes",
                },
            },
        },
        responses={
            200: HousekeepingTaskSerializer,
            400: OpenApiResponse(description="Task already completed or verified"),
        },
        tags=["Housekeeping"],
    )
    @action(detail=True, methods=["post"])
    def complete(self, request, pk=None):
        """Mark the task as completed."""
        from django.utils import timezone

        task = self.get_object()

        if task.status in ["completed", "verified"]:
            return Response(
                {"detail": f"Cannot complete task with status '{task.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        task.status = "completed"
        task.completed_at = timezone.now()
        if request.data.get("notes"):
            task.notes = request.data.get("notes")
        task.save()

        # Update room status to available if it was a cleaning task
        if task.task_type in ["checkout_clean", "stay_clean", "deep_clean"] and task.room:
            task.room.status = Room.Status.AVAILABLE
            task.room.save()

        serializer = HousekeepingTaskSerializer(task)
        return Response(serializer.data)

    @extend_schema(
        summary="Verify housekeeping task",
        description="Verify a completed housekeeping task (manager only).",
        request={
            "type": "object",
            "properties": {
                "notes": {
                    "type": "string",
                    "description": "Optional verification notes",
                },
            },
        },
        responses={
            200: HousekeepingTaskSerializer,
            400: OpenApiResponse(description="Task not completed"),
        },
        tags=["Housekeeping"],
    )
    @action(detail=True, methods=["post"])
    def verify(self, request, pk=None):
        """Verify the completed task."""
        task = self.get_object()

        if task.status != "completed":
            return Response(
                {"detail": "Only completed tasks can be verified."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        task.status = "verified"
        if request.data.get("notes"):
            task.notes = f"{task.notes}\nVerified: {request.data.get('notes')}" if task.notes else f"Verified: {request.data.get('notes')}"
        task.save()

        serializer = HousekeepingTaskSerializer(task)
        return Response(serializer.data)

    @extend_schema(
        summary="Get tasks for today",
        description="Get all housekeeping tasks scheduled for today.",
        responses={
            200: HousekeepingTaskListSerializer(many=True),
        },
        tags=["Housekeeping"],
    )
    @action(detail=False, methods=["get"])
    def today(self, request):
        """Get tasks scheduled for today."""
        from django.utils import timezone

        today = timezone.now().date()
        queryset = self.get_queryset().filter(scheduled_date=today)
        serializer = HousekeepingTaskListSerializer(queryset, many=True)
        return Response(serializer.data)

    @extend_schema(
        summary="Get my tasks",
        description="Get housekeeping tasks assigned to the current user.",
        responses={
            200: HousekeepingTaskListSerializer(many=True),
        },
        tags=["Housekeeping"],
    )
    @action(detail=False, methods=["get"])
    def my_tasks(self, request):
        """Get tasks assigned to the current user."""
        queryset = self.get_queryset().filter(
            assigned_to=request.user,
            status__in=["pending", "in_progress"],
        )
        serializer = HousekeepingTaskListSerializer(queryset, many=True)
        return Response(serializer.data)


@extend_schema_view(
    list=extend_schema(
        summary="List maintenance requests",
        description="List all maintenance requests with filtering options.",
        parameters=[
            OpenApiParameter(
                name="room",
                type=OpenApiTypes.INT,
                description="Filter by room ID",
            ),
            OpenApiParameter(
                name="status",
                type=OpenApiTypes.STR,
                description="Filter by status (pending, assigned, in_progress, on_hold, completed, cancelled)",
            ),
            OpenApiParameter(
                name="priority",
                type=OpenApiTypes.STR,
                description="Filter by priority (low, medium, high, urgent)",
            ),
            OpenApiParameter(
                name="category",
                type=OpenApiTypes.STR,
                description="Filter by category (electrical, plumbing, ac_heating, furniture, appliance, structural, safety, other)",
            ),
            OpenApiParameter(
                name="assigned_to",
                type=OpenApiTypes.INT,
                description="Filter by assigned user ID",
            ),
        ],
        tags=["Maintenance"],
    ),
    retrieve=extend_schema(
        summary="Get maintenance request details",
        description="Get detailed information about a specific maintenance request.",
        tags=["Maintenance"],
    ),
    create=extend_schema(
        summary="Create maintenance request",
        description="Create a new maintenance request.",
        tags=["Maintenance"],
    ),
    update=extend_schema(
        summary="Update maintenance request",
        description="Update a maintenance request.",
        tags=["Maintenance"],
    ),
    partial_update=extend_schema(
        summary="Partial update maintenance request",
        description="Partially update a maintenance request.",
        tags=["Maintenance"],
    ),
    destroy=extend_schema(
        summary="Delete maintenance request",
        description="Delete a maintenance request.",
        tags=["Maintenance"],
    ),
)
class MaintenanceRequestViewSet(viewsets.ModelViewSet):
    """ViewSet for managing maintenance requests."""

    permission_classes = [IsAuthenticated, IsStaffOrManager]
    queryset = MaintenanceRequest.objects.all()

    def get_serializer_class(self):
        if self.action == "list":
            return MaintenanceRequestListSerializer
        elif self.action == "create":
            return MaintenanceRequestCreateSerializer
        elif self.action in ["update", "partial_update"]:
            return MaintenanceRequestUpdateSerializer
        return MaintenanceRequestSerializer

    def get_queryset(self):
        queryset = MaintenanceRequest.objects.select_related(
            "room", "reported_by", "assigned_to", "completed_by"
        ).order_by("-created_at")

        # Filter by room
        room = self.request.query_params.get("room")
        if room:
            queryset = queryset.filter(room_id=room)

        # Filter by status
        status_filter = self.request.query_params.get("status")
        if status_filter:
            queryset = queryset.filter(status=status_filter)

        # Filter by priority
        priority = self.request.query_params.get("priority")
        if priority:
            queryset = queryset.filter(priority=priority)

        # Filter by category
        category = self.request.query_params.get("category")
        if category:
            queryset = queryset.filter(category=category)

        # Filter by assigned user
        assigned_to = self.request.query_params.get("assigned_to")
        if assigned_to:
            queryset = queryset.filter(assigned_to_id=assigned_to)

        return queryset

    def perform_create(self, serializer):
        serializer.save(reported_by=self.request.user)

    @extend_schema(
        summary="Assign maintenance request",
        description="Assign a maintenance request to a staff member.",
        request={
            "type": "object",
            "properties": {
                "assigned_to": {
                    "type": "integer",
                    "description": "User ID of the staff member to assign",
                },
                "estimated_cost": {
                    "type": "number",
                    "description": "Estimated cost for the repair",
                },
            },
            "required": ["assigned_to"],
        },
        responses={
            200: MaintenanceRequestSerializer,
            400: OpenApiResponse(description="Invalid request"),
            404: OpenApiResponse(description="Request or user not found"),
        },
        tags=["Maintenance"],
    )
    @action(detail=True, methods=["post"])
    def assign(self, request, pk=None):
        """Assign the request to a staff member."""
        maintenance_request = self.get_object()
        assigned_to_id = request.data.get("assigned_to")

        if not assigned_to_id:
            return Response(
                {"detail": "assigned_to is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(pk=assigned_to_id)
        except User.DoesNotExist:
            return Response(
                {"detail": "User not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        maintenance_request.assign(user)

        # Update estimated cost if provided
        if request.data.get("estimated_cost"):
            maintenance_request.estimated_cost = request.data.get("estimated_cost")
            maintenance_request.save()

        serializer = MaintenanceRequestSerializer(maintenance_request)
        return Response(serializer.data)

    @extend_schema(
        summary="Complete maintenance request",
        description="Mark a maintenance request as completed.",
        request={
            "type": "object",
            "properties": {
                "actual_cost": {
                    "type": "number",
                    "description": "Actual cost of the repair",
                },
                "resolution_notes": {
                    "type": "string",
                    "description": "Notes about the resolution",
                },
            },
        },
        responses={
            200: MaintenanceRequestSerializer,
            400: OpenApiResponse(description="Request not in progress"),
        },
        tags=["Maintenance"],
    )
    @action(detail=True, methods=["post"])
    def complete(self, request, pk=None):
        """Mark the request as completed."""
        maintenance_request = self.get_object()

        if maintenance_request.status not in ["assigned", "in_progress"]:
            return Response(
                {"detail": f"Cannot complete request with status '{maintenance_request.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        actual_cost = request.data.get("actual_cost")
        resolution_notes = request.data.get("resolution_notes", "")

        # Update actual cost if provided
        if actual_cost is not None:
            maintenance_request.actual_cost = actual_cost
            maintenance_request.save()

        # Use the model's complete method
        maintenance_request.complete(request.user, resolution_notes)

        serializer = MaintenanceRequestSerializer(maintenance_request)
        return Response(serializer.data)

    @extend_schema(
        summary="Put maintenance request on hold",
        description="Put a maintenance request on hold.",
        request={
            "type": "object",
            "properties": {
                "reason": {
                    "type": "string",
                    "description": "Reason for putting on hold",
                },
            },
        },
        responses={
            200: MaintenanceRequestSerializer,
            400: OpenApiResponse(description="Invalid status transition"),
        },
        tags=["Maintenance"],
    )
    @action(detail=True, methods=["post"])
    def hold(self, request, pk=None):
        """Put the request on hold."""
        maintenance_request = self.get_object()

        if maintenance_request.status in ["completed", "cancelled"]:
            return Response(
                {"detail": f"Cannot hold request with status '{maintenance_request.status}'."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        maintenance_request.status = "on_hold"
        if request.data.get("reason"):
            maintenance_request.resolution_notes = f"{maintenance_request.resolution_notes}\nOn hold: {request.data.get('reason')}" if maintenance_request.resolution_notes else f"On hold: {request.data.get('reason')}"
        maintenance_request.save()

        serializer = MaintenanceRequestSerializer(maintenance_request)
        return Response(serializer.data)

    @extend_schema(
        summary="Resume maintenance request",
        description="Resume a maintenance request from on hold.",
        responses={
            200: MaintenanceRequestSerializer,
            400: OpenApiResponse(description="Request not on hold"),
        },
        tags=["Maintenance"],
    )
    @action(detail=True, methods=["post"])
    def resume(self, request, pk=None):
        """Resume the request from on hold."""
        maintenance_request = self.get_object()

        if maintenance_request.status != "on_hold":
            return Response(
                {"detail": "Request is not on hold."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        maintenance_request.status = "in_progress" if maintenance_request.assigned_to else "assigned"
        maintenance_request.save()

        serializer = MaintenanceRequestSerializer(maintenance_request)
        return Response(serializer.data)

    @extend_schema(
        summary="Cancel maintenance request",
        description="Cancel a maintenance request.",
        request={
            "type": "object",
            "properties": {
                "reason": {
                    "type": "string",
                    "description": "Reason for cancellation",
                },
            },
        },
        responses={
            200: MaintenanceRequestSerializer,
            400: OpenApiResponse(description="Request already completed"),
        },
        tags=["Maintenance"],
    )
    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        """Cancel the request."""
        maintenance_request = self.get_object()

        if maintenance_request.status == "completed":
            return Response(
                {"detail": "Cannot cancel completed request."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        maintenance_request.status = "cancelled"
        if request.data.get("reason"):
            maintenance_request.resolution_notes = f"{maintenance_request.resolution_notes}\nCancelled: {request.data.get('reason')}" if maintenance_request.resolution_notes else f"Cancelled: {request.data.get('reason')}"
        maintenance_request.save()

        serializer = MaintenanceRequestSerializer(maintenance_request)
        return Response(serializer.data)

    @extend_schema(
        summary="Get urgent requests",
        description="Get all urgent and high priority maintenance requests that are not completed.",
        responses={
            200: MaintenanceRequestListSerializer(many=True),
        },
        tags=["Maintenance"],
    )
    @action(detail=False, methods=["get"])
    def urgent(self, request):
        """Get urgent and high priority requests."""
        queryset = self.get_queryset().filter(
            priority__in=["urgent", "high"],
            status__in=["pending", "assigned", "in_progress", "on_hold"],
        )
        serializer = MaintenanceRequestListSerializer(queryset, many=True)
        return Response(serializer.data)

    @extend_schema(
        summary="Get my requests",
        description="Get maintenance requests assigned to the current user.",
        responses={
            200: MaintenanceRequestListSerializer(many=True),
        },
        tags=["Maintenance"],
    )
    @action(detail=False, methods=["get"])
    def my_requests(self, request):
        """Get requests assigned to the current user."""
        queryset = self.get_queryset().filter(
            assigned_to=request.user,
            status__in=["assigned", "in_progress", "on_hold"],
        )
        serializer = MaintenanceRequestListSerializer(queryset, many=True)
        return Response(serializer.data)
